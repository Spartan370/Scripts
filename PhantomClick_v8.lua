local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterGui        = game:GetService("StarterGui")
local SoundService      = game:GetService("SoundService")
local HttpService       = game:GetService("HttpService")
local CollectionService = game:GetService("CollectionService")

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")
local CAM = Workspace.CurrentCamera

for _, v in ipairs(PG:GetChildren()) do
    if v.Name == "PhantomV6" or v.Name == "PhantomV7" or v.Name == "PhantomV8" then v:Destroy() end
end

local MAX_BURST  = 8
local CPS_WINDOW = 1.0
local VERSION    = "v8"
local BUILD      = "SPECTRE"

local State = {
    enabled       = false,
    mode          = "AUTO",
    modeLocked    = false,
    cps           = 15,
    MAX_CPS       = 999,
    MIN_CPS       = 1,
    target        = nil,
    targetName    = "None",
    guiTarget     = nil,
    guiTargetName = "None",
    expanded      = false,
    realCps       = 0,
    selectMode    = false,
    totalClicks   = 0,
    sessionStart  = tick(),
    afkGuard      = false,
    afkInterval   = 25,
    autoRespawn   = false,
    soundFeedback = false,
    perfMode      = false,
    opacity       = 1.0,
    showCrosshair = false,
    multiFireAll  = false,
    remoteArgs    = {},
    targetHistory = {},
    hotkey        = Enum.KeyCode.RightBracket,
    activeTab     = "MAIN",
    lastFireTime  = 0,
    targetDist    = 0,
    serverDebounce = false,
    lastDebounceWarn = 0,
    lockOnMode    = false,
    lockOnTarget  = nil,
    walkToTarget  = false,
    autoEquipName = "",
    flashEnabled  = true,
}

local clickBucket  = {}
local accum        = 0.0
local lastTime     = tick()
local afkTimer     = tick()
local afkStep      = 0
local heartbeatSkip = 0
local PERF_SKIP    = 3

local function safeParent(t)
    if not t then return false end
    local ok, p = pcall(function() return t.Parent end)
    return ok and p ~= nil
end

local function findDeepChild(root, className)
    if not root then return nil end
    local found = root:FindFirstChildOfClass(className)
    if found then return found end
    if root.Parent then
        found = root.Parent:FindFirstChildOfClass(className)
        if found then return found end
        if root.Parent.Parent then
            found = root.Parent.Parent:FindFirstChildOfClass(className)
            if found then return found end
        end
    end
    return nil
end

local function findClickDetector(part) return findDeepChild(part, "ClickDetector") end
local function findProximityPrompt(part) return findDeepChild(part, "ProximityPrompt") end

local function getRayTarget(ox, oy)
    local vp = CAM.ViewportSize
    if vp.X <= 0 or vp.Y <= 0 then return nil, 0 end
    local sx = ox or (vp.X / 2)
    local sy = oy or (vp.Y / 2)
    local ray    = CAM:ScreenPointToRay(sx, sy)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    if LP.Character then
        params.FilterDescendantsInstances = {LP.Character}
    end
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 400, params)
    if result then
        local dist = (result.Position - CAM.CFrame.Position).Magnitude
        return result.Instance, dist
    end
    return nil, 0
end

local function findGuiButtonAt(x, y)
    local ok, objects = pcall(function()
        return PG:GetGuiObjectsAtPosition(x, y)
    end)
    if not ok or not objects then return nil end
    for _, obj in ipairs(objects) do
        if obj:IsA("GuiButton") and obj.Visible and obj.Active then
            local sg = obj:FindFirstAncestorOfClass("ScreenGui")
            if sg and sg.Name ~= "PhantomV8" then
                return obj
            end
        end
    end
    return nil
end

local function findToolRemote()
    local char = LP.Character
    if not char then return nil, nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then
        local bp = LP:FindFirstChildOfClass("Backpack")
        if bp and State.autoEquipName ~= "" then
            for _, t in ipairs(bp:GetChildren()) do
                if t:IsA("Tool") and t.Name:lower():find(State.autoEquipName:lower(), 1, true) then
                    humanoid = char:FindFirstChildOfClass("Humanoid")
                    if humanoid then
                        humanoid:EquipTool(t)
                        tool = t
                        break
                    end
                end
            end
        end
    end
    if not tool then return nil, nil end
    local names = {
        "Attack","Hit","Swing","Action","Use","Click","Fire","Damage",
        "Event","Activate","Perform","Cast","Strike","Slash","Stab",
        "Shoot","Throw","Place","Build","Mine","Harvest","Collect"
    }
    for _, n in ipairs(names) do
        local r = tool:FindFirstChild(n) or tool:FindFirstChild(n.."Event") or tool:FindFirstChild(n.."Remote")
        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
            return r, tool
        end
    end
    local r = tool:FindFirstChildOfClass("RemoteEvent") or tool:FindFirstChildOfClass("RemoteFunction")
    if r then return r, tool end
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("RemoteEvent") then
            local cn = child.Name:lower()
            local tn = tool.Name:lower()
            if cn:find(tn, 1, true) or tn:find(cn, 1, true) then
                return child, tool
            end
        end
    end
    for _, child in ipairs(ReplicatedStorage:GetDescendants()) do
        if child:IsA("RemoteEvent") then
            local cn = child.Name:lower()
            if cn:find("attack",1,true) or cn:find("hit",1,true) or cn:find("swing",1,true) then
                return child, tool
            end
        end
    end
    return nil, tool
end

local function classifyPart(part)
    if not part then return nil, nil, "NONE" end
    local cd = findClickDetector(part)
    if cd then return cd, "CLICK", "ClickDetector: "..part.Name end
    local pp = findProximityPrompt(part)
    if pp then return pp, "PROMPT", "Prompt: "..part.Name end
    return part, "TOUCH", "Touch: "..part.Name
end

local function pushHistory(target, name, mode)
    for i, h in ipairs(State.targetHistory) do
        if h.target == target then
            table.remove(State.targetHistory, i)
            break
        end
    end
    table.insert(State.targetHistory, 1, {target=target, name=name, mode=mode, time=tick()})
    if #State.targetHistory > 5 then
        table.remove(State.targetHistory, #State.targetHistory)
    end
end

local function autoDetect()
    local part, dist = getRayTarget()
    State.targetDist = dist
    if not part then
        local remote, tool = findToolRemote()
        if remote then
            State.target     = remote
            if not State.modeLocked then State.mode = "REMOTE" end
            State.targetName = (tool and tool.Name or "?").." → "..remote.Name
            return
        end
        State.target     = nil
        State.targetName = "Nothing in crosshair"
        if not State.modeLocked then State.mode = "AUTO" end
        return
    end
    local obj, mode, name = classifyPart(part)
    State.target     = obj
    State.targetName = name
    if not State.modeLocked then State.mode = mode end
end

local function setManualTarget(screenX, screenY)
    local vp = CAM.ViewportSize
    if vp.X <= 0 or vp.Y <= 0 then return end

    local guiBtn = findGuiButtonAt(screenX, screenY)
    if guiBtn then
        State.guiTarget     = guiBtn
        State.target        = guiBtn
        State.mode          = "GUI"
        State.modeLocked    = true
        State.targetName    = "GUI: "..guiBtn.Name
        State.guiTargetName = guiBtn.Name
        pushHistory(guiBtn, "GUI: "..guiBtn.Name, "GUI")
        return
    end

    local part, dist = getRayTarget(screenX, screenY)
    State.targetDist = dist
    if part then
        local obj, mode, name = classifyPart(part)
        State.target     = obj
        State.mode       = mode
        State.modeLocked = true
        State.targetName = name
        pushHistory(obj, name, mode)
        return
    end

    State.targetName  = string.format("Screen (%.0f, %.0f)", screenX, screenY)
    State.mode        = "AUTO"
    State.modeLocked  = false
    State.target      = nil
end

local flashCallbacks = {}
local function fireClick()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")

    if not safeParent(State.target) then
        if State.modeLocked then
            State.modeLocked = false
            State.target     = nil
            State.targetName = "Target gone"
        end
        if State.mode == "AUTO" then autoDetect() end
    end

    local t = State.target
    if not t then return end

    local fired = false

    if State.mode == "TOUCH" or State.multiFireAll then
        if firetouchinterest and hrp and t:IsA("BasePart") then
            pcall(firetouchinterest, t, hrp, 0)
            task.wait(0.002)
            pcall(firetouchinterest, t, hrp, 1)
            fired = true
        end
    end

    if State.mode == "CLICK" or State.multiFireAll then
        if fireclickdetector and (t:IsA("ClickDetector") or findClickDetector(t) ~= nil) then
            local cd = t:IsA("ClickDetector") and t or findClickDetector(t)
            if cd then
                pcall(fireclickdetector, cd, 0)
                fired = true
            end
        end
    end

    if State.mode == "PROMPT" or State.multiFireAll then
        if fireproximityprompt and (t:IsA("ProximityPrompt") or findProximityPrompt(t) ~= nil) then
            local pp = t:IsA("ProximityPrompt") and t or findProximityPrompt(t)
            if pp then
                pcall(fireproximityprompt, pp)
                if pp.HoldDuration and pp.HoldDuration > 0 then
                    pcall(fireproximityprompt, pp)
                end
                fired = true
            end
        end
    end

    if State.mode == "REMOTE" or State.mode == "TOOL" then
        if t:IsA("RemoteEvent") then
            if #State.remoteArgs > 0 then
                pcall(function() t:FireServer(table.unpack(State.remoteArgs)) end)
            else
                pcall(function() t:FireServer() end)
            end
            fired = true
        elseif t:IsA("RemoteFunction") then
            pcall(function() t:InvokeServer() end)
            fired = true
        end
    end

    if State.mode == "GUI" then
        local gb = State.guiTarget or (t:IsA("GuiButton") and t or nil)
        if gb and safeParent(gb) then
            pcall(function() gb.MouseButton1Click:Fire() end)
            pcall(function() gb.Activated:Fire(InputObject.new and InputObject.new() or nil) end)
            local inner = gb:FindFirstChildOfClass("GuiButton")
            if inner then pcall(function() inner.MouseButton1Click:Fire() end) end
            fired = true
        else
            State.guiTarget  = nil
            State.target     = nil
            State.targetName = "GUI target lost"
            State.modeLocked = false
            State.mode       = "AUTO"
        end
    end

    if fired then
        State.totalClicks  = State.totalClicks + 1
        State.lastFireTime = tick()
        for _, cb in ipairs(flashCallbacks) do
            pcall(cb)
        end
        if State.soundFeedback then
            pcall(function()
                local s = Instance.new("Sound")
                s.SoundId  = "rbxasset://sounds/uuhhh.wav"
                s.Volume   = 0.08
                s.RollOffMaxDistance = 0
                s.Parent   = SoundService
                s:Play()
                game:GetService("Debris"):AddItem(s, 0.3)
            end)
        end
    end
end

local function doLockOn()
    if not State.lockOnMode or not State.lockOnTarget then return end
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    if not safeParent(State.lockOnTarget) then
        State.lockOnTarget = nil
        State.lockOnMode   = false
        return
    end
    local targetPos = State.lockOnTarget.CFrame.Position
    local camCF     = CAM.CFrame
    local lookDir   = (targetPos - camCF.Position).Unit
    local newCF     = CFrame.new(camCF.Position, camCF.Position + lookDir)
    CAM.CFrame      = camCF:Lerp(newCF, 0.12)
end

local function doWalkTo()
    if not State.walkToTarget or not State.target then return end
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    if not hrp or not hum then return end
    if not safeParent(State.target) then return end
    local ok, pos = pcall(function()
        if State.target:IsA("BasePart") then return State.target.Position end
        if State.target:IsA("Model") and State.target.PrimaryPart then
            return State.target.PrimaryPart.Position
        end
        return nil
    end)
    if ok and pos then
        local dist = (hrp.Position - pos).Magnitude
        if dist > 10 then
            hum:MoveTo(pos)
        end
    end
end

local function doAfkGuard()
    if not State.afkGuard then return end
    if tick() - afkTimer < State.afkInterval then return end
    afkTimer = tick()
    local char = LP.Character
    local hum  = char and char:FindFirstChildOfClass("Humanoid")
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")
    if not hum or not hrp then return end
    afkStep = afkStep + 1
    local dirs = {
        hrp.CFrame.LookVector,
        -hrp.CFrame.LookVector,
        hrp.CFrame.RightVector,
        -hrp.CFrame.RightVector,
    }
    local dir = dirs[(afkStep % 4) + 1]
    local target = hrp.Position + dir * 0.5
    hum:MoveTo(target)
    task.delay(0.3, function()
        if hum and hum.Parent then
            hum:MoveTo(hrp.Position)
        end
    end)
end

local function doAutoRespawn()
    if not State.autoRespawn then return end
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum and hum.Health <= 0 then
        pcall(function()
            LP:LoadCharacter()
        end)
    end
end

task.spawn(function()
    while true do
        if State.enabled then
            local now   = tick()
            local delta = math.min(now - lastTime, 0.2)
            lastTime    = now
            accum       = accum + delta * State.cps
            if accum > MAX_BURST then accum = MAX_BURST end
            if State.mode == "AUTO" and not State.modeLocked then
                autoDetect()
            end
            while accum >= 1.0 do
                accum = accum - 1.0
                fireClick()
                table.insert(clickBucket, tick())
            end
            doLockOn()
            doWalkTo()
        else
            accum    = 0
            lastTime = tick()
        end
        local now2 = tick()
        for i = #clickBucket, 1, -1 do
            if now2 - clickBucket[i] > CPS_WINDOW then
                table.remove(clickBucket, i)
            end
        end
        State.realCps = #clickBucket
        doAfkGuard()
        doAutoRespawn()
        task.wait(0)
    end
end)

local SG = Instance.new("ScreenGui")
SG.Name            = "PhantomV8"
SG.ResetOnSpawn    = false
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset  = true
SG.DisplayOrder    = 9999
SG.Parent          = PG

local C = {
    bg       = Color3.fromRGB(4,    4,   9),
    card     = Color3.fromRGB(10,  10,  20),
    card2    = Color3.fromRGB(15,  15,  27),
    card3    = Color3.fromRGB(20,  20,  36),
    border   = Color3.fromRGB(30,  30,  55),
    borderHi = Color3.fromRGB(60,  60, 110),
    accent   = Color3.fromRGB(0,   220, 140),
    accentB  = Color3.fromRGB(0,   150, 255),
    accentP  = Color3.fromRGB(160,  60, 255),
    danger   = Color3.fromRGB(220,  45,  55),
    warn     = Color3.fromRGB(255, 170,  20),
    success  = Color3.fromRGB(60,  200,  90),
    text     = Color3.fromRGB(235, 235, 255),
    textDim  = Color3.fromRGB(140, 140, 190),
    muted    = Color3.fromRGB(70,   70, 120),
    dim      = Color3.fromRGB(40,   40,  70),
    gA       = Color3.fromRGB(0,   210, 135),
    gB       = Color3.fromRGB(0,   150, 255),
    gC       = Color3.fromRGB(130,  55, 255),
    on_bg    = Color3.fromRGB(0,    36,  24),
    off_bg   = Color3.fromRGB(10,   10,  20),
    locked   = Color3.fromRGB(255, 200,  20),
    gui_col  = Color3.fromRGB(200,  80, 255),
}

local MODECOLORS = {
    AUTO   = C.accentB,
    TOUCH  = C.accent,
    CLICK  = C.warn,
    PROMPT = C.accentP,
    TOOL   = C.success,
    REMOTE = C.danger,
    GUI    = C.gui_col,
}

local function rc(f, r)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, r or 12)
    u.Parent       = f
    return u
end

local function grd(f, a, b, rot)
    local g = Instance.new("UIGradient")
    g.Color    = ColorSequence.new(a, b)
    g.Rotation = rot or 0
    g.Parent   = f
    return g
end

local function stk(f, col, px)
    local s = Instance.new("UIStroke")
    s.Color           = col or C.border
    s.Thickness       = px  or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent          = f
    return s
end

local function tw(o, t, p, sty, d)
    return TweenService:Create(o,
        TweenInfo.new(t, sty or Enum.EasingStyle.Quart, d or Enum.EasingDirection.Out), p)
end

local function mkTxt(p, par)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Font           = p.font  or Enum.Font.GothamBold
    l.TextSize       = p.size  or 12
    l.TextColor3     = p.color or C.text
    l.Text           = p.text  or ""
    l.Size           = p.sz    or UDim2.new(1,0,1,0)
    l.Position       = p.pos   or UDim2.new(0,0,0,0)
    l.ZIndex         = p.z     or 5
    l.TextXAlignment = p.xa    or Enum.TextXAlignment.Left
    l.TextYAlignment = p.ya    or Enum.TextYAlignment.Center
    l.TextTruncate   = Enum.TextTruncate.AtEnd
    l.RichText       = p.rich  or false
    l.Parent         = par
    return l
end

local function ripple(btn)
    btn.MouseButton1Down:Connect(function(mx, my)
        local r = Instance.new("Frame")
        r.AnchorPoint            = Vector2.new(0.5, 0.5)
        r.Size                   = UDim2.new(0,0,0,0)
        r.Position               = UDim2.new(0, mx - btn.AbsolutePosition.X,
                                              0, my - btn.AbsolutePosition.Y)
        r.BackgroundColor3       = Color3.fromRGB(255,255,255)
        r.BackgroundTransparency = 0.72
        r.BorderSizePixel        = 0
        r.ZIndex                 = btn.ZIndex + 2
        r.Parent                 = btn
        rc(r, 999)
        local spread = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.8
        tw(r, 0.44, {Size=UDim2.new(0,spread,0,spread), BackgroundTransparency=1},
            Enum.EasingStyle.Quad):Play()
        task.delay(0.45, function() r:Destroy() end)
    end)
end

local function mkBtn(name, text, bg, parent, order, h)
    local b = Instance.new("TextButton")
    b.Name             = name
    b.Size             = UDim2.new(1, 0, 0, h or 48)
    b.BackgroundColor3 = bg
    b.BorderSizePixel  = 0
    b.Font             = Enum.Font.GothamBold
    b.Text             = text
    b.TextColor3       = C.text
    b.TextSize         = 13
    b.ZIndex           = 18
    b.LayoutOrder      = order or 0
    b.ClipsDescendants = true
    b.AutoButtonColor  = false
    b.Parent           = parent
    rc(b, 13)
    ripple(b)
    return b
end

local function mkToggleRow(label, parent, order, initVal)
    local row = Instance.new("Frame")
    row.Size             = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = C.card2
    row.BorderSizePixel  = 0
    row.ZIndex           = 18
    row.LayoutOrder      = order or 0
    row.Parent           = parent
    rc(row, 10)
    stk(row, C.border, 1)
    mkTxt({text=label, size=11, color=C.textDim,
        sz=UDim2.new(1,-54,1,0), pos=UDim2.new(0,12,0,0),
        font=Enum.Font.GothamBold, z=19}, row)
    local track = Instance.new("Frame")
    track.Size             = UDim2.new(0, 38, 0, 20)
    track.Position         = UDim2.new(1, -46, 0.5, -10)
    track.BackgroundColor3 = initVal and C.accent or C.dim
    track.BorderSizePixel  = 0
    track.ZIndex           = 20
    track.Parent           = row
    rc(track, 10)
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0, 16, 0, 16)
    knob.Position         = initVal and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 21
    knob.Parent           = track
    rc(knob, 8)
    local btn = Instance.new("TextButton")
    btn.Size                   = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text                   = ""
    btn.AutoButtonColor        = false
    btn.ZIndex                 = 22
    btn.Parent                 = row
    local state = initVal or false
    local function setVal(v)
        state = v
        tw(track, 0.18, {BackgroundColor3 = v and C.accent or C.dim}):Play()
        tw(knob,  0.18, {Position = v and UDim2.new(1,-18,0.5,-8) or UDim2.new(0,2,0.5,-8)}):Play()
    end
    btn.MouseButton1Click:Connect(function()
        setVal(not state)
    end)
    return row, btn, function() return state end, setVal
end

local function mkSlider(label, minV, maxV, initV, parent, order)
    local card = Instance.new("Frame")
    card.Size             = UDim2.new(1, 0, 0, 52)
    card.BackgroundColor3 = C.card2
    card.BorderSizePixel  = 0
    card.ZIndex           = 18
    card.LayoutOrder      = order or 0
    card.Parent           = parent
    rc(card, 10)
    stk(card, C.border, 1)
    local lbl = mkTxt({text=label.." "..tostring(initV), size=10, color=C.muted,
        sz=UDim2.new(1,-16,0,24), pos=UDim2.new(0,12,0,2),
        font=Enum.Font.GothamBold, z=19}, card)
    local track = Instance.new("Frame")
    track.Size             = UDim2.new(1,-24,0,6)
    track.Position         = UDim2.new(0,12,1,-18)
    track.BackgroundColor3 = C.dim
    track.BorderSizePixel  = 0
    track.ZIndex           = 19
    track.Parent           = card
    rc(track, 3)
    local fill = Instance.new("Frame")
    fill.Size             = UDim2.new((initV-minV)/(maxV-minV),0,1,0)
    fill.BackgroundColor3 = C.accentB
    fill.BorderSizePixel  = 0
    fill.ZIndex           = 20
    fill.Parent           = track
    rc(fill, 3)
    grd(fill, C.gA, C.gB, 0)
    local knob = Instance.new("Frame")
    knob.Size             = UDim2.new(0,14,0,14)
    knob.AnchorPoint      = Vector2.new(0.5,0.5)
    knob.Position         = UDim2.new((initV-minV)/(maxV-minV),0,0.5,0)
    knob.BackgroundColor3 = Color3.fromRGB(255,255,255)
    knob.BorderSizePixel  = 0
    knob.ZIndex           = 21
    knob.Parent           = track
    rc(knob, 7)
    local val = initV
    local dragging = false
    local function updateFromX(absX)
        local ta = track.AbsolutePosition
        local ts = track.AbsoluteSize
        local frac = math.clamp((absX - ta.X) / ts.X, 0, 1)
        val = math.floor(minV + frac * (maxV - minV) + 0.5)
        lbl.Text = label.." "..tostring(val)
        fill.Size  = UDim2.new(frac, 0, 1, 0)
        knob.Position = UDim2.new(frac, 0, 0.5, 0)
    end
    local hitbox = Instance.new("TextButton")
    hitbox.Size                   = UDim2.new(1,-24,0,28)
    hitbox.Position               = UDim2.new(0,12,1,-30)
    hitbox.BackgroundTransparency = 1
    hitbox.Text                   = ""
    hitbox.AutoButtonColor        = false
    hitbox.ZIndex                 = 22
    hitbox.Parent                 = card
    hitbox.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or
           inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            updateFromX(inp.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(inp)
        if not dragging then return end
        if inp.UserInputType == Enum.UserInputType.Touch or
           inp.UserInputType == Enum.UserInputType.MouseMovement then
            updateFromX(inp.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch or
           inp.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
    return card, function() return val end
end

local function mkSectionLabel(text, parent, order)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, 0, 0, 18)
    f.BackgroundTransparency = 1
    f.ZIndex           = 17
    f.LayoutOrder      = order or 0
    f.Parent           = parent
    mkTxt({text=text, size=9, color=C.muted,
        sz=UDim2.new(1,0,1,0), pos=UDim2.new(0,2,0,0),
        font=Enum.Font.GothamBold, z=18}, f)
    return f
end

local PILL_W = 176
local PILL_H = 48
local MARGIN = 12

local function getDrawerMaxH()
    local vh = CAM.ViewportSize.Y
    if vh <= 0 then vh = 700 end
    return math.min(500, math.max(300, vh - PILL_H - MARGIN * 4 - 80))
end

local DRAWER_MAXH = getDrawerMaxH()
local DRAWER_W    = PILL_W + 28
local DRAWER_X    = -14

local Root = Instance.new("Frame")
Root.Name                   = "PhantomRoot"
Root.Size                   = UDim2.new(0, PILL_W + 10, 0, PILL_H + 10)
Root.Position               = UDim2.new(1, -(PILL_W + 10 + MARGIN), 0, 56 + MARGIN)
Root.BackgroundTransparency = 1
Root.ClipsDescendants       = false
Root.ZIndex                 = 20
Root.Parent                 = SG

local Halo = Instance.new("Frame")
Halo.Size                   = UDim2.new(1, 10, 0, PILL_H + 18)
Halo.Position               = UDim2.new(0, -5, 0, -4)
Halo.BackgroundColor3       = C.gA
Halo.BackgroundTransparency = 0.78
Halo.BorderSizePixel        = 0
Halo.ZIndex                 = 19
Halo.Parent                 = Root
rc(Halo, 32)
local HaloGrad = grd(Halo, C.gA, C.gC, 90)

local Pill = Instance.new("Frame")
Pill.Size             = UDim2.new(1, -8, 0, PILL_H)
Pill.Position         = UDim2.new(0, 4, 0, 4)
Pill.BackgroundColor3 = C.off_bg
Pill.BorderSizePixel  = 0
Pill.ZIndex           = 21
Pill.ClipsDescendants = true
Pill.Parent           = Root
rc(Pill, 24)
grd(Pill, Color3.fromRGB(16,16,30), Color3.fromRGB(8,8,16), 140)
local PillStroke = stk(Pill, C.border, 1)

local SDot = Instance.new("Frame")
SDot.Size             = UDim2.new(0, 10, 0, 10)
SDot.Position         = UDim2.new(0, 14, 0.5, -5)
SDot.BackgroundColor3 = Color3.fromRGB(60, 20, 20)
SDot.BorderSizePixel  = 0
SDot.ZIndex           = 23
SDot.Parent           = Pill
rc(SDot, 5)

local PillTxt = mkTxt({text="PHANTOM", size=11, color=C.muted,
    sz=UDim2.new(0,82,1,0), pos=UDim2.new(0,30,0,0),
    font=Enum.Font.GothamBold, z=23}, Pill)

local PillModeTxt = mkTxt({text="AUTO", size=9, color=C.dim,
    sz=UDim2.new(0,82,0,14), pos=UDim2.new(0,30,1,-16),
    font=Enum.Font.Gotham, z=23}, Pill)

local Badge = Instance.new("Frame")
Badge.Size             = UDim2.new(0, 58, 0, 30)
Badge.Position         = UDim2.new(1, -66, 0.5, -15)
Badge.BackgroundColor3 = Color3.fromRGB(12, 12, 24)
Badge.BorderSizePixel  = 0
Badge.ZIndex           = 23
Badge.Parent           = Pill
rc(Badge, 10)
stk(Badge, C.border, 1)

local BadgeTxt = mkTxt({text="0", size=14, color=C.text,
    sz=UDim2.new(1,0,0.6,0), pos=UDim2.new(0,0,0,1),
    font=Enum.Font.GothamBold, z=24, xa=Enum.TextXAlignment.Center}, Badge)

local BadgeSubTxt = mkTxt({text="cps", size=7, color=C.muted,
    sz=UDim2.new(1,0,0.4,0), pos=UDim2.new(0,0,0.62,0),
    font=Enum.Font.Gotham, z=24, xa=Enum.TextXAlignment.Center}, Badge)

local PillTap = Instance.new("TextButton")
PillTap.Size                   = UDim2.new(1, -38, 1, 0)
PillTap.BackgroundTransparency = 1
PillTap.Text                   = ""
PillTap.AutoButtonColor        = false
PillTap.ZIndex                 = 25
PillTap.Parent                 = Pill

local Handle = Instance.new("TextButton")
Handle.Size                   = UDim2.new(0, 32, 1, 0)
Handle.Position               = UDim2.new(1, -32, 0, 0)
Handle.BackgroundTransparency = 1
Handle.Text                   = "⠿"
Handle.TextColor3             = C.dim
Handle.Font                   = Enum.Font.GothamBold
Handle.TextSize               = 18
Handle.AutoButtonColor        = false
Handle.ZIndex                 = 26
Handle.Parent                 = Pill

local DrawerClip = Instance.new("Frame")
DrawerClip.Size                   = UDim2.new(0, DRAWER_W, 0, 0)
DrawerClip.Position               = UDim2.new(0, DRAWER_X, 0, PILL_H + 6)
DrawerClip.BackgroundTransparency = 1
DrawerClip.ClipsDescendants       = true
DrawerClip.ZIndex                 = 14
DrawerClip.Visible                = false
DrawerClip.Parent                 = Root

local DShadow = Instance.new("Frame")
DShadow.Size                   = UDim2.new(1, 28, 1, 28)
DShadow.Position               = UDim2.new(0, -14, 0, -14)
DShadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
DShadow.BackgroundTransparency = 0.38
DShadow.BorderSizePixel        = 0
DShadow.ZIndex                 = 13
DShadow.Parent                 = DrawerClip
rc(DShadow, 26)

local Drawer = Instance.new("Frame")
Drawer.Size             = UDim2.new(1, 0, 0, DRAWER_MAXH)
Drawer.BackgroundColor3 = C.card
Drawer.BorderSizePixel  = 0
Drawer.ZIndex           = 15
Drawer.Parent           = DrawerClip
rc(Drawer, 18)
grd(Drawer, C.card2, C.bg, 150)
stk(Drawer, C.border, 1)

local DH = Instance.new("Frame")
DH.Size             = UDim2.new(1, 0, 0, 50)
DH.BackgroundColor3 = Color3.fromRGB(7, 7, 16)
DH.BorderSizePixel  = 0
DH.ZIndex           = 17
DH.Parent           = Drawer
rc(DH, 18)

local DHSqBot = Instance.new("Frame")
DHSqBot.Size             = UDim2.new(1, 0, 0.5, 0)
DHSqBot.Position         = UDim2.new(0, 0, 0.5, 0)
DHSqBot.BackgroundColor3 = Color3.fromRGB(7, 7, 16)
DHSqBot.BorderSizePixel  = 0
DHSqBot.ZIndex           = 17
DHSqBot.Parent           = DH

mkTxt({text="⚡  PHANTOM  "..VERSION, size=13, color=C.text,
    sz=UDim2.new(0.6,0,0,22), pos=UDim2.new(0,14,0,5),
    font=Enum.Font.GothamBold, z=18}, DH)
mkTxt({text=BUILD.."  ·  REMOTE ENGINE  ·  GUI ENGINE  ·  ZERO CURSOR", size=8, color=C.muted,
    sz=UDim2.new(1,-14,0,14), pos=UDim2.new(0,14,0,28),
    font=Enum.Font.Gotham, z=18}, DH)

local StatsTxt = mkTxt({text="0 clicks", size=9, color=C.dim,
    sz=UDim2.new(0.38,0,0,22), pos=UDim2.new(0.62,0,0,5),
    font=Enum.Font.Gotham, z=18,
    xa=Enum.TextXAlignment.Right}, DH)

local DHDiv = Instance.new("Frame")
DHDiv.Size             = UDim2.new(1, -24, 0, 1)
DHDiv.Position         = UDim2.new(0, 12, 0, 49)
DHDiv.BackgroundColor3 = C.border
DHDiv.BorderSizePixel  = 0
DHDiv.ZIndex           = 17
DHDiv.Parent           = Drawer

local TabBar = Instance.new("Frame")
TabBar.Size             = UDim2.new(1, -24, 0, 30)
TabBar.Position         = UDim2.new(0, 12, 0, 52)
TabBar.BackgroundTransparency = 1
TabBar.ZIndex           = 17
TabBar.Parent           = Drawer

local TabLayout = Instance.new("UIListLayout")
TabLayout.FillDirection = Enum.FillDirection.Horizontal
TabLayout.SortOrder     = Enum.SortOrder.LayoutOrder
TabLayout.Padding       = UDim.new(0, 4)
TabLayout.Parent        = TabBar

local TABS = {"MAIN","SETTINGS","STATS","HISTORY"}
local tabBtns = {}
local tabPages = {}

for i, tabName in ipairs(TABS) do
    local tb = Instance.new("TextButton")
    tb.Size             = UDim2.new(0, 54, 1, 0)
    tb.BackgroundColor3 = i == 1 and C.card3 or C.bg
    tb.BorderSizePixel  = 0
    tb.Font             = Enum.Font.GothamBold
    tb.Text             = tabName
    tb.TextColor3       = i == 1 and C.text or C.muted
    tb.TextSize         = 8
    tb.AutoButtonColor  = false
    tb.ZIndex           = 19
    tb.LayoutOrder      = i
    tb.Parent           = TabBar
    rc(tb, 7)
    stk(tb, i == 1 and C.borderHi or C.border, 1)
    table.insert(tabBtns, tb)
    ripple(tb)
end

local TabDiv = Instance.new("Frame")
TabDiv.Size             = UDim2.new(1, -24, 0, 1)
TabDiv.Position         = UDim2.new(0, 12, 0, 84)
TabDiv.BackgroundColor3 = C.border
TabDiv.BorderSizePixel  = 0
TabDiv.ZIndex           = 17
TabDiv.Parent           = Drawer

local ScrollContainer = Instance.new("Frame")
ScrollContainer.Size             = UDim2.new(1, 0, 1, -87)
ScrollContainer.Position         = UDim2.new(0, 0, 0, 87)
ScrollContainer.BackgroundTransparency = 1
ScrollContainer.ZIndex           = 16
ScrollContainer.ClipsDescendants = true
ScrollContainer.Parent           = Drawer

local function makePageScroll()
    local s = Instance.new("ScrollingFrame")
    s.Size                   = UDim2.new(1, 0, 1, 0)
    s.BackgroundTransparency = 1
    s.BorderSizePixel        = 0
    s.CanvasSize             = UDim2.new(0, 0, 0, 0)
    s.AutomaticCanvasSize    = Enum.AutomaticSize.Y
    s.ScrollBarThickness     = 3
    s.ScrollBarImageColor3   = C.dim
    s.ScrollingDirection     = Enum.ScrollingDirection.Y
    s.ElasticBehavior        = Enum.ElasticBehavior.Always
    s.ZIndex                 = 16
    s.Visible                = false
    s.Parent                 = ScrollContainer
    local ll = Instance.new("UIListLayout")
    ll.SortOrder = Enum.SortOrder.LayoutOrder
    ll.Padding   = UDim.new(0, 8)
    ll.Parent    = s
    local pd = Instance.new("UIPadding")
    pd.PaddingLeft   = UDim.new(0, 12)
    pd.PaddingRight  = UDim.new(0, 12)
    pd.PaddingTop    = UDim.new(0, 10)
    pd.PaddingBottom = UDim.new(0, 10)
    pd.Parent        = s
    return s
end

local MainPage     = makePageScroll()
local SettingsPage = makePageScroll()
local StatsPage    = makePageScroll()
local HistoryPage  = makePageScroll()
MainPage.Visible   = true
State.activeTab    = "MAIN"

tabPages = {MainPage, SettingsPage, StatsPage, HistoryPage}

local function switchTab(idx)
    State.activeTab = TABS[idx]
    for i, pg in ipairs(tabPages) do
        pg.Visible = (i == idx)
    end
    for i, tb in ipairs(tabBtns) do
        local active = (i == idx)
        tw(tb, 0.14, {BackgroundColor3 = active and C.card3 or C.bg,
            TextColor3 = active and C.text or C.muted}):Play()
        local s = tb:FindFirstChildOfClass("UIStroke")
        if s then s.Color = active and C.borderHi or C.border end
    end
end

for i, tb in ipairs(tabBtns) do
    tb.MouseButton1Click:Connect(function() switchTab(i) end)
end

local TogBtn = mkBtn("Toggle", "  AUTO-CLICK  OFF", C.off_bg, MainPage, 1)
local TDot = Instance.new("Frame")
TDot.Size             = UDim2.new(0, 10, 0, 10)
TDot.Position         = UDim2.new(0, 14, 0.5, -5)
TDot.BackgroundColor3 = C.danger
TDot.BorderSizePixel  = 0
TDot.ZIndex           = 19
TDot.Parent           = TogBtn
rc(TDot, 5)

local ModeCard = Instance.new("Frame")
ModeCard.Size             = UDim2.new(1, 0, 0, 48)
ModeCard.BackgroundColor3 = C.card2
ModeCard.BorderSizePixel  = 0
ModeCard.ZIndex           = 18
ModeCard.LayoutOrder      = 2
ModeCard.Parent           = MainPage
rc(ModeCard, 11)
stk(ModeCard, C.border, 1)

mkTxt({text="MODE", size=9, color=C.muted,
    sz=UDim2.new(0,48,0.5,0), pos=UDim2.new(0,12,0,4),
    font=Enum.Font.GothamBold, z=19}, ModeCard)

local ModeLbl = mkTxt({text="AUTO", size=15, color=C.accentB,
    sz=UDim2.new(0,90,0.55,0), pos=UDim2.new(0,12,0.44,0),
    font=Enum.Font.GothamBold, z=19,
    xa=Enum.TextXAlignment.Left}, ModeCard)

local LockBadge = Instance.new("Frame")
LockBadge.Size             = UDim2.new(0, 42, 0, 16)
LockBadge.Position         = UDim2.new(0, 62, 0, 7)
LockBadge.BackgroundColor3 = Color3.fromRGB(60, 50, 0)
LockBadge.BorderSizePixel  = 0
LockBadge.ZIndex           = 20
LockBadge.Visible          = false
LockBadge.Parent           = ModeCard
rc(LockBadge, 5)

mkTxt({text="LOCKED", size=7, color=C.locked,
    sz=UDim2.new(1,0,1,0), pos=UDim2.new(0,0,0,0),
    font=Enum.Font.GothamBold, z=21, xa=Enum.TextXAlignment.Center}, LockBadge)

local ModeCycleRow = Instance.new("Frame")
ModeCycleRow.Size             = UDim2.new(1,-120,0,48)
ModeCycleRow.Position         = UDim2.new(0,112,0,0)
ModeCycleRow.BackgroundTransparency = 1
ModeCycleRow.ZIndex           = 19
ModeCycleRow.Parent           = ModeCard

local MCLayout = Instance.new("UIListLayout")
MCLayout.FillDirection  = Enum.FillDirection.Horizontal
MCLayout.SortOrder      = Enum.SortOrder.LayoutOrder
MCLayout.VerticalAlignment = Enum.VerticalAlignment.Center
MCLayout.Padding        = UDim.new(0, 4)
MCLayout.Parent         = ModeCycleRow

local MODES = {"AUTO","TOUCH","CLICK","PROMPT","TOOL","REMOTE","GUI"}
local modeIdx = 1

for i, mName in ipairs(MODES) do
    local mb = Instance.new("TextButton")
    mb.Size             = UDim2.new(0, 0, 0, 32)
    mb.AutomaticSize    = Enum.AutomaticSize.X
    mb.BackgroundColor3 = mName == "AUTO" and C.card3 or C.card
    mb.BorderSizePixel  = 0
    mb.Font             = Enum.Font.GothamBold
    mb.Text             = " "..mName.." "
    mb.TextColor3       = mName == "AUTO" and C.accentB or C.muted
    mb.TextSize         = 8
    mb.AutoButtonColor  = false
    mb.ZIndex           = 20
    mb.LayoutOrder      = i
    mb.Parent           = ModeCycleRow
    rc(mb, 6)
    stk(mb, mName == "AUTO" and C.borderHi or C.border, 1)
    ripple(mb)
    mb.MouseButton1Click:Connect(function()
        modeIdx = i
        State.mode = mName
        State.modeLocked = (mName ~= "AUTO")
        ModeLbl.Text = mName
        ModeLbl.TextColor3 = MODECOLORS[mName] or C.text
        LockBadge.Visible = State.modeLocked
        if mName == "AUTO" then
            State.target    = nil
            State.guiTarget = nil
            State.targetName = "None"
        end
        for j, btn in ipairs(ModeCycleRow:GetChildren()) do
            if btn:IsA("TextButton") then
                local active = (btn.Text:gsub(" ","") == mName)
                btn.BackgroundColor3 = active and C.card3 or C.card
                btn.TextColor3       = active and (MODECOLORS[mName] or C.text) or C.muted
                local s = btn:FindFirstChildOfClass("UIStroke")
                if s then s.Color = active and C.borderHi or C.border end
            end
        end
        PillModeTxt.Text      = mName
        PillModeTxt.TextColor3 = MODECOLORS[mName] or C.dim
    end)
end

local UDim2Padding = Instance.new("UIPadding")
UDim2Padding.PaddingLeft  = UDim.new(0, 4)
UDim2Padding.PaddingRight = UDim.new(0, 4)
UDim2Padding.Parent       = ModeCycleRow

mkSectionLabel("TARGET", MainPage, 3)

local SelBtn   = mkBtn("Select", "🎯   SET TARGET  (tap anywhere)", Color3.fromRGB(10,46,118), MainPage, 4)
local ClearBtn = mkBtn("Clear",  "✕   CLEAR TARGET",               Color3.fromRGB(26,8,10), MainPage, 5, 38)

local TargCard = Instance.new("Frame")
TargCard.Size             = UDim2.new(1, 0, 0, 36)
TargCard.BackgroundColor3 = C.card2
TargCard.BorderSizePixel  = 0
TargCard.ZIndex           = 18
TargCard.LayoutOrder      = 6
TargCard.Parent           = MainPage
rc(TargCard, 10)
stk(TargCard, C.border, 1)

local TargIconLbl = mkTxt({text="●", size=9, color=C.dim,
    sz=UDim2.new(0,16,1,0), pos=UDim2.new(0,10,0,0),
    z=19, xa=Enum.TextXAlignment.Center}, TargCard)

local TargLbl = mkTxt({text="No target  ·  AUTO uses crosshair", size=10, color=C.muted,
    sz=UDim2.new(1,-36,1,0), pos=UDim2.new(0,26,0,0),
    font=Enum.Font.Gotham, z=19}, TargCard)

local TargDistLbl = mkTxt({text="", size=8, color=C.dim,
    sz=UDim2.new(0,40,1,0), pos=UDim2.new(1,-44,0,0),
    font=Enum.Font.Gotham, z=19, xa=Enum.TextXAlignment.Right}, TargCard)

mkSectionLabel("SPEED", MainPage, 7)

local CpsCard = Instance.new("Frame")
CpsCard.Size             = UDim2.new(1, 0, 0, 58)
CpsCard.BackgroundColor3 = C.card2
CpsCard.BorderSizePixel  = 0
CpsCard.ZIndex           = 18
CpsCard.LayoutOrder      = 8
CpsCard.Parent           = MainPage
rc(CpsCard, 11)
stk(CpsCard, C.border, 1)

mkTxt({text="CPS", size=9, color=C.muted,
    sz=UDim2.new(0,36,0.5,0), pos=UDim2.new(0,12,0,0),
    font=Enum.Font.GothamBold, z=19}, CpsCard)
mkTxt({text="hold to ramp", size=7, color=C.dim,
    sz=UDim2.new(0,72,0.5,0), pos=UDim2.new(0,12,0.5,0),
    font=Enum.Font.Gotham, z=19}, CpsCard)

local BS = 36
local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, BS, 0, BS)
MinBtn.Position         = UDim2.new(1, -(BS*2+16), 0.5, -BS/2)
MinBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 34)
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.Text             = "−"
MinBtn.TextColor3       = C.text
MinBtn.TextSize         = 22
MinBtn.BorderSizePixel  = 0
MinBtn.AutoButtonColor  = false
MinBtn.ZIndex           = 19
MinBtn.Parent           = CpsCard
rc(MinBtn, 9); stk(MinBtn, C.border, 1); ripple(MinBtn)

local CpsNumLbl = mkTxt({text=tostring(State.cps), size=18, color=C.text,
    sz=UDim2.new(0,BS,1,0),
    pos=UDim2.new(1,-(BS*2+16)+BS+2,0,0),
    font=Enum.Font.GothamBold, z=19, xa=Enum.TextXAlignment.Center}, CpsCard)

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size             = UDim2.new(0, BS, 0, BS)
PlusBtn.Position         = UDim2.new(1, -(BS+8), 0.5, -BS/2)
PlusBtn.BackgroundColor3 = Color3.fromRGB(18, 18, 34)
PlusBtn.Font             = Enum.Font.GothamBold
PlusBtn.Text             = "+"
PlusBtn.TextColor3       = C.text
PlusBtn.TextSize         = 22
PlusBtn.BorderSizePixel  = 0
PlusBtn.AutoButtonColor  = false
PlusBtn.ZIndex           = 19
PlusBtn.Parent           = CpsCard
rc(PlusBtn, 9); stk(PlusBtn, C.border, 1); ripple(PlusBtn)

local PresetsRow = Instance.new("Frame")
PresetsRow.Size             = UDim2.new(1, 0, 0, 34)
PresetsRow.BackgroundTransparency = 1
PresetsRow.ZIndex           = 18
PresetsRow.LayoutOrder      = 9
PresetsRow.Parent           = MainPage

local PresetLayout = Instance.new("UIListLayout")
PresetLayout.FillDirection = Enum.FillDirection.Horizontal
PresetLayout.SortOrder     = Enum.SortOrder.LayoutOrder
PresetLayout.Padding       = UDim.new(0, 5)
PresetLayout.VerticalAlignment = Enum.VerticalAlignment.Center
PresetLayout.Parent        = PresetsRow

local PRESETS = {{"SLOW",5},{"NORMAL",15},{"FAST",50},{"TURBO",200},{"INSANE",999}}
local function refreshCps()
    CpsNumLbl.Text = tostring(State.cps)
end

for idx, pr in ipairs(PRESETS) do
    local pName, pVal = pr[1], pr[2]
    local pb = Instance.new("TextButton")
    pb.Size             = UDim2.new(0, 0, 1, 0)
    pb.AutomaticSize    = Enum.AutomaticSize.X
    pb.BackgroundColor3 = C.card2
    pb.BorderSizePixel  = 0
    pb.Font             = Enum.Font.GothamBold
    pb.Text             = " "..pName.." "
    pb.TextColor3       = C.muted
    pb.TextSize         = 8
    pb.AutoButtonColor  = false
    pb.ZIndex           = 19
    pb.LayoutOrder      = idx
    pb.Parent           = PresetsRow
    rc(pb, 7); stk(pb, C.border, 1); ripple(pb)
    pb.MouseButton1Click:Connect(function()
        State.cps = pVal
        refreshCps()
        tw(pb, 0.12, {TextColor3=C.accent}):Play()
        task.delay(0.5, function() tw(pb,0.2,{TextColor3=C.muted}):Play() end)
    end)
end

local MeterCard = Instance.new("Frame")
MeterCard.Size             = UDim2.new(1, 0, 0, 36)
MeterCard.BackgroundColor3 = Color3.fromRGB(7, 7, 15)
MeterCard.BorderSizePixel  = 0
MeterCard.ZIndex           = 18
MeterCard.LayoutOrder      = 10
MeterCard.Parent           = MainPage
rc(MeterCard, 10); stk(MeterCard, C.border, 1)

local MeterFill = Instance.new("Frame")
MeterFill.Size             = UDim2.new(0, 0, 1, 0)
MeterFill.BackgroundColor3 = C.accent
MeterFill.BackgroundTransparency = 0.75
MeterFill.BorderSizePixel  = 0
MeterFill.ZIndex           = 18
MeterFill.Parent           = MeterCard
rc(MeterFill, 10)
grd(MeterFill, C.gA, C.gB, 0)

local MeterLbl = mkTxt({text="Actual: 0 cps  ·  Set: 15 cps", size=10, color=C.muted,
    sz=UDim2.new(1,-16,1,0), pos=UDim2.new(0,10,0,0),
    font=Enum.Font.Gotham, z=20}, MeterCard)

local FlashOverlay = Instance.new("Frame")
FlashOverlay.Size                   = UDim2.new(1, 0, 1, 0)
FlashOverlay.BackgroundColor3       = C.accent
FlashOverlay.BackgroundTransparency = 1
FlashOverlay.BorderSizePixel        = 0
FlashOverlay.ZIndex                 = 17
FlashOverlay.Parent                 = MeterCard
rc(FlashOverlay, 10)

table.insert(flashCallbacks, function()
    if not State.flashEnabled then return end
    FlashOverlay.BackgroundTransparency = 0.55
    tw(FlashOverlay, 0.18, {BackgroundTransparency=1}, Enum.EasingStyle.Quad):Play()
end)

mkSectionLabel("MULTI-FIRE", MainPage, 11)

local MultiRow, MultiBtn, getMulti, setMulti = mkToggleRow("Fire ALL tiers simultaneously", MainPage, 12, false)
MultiBtn.MouseButton1Click:Connect(function()
    State.multiFireAll = getMulti()
end)

local InfoCard = Instance.new("Frame")
InfoCard.Size             = UDim2.new(1, 0, 0, 28)
InfoCard.BackgroundColor3 = Color3.fromRGB(5, 5, 12)
InfoCard.BorderSizePixel  = 0
InfoCard.ZIndex           = 18
InfoCard.LayoutOrder      = 13
InfoCard.Parent           = MainPage
rc(InfoCard, 10); stk(InfoCard, C.border, 1)

local EngineInfoTxt = mkTxt({text="Tiers: touchinterest · clickdetector · proximityprompt · remote · GUI", size=8,
    color=C.dim, sz=UDim2.new(1,-16,1,0), pos=UDim2.new(0,10,0,0),
    font=Enum.Font.Gotham, z=19}, InfoCard)

local ColBtn = mkBtn("Collapse", "▲   COLLAPSE", Color3.fromRGB(12,12,24), MainPage, 14, 40)

mkSectionLabel("AUTOMATION", SettingsPage, 1)

local AfkRow, AfkBtn, getAfk, setAfk = mkToggleRow("AFK Guard (prevent idle kick)", SettingsPage, 2, false)
AfkBtn.MouseButton1Click:Connect(function()
    State.afkGuard = getAfk()
end)

local RespawnRow, RespawnBtn, getRespawn = mkToggleRow("Auto-Respawn on Death", SettingsPage, 3, false)
RespawnBtn.MouseButton1Click:Connect(function()
    State.autoRespawn = getRespawn()
end)

local WalkRow, WalkBtn, getWalk = mkToggleRow("Walk Toward Target", SettingsPage, 4, false)
WalkBtn.MouseButton1Click:Connect(function()
    State.walkToTarget = getWalk()
end)

local LockOnRow, LockOnBtn, getLockOn = mkToggleRow("Camera Lock-On to Target", SettingsPage, 5, false)
LockOnBtn.MouseButton1Click:Connect(function()
    State.lockOnMode = getLockOn()
    if State.lockOnMode and State.target and State.target:IsA("BasePart") then
        State.lockOnTarget = State.target
    end
end)

mkSectionLabel("VISUAL", SettingsPage, 6)

local FlashRow, FlashBtn, getFlash, setFlash = mkToggleRow("Click Flash Indicator", SettingsPage, 7, true)
FlashBtn.MouseButton1Click:Connect(function()
    State.flashEnabled = getFlash()
end)

local CrosshairRow, CrosshairBtn, getCrosshair = mkToggleRow("Show Crosshair Overlay", SettingsPage, 8, false)
CrosshairBtn.MouseButton1Click:Connect(function()
    State.showCrosshair = getCrosshair()
    CrosshairFrame.Visible = State.showCrosshair
end)

local SoundRow, SoundBtn, getSound = mkToggleRow("Click Sound Feedback", SettingsPage, 9, false)
SoundBtn.MouseButton1Click:Connect(function()
    State.soundFeedback = getSound()
end)

local PerfRow, PerfBtn, getPerf = mkToggleRow("Performance Mode (less UI updates)", SettingsPage, 10, false)
PerfBtn.MouseButton1Click:Connect(function()
    State.perfMode = getPerf()
end)

mkSectionLabel("CONTROLS", SettingsPage, 11)

local HotkeyCard = Instance.new("Frame")
HotkeyCard.Size             = UDim2.new(1, 0, 0, 40)
HotkeyCard.BackgroundColor3 = C.card2
HotkeyCard.BorderSizePixel  = 0
HotkeyCard.ZIndex           = 18
HotkeyCard.LayoutOrder      = 12
HotkeyCard.Parent           = SettingsPage
rc(HotkeyCard, 10); stk(HotkeyCard, C.border, 1)
mkTxt({text="Hotkey:", size=10, color=C.muted,
    sz=UDim2.new(0.5,0,1,0), pos=UDim2.new(0,12,0,0),
    font=Enum.Font.GothamBold, z=19}, HotkeyCard)
local HotkeyLbl = mkTxt({text="]", size=12, color=C.accent,
    sz=UDim2.new(0.5,0,1,0), pos=UDim2.new(0.5,0,0,0),
    font=Enum.Font.GothamBold, z=19, xa=Enum.TextXAlignment.Right}, HotkeyCard)
local hotkeyNames = {
    [Enum.KeyCode.RightBracket]    = "]",
    [Enum.KeyCode.LeftBracket]     = "[",
    [Enum.KeyCode.Semicolon]       = ";",
    [Enum.KeyCode.Quote]           = "'",
    [Enum.KeyCode.Backslash]       = "\\",
    [Enum.KeyCode.Equals]          = "=",
    [Enum.KeyCode.Minus]           = "-",
    [Enum.KeyCode.Period]          = ".",
    [Enum.KeyCode.Comma]           = ",",
    [Enum.KeyCode.F5]              = "F5",
    [Enum.KeyCode.F6]              = "F6",
    [Enum.KeyCode.F7]              = "F7",
    [Enum.KeyCode.F8]              = "F8",
}
local hotkeyKeys = {}
for k in pairs(hotkeyNames) do table.insert(hotkeyKeys, k) end
local hotkeyIdx = 1
for i, k in ipairs(hotkeyKeys) do
    if k == Enum.KeyCode.RightBracket then hotkeyIdx = i; break end
end
local hotkeyListenBtn = Instance.new("TextButton")
hotkeyListenBtn.Size             = UDim2.new(0, 50, 0, 26)
hotkeyListenBtn.Position         = UDim2.new(1, -58, 0.5, -13)
hotkeyListenBtn.BackgroundColor3 = C.card3
hotkeyListenBtn.BorderSizePixel  = 0
hotkeyListenBtn.Font             = Enum.Font.GothamBold
hotkeyListenBtn.Text             = "NEXT"
hotkeyListenBtn.TextColor3       = C.muted
hotkeyListenBtn.TextSize         = 8
hotkeyListenBtn.AutoButtonColor  = false
hotkeyListenBtn.ZIndex           = 20
hotkeyListenBtn.Parent           = HotkeyCard
rc(hotkeyListenBtn, 7); stk(hotkeyListenBtn, C.border, 1); ripple(hotkeyListenBtn)
hotkeyListenBtn.MouseButton1Click:Connect(function()
    hotkeyIdx = hotkeyIdx % #hotkeyKeys + 1
    State.hotkey = hotkeyKeys[hotkeyIdx]
    HotkeyLbl.Text = hotkeyNames[State.hotkey] or "?"
end)

mkSectionLabel("TOOL EQUIP", SettingsPage, 13)
local EquipCard = Instance.new("Frame")
EquipCard.Size             = UDim2.new(1, 0, 0, 40)
EquipCard.BackgroundColor3 = C.card2
EquipCard.BorderSizePixel  = 0
EquipCard.ZIndex           = 18
EquipCard.LayoutOrder      = 14
EquipCard.Parent           = SettingsPage
rc(EquipCard, 10); stk(EquipCard, C.border, 1)
mkTxt({text="Auto-equip tool name:", size=9, color=C.muted,
    sz=UDim2.new(0.52,0,1,0), pos=UDim2.new(0,12,0,0),
    font=Enum.Font.GothamBold, z=19}, EquipCard)
local EquipNameLbl = mkTxt({text="(none)", size=10, color=C.dim,
    sz=UDim2.new(0.44,0,1,0), pos=UDim2.new(0.54,0,0,0),
    font=Enum.Font.Gotham, z=19, xa=Enum.TextXAlignment.Right}, EquipCard)

mkSectionLabel("OPACITY", SettingsPage, 15)
local opacityCard, getOpacity = mkSlider("UI Opacity", 20, 100, 100, SettingsPage, 16)

local ResetPosBtn = mkBtn("ResetPos", "↺   RESET POSITION", Color3.fromRGB(14,14,26), SettingsPage, 17, 40)
ResetPosBtn.MouseButton1Click:Connect(function()
    tw(Root, 0.3, {Position=UDim2.new(1, -(PILL_W + 10 + MARGIN), 0, 56 + MARGIN)},
        Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
end)

local TotalClicksLbl  = mkTxt({text="Total Clicks: 0", size=14, color=C.text,
    sz=UDim2.new(1,0,0,28), pos=UDim2.new(0,0,0,0),
    font=Enum.Font.GothamBold, z=18, xa=Enum.TextXAlignment.Center}, StatsPage)
TotalClicksLbl.LayoutOrder = 1
TotalClicksLbl.BackgroundTransparency = 1
TotalClicksLbl.Parent = StatsPage

local SessionTimeLbl  = mkTxt({text="Session: 0s", size=11, color=C.muted,
    sz=UDim2.new(1,0,0,22), pos=UDim2.new(0,0,0,0),
    font=Enum.Font.Gotham, z=18, xa=Enum.TextXAlignment.Center}, StatsPage)
SessionTimeLbl.LayoutOrder = 2
SessionTimeLbl.BackgroundTransparency = 1
SessionTimeLbl.Parent = StatsPage

local ClickRateLbl = mkTxt({text="Rate: 0 clicks/min", size=11, color=C.muted,
    sz=UDim2.new(1,0,0,22),
    font=Enum.Font.Gotham, z=18, xa=Enum.TextXAlignment.Center}, StatsPage)
ClickRateLbl.LayoutOrder = 3
ClickRateLbl.BackgroundTransparency = 1
ClickRateLbl.Parent = StatsPage

mkSectionLabel("CLICK GRAPH (last 10s)", StatsPage, 4)

local GraphCard = Instance.new("Frame")
GraphCard.Size             = UDim2.new(1, 0, 0, 70)
GraphCard.BackgroundColor3 = Color3.fromRGB(6, 6, 14)
GraphCard.BorderSizePixel  = 0
GraphCard.ZIndex           = 18
GraphCard.LayoutOrder      = 5
GraphCard.Parent           = StatsPage
rc(GraphCard, 10); stk(GraphCard, C.border, 1)

local graphBars = {}
for gi = 1, 10 do
    local bar = Instance.new("Frame")
    bar.Size             = UDim2.new(0.08, -2, 0, 0)
    bar.Position         = UDim2.new((gi-1)*0.1, 2, 1, 0)
    bar.AnchorPoint      = Vector2.new(0, 1)
    bar.BackgroundColor3 = C.accent
    bar.BackgroundTransparency = 0.3
    bar.BorderSizePixel  = 0
    bar.ZIndex           = 19
    bar.Parent           = GraphCard
    rc(bar, 3)
    table.insert(graphBars, bar)
end
grd(graphBars[1].Parent or GraphCard, C.bg, C.card, 90)

local graphHistory  = {}
local graphTimer    = tick()

local ResetStatsBtn = mkBtn("ResetStats", "✕   RESET STATS", Color3.fromRGB(20,8,8), StatsPage, 6, 38)
ResetStatsBtn.MouseButton1Click:Connect(function()
    State.totalClicks  = 0
    State.sessionStart = tick()
end)

mkSectionLabel("RECENT TARGETS", HistoryPage, 1)

local historyItems = {}
for hi = 1, 5 do
    local hCard = Instance.new("Frame")
    hCard.Size             = UDim2.new(1, 0, 0, 40)
    hCard.BackgroundColor3 = C.card2
    hCard.BorderSizePixel  = 0
    hCard.ZIndex           = 18
    hCard.LayoutOrder      = hi + 1
    hCard.Visible          = false
    hCard.Parent           = HistoryPage
    rc(hCard, 9); stk(hCard, C.border, 1)
    local hNameLbl = mkTxt({text="", size=10, color=C.text,
        sz=UDim2.new(1,-76,0.6,0), pos=UDim2.new(0,10,0,2),
        font=Enum.Font.GothamBold, z=19}, hCard)
    local hModeLbl = mkTxt({text="", size=8, color=C.muted,
        sz=UDim2.new(1,-76,0.4,0), pos=UDim2.new(0,10,0.6,-1),
        font=Enum.Font.Gotham, z=19}, hCard)
    local hUseBtn = Instance.new("TextButton")
    hUseBtn.Size             = UDim2.new(0, 60, 0, 26)
    hUseBtn.Position         = UDim2.new(1, -66, 0.5, -13)
    hUseBtn.BackgroundColor3 = C.card3
    hUseBtn.BorderSizePixel  = 0
    hUseBtn.Font             = Enum.Font.GothamBold
    hUseBtn.Text             = "USE"
    hUseBtn.TextColor3       = C.accent
    hUseBtn.TextSize         = 9
    hUseBtn.AutoButtonColor  = false
    hUseBtn.ZIndex           = 20
    hUseBtn.Parent           = hCard
    rc(hUseBtn, 7); stk(hUseBtn, C.border, 1); ripple(hUseBtn)
    table.insert(historyItems, {card=hCard, name=hNameLbl, mode=hModeLbl, use=hUseBtn})
end

local ClearHistBtn = mkBtn("ClearHist", "✕   CLEAR HISTORY", Color3.fromRGB(18,6,6), HistoryPage, 8, 36)
ClearHistBtn.MouseButton1Click:Connect(function()
    State.targetHistory = {}
end)

local function refreshHistory()
    for i, item in ipairs(historyItems) do
        local h = State.targetHistory[i]
        if h then
            item.card.Visible   = true
            item.name.Text      = h.name
            item.mode.Text      = h.mode.." · "..(tick()-h.time < 3600 and
                string.format("%.0fs ago", tick()-h.time) or "old")
            item.use.MouseButton1Click:Connect(function()
                if safeParent(h.target) then
                    State.target     = h.target
                    State.mode       = h.mode
                    State.modeLocked = true
                    State.targetName = h.name
                    ModeLbl.Text     = h.mode
                    ModeLbl.TextColor3 = MODECOLORS[h.mode] or C.text
                    LockBadge.Visible = true
                    TargLbl.Text      = "✓  "..h.name
                    TargLbl.TextColor3 = C.accent
                    switchTab(1)
                end
            end)
        else
            item.card.Visible = false
        end
    end
end

local CrosshairFrame = Instance.new("Frame")
CrosshairFrame.Size                   = UDim2.new(0, 20, 0, 20)
CrosshairFrame.Position               = UDim2.new(0.5, -10, 0.5, -10)
CrosshairFrame.BackgroundTransparency = 1
CrosshairFrame.ZIndex                 = 5
CrosshairFrame.Visible                = false
CrosshairFrame.Parent                 = SG

local CHH = Instance.new("Frame")
CHH.Size             = UDim2.new(1, 0, 0, 1)
CHH.Position         = UDim2.new(0, 0, 0.5, 0)
CHH.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CHH.BackgroundTransparency = 0.3
CHH.BorderSizePixel  = 0
CHH.ZIndex           = 6
CHH.Parent           = CrosshairFrame

local CHV = Instance.new("Frame")
CHV.Size             = UDim2.new(0, 1, 1, 0)
CHV.Position         = UDim2.new(0.5, 0, 0, 0)
CHV.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
CHV.BackgroundTransparency = 0.3
CHV.BorderSizePixel  = 0
CHV.ZIndex           = 6
CHV.Parent           = CrosshairFrame

local CHDot = Instance.new("Frame")
CHDot.Size             = UDim2.new(0, 4, 0, 4)
CHDot.Position         = UDim2.new(0.5, -2, 0.5, -2)
CHDot.BackgroundColor3 = C.accent
CHDot.BorderSizePixel  = 0
CHDot.ZIndex           = 7
CHDot.Parent           = CrosshairFrame
rc(CHDot, 2)

local function setExpanded(open)
    State.expanded = open
    if open then
        DrawerClip.Visible = true
        DrawerClip.Size    = UDim2.new(0, DRAWER_W, 0, 0)
        tw(DrawerClip, 0.28, {Size=UDim2.new(0, DRAWER_W, 0, DRAWER_MAXH)},
            Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    else
        tw(DrawerClip, 0.22, {Size=UDim2.new(0, DRAWER_W, 0, 0)},
            Enum.EasingStyle.Quart):Play()
        task.delay(0.23, function() DrawerClip.Visible = false end)
    end
end

PillTap.MouseButton1Click:Connect(function() setExpanded(not State.expanded) end)
ColBtn.MouseButton1Click:Connect(function()  setExpanded(false) end)

local dragOn, dragFrom, dragOrigin = false, nil, nil

Handle.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragOn     = true
        dragFrom   = Vector2.new(inp.Position.X, inp.Position.Y)
        dragOrigin = Root.Position
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if not dragOn then return end
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseMovement then
        local dx = inp.Position.X - dragFrom.X
        local dy = inp.Position.Y - dragFrom.Y
        Root.Position = UDim2.new(
            dragOrigin.X.Scale, dragOrigin.X.Offset + dx,
            dragOrigin.Y.Scale, dragOrigin.Y.Offset + dy)
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragOn = false
    end
end)

local function applyToggleUI()
    if State.enabled then
        TogBtn.Text            = "  AUTO-CLICK  ON"
        TDot.BackgroundColor3  = C.accent
        tw(TogBtn, 0.2, {BackgroundColor3=Color3.fromRGB(0,90,58)}):Play()
        tw(SDot,   0.2, {BackgroundColor3=C.accent}):Play()
        tw(Pill,   0.2, {BackgroundColor3=C.on_bg}):Play()
        PillTxt.TextColor3     = C.accent
        PillStroke.Color       = C.accent
        accum    = 0
        lastTime = tick()
    else
        TogBtn.Text            = "  AUTO-CLICK  OFF"
        TDot.BackgroundColor3  = C.danger
        tw(TogBtn, 0.2, {BackgroundColor3=C.off_bg}):Play()
        tw(SDot,   0.2, {BackgroundColor3=Color3.fromRGB(60,20,20)}):Play()
        tw(Pill,   0.2, {BackgroundColor3=C.off_bg}):Play()
        PillTxt.TextColor3     = C.muted
        PillStroke.Color       = C.border
        accum = 0
    end
end

TogBtn.MouseButton1Click:Connect(function()
    State.enabled = not State.enabled
    applyToggleUI()
end)

UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == State.hotkey then
        State.enabled = not State.enabled
        applyToggleUI()
    end
end)

local selectConn

SelBtn.MouseButton1Click:Connect(function()
    if State.selectMode then return end
    State.selectMode = true
    SelBtn.Text = "🎯   TAP YOUR TARGET..."
    tw(SelBtn, 0.15, {BackgroundColor3=Color3.fromRGB(110,52,8)}):Play()
    setExpanded(false)
    if selectConn then selectConn:Disconnect() end
    task.wait(0.20)
    selectConn = UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch
        and inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end
        local px, py = inp.Position.X, inp.Position.Y
        local rp = Root.AbsolutePosition
        local rs = Root.AbsoluteSize
        local extraH = State.expanded and DRAWER_MAXH or 0
        if px >= rp.X - 14 and px <= rp.X + rs.X + 14
        and py >= rp.Y - 14 and py <= rp.Y + rs.Y + 14 + extraH then return end
        setManualTarget(px, py)
        SelBtn.Text = "🎯   SET TARGET  (tap anywhere)"
        tw(SelBtn, 0.15, {BackgroundColor3=Color3.fromRGB(10,46,118)}):Play()
        TargLbl.Text       = "✓  "..State.targetName
        TargLbl.TextColor3 = C.accent
        TargIconLbl.TextColor3 = MODECOLORS[State.mode] or C.accent
        ModeLbl.Text       = State.mode
        ModeLbl.TextColor3 = MODECOLORS[State.mode] or C.text
        LockBadge.Visible  = State.modeLocked
        for _, btn in ipairs(ModeCycleRow:GetChildren()) do
            if btn:IsA("TextButton") then
                local active = (btn.Text:gsub(" ","") == State.mode)
                btn.BackgroundColor3 = active and C.card3 or C.card
                btn.TextColor3       = active and (MODECOLORS[State.mode] or C.text) or C.muted
                local s = btn:FindFirstChildOfClass("UIStroke")
                if s then s.Color = active and C.borderHi or C.border end
            end
        end
        PillModeTxt.Text       = State.mode
        PillModeTxt.TextColor3 = MODECOLORS[State.mode] or C.dim
        State.selectMode = false
        selectConn:Disconnect()
        selectConn = nil
    end)
end)

ClearBtn.MouseButton1Click:Connect(function()
    State.target     = nil
    State.guiTarget  = nil
    State.targetName = "None"
    State.modeLocked = false
    State.mode       = "AUTO"
    modeIdx          = 1
    ModeLbl.Text     = "AUTO"
    ModeLbl.TextColor3 = C.accentB
    LockBadge.Visible  = false
    TargLbl.Text       = "No target  ·  AUTO uses crosshair"
    TargLbl.TextColor3 = C.muted
    TargIconLbl.TextColor3 = C.dim
    PillModeTxt.Text       = "AUTO"
    PillModeTxt.TextColor3 = C.dim
    for _, btn in ipairs(ModeCycleRow:GetChildren()) do
        if btn:IsA("TextButton") then
            local active = (btn.Text:gsub(" ","") == "AUTO")
            btn.BackgroundColor3 = active and C.card3 or C.card
            btn.TextColor3       = active and C.accentB or C.muted
            local s = btn:FindFirstChildOfClass("UIStroke")
            if s then s.Color = active and C.borderHi or C.border end
        end
    end
end)

PlusBtn.MouseButton1Click:Connect(function()
    State.cps = math.min(State.cps + 1, State.MAX_CPS)
    refreshCps()
end)
MinBtn.MouseButton1Click:Connect(function()
    State.cps = math.max(State.cps - 1, State.MIN_CPS)
    refreshCps()
end)

local function holdRamp(btn, delta)
    local held = false
    btn.MouseButton1Down:Connect(function()
        held = true
        task.delay(0.28, function()
            while held do
                State.cps = math.clamp(State.cps + delta, State.MIN_CPS, State.MAX_CPS)
                refreshCps()
                task.wait(0.040)
            end
        end)
    end)
    local function stopHold() held = false end
    btn.MouseButton1Up:Connect(stopHold)
    btn.MouseLeave:Connect(stopHold)
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then stopHold() end
    end)
end

holdRamp(PlusBtn,  1)
holdRamp(MinBtn,  -1)

for i, item in ipairs(historyItems) do
    item.use.MouseButton1Click:Connect(function()
        local h = State.targetHistory[i]
        if h and safeParent(h.target) then
            State.target      = h.target
            State.mode        = h.mode
            State.modeLocked  = true
            State.targetName  = h.name
            ModeLbl.Text      = h.mode
            ModeLbl.TextColor3 = MODECOLORS[h.mode] or C.text
            LockBadge.Visible = true
            TargLbl.Text      = "✓  "..h.name
            TargLbl.TextColor3 = C.accent
            switchTab(1)
        end
    end)
end

local chromaT  = 0
local pulseT   = 0
local pulseDir = 1
local frameN   = 0
local graphUpdateT = tick()
local graphBuckets = {}
for i = 1, 10 do graphBuckets[i] = 0 end

RunService.Heartbeat:Connect(function(dt)
    frameN = frameN + 1
    if State.perfMode and (frameN % PERF_SKIP ~= 0) then return end

    chromaT = (chromaT + dt * 60) % 360
    HaloGrad.Rotation = chromaT

    if State.enabled then
        pulseT   = pulseT + dt * pulseDir * 1.8
        if pulseT >= 1 then pulseT = 1; pulseDir = -1 end
        if pulseT <= 0 then pulseT = 0; pulseDir =  1 end
        Halo.BackgroundTransparency = 0.10 + pulseT * 0.52
    else
        Halo.BackgroundTransparency = 0.80
    end

    BadgeTxt.Text = tostring(State.realCps)

    local meterFrac = math.min(State.realCps / math.max(State.cps, 1), 1)
    MeterFill.Size = UDim2.new(meterFrac, 0, 1, 0)
    MeterLbl.Text = string.format("Actual: %d cps   ·   Set: %d cps   ·   Total: %d",
        State.realCps, State.cps, State.totalClicks)
    MeterLbl.TextColor3 = State.enabled and C.accent or C.muted

    local opVal = getOpacity() / 100
    if math.abs(opVal - State.opacity) > 0.01 then
        State.opacity = opVal
        SG.Enabled = true
        Root.GroupTransparency = 1 - opVal
    end

    if not State.selectMode then
        PillModeTxt.Text       = State.mode
        PillModeTxt.TextColor3 = MODECOLORS[State.mode] or C.dim
    end

    if State.mode == "AUTO" and State.enabled and not State.selectMode then
        TargLbl.Text       = "⟳  "..State.targetName
        TargLbl.TextColor3 = C.warn
        TargIconLbl.TextColor3 = C.warn
    end

    if State.targetDist > 0 then
        TargDistLbl.Text = string.format("%.1fm", State.targetDist)
    else
        TargDistLbl.Text = ""
    end

    local now = tick()
    if State.activeTab == "STATS" and frameN % 30 == 0 then
        local elapsed = now - State.sessionStart
        local mins    = math.floor(elapsed / 60)
        local secs    = math.floor(elapsed % 60)
        TotalClicksLbl.Text  = "Total Clicks: "..tostring(State.totalClicks)
        SessionTimeLbl.Text  = string.format("Session: %dm %ds", mins, secs)
        local cpm = State.totalClicks / math.max(elapsed / 60, 0.001)
        ClickRateLbl.Text = string.format("Rate: %.0f clicks/min", cpm)
        StatsTxt.Text = string.format("%d clicks", State.totalClicks)
    end

    if now - graphUpdateT >= 1 then
        graphUpdateT = now
        table.remove(graphBuckets, 1)
        table.insert(graphBuckets, State.realCps)
        local maxVal = 1
        for _, v in ipairs(graphBuckets) do if v > maxVal then maxVal = v end end
        for gi, bar in ipairs(graphBars) do
            local frac = graphBuckets[gi] / maxVal
            tw(bar, 0.35, {Size=UDim2.new(0.08,-2,frac,0)}, Enum.EasingStyle.Quad):Play()
        end
    end

    if State.activeTab == "HISTORY" and frameN % 60 == 0 then
        refreshHistory()
    end

    CHDot.BackgroundColor3 = State.enabled and C.accent or C.muted
end)

print("[PhantomV8 SPECTRE] Loaded.")
print("  Engine: touchinterest | clickdetector | proximityprompt | remote | GuiButton")
print("  Hotkey: ] to toggle | Drag: ⠿ handle | Tabs: MAIN / SETTINGS / STATS / HISTORY")

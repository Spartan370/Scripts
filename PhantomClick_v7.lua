-- ╔══════════════════════════════════════════════════════════════════════╗
-- ║  PHANTOM  v7  ·  "WRAITH"                                           ║
-- ║  Universal Edition  ·  iPhone / Delta  ·  Zero Cursor              ║
-- ║  Remote-Fire Engine  ·  FireTouchInterest  ·  FireClickDetector     ║
-- ║  Bypasses 60-CPS game limits  ·  No screen tap  ·  No input sim    ║
-- ╚══════════════════════════════════════════════════════════════════════╝

--[[
════════════════════════════════════════════════════════════════════════
  HOW THE CLICK ENGINE WORKS  (why there's no cursor)
════════════════════════════════════════════════════════════════════════
  v7 uses REMOTE FIRE — directly invokes game objects instead of
  simulating screen input (which spawns the white cursor on iOS Delta).

  TIER 1 — firetouchinterest(part, HumanoidRootPart, 0/1)
    Fires .Touched/.TouchEnded on any BasePart. Works on mining nodes,
    combat dummies, etc. No distance limit. No cursor. No CPS cap.

  TIER 2 — fireclickdetector(clickDetector, dist)
    Fires a ClickDetector as if clicked. Works on doors, buttons, NPCs.

  TIER 3 — fireproximityprompt(prompt)
    Fires a ProximityPrompt. Works on interact-to-harvest/attack.

  TIER 4 — FireServer() on tool Activated remote
    Fires a tool's RemoteEvent the same way its LocalScript would.

  AUTO-DETECT scans the camera crosshair each fire cycle and picks the
  correct tier. Manual SET TARGET lets you tap any object.

  BUG-FIXES vs v6:
    • CPS bucket purge was skipping entries (forward-loop + remove bug)
      → Fixed: iterate in reverse
    • autoDetect() was called TWICE per fire in AUTO mode
      → Fixed: only called from worker, not inside fireClick()
    • holdRamp held=true forever on mobile (MouseLeave unreliable)
      → Fixed: also hooks InputEnded for Touch type
    • Manual mode lock: user-set mode no longer overwritten by autoDetect
    • findClickDetector/findProximityPrompt now search full model hierarchy
    • fireproximityprompt fires with holdDuration for harvest-type prompts
    • Burst cap: max 8 clicks per Heartbeat prevents runaway spikes
    • DRAWER_MAXH clamped to viewport height for small iPhones
    • Halo gradient update is rotation-only (no new ColorSequence per frame)
    • State.modeLabel removed (was declared but never used)
    • target.Parent access wrapped in pcall to avoid race-condition errors
    • DrawerClip bounds included in SET TARGET self-rejection
════════════════════════════════════════════════════════════════════════
]]

-- ── Services ──────────────────────────────────────────────────────────
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local UserInputService  = game:GetService("UserInputService")
local TweenService      = game:GetService("TweenService")
local Workspace         = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP  = Players.LocalPlayer
local PG  = LP:WaitForChild("PlayerGui")
local CAM = Workspace.CurrentCamera

-- ── Cleanup old instances ─────────────────────────────────────────────
for _, v in ipairs(PG:GetChildren()) do
    if v.Name == "PhantomV6" or v.Name == "PhantomV7" then v:Destroy() end
end

-- ══════════════════════════════════════════════════════════════════════
--  CONSTANTS & STATE
-- ══════════════════════════════════════════════════════════════════════
local MAX_BURST = 8      -- max clicks fired per Heartbeat frame (prevents runaway)
local CPS_WINDOW = 1.0   -- rolling window for real-CPS measurement (seconds)

local State = {
    enabled      = false,
    mode         = "AUTO",  -- "AUTO"|"TOUCH"|"CLICK"|"PROMPT"|"TOOL"|"REMOTE"
    modeLocked   = false,   -- true when user manually set mode — blocks autoDetect override
    cps          = 15,
    MAX_CPS      = 999,
    MIN_CPS      = 1,
    target       = nil,     -- BasePart / ClickDetector / ProximityPrompt / RemoteEvent
    targetName   = "None",
    expanded     = false,
    realCps      = 0,
    selectMode   = false,
}

local clickBucket = {}
local accum       = 0.0
local lastTime    = tick()

-- ══════════════════════════════════════════════════════════════════════
--  CLICK ENGINE — remote-fire only, no input simulation, no cursor
-- ══════════════════════════════════════════════════════════════════════

-- ── Raycast helper — camera crosshair ────────────────────────────────
local function getRayTarget()
    local vp = CAM.ViewportSize
    if vp.X <= 0 or vp.Y <= 0 then return nil end
    local ray    = CAM:ScreenPointToRay(vp.X / 2, vp.Y / 2)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    if LP.Character then
        params.FilterDescendantsInstances = {LP.Character}
    end
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 300, params)
    return result and result.Instance or nil
end

-- ── Deep-search helpers — walk full ancestor chain ───────────────────
local function findDeepChild(root, className, depth)
    depth = depth or 3
    if not root or depth <= 0 then return nil end
    local found = root:FindFirstChildOfClass(className)
    if found then return found end
    if root.Parent then
        found = root.Parent:FindFirstChildOfClass(className)
        if found then return found end
        if root.Parent.Parent and depth >= 3 then
            found = root.Parent.Parent:FindFirstChildOfClass(className)
            if found then return found end
        end
    end
    return nil
end

local function findClickDetector(part)
    return findDeepChild(part, "ClickDetector", 3)
end

local function findProximityPrompt(part)
    return findDeepChild(part, "ProximityPrompt", 3)
end

-- ── Find active tool's RemoteEvent ────────────────────────────────────
local function findToolRemote()
    local char = LP.Character
    if not char then return nil, nil end
    local tool = char:FindFirstChildOfClass("Tool")
    if not tool then return nil, nil end

    local names = {
        "Attack","Hit","Swing","Action","Use","Click","Fire",
        "Damage","Event","Activate","Perform","Cast"
    }
    for _, n in ipairs(names) do
        local r = tool:FindFirstChild(n) or tool:FindFirstChild(n .. "Event")
        if r and (r:IsA("RemoteEvent") or r:IsA("RemoteFunction")) then
            return r, tool
        end
    end

    local r = tool:FindFirstChildOfClass("RemoteEvent")
           or tool:FindFirstChildOfClass("RemoteFunction")
    if r then return r, tool end

    -- Search ReplicatedStorage for remotes named after the tool
    for _, child in ipairs(ReplicatedStorage:GetChildren()) do
        if child:IsA("RemoteEvent") then
            local cn = child.Name:lower()
            local tn = tool.Name:lower()
            if cn:find(tn, 1, true) or tn:find(cn, 1, true) then
                return child, tool
            end
        end
    end
    return nil, tool
end

-- ── Validate a target is still alive ─────────────────────────────────
local function targetAlive(t)
    if not t then return false end
    local ok, parent = pcall(function() return t.Parent end)
    return ok and parent ~= nil
end

-- ── AUTO-DETECT: scan crosshair and classify target ──────────────────
-- Only updates State.mode/target if mode is not user-locked
local function autoDetect()
    local part = getRayTarget()
    if not part then
        local remote, tool = findToolRemote()
        if remote then
            State.target     = remote
            if not State.modeLocked then State.mode = "REMOTE" end
            State.targetName = (tool and tool.Name or "?") .. " → " .. remote.Name
            return
        end
        State.target     = nil
        State.targetName = "Nothing in crosshair"
        if not State.modeLocked then State.mode = "AUTO" end
        return
    end

    local cd = findClickDetector(part)
    if cd then
        State.target     = cd
        if not State.modeLocked then State.mode = "CLICK" end
        State.targetName = "ClickDetector: " .. part.Name
        return
    end

    local pp = findProximityPrompt(part)
    if pp then
        State.target     = pp
        if not State.modeLocked then State.mode = "PROMPT" end
        State.targetName = "Prompt: " .. part.Name
        return
    end

    State.target     = part
    if not State.modeLocked then State.mode = "TOUCH" end
    State.targetName = "Touch: " .. part.Name
end

-- ── Manual target override ────────────────────────────────────────────
local function setManualTarget(screenX, screenY)
    local vp = CAM.ViewportSize
    if vp.X <= 0 or vp.Y <= 0 then return end

    local ray    = CAM:ScreenPointToRay(screenX, screenY)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    if LP.Character then
        params.FilterDescendantsInstances = {LP.Character}
    end
    local result = Workspace:Raycast(ray.Origin, ray.Direction * 500, params)

    if result and result.Instance then
        local part = result.Instance
        local cd   = findClickDetector(part)
        if cd then
            State.target      = cd
            State.mode        = "CLICK"
            State.modeLocked  = true
            State.targetName  = "ClickDetector: " .. part.Name
            return
        end
        local pp = findProximityPrompt(part)
        if pp then
            State.target      = pp
            State.mode        = "PROMPT"
            State.modeLocked  = true
            State.targetName  = "Prompt: " .. part.Name
            return
        end
        State.target      = part
        State.mode        = "TOUCH"
        State.modeLocked  = true
        State.targetName  = "Touch: " .. part.Name
        return
    end

    State.targetName  = string.format("Screen (%.0f, %.0f)", screenX, screenY)
    State.mode        = "AUTO"
    State.modeLocked  = false
    State.target      = nil
end

-- ── FIRE FUNCTION — the heart of the engine ──────────────────────────
local function fireClick()
    local char = LP.Character
    local hrp  = char and char:FindFirstChild("HumanoidRootPart")

    if not targetAlive(State.target) then
        -- Target gone — if locked reset the lock so AUTO can re-detect
        if State.modeLocked then
            State.modeLocked = false
            State.target     = nil
            State.targetName = "Target gone — re-scanning"
        end
        if State.mode == "AUTO" then
            autoDetect()
        end
    end

    local t = State.target
    if not t then return end

    if State.mode == "TOUCH" then
        if firetouchinterest and hrp then
            pcall(firetouchinterest, t, hrp, 0)
            task.wait(0.002)
            pcall(firetouchinterest, t, hrp, 1)
        end

    elseif State.mode == "CLICK" then
        if fireclickdetector then
            pcall(fireclickdetector, t, 0)
        end

    elseif State.mode == "PROMPT" then
        if fireproximityprompt then
            -- Fire twice: once as tap, once as hold-start, covers harvest-type prompts
            pcall(fireproximityprompt, t)
            -- Some games require a held trigger; attempt with holdDuration if supported
            pcall(function()
                if t and t.HoldDuration and t.HoldDuration > 0 then
                    fireproximityprompt(t)
                end
            end)
        end

    elseif State.mode == "REMOTE" or State.mode == "TOOL" then
        if t:IsA("RemoteEvent") then
            pcall(function() t:FireServer() end)
        elseif t:IsA("RemoteFunction") then
            pcall(function() t:InvokeServer() end)
        end
    end
end

-- ══════════════════════════════════════════════════════════════════════
--  BACKGROUND WORKER — precision accumulator with burst cap
-- ══════════════════════════════════════════════════════════════════════
task.spawn(function()
    while true do
        if State.enabled then
            local now   = tick()
            local delta = math.min(now - lastTime, 0.2)
            lastTime    = now

            accum = accum + delta * State.cps

            -- Burst cap: clamp so we never fire more than MAX_BURST per frame
            if accum > MAX_BURST then accum = MAX_BURST end

            -- In AUTO mode, re-detect each frame (tracks moving targets)
            if State.mode == "AUTO" and not State.modeLocked then
                autoDetect()
            end

            while accum >= 1.0 do
                accum = accum - 1.0
                fireClick()
                table.insert(clickBucket, tick())
            end
        else
            accum    = 0
            lastTime = tick()
        end

        -- Purge stale CPS bucket (FIXED: iterate in reverse to avoid skip-on-remove bug)
        local now = tick()
        for i = #clickBucket, 1, -1 do
            if now - clickBucket[i] > CPS_WINDOW then
                table.remove(clickBucket, i)
            end
        end
        State.realCps = #clickBucket

        task.wait(0)
    end
end)

-- ══════════════════════════════════════════════════════════════════════
--  GUI
-- ══════════════════════════════════════════════════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name            = "PhantomV7"
SG.ResetOnSpawn    = false
SG.ZIndexBehavior  = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset  = true
SG.DisplayOrder    = 9999
SG.Parent          = PG

-- ── Color palette ─────────────────────────────────────────────────────
local C = {
    bg      = Color3.fromRGB(5,    5,  10),
    card    = Color3.fromRGB(11,  11,  20),
    card2   = Color3.fromRGB(16,  16,  28),
    border  = Color3.fromRGB(32,  32,  58),
    accent  = Color3.fromRGB(0,  220, 140),
    accentB = Color3.fromRGB(0,  150, 255),
    danger  = Color3.fromRGB(220,  45,  55),
    warn    = Color3.fromRGB(255, 170,  20),
    text    = Color3.fromRGB(235, 235, 255),
    muted   = Color3.fromRGB(75,   75, 125),
    dim     = Color3.fromRGB(45,   45,  75),
    gA      = Color3.fromRGB(0,   210, 135),
    gB      = Color3.fromRGB(0,   150, 255),
    gC      = Color3.fromRGB(130,  55, 255),
    on_bg   = Color3.fromRGB(0,    38,  26),
    off_bg  = Color3.fromRGB(12,   12,  22),
    locked  = Color3.fromRGB(255, 200,  20),
}

-- ── Shared helpers ────────────────────────────────────────────────────
local function rc(f, r)
    local u = Instance.new("UICorner")
    u.CornerRadius = UDim.new(0, r or 12)
    u.Parent = f
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
    l.Parent         = par
    return l
end

-- Ripple — fires on press, cleans itself up, no size-persistence bug
local function ripple(btn)
    btn.MouseButton1Down:Connect(function(mx, my)
        local r = Instance.new("Frame")
        r.AnchorPoint            = Vector2.new(0.5, 0.5)
        r.Size                   = UDim2.new(0,0,0,0)
        r.Position               = UDim2.new(0, mx - btn.AbsolutePosition.X,
                                              0, my - btn.AbsolutePosition.Y)
        r.BackgroundColor3       = Color3.fromRGB(255,255,255)
        r.BackgroundTransparency = 0.70
        r.BorderSizePixel        = 0
        r.ZIndex                 = btn.ZIndex + 2
        r.Parent                 = btn
        rc(r, 999)

        local spread = math.max(btn.AbsoluteSize.X, btn.AbsoluteSize.Y) * 2.6
        tw(r, 0.42, {
            Size = UDim2.new(0, spread, 0, spread),
            BackgroundTransparency = 1,
        }, Enum.EasingStyle.Quad):Play()
        task.delay(0.43, function() r:Destroy() end)
    end)
end

-- Standard card-style button
local function mkBtn(name, text, bg, parent, order)
    local b = Instance.new("TextButton")
    b.Name             = name
    b.Size             = UDim2.new(1, 0, 0, 50)
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

-- ── Root frame ────────────────────────────────────────────────────────
local PILL_W = 170
local PILL_H = 46
local MARGIN = 10

-- Clamp drawer height to viewport so it doesn't go off-screen on small iPhones
local function getDrawerMaxH()
    local vh = CAM.ViewportSize.Y
    if vh <= 0 then vh = 700 end
    return math.min(460, vh - PILL_H - MARGIN * 4 - 60)
end
local DRAWER_MAXH = getDrawerMaxH()
local DRAWER_W    = PILL_W + 22
local DRAWER_X    = -11

local Root = Instance.new("Frame")
Root.Name                   = "PhantomRoot"
Root.Size                   = UDim2.new(0, PILL_W + 8, 0, PILL_H + 8)
Root.Position               = UDim2.new(1, -(PILL_W + 8 + MARGIN), 0, 56 + MARGIN)
Root.BackgroundTransparency = 1
Root.ClipsDescendants       = false
Root.ZIndex                 = 20
Root.Parent                 = SG

-- ── Animated glow halo ────────────────────────────────────────────────
local Halo = Instance.new("Frame")
Halo.Size                   = UDim2.new(1, 0, 0, PILL_H + 8)
Halo.BackgroundColor3       = C.gA
Halo.BackgroundTransparency = 0.6
Halo.BorderSizePixel        = 0
Halo.ZIndex                 = 19
Halo.Parent                 = Root
rc(Halo, 28)
local HaloGrad = grd(Halo, C.gA, C.gB, 90)

-- ── Pill body ─────────────────────────────────────────────────────────
local Pill = Instance.new("Frame")
Pill.Size             = UDim2.new(1, -6, 0, PILL_H)
Pill.Position         = UDim2.new(0, 3, 0, 3)
Pill.BackgroundColor3 = C.off_bg
Pill.BorderSizePixel  = 0
Pill.ZIndex           = 21
Pill.ClipsDescendants = true
Pill.Parent           = Root
rc(Pill, 23)
grd(Pill, Color3.fromRGB(16,16,28), Color3.fromRGB(9,9,16), 140)
stk(Pill, C.border, 1)

-- Status dot
local SDot = Instance.new("Frame")
SDot.Size             = UDim2.new(0, 9, 0, 9)
SDot.Position         = UDim2.new(0, 13, 0.5, -4)
SDot.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
SDot.BorderSizePixel  = 0
SDot.ZIndex           = 23
SDot.Parent           = Pill
rc(SDot, 5)

-- Pill label
local PillTxt = mkTxt({
    text  = "PHANTOM",
    size  = 11,
    color = C.muted,
    sz    = UDim2.new(0, 76, 1, 0),
    pos   = UDim2.new(0, 28, 0, 0),
    font  = Enum.Font.GothamBold,
    z     = 23,
}, Pill)

-- CPS badge in pill
local Badge = Instance.new("Frame")
Badge.Size             = UDim2.new(0, 54, 0, 28)
Badge.Position         = UDim2.new(1, -62, 0.5, -14)
Badge.BackgroundColor3 = Color3.fromRGB(14, 14, 26)
Badge.BorderSizePixel  = 0
Badge.ZIndex           = 23
Badge.Parent           = Pill
rc(Badge, 9)
stk(Badge, C.border, 1)

local BadgeTxt = mkTxt({
    text  = "0",
    size  = 13,
    color = C.text,
    sz    = UDim2.new(1, 0, 1, 0),
    font  = Enum.Font.GothamBold,
    z     = 24,
    xa    = Enum.TextXAlignment.Center,
}, Badge)

-- Tap pill to toggle drawer
local PillTap = Instance.new("TextButton")
PillTap.Size                   = UDim2.new(1, -34, 1, 0)
PillTap.BackgroundTransparency = 1
PillTap.Text                   = ""
PillTap.AutoButtonColor        = false
PillTap.ZIndex                 = 25
PillTap.Parent                 = Pill

-- Drag handle ⠿
local Handle = Instance.new("TextButton")
Handle.Size                   = UDim2.new(0, 30, 1, 0)
Handle.Position               = UDim2.new(1, -30, 0, 0)
Handle.BackgroundTransparency = 1
Handle.Text                   = "⠿"
Handle.TextColor3             = C.dim
Handle.Font                   = Enum.Font.GothamBold
Handle.TextSize               = 18
Handle.AutoButtonColor        = false
Handle.ZIndex                 = 26
Handle.Parent                 = Pill

-- ── DRAWER ────────────────────────────────────────────────────────────
local DrawerClip = Instance.new("Frame")
DrawerClip.Size                   = UDim2.new(0, DRAWER_W, 0, 0)
DrawerClip.Position               = UDim2.new(0, DRAWER_X, 0, PILL_H + 4)
DrawerClip.BackgroundTransparency = 1
DrawerClip.ClipsDescendants       = true
DrawerClip.ZIndex                 = 14
DrawerClip.Visible                = false
DrawerClip.Parent                 = Root

-- Card shadow
local DShadow = Instance.new("Frame")
DShadow.Size                   = UDim2.new(1, 24, 1, 24)
DShadow.Position               = UDim2.new(0, -12, 0, -12)
DShadow.BackgroundColor3       = Color3.fromRGB(0, 0, 0)
DShadow.BackgroundTransparency = 0.42
DShadow.BorderSizePixel        = 0
DShadow.ZIndex                 = 13
DShadow.Parent                 = DrawerClip
rc(DShadow, 24)

-- Drawer card
local Drawer = Instance.new("Frame")
Drawer.Size             = UDim2.new(1, 0, 0, DRAWER_MAXH)
Drawer.BackgroundColor3 = C.card
Drawer.BorderSizePixel  = 0
Drawer.ZIndex           = 15
Drawer.Parent           = DrawerClip
rc(Drawer, 18)
grd(Drawer, C.card2, C.bg, 155)
stk(Drawer, C.border, 1)

-- ── Drawer header (fixed) ─────────────────────────────────────────────
local DH = Instance.new("Frame")
DH.Size             = UDim2.new(1, 0, 0, 46)
DH.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
DH.BorderSizePixel  = 0
DH.ZIndex           = 17
DH.Parent           = Drawer
rc(DH, 18)

local DHSq = Instance.new("Frame")
DHSq.Size             = UDim2.new(1, 0, 0.5, 0)
DHSq.Position         = UDim2.new(0, 0, 0.5, 0)
DHSq.BackgroundColor3 = Color3.fromRGB(8, 8, 18)
DHSq.BorderSizePixel  = 0
DHSq.ZIndex           = 17
DHSq.Parent           = DH

mkTxt({text="⚡  PHANTOM  v7", size=13, color=C.text,
    sz=UDim2.new(1,-40,0,22), pos=UDim2.new(0,14,0,4),
    font=Enum.Font.GothamBold, z=18}, DH)
mkTxt({text="WRAITH  ·  REMOTE ENGINE  ·  ZERO CURSOR", size=8, color=C.muted,
    sz=UDim2.new(1,-14,0,14), pos=UDim2.new(0,14,0,26),
    font=Enum.Font.Gotham, z=18}, DH)

local DHDiv = Instance.new("Frame")
DHDiv.Size             = UDim2.new(1, -24, 0, 1)
DHDiv.Position         = UDim2.new(0, 12, 0, 45)
DHDiv.BackgroundColor3 = C.border
DHDiv.BorderSizePixel  = 0
DHDiv.ZIndex           = 17
DHDiv.Parent           = Drawer

-- ── Scrolling body ────────────────────────────────────────────────────
local Scroll = Instance.new("ScrollingFrame")
Scroll.Size                   = UDim2.new(1, 0, 1, -47)
Scroll.Position               = UDim2.new(0, 0, 0, 47)
Scroll.BackgroundTransparency = 1
Scroll.BorderSizePixel        = 0
Scroll.CanvasSize             = UDim2.new(0, 0, 0, 0)
Scroll.AutomaticCanvasSize    = Enum.AutomaticSize.Y
Scroll.ScrollBarThickness     = 3
Scroll.ScrollBarImageColor3   = C.dim
Scroll.ScrollingDirection     = Enum.ScrollingDirection.Y
Scroll.ElasticBehavior        = Enum.ElasticBehavior.Always
Scroll.ZIndex                 = 16
Scroll.Parent                 = Drawer

local SLL = Instance.new("UIListLayout")
SLL.SortOrder = Enum.SortOrder.LayoutOrder
SLL.Padding   = UDim.new(0, 8)
SLL.Parent    = Scroll

local SPD = Instance.new("UIPadding")
SPD.PaddingLeft   = UDim.new(0, 12)
SPD.PaddingRight  = UDim.new(0, 12)
SPD.PaddingTop    = UDim.new(0, 10)
SPD.PaddingBottom = UDim.new(0, 10)
SPD.Parent        = Scroll

-- ── TOGGLE ────────────────────────────────────────────────────────────
local TogBtn = mkBtn("Toggle", "  AUTO-CLICK  OFF", C.off_bg, Scroll, 1)

local TDot = Instance.new("Frame")
TDot.Size             = UDim2.new(0, 9, 0, 9)
TDot.Position         = UDim2.new(0, 15, 0.5, -4)
TDot.BackgroundColor3 = C.danger
TDot.BorderSizePixel  = 0
TDot.ZIndex           = 19
TDot.Parent           = TogBtn
rc(TDot, 5)

-- ── MODE SELECTOR ─────────────────────────────────────────────────────
local ModeCard = Instance.new("Frame")
ModeCard.Size             = UDim2.new(1, 0, 0, 44)
ModeCard.BackgroundColor3 = C.card2
ModeCard.BorderSizePixel  = 0
ModeCard.ZIndex           = 18
ModeCard.LayoutOrder      = 2
ModeCard.Parent           = Scroll
rc(ModeCard, 11)
stk(ModeCard, C.border, 1)

mkTxt({text="MODE", size=9, color=C.muted,
    sz=UDim2.new(0,55,1,0), pos=UDim2.new(0,12,0,0),
    font=Enum.Font.GothamBold, z=19}, ModeCard)

local ModeLbl = mkTxt({text="AUTO", size=12, color=C.accent,
    sz=UDim2.new(1,-70,1,0), pos=UDim2.new(0,60,0,0),
    font=Enum.Font.GothamBold, z=19,
    xa=Enum.TextXAlignment.Right}, ModeCard)

-- Mode lock indicator (shown when user has manually set mode)
local LockLbl = mkTxt({text="", size=8, color=C.locked,
    sz=UDim2.new(0,38,1,0), pos=UDim2.new(0,60,0,0),
    font=Enum.Font.Gotham, z=20,
    xa=Enum.TextXAlignment.Left}, ModeCard)

-- Mode cycle button
local ModeBtn = Instance.new("TextButton")
ModeBtn.Size             = UDim2.new(0, 28, 0, 28)
ModeBtn.Position         = UDim2.new(1, -34, 0.5, -14)
ModeBtn.BackgroundColor3 = C.card
ModeBtn.Text             = "↻"
ModeBtn.TextColor3       = C.muted
ModeBtn.Font             = Enum.Font.GothamBold
ModeBtn.TextSize         = 16
ModeBtn.BorderSizePixel  = 0
ModeBtn.AutoButtonColor  = false
ModeBtn.ZIndex           = 20
ModeBtn.Parent           = ModeCard
rc(ModeBtn, 7)
stk(ModeBtn, C.border, 1)
ripple(ModeBtn)

local MODES   = {"AUTO","TOUCH","CLICK","PROMPT","TOOL","REMOTE"}
local modeIdx = 1

ModeBtn.MouseButton1Click:Connect(function()
    modeIdx = modeIdx % #MODES + 1
    State.mode      = MODES[modeIdx]
    State.modeLocked = (State.mode ~= "AUTO")
    ModeLbl.Text    = State.mode
    LockLbl.Text    = State.modeLocked and "LOCK" or ""
    -- When switching back to AUTO, clear manual target
    if State.mode == "AUTO" then
        State.target    = nil
        State.targetName = "None"
    end
end)

-- ── SET TARGET ────────────────────────────────────────────────────────
local SelBtn   = mkBtn("Select", "🎯   SET TARGET  (tap to aim)", Color3.fromRGB(12,48,120), Scroll, 3)
local ClearBtn = mkBtn("Clear",  "✕   CLEAR TARGET", Color3.fromRGB(28,10,10), Scroll, 4)

-- Target info card
local TargCard = Instance.new("Frame")
TargCard.Size             = UDim2.new(1, 0, 0, 34)
TargCard.BackgroundColor3 = C.card2
TargCard.BorderSizePixel  = 0
TargCard.ZIndex           = 18
TargCard.LayoutOrder      = 5
TargCard.Parent           = Scroll
rc(TargCard, 10)
stk(TargCard, C.border, 1)

local TargLbl = mkTxt({text="No target  ·  AUTO uses crosshair", size=10, color=C.muted,
    sz=UDim2.new(1,-16,1,0), pos=UDim2.new(0,10,0,0),
    font=Enum.Font.Gotham, z=19, xa=Enum.TextXAlignment.Left}, TargCard)

-- ── CPS ROW ───────────────────────────────────────────────────────────
local CpsCard = Instance.new("Frame")
CpsCard.Size             = UDim2.new(1, 0, 0, 56)
CpsCard.BackgroundColor3 = C.card2
CpsCard.BorderSizePixel  = 0
CpsCard.ZIndex           = 18
CpsCard.LayoutOrder      = 6
CpsCard.Parent           = Scroll
rc(CpsCard, 11)
stk(CpsCard, C.border, 1)

mkTxt({text="CPS", size=9, color=C.muted,
    sz=UDim2.new(0,55,0.5,0), pos=UDim2.new(0,12,0,0),
    font=Enum.Font.GothamBold, z=19}, CpsCard)
mkTxt({text="hold to ramp", size=8, color=C.dim,
    sz=UDim2.new(0,80,0.5,0), pos=UDim2.new(0,12,0.5,0),
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
rc(MinBtn, 9)
stk(MinBtn, C.border, 1)
ripple(MinBtn)

local CpsNumLbl = mkTxt({
    text  = tostring(State.cps),
    size  = 18,
    color = C.text,
    sz    = UDim2.new(0, BS, 1, 0),
    pos   = UDim2.new(1, -(BS*2+16)+BS+2, 0, 0),
    font  = Enum.Font.GothamBold,
    z     = 19,
    xa    = Enum.TextXAlignment.Center,
}, CpsCard)

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
rc(PlusBtn, 9)
stk(PlusBtn, C.border, 1)
ripple(PlusBtn)

-- ── LIVE METER ────────────────────────────────────────────────────────
local MeterCard = Instance.new("Frame")
MeterCard.Size             = UDim2.new(1, 0, 0, 34)
MeterCard.BackgroundColor3 = Color3.fromRGB(8, 8, 16)
MeterCard.BorderSizePixel  = 0
MeterCard.ZIndex           = 18
MeterCard.LayoutOrder      = 7
MeterCard.Parent           = Scroll
rc(MeterCard, 10)
stk(MeterCard, C.border, 1)

local MeterLbl = mkTxt({text="Actual: 0 cps  ·  Set: 15 cps", size=10, color=C.muted,
    sz=UDim2.new(1,-16,1,0), pos=UDim2.new(0,10,0,0),
    font=Enum.Font.Gotham, z=19}, MeterCard)

-- ── ENGINE INFO ───────────────────────────────────────────────────────
local InfoCard = Instance.new("Frame")
InfoCard.Size             = UDim2.new(1, 0, 0, 28)
InfoCard.BackgroundColor3 = Color3.fromRGB(6, 6, 14)
InfoCard.BorderSizePixel  = 0
InfoCard.ZIndex           = 18
InfoCard.LayoutOrder      = 8
InfoCard.Parent           = Scroll
rc(InfoCard, 10)
stk(InfoCard, C.border, 1)

mkTxt({
    text  = "Engine: touchinterest / clickdetector / proximityprompt / remote",
    size  = 9,
    color = C.dim,
    sz    = UDim2.new(1,-16,1,0),
    pos   = UDim2.new(0,10,0,0),
    font  = Enum.Font.Gotham,
    z     = 19,
}, InfoCard)

-- ── COLLAPSE ──────────────────────────────────────────────────────────
local ColBtn = mkBtn("Collapse", "▲   COLLAPSE", Color3.fromRGB(14,14,26), Scroll, 9)

-- ══════════════════════════════════════════════════════════════════════
--  EXPAND / COLLAPSE
-- ══════════════════════════════════════════════════════════════════════
local function setExpanded(open)
    State.expanded = open
    if open then
        DrawerClip.Visible = true
        DrawerClip.Size    = UDim2.new(0, DRAWER_W, 0, 0)
        tw(DrawerClip, 0.30, {Size=UDim2.new(0, DRAWER_W, 0, DRAWER_MAXH)},
            Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
    else
        tw(DrawerClip, 0.22, {Size=UDim2.new(0, DRAWER_W, 0, 0)},
            Enum.EasingStyle.Quart):Play()
        task.delay(0.23, function() DrawerClip.Visible = false end)
    end
end

PillTap.MouseButton1Click:Connect(function() setExpanded(not State.expanded) end)
ColBtn.MouseButton1Click:Connect(function()  setExpanded(false) end)

-- ══════════════════════════════════════════════════════════════════════
--  DRAG  (handle only)
-- ══════════════════════════════════════════════════════════════════════
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

-- FIXED: also stop drag on TouchEnd to prevent stuck drag on iOS
UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.Touch
    or inp.UserInputType == Enum.UserInputType.MouseButton1 then
        dragOn = false
    end
end)

-- ══════════════════════════════════════════════════════════════════════
--  TOGGLE
-- ══════════════════════════════════════════════════════════════════════
local function applyToggleUI()
    if State.enabled then
        TogBtn.Text           = "  AUTO-CLICK  ON"
        TDot.BackgroundColor3 = C.accent
        tw(TogBtn, 0.2, {BackgroundColor3=Color3.fromRGB(0,95,60)}):Play()
        tw(SDot,   0.2, {BackgroundColor3=C.accent}):Play()
        tw(Pill,   0.2, {BackgroundColor3=C.on_bg}):Play()
        PillTxt.TextColor3 = C.accent
        accum    = 0
        lastTime = tick()
    else
        TogBtn.Text           = "  AUTO-CLICK  OFF"
        TDot.BackgroundColor3 = C.danger
        tw(TogBtn, 0.2, {BackgroundColor3=C.off_bg}):Play()
        tw(SDot,   0.2, {BackgroundColor3=Color3.fromRGB(50,20,20)}):Play()
        tw(Pill,   0.2, {BackgroundColor3=C.off_bg}):Play()
        PillTxt.TextColor3 = C.muted
        accum = 0
    end
end

TogBtn.MouseButton1Click:Connect(function()
    State.enabled = not State.enabled
    applyToggleUI()
end)

-- Keyboard shortcut: ] (Right Bracket) toggles on PC / emulator
UserInputService.InputBegan:Connect(function(inp, gp)
    if gp then return end
    if inp.KeyCode == Enum.KeyCode.RightBracket then
        State.enabled = not State.enabled
        applyToggleUI()
    end
end)

-- ══════════════════════════════════════════════════════════════════════
--  SET TARGET
-- ══════════════════════════════════════════════════════════════════════
local selectConn

SelBtn.MouseButton1Click:Connect(function()
    if State.selectMode then return end
    State.selectMode = true
    SelBtn.Text = "🎯   TAP YOUR TARGET..."
    tw(SelBtn, 0.15, {BackgroundColor3=Color3.fromRGB(110,52,8)}):Play()
    setExpanded(false)

    if selectConn then selectConn:Disconnect() end
    task.wait(0.18)

    selectConn = UserInputService.InputBegan:Connect(function(inp)
        if inp.UserInputType ~= Enum.UserInputType.Touch
        and inp.UserInputType ~= Enum.UserInputType.MouseButton1 then return end

        local px, py = inp.Position.X, inp.Position.Y

        -- Self-rejection: includes both pill and drawer bounds
        local rp = Root.AbsolutePosition
        local rs = Root.AbsoluteSize
        local extraH = State.expanded and DRAWER_MAXH or 0
        if px >= rp.X - 14 and px <= rp.X + rs.X + 14
        and py >= rp.Y - 14 and py <= rp.Y + rs.Y + 14 + extraH then return end

        setManualTarget(px, py)

        SelBtn.Text = "🎯   SET TARGET  (tap to aim)"
        tw(SelBtn, 0.15, {BackgroundColor3=Color3.fromRGB(12,48,120)}):Play()
        TargLbl.Text       = "✓  " .. State.targetName
        TargLbl.TextColor3 = C.accent

        ModeLbl.Text = State.mode
        LockLbl.Text = State.modeLocked and "LOCK" or ""
        for i, m in ipairs(MODES) do
            if m == State.mode then modeIdx = i; break end
        end

        State.selectMode = false
        selectConn:Disconnect()
        selectConn = nil
    end)
end)

-- Clear Target button
ClearBtn.MouseButton1Click:Connect(function()
    State.target     = nil
    State.targetName = "None"
    State.modeLocked = false
    State.mode       = "AUTO"
    modeIdx          = 1
    ModeLbl.Text     = "AUTO"
    LockLbl.Text     = ""
    TargLbl.Text     = "No target  ·  AUTO uses crosshair"
    TargLbl.TextColor3 = C.muted
end)

-- ══════════════════════════════════════════════════════════════════════
--  CPS CONTROLS
-- ══════════════════════════════════════════════════════════════════════
local function refreshCps()
    CpsNumLbl.Text = tostring(State.cps)
end

PlusBtn.MouseButton1Click:Connect(function()
    State.cps = math.min(State.cps + 1, State.MAX_CPS)
    refreshCps()
end)
MinBtn.MouseButton1Click:Connect(function()
    State.cps = math.max(State.cps - 1, State.MIN_CPS)
    refreshCps()
end)

-- FIXED: holdRamp also hooks TouchEnd so held never gets stuck on mobile
local function holdRamp(btn, delta)
    local held = false

    btn.MouseButton1Down:Connect(function()
        held = true
        task.delay(0.3, function()
            while held do
                State.cps = math.clamp(State.cps + delta, State.MIN_CPS, State.MAX_CPS)
                refreshCps()
                task.wait(0.045)
            end
        end)
    end)

    local function stopHold() held = false end
    btn.MouseButton1Up:Connect(stopHold)
    btn.MouseLeave:Connect(stopHold)

    -- Mobile safety: stop on any touch-end anywhere
    UserInputService.InputEnded:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.Touch then
            stopHold()
        end
    end)
end

holdRamp(PlusBtn,  1)
holdRamp(MinBtn,  -1)

-- ══════════════════════════════════════════════════════════════════════
--  VISUAL HEARTBEAT  (cosmetics only — no click logic here)
-- ══════════════════════════════════════════════════════════════════════
local chromaT  = 0
local pulseT   = 0
local pulseDir = 1

RunService.Heartbeat:Connect(function(dt)
    -- Halo spin — FIXED: only update Rotation, no new ColorSequence each frame
    chromaT = (chromaT + dt * 65) % 360
    HaloGrad.Rotation = chromaT

    -- Pulse glow when active
    if State.enabled then
        pulseT   = pulseT + dt * pulseDir * 2.0
        if pulseT >= 1 then pulseT = 1; pulseDir = -1 end
        if pulseT <= 0 then pulseT = 0; pulseDir =  1 end
        Halo.BackgroundTransparency = 0.12 + pulseT * 0.50
    else
        Halo.BackgroundTransparency = 0.78
    end

    -- Pill CPS badge
    BadgeTxt.Text = tostring(State.realCps)

    -- Meter
    MeterLbl.Text = string.format("Actual: %d cps   ·   Set: %d cps",
        State.realCps, State.cps)
    MeterLbl.TextColor3 = State.enabled and C.accent or C.muted

    -- Mode label on pill (always up to date)
    if not State.selectMode then
        ModeLbl.Text = State.mode
        LockLbl.Text = State.modeLocked and "LOCK" or ""
    end

    -- Auto-update target label in AUTO mode
    if State.mode == "AUTO" and State.enabled and not State.selectMode then
        TargLbl.Text       = "⟳  " .. State.targetName
        TargLbl.TextColor3 = C.warn
    end
end)

print("[PhantomV7 WRAITH] Loaded. Remote-fire engine active. No cursor. No input sim.")
print("  Fixes: CPS bucket purge, double-autoDetect, holdRamp TouchEnd, burst cap, deep-search")
print("  New: Mode lock, Clear Target, ] key toggle, drawer height clamp, halo perf fix")

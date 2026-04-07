-- ╔═══════════════════════════════════════════════════╗
-- ║   PHANTOM CLICK v3  •  Delta Executor Edition     ║
-- ║   Compact • Modern • Full UI Passthrough          ║
-- ╚═══════════════════════════════════════════════════╝

local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui   = LocalPlayer:WaitForChild("PlayerGui")

-- ══════════════════════════
--  CLEAN UP OLD INSTANCES
-- ══════════════════════════
if PlayerGui:FindFirstChild("PhantomV3") then
    PlayerGui:FindFirstChild("PhantomV3"):Destroy()
end

-- ══════════════════════════
--  STATE
-- ══════════════════════════
local enabled      = false
local cps          = 10
local MAX_CPS      = 9999
local target       = nil        -- Vector2
local selectMode   = false
local selectConn   = nil
local collapsed    = false
local accum        = 0
local lastT        = tick()

local isMobile = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled

-- ══════════════════════════
--  DIMENSIONS
-- ══════════════════════════
local W       = isMobile and 260 or 240
local TH      = isMobile and 40  or 36   -- title bar height
local BH      = isMobile and 48  or 42   -- button height
local PAD     = 8
local FS      = isMobile and 13  or 12
local CORNER  = 14
local FULL_H  = TH + PAD + BH + PAD + BH + PAD + BH + PAD + 30 + PAD

-- ══════════════════════════
--  SCREEN GUI
-- ══════════════════════════
local SG = Instance.new("ScreenGui")
SG.Name             = "PhantomV3"
SG.ResetOnSpawn     = false
SG.ZIndexBehavior   = Enum.ZIndexBehavior.Sibling
SG.IgnoreGuiInset   = true
-- CRITICAL: DisplayOrder pushes our UI above all game GUIs
SG.DisplayOrder     = 999
SG.Parent           = PlayerGui

-- ══════════════════════════
--  CHROMA BORDER
-- ══════════════════════════
local Chroma = Instance.new("Frame")
Chroma.Name             = "Chroma"
Chroma.Size             = UDim2.new(0, W + 4, 0, FULL_H + 4)
Chroma.Position         = UDim2.new(0, 12, 0, 56)
Chroma.BackgroundColor3 = Color3.fromRGB(255, 0, 100)
Chroma.BorderSizePixel  = 0
Chroma.ZIndex           = 1
Chroma.Parent           = SG
Instance.new("UICorner", Chroma).CornerRadius = UDim.new(0, CORNER + 2)

local CG = Instance.new("UIGradient")
CG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,    Color3.fromRGB(255, 0,   110)),
    ColorSequenceKeypoint.new(0.16, Color3.fromRGB(255, 100, 0)),
    ColorSequenceKeypoint.new(0.33, Color3.fromRGB(220, 230, 0)),
    ColorSequenceKeypoint.new(0.5,  Color3.fromRGB(0,   210, 100)),
    ColorSequenceKeypoint.new(0.66, Color3.fromRGB(0,   170, 255)),
    ColorSequenceKeypoint.new(0.83, Color3.fromRGB(120, 0,   255)),
    ColorSequenceKeypoint.new(1,    Color3.fromRGB(255, 0,   110)),
})
CG.Parent = Chroma

-- ══════════════════════════
--  MAIN FRAME
-- ══════════════════════════
local Main = Instance.new("Frame")
Main.Name             = "Main"
Main.Size             = UDim2.new(1, -4, 1, -4)
Main.Position         = UDim2.new(0, 2, 0, 2)
Main.BackgroundColor3 = Color3.fromRGB(10, 10, 16)
Main.BorderSizePixel  = 0
Main.ClipsDescendants = true
Main.ZIndex           = 2
Main.Parent           = Chroma
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, CORNER)

local MG = Instance.new("UIGradient")
MG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(18, 18, 28)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(8,  8,  13)),
})
MG.Rotation = 145
MG.Parent = Main

-- ══════════════════════════
--  TITLE BAR
-- ══════════════════════════
local Title = Instance.new("Frame")
Title.Name             = "Title"
Title.Size             = UDim2.new(1, 0, 0, TH)
Title.BackgroundColor3 = Color3.fromRGB(15, 15, 24)
Title.BorderSizePixel  = 0
Title.ZIndex           = 3
Title.Parent           = Main
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, CORNER)

-- Square off bottom of title
local TSq = Instance.new("Frame")
TSq.Size             = UDim2.new(1, 0, 0.5, 0)
TSq.Position         = UDim2.new(0, 0, 0.5, 0)
TSq.BackgroundColor3 = Color3.fromRGB(15, 15, 24)
TSq.BorderSizePixel  = 0
TSq.ZIndex           = 3
TSq.Parent           = Title

-- Icon
local Icon = Instance.new("TextLabel")
Icon.Size              = UDim2.new(0, 22, 1, 0)
Icon.Position          = UDim2.new(0, 8, 0, 0)
Icon.BackgroundTransparency = 1
Icon.Font              = Enum.Font.GothamBold
Icon.Text              = "⚡"
Icon.TextColor3        = Color3.fromRGB(255, 210, 40)
Icon.TextSize          = FS + 1
Icon.ZIndex            = 4
Icon.Parent            = Title

-- Title text
local TitleLbl = Instance.new("TextLabel")
TitleLbl.Size              = UDim2.new(1, -90, 1, 0)
TitleLbl.Position          = UDim2.new(0, 32, 0, 0)
TitleLbl.BackgroundTransparency = 1
TitleLbl.Font              = Enum.Font.GothamBold
TitleLbl.Text              = "PHANTOM"
TitleLbl.TextColor3        = Color3.fromRGB(240, 240, 255)
TitleLbl.TextSize          = FS
TitleLbl.TextXAlignment    = Enum.TextXAlignment.Left
TitleLbl.ZIndex            = 4
TitleLbl.Parent            = Title

-- Collapse button
local ColBtn = Instance.new("TextButton")
ColBtn.Size             = UDim2.new(0, isMobile and 36 or 28, 0, isMobile and 28 or 22)
ColBtn.Position         = UDim2.new(1, -(isMobile and 40 or 32), 0.5, -(isMobile and 14 or 11))
ColBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 40)
ColBtn.Font             = Enum.Font.GothamBold
ColBtn.Text             = "▼"
ColBtn.TextColor3       = Color3.fromRGB(140, 140, 200)
ColBtn.TextSize         = 10
ColBtn.BorderSizePixel  = 0
ColBtn.ZIndex           = 5
ColBtn.Parent           = Title
Instance.new("UICorner", ColBtn).CornerRadius = UDim.new(0, 6)

-- Thin separator
local Sep = Instance.new("Frame")
Sep.Size             = UDim2.new(1, -16, 0, 1)
Sep.Position         = UDim2.new(0, 8, 0, TH)
Sep.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
Sep.BorderSizePixel  = 0
Sep.ZIndex           = 3
Sep.Parent           = Main

-- ══════════════════════════
--  CONTENT FRAME
-- ══════════════════════════
local Content = Instance.new("Frame")
Content.Name             = "Content"
Content.Size             = UDim2.new(1, 0, 1, -TH - 1)
Content.Position         = UDim2.new(0, 0, 0, TH + 1)
Content.BackgroundTransparency = 1
Content.ZIndex           = 3
Content.Parent           = Main

-- ══════════════════════════
--  HELPER: create button
-- ══════════════════════════
local function Btn(name, text, y, bg, parent)
    local b = Instance.new("TextButton")
    b.Name             = name
    b.Size             = UDim2.new(1, -PAD * 2, 0, BH)
    b.Position         = UDim2.new(0, PAD, 0, y)
    b.BackgroundColor3 = bg
    b.BorderSizePixel  = 0
    b.Font             = Enum.Font.GothamBold
    b.Text             = text
    b.TextColor3       = Color3.fromRGB(255, 255, 255)
    b.TextSize         = FS
    b.ZIndex           = 4
    b.Parent           = parent or Content
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)

    b.MouseButton1Down:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.07), {
            Size = UDim2.new(1, -PAD * 2 - 4, 0, BH - 3)
        }):Play()
    end)
    b.MouseButton1Up:Connect(function()
        TweenService:Create(b, TweenInfo.new(0.1), {
            Size = UDim2.new(1, -PAD * 2, 0, BH)
        }):Play()
    end)
    return b
end

-- ══════════════════════════
--  BUTTON ROWS
-- ══════════════════════════
local Y1 = PAD
local Y2 = Y1 + BH + PAD
local Y3 = Y2 + BH + PAD

local OFF_C = Color3.fromRGB(28, 28, 44)
local ON_C  = Color3.fromRGB(0, 170, 80)
local SEL_C = Color3.fromRGB(20, 70, 160)
local SAC_C = Color3.fromRGB(160, 65, 0)

-- Toggle
local TogBtn = Btn("Toggle", "● OFF", Y1, OFF_C)

-- Dot
local Dot = Instance.new("Frame")
Dot.Size             = UDim2.new(0, 8, 0, 8)
Dot.Position         = UDim2.new(0, 12, 0.5, -4)
Dot.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
Dot.BorderSizePixel  = 0
Dot.ZIndex           = 5
Dot.Parent           = TogBtn
Instance.new("UICorner", Dot).CornerRadius = UDim.new(1, 0)

-- Select
local SelBtn = Btn("Select", "🎯  SET TARGET", Y2, SEL_C)

-- Info label
local InfoLbl = Instance.new("TextLabel")
InfoLbl.Size              = UDim2.new(1, -PAD * 2, 0, 16)
InfoLbl.Position          = UDim2.new(0, PAD, 0, Y2 + BH + 4)
InfoLbl.BackgroundTransparency = 1
InfoLbl.Font              = Enum.Font.Gotham
InfoLbl.Text              = "No target set"
InfoLbl.TextColor3        = Color3.fromRGB(80, 80, 120)
InfoLbl.TextSize          = 10
InfoLbl.ZIndex            = 4
InfoLbl.Parent            = Content

-- CPS row
local CpsY = Y3 + 20
local CpsBox = Instance.new("Frame")
CpsBox.Size             = UDim2.new(1, -PAD * 2, 0, BH)
CpsBox.Position         = UDim2.new(0, PAD, 0, CpsY)
CpsBox.BackgroundColor3 = Color3.fromRGB(18, 18, 30)
CpsBox.BorderSizePixel  = 0
CpsBox.ZIndex           = 4
CpsBox.Parent           = Content
Instance.new("UICorner", CpsBox).CornerRadius = UDim.new(0, 10)

local CpsLbl = Instance.new("TextLabel")
CpsLbl.Size              = UDim2.new(0, 80, 1, 0)
CpsLbl.Position          = UDim2.new(0, 10, 0, 0)
CpsLbl.BackgroundTransparency = 1
CpsLbl.Font              = Enum.Font.GothamBold
CpsLbl.Text              = "CPS AMOUNT"
CpsLbl.TextColor3        = Color3.fromRGB(160, 160, 220)
CpsLbl.TextSize          = 9
CpsLbl.TextXAlignment    = Enum.TextXAlignment.Left
CpsLbl.ZIndex            = 5
CpsLbl.Parent            = CpsBox

local BSZ = isMobile and 34 or 28

local MinBtn = Instance.new("TextButton")
MinBtn.Size             = UDim2.new(0, BSZ, 0, BSZ)
MinBtn.Position         = UDim2.new(1, -(BSZ * 2 + 12), 0.5, -BSZ / 2)
MinBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 58)
MinBtn.Font             = Enum.Font.GothamBold
MinBtn.Text             = "−"
MinBtn.TextColor3       = Color3.fromRGB(220, 220, 255)
MinBtn.TextSize         = 16
MinBtn.BorderSizePixel  = 0
MinBtn.ZIndex           = 5
MinBtn.Parent           = CpsBox
Instance.new("UICorner", MinBtn).CornerRadius = UDim.new(0, 7)

local CpsVal = Instance.new("TextLabel")
CpsVal.Size              = UDim2.new(0, BSZ, 1, 0)
CpsVal.Position          = UDim2.new(1, -(BSZ + 6), 0, 0)
CpsVal.BackgroundTransparency = 1
CpsVal.Font              = Enum.Font.GothamBold
CpsVal.Text              = tostring(cps)
CpsVal.TextColor3        = Color3.fromRGB(255, 255, 255)
CpsVal.TextSize          = FS + 1
CpsVal.ZIndex            = 5
CpsVal.Parent            = CpsBox

local PlusBtn = Instance.new("TextButton")
PlusBtn.Size             = UDim2.new(0, BSZ, 0, BSZ)
PlusBtn.Position         = UDim2.new(1, -(BSZ + 6), 0.5, -BSZ / 2)
PlusBtn.BackgroundColor3 = Color3.fromRGB(35, 35, 58)
PlusBtn.Font             = Enum.Font.GothamBold
PlusBtn.Text             = "+"
PlusBtn.TextColor3       = Color3.fromRGB(220, 220, 255)
PlusBtn.TextSize         = 16
PlusBtn.BorderSizePixel  = 0
PlusBtn.ZIndex           = 5
PlusBtn.Parent           = CpsBox
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 7)

-- ══════════════════════════
--  COLLAPSE
-- ══════════════════════════
local function setCollapsed(state)
    collapsed = state
    local newH = state and (TH + 4) or (FULL_H + 4)
    TweenService:Create(Chroma, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
        Size = UDim2.new(0, W + 4, 0, newH)
    }):Play()
    TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quart), {
        Size = UDim2.new(1, -4, 0, newH - 4)
    }):Play()
    ColBtn.Text = state and "▲" or "▼"
    TweenService:Create(Content, TweenInfo.new(0.12), {
        GroupTransparency = state and 1 or 0
    }):Play()
end

ColBtn.MouseButton1Click:Connect(function()
    setCollapsed(not collapsed)
end)

-- ══════════════════════════
--  DRAG
-- ══════════════════════════
local dragging, dStart, dPos

Title.InputBegan:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dStart   = inp.Position
        dPos     = Chroma.Position
    end
end)

UserInputService.InputChanged:Connect(function(inp)
    if dragging and (
        inp.UserInputType == Enum.UserInputType.MouseMovement or
        inp.UserInputType == Enum.UserInputType.Touch
    ) then
        local d = inp.Position - dStart
        Chroma.Position = UDim2.new(
            dPos.X.Scale, dPos.X.Offset + d.X,
            dPos.Y.Scale, dPos.Y.Offset + d.Y
        )
    end
end)

UserInputService.InputEnded:Connect(function(inp)
    if inp.UserInputType == Enum.UserInputType.MouseButton1
    or inp.UserInputType == Enum.UserInputType.Touch then
        dragging = false
    end
end)

-- ══════════════════════════
--  TOGGLE
-- ══════════════════════════
TogBtn.MouseButton1Click:Connect(function()
    enabled = not enabled
    if enabled then
        TogBtn.Text          = "● ON"
        Dot.BackgroundColor3 = Color3.fromRGB(0, 210, 90)
        TweenService:Create(TogBtn, TweenInfo.new(0.18), {BackgroundColor3 = ON_C}):Play()
    else
        TogBtn.Text          = "● OFF"
        Dot.BackgroundColor3 = Color3.fromRGB(160, 50, 50)
        TweenService:Create(TogBtn, TweenInfo.new(0.18), {BackgroundColor3 = OFF_C}):Play()
    end
    lastT = tick()
    accum = 0
end)

-- ══════════════════════════
--  SELECT TARGET
--  Works on ANY GUI element,
--  ScreenGui, menus, buttons,
--  world-space — everything.
-- ══════════════════════════
SelBtn.MouseButton1Click:Connect(function()
    if selectMode then return end
    selectMode = true
    SelBtn.Text = "🎯  TAP TO SET..."
    TweenService:Create(SelBtn, TweenInfo.new(0.15), {BackgroundColor3 = SAC_C}):Play()

    if selectConn then selectConn:Disconnect() end
    task.wait(0.12)  -- prevent self-capture

    selectConn = UserInputService.InputBegan:Connect(function(inp)
        local isClick = inp.UserInputType == Enum.UserInputType.MouseButton1
        local isTouch = inp.UserInputType == Enum.UserInputType.Touch
        if not (isClick or isTouch) then return end

        -- Get raw screen position — works regardless of what's under the cursor
        local pos = UserInputService:GetMouseLocation()

        -- Only ignore if clicking on OUR own UI chrome
        local cp = Chroma.AbsolutePosition
        local cs = Chroma.AbsoluteSize
        local onSelf = pos.X >= cp.X and pos.X <= cp.X + cs.X
                   and pos.Y >= cp.Y and pos.Y <= cp.Y + cs.Y
        if onSelf then return end

        target     = Vector2.new(pos.X, pos.Y)
        selectMode = false
        SelBtn.Text = "🎯  SET TARGET"
        TweenService:Create(SelBtn, TweenInfo.new(0.15), {BackgroundColor3 = SEL_C}):Play()
        InfoLbl.Text      = string.format("(%d, %d)", math.floor(pos.X), math.floor(pos.Y))
        InfoLbl.TextColor3 = Color3.fromRGB(0, 190, 110)
        selectConn:Disconnect()
        selectConn = nil
    end)
end)

-- ══════════════════════════
--  CPS CONTROLS
-- ══════════════════════════
PlusBtn.MouseButton1Click:Connect(function()
    cps = math.min(cps + 1, MAX_CPS)
    CpsVal.Text = tostring(cps)
end)

MinBtn.MouseButton1Click:Connect(function()
    cps = math.max(cps - 1, 1)
    CpsVal.Text = tostring(cps)
end)

local function holdRamp(btn, delta)
    local held = false
    btn.MouseButton1Down:Connect(function()
        held = true
        task.delay(0.3, function()
            while held do
                cps = math.clamp(cps + delta, 1, MAX_CPS)
                CpsVal.Text = tostring(cps)
                task.wait(0.035)
            end
        end)
    end)
    btn.MouseButton1Up:Connect(function()  held = false end)
    btn.MouseLeave:Connect(function()      held = false end)
end
holdRamp(PlusBtn,  1)
holdRamp(MinBtn,  -1)

-- ══════════════════════════
--  CHROMA + CLICK ENGINE
-- ══════════════════════════
local angle = 0

RunService.Heartbeat:Connect(function(dt)
    -- Chroma spin
    angle = (angle + dt * 75) % 360
    CG.Rotation = angle

    -- Clamp runaway accumulator
    if accum > 4 then accum = 4 end

    if not enabled or not target then
        lastT = tick()
        accum = 0
        return
    end

    local now   = tick()
    local delta = now - lastT
    lastT       = now
    accum       = accum + delta * cps

    while accum >= 1 do
        accum = accum - 1

        -- Move to target position (Delta global)
        if mousemoveabs then
            pcall(mousemoveabs, target.X, target.Y)
        end

        -- Delta click functions — work on any screen position
        -- including game GUIs, menus, ScreenGuis, etc.
        if mouse1click then
            pcall(mouse1click)
        elseif mouse1press and mouse1release then
            pcall(mouse1press)
            pcall(mouse1release)
        end
    end
end)

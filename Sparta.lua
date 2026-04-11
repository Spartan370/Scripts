local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local StarterGui = game:GetService("StarterGui")
local Camera = Workspace.CurrentCamera

local lp = Players.LocalPlayer
local mouse = lp:GetMouse()
local char = lp.Character or lp.CharacterAdded:Wait()
local hrp = char:WaitForChild("HumanoidRootPart")
local hum = char:WaitForChild("Humanoid")

local VALID_KEYS = { ["37"] = true, ["CM"] = true, ["217"] = true }

local cfg = {
	SilentAim = false,
	AimLock = false,
	TeamCheck = true,
	FOVSize = 120,
	Smoothness = 50,
	HitboxExpand = false,
	HitboxSize = 6,
	HeadExpand = false,
	HeadSize = 4,
	AutoClick = false,
	CPS = 12,
	RandomDelay = false,
	ClickOnTouch = true,
	SpeedHack = false,
	WalkSpeed = 32,
	SpeedBypass = false,
	Fly = false,
	FlySpeed = 50,
	Noclip = false,
	PlayerESP = false,
	BoxESP = false,
	NameESP = true,
	HealthBar = true,
	Tracers = false,
	ESPDistance = 2000,
	AntiAFK = true,
	InfiniteJump = false,
	JumpPower = 100,
	NoFallDamage = true,
	Fullbright = false,
	GodMode = false,
}

local gui = Instance.new("ScreenGui")
gui.Name = "SpartaHub"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true

pcall(function()
	if syn then
		syn.protect_gui(gui)
	end
end)

pcall(function()
	gui.Parent = CoreGui
end)
if not gui.Parent then
	gui.Parent = lp.PlayerGui
end

local function color3(r, g, b)
	return Color3.fromRGB(r, g, b)
end

local function newTween(obj, props, t, style, dir)
	return TweenService:Create(obj, TweenInfo.new(t or 0.15, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
end

local BG_DARK = color3(18, 18, 31)
local BG_SIDEBAR = color3(14, 14, 20)
local BG_CARD = color3(25, 25, 36)
local BG_CARD2 = color3(22, 22, 32)
local TEXT_MAIN = color3(220, 220, 230)
local TEXT_MUTED = color3(100, 100, 115)
local TEXT_SECTION = color3(65, 65, 75)
local BORDER = color3(40, 40, 55)
local ACCENT = color3(59, 130, 246)
local GREEN = color3(40, 200, 64)
local RED_DOT = color3(255, 95, 87)
local ORANGE_DOT = color3(254, 188, 46)
local GREEN_DOT = color3(40, 200, 64)

local CHROMA_COLORS = {
	color3(255, 0, 0), color3(255, 119, 0), color3(255, 255, 0),
	color3(0, 255, 0), color3(0, 119, 255), color3(139, 0, 255), color3(255, 0, 255)
}
local chromaIdx = 1
local chromaTimer = 0

local TABS = {
	{ id = "aim",       label = "Aim Assist", color = color3(239, 68, 68) },
	{ id = "hitbox",    label = "Hitbox",     color = color3(249, 115, 22) },
	{ id = "autoclick", label = "Auto Click", color = color3(234, 179, 8) },
	{ id = "speed",     label = "Speed",      color = color3(34, 197, 94) },
	{ id = "fly",       label = "Fly",        color = color3(59, 130, 246) },
	{ id = "esp",       label = "ESP",        color = color3(168, 85, 247) },
	{ id = "misc",      label = "Misc",       color = color3(236, 72, 153) },
}

local activeTab = "aim"
local guiOpen = true
local sidebarOpen = true

local function makeFrame(parent, props)
	local f = Instance.new("Frame")
	f.BorderSizePixel = 0
	f.BackgroundColor3 = BG_DARK
	for k, v in pairs(props or {}) do f[k] = v end
	f.Parent = parent
	return f
end

local function makeLabel(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.TextColor3 = TEXT_MAIN
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 11
	l.BorderSizePixel = 0
	for k, v in pairs(props or {}) do l[k] = v end
	l.Parent = parent
	return l
end

local function makeButton(parent, props)
	local b = Instance.new("TextButton")
	b.BackgroundTransparency = 1
	b.TextColor3 = TEXT_MAIN
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 11
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	for k, v in pairs(props or {}) do b[k] = v end
	b.Parent = parent
	return b
end

local function makeToggle(parent, pos, size, defaultOn, onChange)
	local track = makeFrame(parent, {
		Position = pos,
		Size = size or UDim2.new(0, 44, 0, 24),
		BackgroundColor3 = defaultOn and color3(59, 130, 246) or color3(45, 45, 60),
	})
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local thumb = makeFrame(track, {
		Size = UDim2.new(0, 18, 0, 18),
		Position = defaultOn and UDim2.new(0, 22, 0, 3) or UDim2.new(0, 3, 0, 3),
		BackgroundColor3 = color3(255, 255, 255),
	})
	Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

	local state = defaultOn or false
	local btn = makeButton(track, {
		Size = UDim2.new(1, 0, 1, 0),
		Position = UDim2.new(0, 0, 0, 0),
		Text = "",
		BackgroundTransparency = 1,
	})

	btn.MouseButton1Click:Connect(function()
		state = not state
		if state then
			newTween(track, { BackgroundColor3 = color3(59, 130, 246) }):Play()
			newTween(thumb, { Position = UDim2.new(0, 22, 0, 3) }):Play()
		else
			newTween(track, { BackgroundColor3 = color3(45, 45, 60) }):Play()
			newTween(thumb, { Position = UDim2.new(0, 3, 0, 3) }):Play()
		end
		if onChange then onChange(state) end
	end)

	return track, function() return state end
end

local function makeSlider(parent, pos, min, max, default, suffix, onChange)
	local container = makeFrame(parent, {
		Position = pos,
		Size = UDim2.new(1, -24, 0, 28),
		BackgroundTransparency = 1,
	})

	local track = makeFrame(container, {
		Position = UDim2.new(0, 0, 0.5, -2),
		Size = UDim2.new(1, -50, 0, 4),
		BackgroundColor3 = color3(50, 50, 65),
	})
	Instance.new("UICorner", track).CornerRadius = UDim.new(1, 0)

	local fill = makeFrame(track, {
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new((default - min) / (max - min), 0, 1, 0),
		BackgroundColor3 = color3(59, 130, 246),
	})
	Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

	local thumb = makeFrame(track, {
		Size = UDim2.new(0, 16, 0, 16),
		Position = UDim2.new((default - min) / (max - min), -8, 0.5, -8),
		BackgroundColor3 = color3(255, 255, 255),
	})
	Instance.new("UICorner", thumb).CornerRadius = UDim.new(1, 0)

	local valLabel = makeLabel(container, {
		Position = UDim2.new(1, -48, 0, 0),
		Size = UDim2.new(0, 48, 1, 0),
		Text = tostring(default) .. (suffix or ""),
		TextColor3 = color3(59, 130, 246),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local value = default
	local dragging = false

	local function update(x)
		local trackPos = track.AbsolutePosition.X
		local trackSize = track.AbsoluteSize.X
		local pct = math.clamp((x - trackPos) / trackSize, 0, 1)
		value = math.round(min + pct * (max - min))
		fill.Size = UDim2.new(pct, 0, 1, 0)
		thumb.Position = UDim2.new(pct, -8, 0.5, -8)
		valLabel.Text = tostring(value) .. (suffix or "")
		if onChange then onChange(value) end
	end

	track.InputBegan:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			update(inp.Position.X)
		end
	end)

	UserInputService.InputChanged:Connect(function(inp)
		if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
			update(inp.Position.X)
		end
	end)

	UserInputService.InputEnded:Connect(function(inp)
		if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return container
end

local function makeSectionLabel(parent, yOff, text)
	local row = makeFrame(parent, {
		Position = UDim2.new(0, 8, 0, yOff),
		Size = UDim2.new(1, -16, 0, 18),
		BackgroundTransparency = 1,
	})
	makeLabel(row, {
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(0, 0, 1, 0),
		AutomaticSize = Enum.AutomaticSize.X,
		Text = string.upper(text),
		TextColor3 = TEXT_SECTION,
		Font = Enum.Font.GothamBold,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local line = makeFrame(row, {
		Position = UDim2.new(0, string.len(text) * 6 + 4, 0.5, 0),
		Size = UDim2.new(1, -(string.len(text) * 6 + 4), 0, 1),
		BackgroundColor3 = color3(40, 40, 55),
	})
	return row
end

local function makeCard(parent, yOff, title, desc, cardType, accentCol, togDefault, slMin, slMax, slDef, slSuf, onChange)
	local cardH = (cardType == "slider") and 68 or (desc and 50 or 40)
	local card = makeFrame(parent, {
		Position = UDim2.new(0, 4, 0, yOff),
		Size = UDim2.new(1, -8, 0, cardH),
		BackgroundColor3 = BG_CARD,
	})
	Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

	if cardType == "toggle" and accentCol then
		local bar = makeFrame(card, {
			Position = UDim2.new(0, 10, 0.2, 0),
			Size = UDim2.new(0, 3, 0.6, 0),
			BackgroundColor3 = accentCol,
		})
		Instance.new("UICorner", bar).CornerRadius = UDim.new(1, 0)
	end

	local titleOff = (cardType == "toggle" and accentCol) and 20 or 12
	makeLabel(card, {
		Position = UDim2.new(0, titleOff, 0, desc and 8 or 0),
		Size = UDim2.new(1, -70, desc and 0 or 1, desc and 0 or 0),
		AutomaticSize = desc and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		Text = title,
		Font = Enum.Font.GothamSemibold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	if desc then
		makeLabel(card, {
			Position = UDim2.new(0, titleOff, 0, 24),
			Size = UDim2.new(1, -70, 0, 16),
			Text = desc,
			TextColor3 = TEXT_MUTED,
			Font = Enum.Font.Gotham,
			TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	if cardType == "toggle" then
		local tog = makeToggle(card, UDim2.new(1, -52, 0.5, -12), UDim2.new(0, 44, 0, 24), togDefault, onChange)
	elseif cardType == "slider" then
		makeSlider(card, UDim2.new(0, 10, 0, 38), slMin, slMax, slDef, slSuf, onChange)
	end

	return card, cardH
end

local ROOT = makeFrame(gui, {
	Position = UDim2.new(0, 20, 0, 55),
	Size = UDim2.new(0, 480, 0, 530),
	BackgroundColor3 = BG_DARK,
	Visible = true,
})
Instance.new("UICorner", ROOT).CornerRadius = UDim.new(0, 16)

local rootStroke = Instance.new("UIStroke", ROOT)
rootStroke.Thickness = 1.5
rootStroke.Color = color3(255, 0, 0)

local TITLEBAR = makeFrame(ROOT, {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 0, 34),
	BackgroundColor3 = color3(10, 10, 16),
})
Instance.new("UICorner", TITLEBAR).CornerRadius = UDim.new(0, 16)

local titlebarBottom = makeFrame(ROOT, {
	Position = UDim2.new(0, 0, 0, 18),
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundColor3 = color3(10, 10, 16),
})

local titleStroke = Instance.new("UIStroke", TITLEBAR)
titleStroke.Thickness = 0
titleStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border

local dotRed = makeFrame(TITLEBAR, {
	Position = UDim2.new(0, 16, 0.5, -6),
	Size = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = RED_DOT,
})
Instance.new("UICorner", dotRed).CornerRadius = UDim.new(1, 0)

local dotOrange = makeFrame(TITLEBAR, {
	Position = UDim2.new(0, 34, 0.5, -6),
	Size = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = ORANGE_DOT,
})
Instance.new("UICorner", dotOrange).CornerRadius = UDim.new(1, 0)

local dotGreen = makeFrame(TITLEBAR, {
	Position = UDim2.new(0, 52, 0.5, -6),
	Size = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = GREEN_DOT,
})
Instance.new("UICorner", dotGreen).CornerRadius = UDim.new(1, 0)

local dotRedBtn = makeButton(dotRed, { Size = UDim2.new(1, 0, 1, 0), Text = "" })
local dotOrangeBtn = makeButton(dotOrange, { Size = UDim2.new(1, 0, 1, 0), Text = "" })
local dotGreenBtn = makeButton(dotGreen, { Size = UDim2.new(1, 0, 1, 0), Text = "" })

local chromaTitleLabel = makeLabel(TITLEBAR, {
	Position = UDim2.new(0, 70, 0, 0),
	Size = UDim2.new(1, -140, 1, 0),
	Text = "Sparta",
	Font = Enum.Font.GothamBold,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Center,
})

local sepLabel1 = makeLabel(TITLEBAR, {
	Position = UDim2.new(0.5, -30, 0, 0),
	Size = UDim2.new(0, 10, 1, 0),
	Text = "|",
	TextColor3 = color3(60, 60, 75),
	Font = Enum.Font.Gotham,
	TextSize = 11,
})

local tabTitleLabel = makeLabel(TITLEBAR, {
	Position = UDim2.new(0.5, -20, 0, 0),
	Size = UDim2.new(0, 80, 1, 0),
	Text = "Aim Assist",
	TextColor3 = color3(130, 130, 155),
	Font = Enum.Font.GothamMedium,
	TextSize = 11,
})

local versionLabel = makeLabel(TITLEBAR, {
	Position = UDim2.new(1, -52, 0, 0),
	Size = UDim2.new(0, 50, 1, 0),
	Text = "v1.0.0",
	TextColor3 = color3(70, 70, 90),
	Font = Enum.Font.Code,
	TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Right,
})

local BODY = makeFrame(ROOT, {
	Position = UDim2.new(0, 0, 0, 34),
	Size = UDim2.new(1, 0, 1, -34),
	BackgroundTransparency = 1,
})

local SIDEBAR = makeFrame(BODY, {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(0, 148, 1, 0),
	BackgroundColor3 = BG_SIDEBAR,
})
Instance.new("UICorner", SIDEBAR).CornerRadius = UDim.new(0, 16)

local sidebarTopFill = makeFrame(SIDEBAR, {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 0, 16),
	BackgroundColor3 = BG_SIDEBAR,
})

local sidebarRightFill = makeFrame(SIDEBAR, {
	Position = UDim2.new(1, -16, 0, 0),
	Size = UDim2.new(0, 16, 1, 0),
	BackgroundColor3 = BG_SIDEBAR,
})

local sidebarBorder = makeFrame(SIDEBAR, {
	Position = UDim2.new(1, -1, 0, 0),
	Size = UDim2.new(0, 1, 1, 0),
	BackgroundColor3 = color3(30, 30, 45),
})

local searchBox = makeFrame(SIDEBAR, {
	Position = UDim2.new(0, 6, 0, 6),
	Size = UDim2.new(1, -12, 0, 26),
	BackgroundColor3 = color3(22, 22, 32),
})
Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 7)
makeLabel(searchBox, {
	Position = UDim2.new(0, 8, 0, 0),
	Size = UDim2.new(1, -8, 1, 0),
	Text = "Search",
	TextColor3 = color3(60, 60, 75),
	Font = Enum.Font.Gotham,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local aboutBtn = makeButton(SIDEBAR, {
	Position = UDim2.new(0, 4, 0, 36),
	Size = UDim2.new(1, -8, 0, 28),
	Text = "",
	BackgroundColor3 = color3(22, 22, 32),
	BackgroundTransparency = 1,
})
Instance.new("UICorner", aboutBtn).CornerRadius = UDim.new(0, 7)

local aboutIcon = makeFrame(aboutBtn, {
	Position = UDim2.new(0, 6, 0.5, -7),
	Size = UDim2.new(0, 14, 0, 14),
	BackgroundColor3 = color3(35, 35, 50),
})
Instance.new("UICorner", aboutIcon).CornerRadius = UDim.new(0, 4)
makeLabel(aboutBtn, {
	Position = UDim2.new(0, 26, 0, 0),
	Size = UDim2.new(1, -26, 1, 0),
	Text = "About Sparta",
	TextColor3 = color3(100, 100, 120),
	Font = Enum.Font.GothamMedium,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
})

makeLabel(SIDEBAR, {
	Position = UDim2.new(0, 10, 0, 70),
	Size = UDim2.new(1, -10, 0, 16),
	Text = "ELEMENTS",
	TextColor3 = color3(55, 55, 70),
	Font = Enum.Font.GothamBold,
	TextSize = 9,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local tabButtons = {}
local yOff = 90

for i, tab in ipairs(TABS) do
	local tabBtn = makeButton(SIDEBAR, {
		Position = UDim2.new(0, 4, 0, yOff),
		Size = UDim2.new(1, -8, 0, 28),
		Text = "",
		BackgroundColor3 = color3(35, 35, 52),
		BackgroundTransparency = activeTab == tab.id and 0.6 or 1,
	})
	Instance.new("UICorner", tabBtn).CornerRadius = UDim.new(0, 7)

	local dot = makeFrame(tabBtn, {
		Position = UDim2.new(0, 7, 0.5, -6),
		Size = UDim2.new(0, 12, 0, 12),
		BackgroundColor3 = tab.color,
	})
	Instance.new("UICorner", dot).CornerRadius = UDim.new(0, 3)

	makeLabel(tabBtn, {
		Position = UDim2.new(0, 25, 0, 0),
		Size = UDim2.new(1, -25, 1, 0),
		Text = tab.label,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = activeTab == tab.id and TEXT_MAIN or color3(100, 100, 120),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	tabButtons[tab.id] = tabBtn
	yOff = yOff + 30
end

local configBtn = makeButton(SIDEBAR, {
	Position = UDim2.new(0, 6, 1, -32),
	Size = UDim2.new(1, -12, 0, 26),
	Text = "Config Usage  ▾",
	Font = Enum.Font.Gotham,
	TextSize = 9,
	TextColor3 = color3(70, 70, 90),
	BackgroundColor3 = color3(22, 22, 32),
})
Instance.new("UICorner", configBtn).CornerRadius = UDim.new(0, 7)

local CONTENT = makeFrame(BODY, {
	Position = UDim2.new(0, 148, 0, 0),
	Size = UDim2.new(1, -148, 1, 0),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
})

local SCROLL = Instance.new("ScrollingFrame")
SCROLL.Position = UDim2.new(0, 0, 0, 0)
SCROLL.Size = UDim2.new(1, 0, 1, 0)
SCROLL.BackgroundTransparency = 1
SCROLL.BorderSizePixel = 0
SCROLL.ScrollBarThickness = 3
SCROLL.ScrollBarImageColor3 = color3(50, 50, 70)
SCROLL.CanvasSize = UDim2.new(0, 0, 0, 0)
SCROLL.Parent = CONTENT

local contentPages = {}

local function buildPage(tabId)
	local page = makeFrame(SCROLL, {
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, 0),
		BackgroundTransparency = 1,
		Visible = tabId == activeTab,
	})
	page.AutomaticSize = Enum.AutomaticSize.Y
	return page
end

local function switchTab(tabId)
	for id, btn in pairs(tabButtons) do
		local isActive = id == tabId
		newTween(btn, { BackgroundTransparency = isActive and 0.6 or 1 }):Play()
		local lbl = btn:FindFirstChildWhichIsA("TextLabel")
		if lbl then
			lbl.TextColor3 = isActive and TEXT_MAIN or color3(100, 100, 120)
		end
	end
	for id, page in pairs(contentPages) do
		page.Visible = id == tabId
	end
	for _, tab in ipairs(TABS) do
		if tab.id == tabId then
			tabTitleLabel.Text = tab.label
			break
		end
	end
	activeTab = tabId
	SCROLL.CanvasPosition = Vector2.new(0, 0)
end

local function buildCards(page, cards)
	local y = 4
	local maxY = 4
	for _, c in ipairs(cards) do
		if c.type == "section" then
			local s = makeSectionLabel(page, y, c.title)
			s.Position = UDim2.new(0, 4, 0, y)
			y = y + 22
		elseif c.type == "note" then
			makeLabel(page, {
				Position = UDim2.new(0, 12, 0, y),
				Size = UDim2.new(1, -12, 0, 14),
				Text = c.text,
				TextColor3 = color3(70, 70, 90),
				Font = Enum.Font.Gotham,
				TextSize = 9,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			y = y + 18
		elseif c.type == "toggle" or c.type == "slider" then
			local card, h = makeCard(page, y, c.title, c.desc, c.type, c.accent, c.default, c.min, c.max, c.val, c.suf, c.cb)
			y = y + h + 6
		end
		maxY = y
	end
	SCROLL.CanvasSize = UDim2.new(0, 0, 0, maxY + 8)
	return maxY
end

local aimPage = buildPage("aim")
contentPages["aim"] = aimPage
buildCards(aimPage, {
	{ type = "section", title = "Aim Assist" },
	{ type = "toggle", title = "Silent Aim", desc = "Bullets bend toward nearest", accent = color3(239,68,68), default = false, cb = function(v) cfg.SilentAim = v end },
	{ type = "toggle", title = "Aim Lock", desc = "Lock onto nearest target", accent = color3(239,68,68), default = false, cb = function(v) cfg.AimLock = v end },
	{ type = "toggle", title = "Team Check", desc = "Ignore teammates", accent = color3(239,68,68), default = true, cb = function(v) cfg.TeamCheck = v end },
	{ type = "note", text = "Updates every 0.2s" },
	{ type = "slider", title = "FOV Size", min = 10, max = 360, val = 120, suf = "px", cb = function(v) cfg.FOVSize = v end },
	{ type = "slider", title = "Smoothness", min = 0, max = 100, val = 50, suf = "%", cb = function(v) cfg.Smoothness = v end },
})

local hitboxPage = buildPage("hitbox")
contentPages["hitbox"] = hitboxPage
buildCards(hitboxPage, {
	{ type = "section", title = "Hitbox" },
	{ type = "toggle", title = "Hitbox Expander", desc = "Inflate all player hitboxes", accent = color3(249,115,22), default = false, cb = function(v) cfg.HitboxExpand = v end },
	{ type = "slider", title = "Hitbox Size", min = 1, max = 20, val = 6, suf = " st", cb = function(v) cfg.HitboxSize = v end },
	{ type = "toggle", title = "Head Expand", accent = color3(249,115,22), default = false, cb = function(v) cfg.HeadExpand = v end },
	{ type = "slider", title = "Head Size", min = 1, max = 15, val = 4, suf = " st", cb = function(v) cfg.HeadSize = v end },
})

local autoPage = buildPage("autoclick")
contentPages["autoclick"] = autoPage
buildCards(autoPage, {
	{ type = "section", title = "Auto Click" },
	{ type = "toggle", title = "Auto Click", desc = "Left-click rapidly", accent = color3(234,179,8), default = false, cb = function(v) cfg.AutoClick = v end },
	{ type = "slider", title = "CPS", min = 1, max = 50, val = 12, suf = " cps", cb = function(v) cfg.CPS = v end },
	{ type = "toggle", title = "Randomize Delay", accent = color3(234,179,8), default = false, cb = function(v) cfg.RandomDelay = v end },
	{ type = "toggle", title = "Click on Touch", accent = color3(234,179,8), default = true, cb = function(v) cfg.ClickOnTouch = v end },
})

local speedPage = buildPage("speed")
contentPages["speed"] = speedPage
buildCards(speedPage, {
	{ type = "section", title = "Speed" },
	{ type = "toggle", title = "Speed Hack", accent = color3(34,197,94), default = false, cb = function(v) cfg.SpeedHack = v end },
	{ type = "slider", title = "Walk Speed", min = 16, max = 200, val = 32, suf = " ws", cb = function(v) cfg.WalkSpeed = v end },
	{ type = "toggle", title = "Speed Bypass", desc = "Bypass anti-cheat", accent = color3(34,197,94), default = false, cb = function(v) cfg.SpeedBypass = v end },
})

local flyPage = buildPage("fly")
contentPages["fly"] = flyPage
buildCards(flyPage, {
	{ type = "section", title = "Fly" },
	{ type = "toggle", title = "Fly", accent = color3(59,130,246), default = false, cb = function(v) cfg.Fly = v end },
	{ type = "slider", title = "Fly Speed", min = 1, max = 200, val = 50, suf = " sp", cb = function(v) cfg.FlySpeed = v end },
	{ type = "toggle", title = "Noclip", desc = "Fly through walls", accent = color3(59,130,246), default = false, cb = function(v) cfg.Noclip = v end },
	{ type = "section", title = "Controls" },
	{ type = "note", text = "Uses default Roblox mobile thumbstick" },
})

local espPage = buildPage("esp")
contentPages["esp"] = espPage
buildCards(espPage, {
	{ type = "section", title = "ESP / Visuals" },
	{ type = "toggle", title = "Player ESP", desc = "See through walls", accent = color3(168,85,247), default = false, cb = function(v) cfg.PlayerESP = v end },
	{ type = "toggle", title = "Box ESP", accent = color3(168,85,247), default = false, cb = function(v) cfg.BoxESP = v end },
	{ type = "toggle", title = "Name ESP", accent = color3(168,85,247), default = true, cb = function(v) cfg.NameESP = v end },
	{ type = "toggle", title = "Health Bar", accent = color3(168,85,247), default = true, cb = function(v) cfg.HealthBar = v end },
	{ type = "toggle", title = "Tracers", accent = color3(168,85,247), default = false, cb = function(v) cfg.Tracers = v end },
	{ type = "slider", title = "ESP Distance", min = 100, max = 5000, val = 2000, suf = " st", cb = function(v) cfg.ESPDistance = v end },
})

local miscPage = buildPage("misc")
contentPages["misc"] = miscPage
buildCards(miscPage, {
	{ type = "section", title = "Misc" },
	{ type = "toggle", title = "Anti AFK", accent = color3(236,72,153), default = true, cb = function(v) cfg.AntiAFK = v end },
	{ type = "toggle", title = "Infinite Jump", accent = color3(236,72,153), default = false, cb = function(v) cfg.InfiniteJump = v end },
	{ type = "slider", title = "Jump Power", min = 50, max = 500, val = 100, suf = " jp", cb = function(v) cfg.JumpPower = v end },
	{ type = "toggle", title = "No Fall Damage", accent = color3(236,72,153), default = true, cb = function(v) cfg.NoFallDamage = v end },
	{ type = "toggle", title = "Fullbright", accent = color3(236,72,153), default = false, cb = function(v) cfg.Fullbright = v end },
	{ type = "toggle", title = "God Mode", accent = color3(236,72,153), default = false, cb = function(v) cfg.GodMode = v end },
})

for id, btn in pairs(tabButtons) do
	local tabId = id
	btn.MouseButton1Click:Connect(function() switchTab(tabId) end)
end

local dragging = false
local dragStart = nil
local startPos = nil

TITLEBAR.InputBegan:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = inp.Position
		startPos = ROOT.Position
	end
end)

UserInputService.InputChanged:Connect(function(inp)
	if dragging and (inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch) then
		local delta = inp.Position - dragStart
		ROOT.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputEnded:Connect(function(inp)
	if inp.UserInputType == Enum.UserInputType.MouseButton1 or inp.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

dotRedBtn.MouseButton1Click:Connect(function()
	ROOT.Visible = false
	gui:Destroy()
end)

dotOrangeBtn.MouseButton1Click:Connect(function()
	BODY.Visible = false
	ROOT.Size = UDim2.new(0, 480, 0, 34)
end)

dotGreenBtn.MouseButton1Click:Connect(function()
	if sidebarOpen then
		sidebarOpen = false
		SIDEBAR.Visible = false
		CONTENT.Position = UDim2.new(0, 0, 0, 0)
		CONTENT.Size = UDim2.new(1, 0, 1, 0)
	else
		sidebarOpen = true
		SIDEBAR.Visible = true
		CONTENT.Position = UDim2.new(0, 148, 0, 0)
		CONTENT.Size = UDim2.new(1, -148, 1, 0)
	end
end)

local LOCK = makeFrame(gui, {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 1, 0),
	BackgroundColor3 = color3(8, 8, 15),
})

ROOT.Visible = false

local keyFrame = makeFrame(LOCK, {
	Position = UDim2.new(0.5, -160, 0.5, -130),
	Size = UDim2.new(0, 320, 0, 230),
	BackgroundColor3 = color3(28, 28, 34),
})
Instance.new("UICorner", keyFrame).CornerRadius = UDim.new(0, 14)

local keyTitleBar = makeFrame(keyFrame, {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 0, 36),
	BackgroundColor3 = color3(12, 12, 18),
})
Instance.new("UICorner", keyTitleBar).CornerRadius = UDim.new(0, 14)

local keyTitleFix = makeFrame(keyFrame, {
	Position = UDim2.new(0, 0, 0, 18),
	Size = UDim2.new(1, 0, 0, 18),
	BackgroundColor3 = color3(12, 12, 18),
})

local keyDotRed = makeFrame(keyTitleBar, {
	Position = UDim2.new(0, 14, 0.5, -6),
	Size = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = RED_DOT,
})
Instance.new("UICorner", keyDotRed).CornerRadius = UDim.new(1, 0)

local keyDotOrange = makeFrame(keyTitleBar, {
	Position = UDim2.new(0, 32, 0.5, -6),
	Size = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = ORANGE_DOT,
})
Instance.new("UICorner", keyDotOrange).CornerRadius = UDim.new(1, 0)

local keyDotGreen = makeFrame(keyTitleBar, {
	Position = UDim2.new(0, 50, 0.5, -6),
	Size = UDim2.new(0, 12, 0, 12),
	BackgroundColor3 = color3(40, 200, 64),
	BackgroundTransparency = 0.5,
})
Instance.new("UICorner", keyDotGreen).CornerRadius = UDim.new(1, 0)

makeLabel(keyTitleBar, {
	Position = UDim2.new(0, 68, 0, 0),
	Size = UDim2.new(1, -68, 1, 0),
	Text = "Sparta | Key System",
	TextColor3 = color3(100, 100, 120),
	Font = Enum.Font.GothamMedium,
	TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local lockIcon = makeFrame(keyFrame, {
	Position = UDim2.new(0.5, -24, 0, 46),
	Size = UDim2.new(0, 48, 0, 48),
	BackgroundColor3 = color3(35, 35, 48),
})
Instance.new("UICorner", lockIcon).CornerRadius = UDim.new(0, 12)

makeLabel(lockIcon, {
	Position = UDim2.new(0, 0, 0, 0),
	Size = UDim2.new(1, 0, 1, 0),
	Text = "🔒",
	Font = Enum.Font.Gotham,
	TextSize = 22,
})

makeLabel(keyFrame, {
	Position = UDim2.new(0, 0, 0, 100),
	Size = UDim2.new(1, 0, 0, 20),
	Text = "Enter Key",
	Font = Enum.Font.GothamSemibold,
	TextSize = 13,
	TextColor3 = color3(220, 220, 230),
})

makeLabel(keyFrame, {
	Position = UDim2.new(0, 0, 0, 118),
	Size = UDim2.new(1, 0, 0, 16),
	Text = "Enter one valid passcode",
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = color3(80, 80, 100),
})

local keyInput = Instance.new("TextBox")
keyInput.Position = UDim2.new(0, 16, 0, 142)
keyInput.Size = UDim2.new(1, -32, 0, 40)
keyInput.BackgroundColor3 = color3(35, 35, 50)
keyInput.TextColor3 = color3(220, 220, 230)
keyInput.Font = Enum.Font.Code
keyInput.TextSize = 14
keyInput.PlaceholderText = "Key..."
keyInput.PlaceholderColor3 = color3(70, 70, 90)
keyInput.Text = ""
keyInput.BorderSizePixel = 0
keyInput.ClearTextOnFocus = false
Instance.new("UICorner", keyInput).CornerRadius = UDim.new(0, 10)
keyInput.Parent = keyFrame

local keyError = makeLabel(keyFrame, {
	Position = UDim2.new(0, 0, 0, 183),
	Size = UDim2.new(1, 0, 0, 14),
	Text = "",
	TextColor3 = color3(255, 80, 80),
	Font = Enum.Font.GothamMedium,
	TextSize = 10,
})

local keySubmit = makeButton(keyFrame, {
	Position = UDim2.new(0, 16, 0, 192),
	Size = UDim2.new(1, -32, 0, 36),
	Text = "Submit",
	Font = Enum.Font.GothamSemibold,
	TextSize = 13,
	TextColor3 = color3(200, 200, 215),
	BackgroundColor3 = color3(35, 35, 50),
})
Instance.new("UICorner", keySubmit).CornerRadius = UDim.new(0, 10)

local keyMinimized = false

local function tryUnlock()
	local val = keyInput.Text:match("^%s*(.-)%s*$")
	if VALID_KEYS[val] or VALID_KEYS[val:upper()] then
		newTween(LOCK, { BackgroundTransparency = 1 }, 0.3):Play()
		task.delay(0.3, function()
			LOCK.Visible = false
			ROOT.Visible = true
		end)
	else
		keyError.Text = "Invalid key"
		newTween(keyFrame, { Position = UDim2.new(0.5, -168, 0.5, -130) }, 0.05):Play()
		task.delay(0.05, function()
			newTween(keyFrame, { Position = UDim2.new(0.5, -152, 0.5, -130) }, 0.05):Play()
			task.delay(0.05, function()
				newTween(keyFrame, { Position = UDim2.new(0.5, -160, 0.5, -130) }, 0.05):Play()
				task.delay(1, function() keyError.Text = "" end)
			end)
		end)
	end
end

keySubmit.MouseButton1Click:Connect(tryUnlock)

keyInput.FocusLost:Connect(function(enterPressed)
	if enterPressed then tryUnlock() end
end)

local keyDotRedBtn = makeButton(keyDotRed, { Size = UDim2.new(1, 0, 1, 0), Text = "" })
local keyDotOrangeBtn = makeButton(keyDotOrange, { Size = UDim2.new(1, 0, 1, 0), Text = "" })

keyDotRedBtn.MouseButton1Click:Connect(function()
	LOCK.Visible = false
	gui:Destroy()
end)

keyDotOrangeBtn.MouseButton1Click:Connect(function()
	if keyMinimized then
		keyMinimized = false
		keyFrame.Size = UDim2.new(0, 320, 0, 230)
		keyTitleFix.Visible = true
		lockIcon.Visible = true
		keyInput.Visible = true
		keySubmit.Visible = true
		keyError.Visible = true
	else
		keyMinimized = true
		keyFrame.Size = UDim2.new(0, 320, 0, 36)
		keyTitleFix.Visible = false
		lockIcon.Visible = false
		keyInput.Visible = false
		keySubmit.Visible = false
		keyError.Visible = false
	end
end)

RunService.Heartbeat:Connect(function(dt)
	chromaTimer = chromaTimer + dt
	if chromaTimer >= 0.2 then
		chromaTimer = 0
		chromaIdx = (chromaIdx % #CHROMA_COLORS) + 1
	end
	local c1 = CHROMA_COLORS[chromaIdx]
	local c2 = CHROMA_COLORS[(chromaIdx % #CHROMA_COLORS) + 1]
	local alpha = chromaTimer / 0.2
	local cr = c1.R + (c2.R - c1.R) * alpha
	local cg = c1.G + (c2.G - c1.G) * alpha
	local cb2 = c1.B + (c2.B - c1.B) * alpha
	local chromaCol = Color3.new(cr, cg, cb2)
	rootStroke.Color = chromaCol
	chromaTitleLabel.TextColor3 = chromaCol
end)

local aimTimer = 0
RunService.Heartbeat:Connect(function(dt)
	aimTimer = aimTimer + dt

	char = lp.Character
	if not char then return end
	hrp = char:FindFirstChild("HumanoidRootPart")
	hum = char:FindFirstChild("Humanoid")

	if cfg.GodMode and hum then
		hum.MaxHealth = math.huge
		hum.Health = math.huge
	end

	if cfg.NoFallDamage and hum then
		hum.MaxHealth = hum.MaxHealth
	end

	if cfg.Noclip and char then
		for _, part in ipairs(char:GetDescendants()) do
			if part:IsA("BasePart") then
				part.CanCollide = false
			end
		end
	end

	if cfg.Fullbright then
		local lighting = game:GetService("Lighting")
		lighting.Brightness = 2
		lighting.ClockTime = 14
		lighting.FogEnd = 100000
		lighting.GlobalShadows = false
		lighting.Ambient = Color3.new(1, 1, 1)
	end

	if cfg.SpeedHack and hum then
		hum.WalkSpeed = cfg.WalkSpeed
	elseif hum and not cfg.SpeedHack then
		if hum.WalkSpeed == cfg.WalkSpeed and cfg.WalkSpeed ~= 16 then
			hum.WalkSpeed = 16
		end
	end

	if cfg.InfiniteJump and hum then
		hum.JumpPower = cfg.JumpPower
	end

	if aimTimer >= 0.2 then
		aimTimer = 0

		if (cfg.SilentAim or cfg.AimLock) and hrp then
			local closest = nil
			local closestDist = math.huge
			local myTeam = lp.Team

			for _, plr in ipairs(Players:GetPlayers()) do
				if plr ~= lp then
					if cfg.TeamCheck and plr.Team == myTeam then continue end
					local c = plr.Character
					if not c then continue end
					local tHrp = c:FindFirstChild("HumanoidRootPart")
					local tHum = c:FindFirstChild("Humanoid")
					if not tHrp or not tHum or tHum.Health <= 0 then continue end
					local screenPos, onScreen = Camera:WorldToScreenPoint(tHrp.Position)
					if not onScreen then continue end
					local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
					local dist = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
					if dist < cfg.FOVSize and dist < closestDist then
						closestDist = dist
						closest = plr
					end
				end
			end

			if closest and closest.Character then
				local tHrp = closest.Character:FindFirstChild("HumanoidRootPart")
				local head = closest.Character:FindFirstChild("Head")
				local target = head or tHrp
				if target then
					if cfg.AimLock then
						local smooth = 1 - (cfg.Smoothness / 100 * 0.9)
						Camera.CFrame = Camera.CFrame:Lerp(
							CFrame.new(Camera.CFrame.Position, target.Position),
							smooth
						)
					end
				end
			end
		end
	end
end)

RunService.Stepped:Connect(function()
	char = lp.Character
	if not char then return end

	if cfg.HitboxExpand then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr ~= lp and plr.Character then
				local tHrp = plr.Character:FindFirstChild("HumanoidRootPart")
				if tHrp then
					tHrp.Size = Vector3.new(cfg.HitboxSize, cfg.HitboxSize, cfg.HitboxSize)
				end
				if cfg.HeadExpand then
					local head = plr.Character:FindFirstChild("Head")
					if head then
						head.Size = Vector3.new(cfg.HeadSize, cfg.HeadSize, cfg.HeadSize)
					end
				end
			end
		end
	end
end)

local flyBody = nil
local flyGyro = nil

RunService.Heartbeat:Connect(function()
	char = lp.Character
	if not char then return end
	hrp = char:FindFirstChild("HumanoidRootPart")
	hum = char:FindFirstChild("Humanoid")

	if cfg.Fly and hrp and hum then
		hum.PlatformStand = true
		if not flyBody then
			flyBody = Instance.new("BodyVelocity")
			flyBody.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
			flyBody.Velocity = Vector3.new(0, 0, 0)
			flyBody.Name = "SpartaFlyBody"
			flyBody.Parent = hrp
		end
		if not flyGyro then
			flyGyro = Instance.new("BodyGyro")
			flyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
			flyGyro.P = 1e4
			flyGyro.Name = "SpartaFlyGyro"
			flyGyro.Parent = hrp
		end

		local moveDir = Vector3.new(0, 0, 0)
		local mover = lp.Character and lp.Character:FindFirstChild("HumanoidRootPart")
		if mover then
			local movVec = hum.MoveDirection
			if movVec.Magnitude > 0.1 then
				moveDir = Camera.CFrame:VectorToWorldSpace(movVec)
				moveDir = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
			end
		end

		local upDown = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDown = 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then upDown = -1 end

		flyBody.Velocity = (moveDir * cfg.FlySpeed) + Vector3.new(0, upDown * cfg.FlySpeed * 0.6, 0)
		flyGyro.CFrame = Camera.CFrame
	else
		if flyBody then flyBody:Destroy() flyBody = nil end
		if flyGyro then flyGyro:Destroy() flyGyro = nil end
		if hum and not cfg.Fly then
			hum.PlatformStand = false
		end
	end
end)

local espDrawings = {}

local function clearESP()
	for _, drawings in pairs(espDrawings) do
		for _, d in pairs(drawings) do
			pcall(function() d:Remove() end)
		end
	end
	espDrawings = {}
end

RunService.Heartbeat:Connect(function()
	if not (cfg.PlayerESP or cfg.BoxESP or cfg.NameESP or cfg.HealthBar or cfg.Tracers) then
		clearESP()
		return
	end

	local rendered = {}

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == lp then continue end
		local c = plr.Character
		if not c then continue end
		local tHrp = c:FindFirstChild("HumanoidRootPart")
		local tHum = c:FindFirstChild("Humanoid")
		if not tHrp or not tHum then continue end

		local screenPos, onScreen = Camera:WorldToScreenPoint(tHrp.Position)
		if not onScreen then continue end

		local dist = (hrp and (tHrp.Position - hrp.Position).Magnitude) or 0
		if dist > cfg.ESPDistance then continue end

		rendered[plr.Name] = true

		if not espDrawings[plr.Name] then
			espDrawings[plr.Name] = {}
		end

		local d = espDrawings[plr.Name]

		if cfg.NameESP then
			if not d.name then
				d.name = Drawing.new("Text")
				d.name.Size = 13
				d.name.Center = true
				d.name.Outline = true
				d.name.Color = Color3.new(1, 1, 1)
			end
			d.name.Visible = true
			d.name.Text = plr.Name
			d.name.Position = Vector2.new(screenPos.X, screenPos.Y - 30)
		elseif d.name then
			d.name.Visible = false
		end

		if cfg.HealthBar and tHum then
			if not d.health then
				d.health = Drawing.new("Text")
				d.health.Size = 11
				d.health.Center = true
				d.health.Outline = true
			end
			d.health.Visible = true
			local hp = math.floor(tHum.Health / tHum.MaxHealth * 100)
			d.health.Text = hp .. "%"
			d.health.Color = Color3.fromRGB(math.floor((1 - hp / 100) * 255), math.floor((hp / 100) * 255), 0)
			d.health.Position = Vector2.new(screenPos.X, screenPos.Y - 16)
		elseif d.health then
			d.health.Visible = false
		end

		if cfg.Tracers then
			if not d.tracer then
				d.tracer = Drawing.new("Line")
				d.tracer.Thickness = 1
				d.tracer.Color = Color3.new(1, 0.3, 0.3)
				d.tracer.Transparency = 0.5
			end
			d.tracer.Visible = true
			d.tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
			d.tracer.To = Vector2.new(screenPos.X, screenPos.Y)
		elseif d.tracer then
			d.tracer.Visible = false
		end
	end

	for name, _ in pairs(espDrawings) do
		if not rendered[name] then
			for _, d in pairs(espDrawings[name]) do
				pcall(function() d.Visible = false end)
			end
		end
	end
end)

local autoClickTimer = 0
RunService.Heartbeat:Connect(function(dt)
	if not cfg.AutoClick then return end
	autoClickTimer = autoClickTimer + dt
	local delay = 1 / cfg.CPS
	if cfg.RandomDelay then
		delay = delay * (0.8 + math.random() * 0.4)
	end
	if autoClickTimer >= delay then
		autoClickTimer = 0
		local vp = game:GetService("VirtualUser")
		pcall(function()
			vp:ClickButton1(Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2))
		end)
	end
end)

if cfg.AntiAFK then
	local VU = game:GetService("VirtualUser")
	lp.Idled:Connect(function()
		VU:Button2Down(Vector2.new(0, 0), CFrame.new())
		task.wait(1)
		VU:Button2Up(Vector2.new(0, 0), CFrame.new())
	end)
end

lp.CharacterAdded:Connect(function(newChar)
	char = newChar
	hrp = newChar:WaitForChild("HumanoidRootPart")
	hum = newChar:WaitForChild("Humanoid")

	if cfg.NoFallDamage then
		hum.FreeFalling:Connect(function(active)
			if not active and cfg.NoFallDamage then
				hum.Health = hum.Health
			end
		end)
	end

	if cfg.InfiniteJump then
		hum.StateChanged:Connect(function(_, new)
			if new == Enum.HumanoidStateType.Jumping and cfg.InfiniteJump then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end)
	end
end)

lp.Character.Humanoid.FreeFalling:Connect(function(active)
	if not active and cfg.NoFallDamage then
		lp.Character.Humanoid.Health = lp.Character.Humanoid.Health
	end
end)

lp.Character.Humanoid.StateChanged:Connect(function(_, new)
	if new == Enum.HumanoidStateType.Jumping and cfg.InfiniteJump then
		lp.Character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

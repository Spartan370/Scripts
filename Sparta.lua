local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local Lighting = game:GetService("Lighting")
local VirtualUser = game:GetService("VirtualUser")
local TeleportService = game:GetService("TeleportService")
local SoundService = game:GetService("SoundService")

local lp = Players.LocalPlayer
local mouse = lp:GetMouse()
local Camera = Workspace.CurrentCamera

local cfg = {
	SilentAim = false,
	AimLock = false,
	TeamCheck = true,
	VisibleCheck = false,
	FOVSize = 150,
	Smoothness = 35,
	FOVCircle = true,
	Prediction = false,
	PredictionStrength = 40,

	HitboxExpand = false,
	HitboxSize = 6,
	HeadOnly = false,
	HeadSize = 5,
	HitboxTeamCheck = true,

	AutoClick = false,
	CPS = 14,
	RandomizeCPS = false,
	RandomRange = 5,
	HoldToClick = true,
	JitterAim = false,
	JitterStrength = 3,

	SpeedHack = false,
	WalkSpeed = 50,
	SpeedBypass = false,
	Noclip = false,
	LongJump = false,
	BunnyHop = false,

	Fly = false,
	FlySpeed = 60,
	VerticalSpeed = 40,
	FlyNoclip = false,
	AntiGravity = true,
	SmoothFly = true,

	PlayerESP = false,
	BoxESP = false,
	CornerBox = false,
	NameESP = true,
	DistanceESP = true,
	HealthBar = true,
	HealthText = false,
	Tracers = false,
	Chams = false,
	SkeletonESP = false,
	TeamColor = true,
	ESPMaxDist = 2500,

	AntiAFK = true,
	InfiniteJump = false,
	JumpPower = 100,
	NoFallDamage = true,
	GodMode = false,
	Fullbright = false,
	NoFog = false,
	TimeOfDay = 14,
	Rejoin = false,
	NoAnimations = false,
}

local VALID_KEYS = { ["37"] = true, ["cm"] = true, ["217"] = true }

local function getChar() return lp.Character end
local function getHRP() return getChar() and getChar():FindFirstChild("HumanoidRootPart") end
local function getHum() return getChar() and getChar():FindFirstChildOfClass("Humanoid") end

local gui = Instance.new("ScreenGui")
gui.Name = "SpartaGUI_v2"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999

pcall(function() if syn then syn.protect_gui(gui) end end)
pcall(function() if gethui then gui.Parent = gethui() else gui.Parent = CoreGui end end)
if not gui.Parent then gui.Parent = lp:WaitForChild("PlayerGui") end

local function rgb(r,g,b) return Color3.fromRGB(r,g,b) end
local function lerp(a,b,t) return a+(b-a)*t end

local CHROMA = {
	rgb(255,0,0), rgb(255,120,0), rgb(255,255,0),
	rgb(0,255,0), rgb(0,120,255), rgb(90,0,255), rgb(255,0,200)
}
local chromaT = 0
local chromaI = 1

local function getChroma(offset)
	local i = ((chromaI - 1 + (offset or 0)) % #CHROMA) + 1
	local j = (i % #CHROMA) + 1
	local a = chromaT / 0.18
	return Color3.new(
		lerp(CHROMA[i].R, CHROMA[j].R, a),
		lerp(CHROMA[i].G, CHROMA[j].G, a),
		lerp(CHROMA[i].B, CHROMA[j].B, a)
	)
end

local function tw(obj, props, t, style, dir)
	return TweenService:Create(obj, TweenInfo.new(t or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
end

local function mkFrame(parent, props)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = rgb(18,18,28)
	f.BorderSizePixel = 0
	for k,v in pairs(props or {}) do f[k]=v end
	f.Parent = parent
	return f
end

local function mkLabel(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.TextColor3 = rgb(220,220,235)
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 11
	l.BorderSizePixel = 0
	l.RichText = true
	for k,v in pairs(props or {}) do l[k]=v end
	l.Parent = parent
	return l
end

local function mkBtn(parent, props)
	local b = Instance.new("TextButton")
	b.BackgroundTransparency = 1
	b.TextColor3 = rgb(220,220,235)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 11
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	for k,v in pairs(props or {}) do b[k]=v end
	b.Parent = parent
	return b
end

local function mkCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, radius or 8)
	return c
end

local function mkStroke(parent, color, thickness)
	local s = Instance.new("UIStroke", parent)
	s.Color = color or rgb(60,60,80)
	s.Thickness = thickness or 1
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

local function mkToggle(parent, pos, size, default, onChange)
	local W, H = (size and size.X.Offset) or 38, (size and size.Y.Offset) or 20
	local track = mkFrame(parent, {
		Position = pos or UDim2.new(1,-W-8,0.5,-(H/2)),
		Size = UDim2.new(0,W,0,H),
		BackgroundColor3 = default and rgb(59,130,246) or rgb(38,38,52),
	})
	mkCorner(track, H)

	local thumb = mkFrame(track, {
		Size = UDim2.new(0,H-6,0,H-6),
		Position = default and UDim2.new(1,-(H-3),0.5,-(H-6)/2) or UDim2.new(0,3,0.5,-(H-6)/2),
		BackgroundColor3 = rgb(255,255,255),
	})
	mkCorner(thumb, H)

	local state = default and true or false
	local hitbox = mkBtn(track, { Size = UDim2.new(1,0,1,0), Text = "" })

	hitbox.MouseButton1Click:Connect(function()
		state = not state
		if state then
			tw(track, { BackgroundColor3 = rgb(59,130,246) }):Play()
			tw(thumb, { Position = UDim2.new(1,-(H-3),0.5,-(H-6)/2) }):Play()
		else
			tw(track, { BackgroundColor3 = rgb(38,38,52) }):Play()
			tw(thumb, { Position = UDim2.new(0,3,0.5,-(H-6)/2) }):Play()
		end
		if onChange then pcall(onChange, state) end
	end)

	return track, function() return state end
end

local function mkSlider(parent, yPos, min, max, default, suffix, onChange)
	local container = mkFrame(parent, {
		Position = UDim2.new(0,8,0,yPos),
		Size = UDim2.new(1,-16,0,24),
		BackgroundTransparency = 1,
	})

	local track = mkFrame(container, {
		Position = UDim2.new(0,0,0.5,-3),
		Size = UDim2.new(1,-52,0,6),
		BackgroundColor3 = rgb(40,40,58),
	})
	mkCorner(track, 6)

	local fill = mkFrame(track, {
		Size = UDim2.new((default-min)/(max-min),0,1,0),
		BackgroundColor3 = rgb(59,130,246),
	})
	mkCorner(fill, 6)

	local thumb = mkFrame(track, {
		Size = UDim2.new(0,14,0,14),
		Position = UDim2.new((default-min)/(max-min),-7,0.5,-7),
		BackgroundColor3 = rgb(255,255,255),
	})
	mkCorner(thumb, 14)
	mkStroke(thumb, rgb(59,130,246), 1.5)

	local valLabel = mkLabel(container, {
		Position = UDim2.new(1,-50,0,0),
		Size = UDim2.new(0,50,1,0),
		Text = tostring(default)..(suffix or ""),
		TextColor3 = rgb(59,130,246),
		Font = Enum.Font.GothamBold,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local value = default
	local dragging = false

	local function updateSlider(x)
		local trackAbs = track.AbsolutePosition.X
		local trackSz = track.AbsoluteSize.X
		local pct = math.clamp((x - trackAbs) / trackSz, 0, 1)
		value = math.round(min + pct * (max - min))
		fill.Size = UDim2.new(pct, 0, 1, 0)
		thumb.Position = UDim2.new(pct, -7, 0.5, -7)
		valLabel.Text = tostring(value) .. (suffix or "")
		if onChange then pcall(onChange, value) end
	end

	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true; updateSlider(i.Position.X)
		end
	end)
	thumb.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = true
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			updateSlider(i.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	return container
end

local TABS = {
	{ id="aim",       label="Aim Assist", col=rgb(239,68,68) },
	{ id="hitbox",    label="Hitbox",     col=rgb(249,115,22) },
	{ id="autoclick", label="Auto Click", col=rgb(234,179,8) },
	{ id="speed",     label="Speed",      col=rgb(34,197,94) },
	{ id="fly",       label="Fly",        col=rgb(59,130,246) },
	{ id="esp",       label="ESP",        col=rgb(168,85,247) },
	{ id="misc",      label="Misc",       col=rgb(236,72,153) },
}
local activeTab = "aim"
local sidebarVisible = true
local guiMinimized = false

local ROOT = mkFrame(gui, {
	Position = UDim2.new(0,18,0,50),
	Size = UDim2.new(0,490,0,540),
	BackgroundColor3 = rgb(14,14,22),
	Visible = false,
})
mkCorner(ROOT, 14)
local rootStroke = mkStroke(ROOT, CHROMA[1], 1.5)

local TITLEBAR = mkFrame(ROOT, {
	Position = UDim2.new(0,0,0,0),
	Size = UDim2.new(1,0,0,36),
	BackgroundColor3 = rgb(8,8,14),
})
mkCorner(TITLEBAR, 14)

local titleFix = mkFrame(ROOT, {
	Position = UDim2.new(0,0,0,20),
	Size = UDim2.new(1,0,0,16),
	BackgroundColor3 = rgb(8,8,14),
})

local function makeDot(xOff, col)
	local f = mkFrame(TITLEBAR, {
		Position = UDim2.new(0, xOff, 0.5, -7),
		Size = UDim2.new(0,14,0,14),
		BackgroundColor3 = col,
	})
	mkCorner(f, 14)
	local b = mkBtn(f, { Size = UDim2.new(1,0,1,0), Text="" })
	return f, b
end

local dotRed, dotRedBtn = makeDot(14, rgb(255,95,87))
local dotOrange, dotOrangeBtn = makeDot(34, rgb(254,188,46))
local dotGreen, dotGreenBtn = makeDot(54, rgb(40,200,64))

local chromaTitle = mkLabel(TITLEBAR, {
	Position = UDim2.new(0,75,0,0),
	Size = UDim2.new(1,-150,1,0),
	Text = "Sparta",
	Font = Enum.Font.GothamBold,
	TextSize = 12,
	TextXAlignment = Enum.TextXAlignment.Center,
})

local tabLabel = mkLabel(TITLEBAR, {
	Position = UDim2.new(0,75,0,0),
	Size = UDim2.new(1,-150,1,0),
	Text = "| Aim Assist | v2.0",
	Font = Enum.Font.Gotham,
	TextSize = 10,
	TextColor3 = rgb(90,90,110),
	TextXAlignment = Enum.TextXAlignment.Right,
})

local BODY = mkFrame(ROOT, {
	Position = UDim2.new(0,0,0,36),
	Size = UDim2.new(1,0,1,-36),
	BackgroundTransparency = 1,
})

local SIDEBAR = mkFrame(BODY, {
	Size = UDim2.new(0,152,1,0),
	BackgroundColor3 = rgb(10,10,17),
})
mkCorner(SIDEBAR, 14)

local sideTopFill = mkFrame(SIDEBAR, { Size = UDim2.new(1,0,0,14), BackgroundColor3 = rgb(10,10,17) })
local sideRightFill = mkFrame(SIDEBAR, {
	Position = UDim2.new(1,-14,0,0), Size = UDim2.new(0,14,1,0),
	BackgroundColor3 = rgb(10,10,17),
})
mkFrame(SIDEBAR, {
	Position = UDim2.new(1,-1,0,0), Size = UDim2.new(0,1,1,0),
	BackgroundColor3 = rgb(25,25,38),
})

local searchRow = mkFrame(SIDEBAR, {
	Position = UDim2.new(0,6,0,6), Size = UDim2.new(1,-12,0,25),
	BackgroundColor3 = rgb(20,20,30),
})
mkCorner(searchRow, 6)
mkLabel(searchRow, {
	Position = UDim2.new(0,8,0,0), Size = UDim2.new(1,-8,1,0),
	Text = "🔍  Search...", TextColor3 = rgb(55,55,72),
	Font = Enum.Font.Gotham, TextSize = 10,
	TextXAlignment = Enum.TextXAlignment.Left,
})

mkLabel(SIDEBAR, {
	Position = UDim2.new(0,10,0,36), Size = UDim2.new(1,-10,0,14),
	Text = "FEATURES", TextColor3 = rgb(50,50,68),
	Font = Enum.Font.GothamBold, TextSize = 8,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local TABLIST = Instance.new("ScrollingFrame")
TABLIST.Position = UDim2.new(0,4,0,52)
TABLIST.Size = UDim2.new(1,-8,1,-95)
TABLIST.BackgroundTransparency = 1
TABLIST.BorderSizePixel = 0
TABLIST.ScrollBarThickness = 2
TABLIST.ScrollBarImageColor3 = rgb(50,50,75)
TABLIST.CanvasSize = UDim2.new(0,0,0,0)
TABLIST.AutomaticCanvasSize = Enum.AutomaticSize.Y
TABLIST.Parent = SIDEBAR

local tabListLayout = Instance.new("UIListLayout", TABLIST)
tabListLayout.Padding = UDim.new(0,2)
tabListLayout.SortOrder = Enum.SortOrder.LayoutOrder

local tabBtns = {}

for i, tab in ipairs(TABS) do
	local row = mkBtn(TABLIST, {
		Size = UDim2.new(1,0,0,28),
		Text = "",
		BackgroundColor3 = tab.id == activeTab and rgb(30,30,45) or rgb(0,0,0),
		BackgroundTransparency = tab.id == activeTab and 0 or 1,
		LayoutOrder = i,
	})
	mkCorner(row, 7)

	local dot = mkFrame(row, {
		Position = UDim2.new(0,8,0.5,-5),
		Size = UDim2.new(0,10,0,10),
		BackgroundColor3 = tab.col,
	})
	mkCorner(dot, 3)

	mkLabel(row, {
		Position = UDim2.new(0,24,0,0),
		Size = UDim2.new(1,-30,1,0),
		Text = tab.label,
		Font = Enum.Font.GothamMedium,
		TextSize = 11,
		TextColor3 = tab.id == activeTab and rgb(220,220,235) or rgb(90,90,115),
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	if tab.id == activeTab then
		local indicator = mkFrame(row, {
			Position = UDim2.new(1,-4,0.5,-4), Size = UDim2.new(0,4,0,8),
			BackgroundColor3 = tab.col,
		})
		mkCorner(indicator, 4)
	end

	tabBtns[tab.id] = row
end

local configSection = mkFrame(SIDEBAR, {
	Position = UDim2.new(0,6,1,-40),
	Size = UDim2.new(1,-12,0,34),
	BackgroundColor3 = rgb(16,16,26),
})
mkCorner(configSection, 7)

local configToggleBtn = mkBtn(configSection, {
	Size = UDim2.new(1,0,0,34),
	Text = "⚙  Config",
	Font = Enum.Font.GothamMedium,
	TextSize = 10,
	TextColor3 = rgb(80,80,105),
})

local CONTENT = mkFrame(BODY, {
	Position = UDim2.new(0,152,0,0),
	Size = UDim2.new(1,-152,1,0),
	BackgroundTransparency = 1,
	ClipsDescendants = true,
})

local pages = {}

local function buildScroll(id)
	local sf = Instance.new("ScrollingFrame")
	sf.Position = UDim2.new(0,0,0,0)
	sf.Size = UDim2.new(1,0,1,0)
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 3
	sf.ScrollBarImageColor3 = rgb(45,45,65)
	sf.CanvasSize = UDim2.new(0,0,0,0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	sf.Visible = id == activeTab
	sf.Parent = CONTENT

	local layout = Instance.new("UIListLayout", sf)
	layout.Padding = UDim.new(0,4)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	Instance.new("UIPadding", sf).PaddingLeft = UDim.new(0,6)

	return sf
end

local function addSection(page, order, title)
	local row = mkFrame(page, {
		Size = UDim2.new(1,-6,0,18),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	})
	mkLabel(row, {
		Position = UDim2.new(0,2,0,0), Size = UDim2.new(1,-4,1,0),
		Text = string.upper(title),
		TextColor3 = rgb(55,55,72), Font = Enum.Font.GothamBold, TextSize = 8,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	local line = mkFrame(row, {
		Position = UDim2.new(0,#title*4.5+4,0.5,0),
		Size = UDim2.new(1,-(#title*4.5+4),0,1),
		BackgroundColor3 = rgb(28,28,42),
	})
	return row
end

local function addInfoBadge(page, order, text)
	local row = mkFrame(page, {
		Size = UDim2.new(1,-6,0,22),
		BackgroundColor3 = rgb(20,30,55),
		LayoutOrder = order,
	})
	mkCorner(row, 6)
	mkStroke(row, rgb(40,70,120), 1)
	mkLabel(row, {
		Position = UDim2.new(0,8,0,0), Size = UDim2.new(1,-8,1,0),
		Text = "ℹ  " .. text, TextColor3 = rgb(80,130,220),
		Font = Enum.Font.Gotham, TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	return row
end

local function addCard(page, order, title, desc, cardType, accentCol, togDefault, slMin, slMax, slDef, slSuf, cfgKey)
	local cardH = cardType == "slider" and 58 or (desc and 48 or 38)
	local card = mkFrame(page, {
		Size = UDim2.new(1,-6,0,cardH),
		BackgroundColor3 = rgb(18,18,28),
		LayoutOrder = order,
	})
	mkCorner(card, 9)
	mkStroke(card, rgb(32,32,48), 1)

	if cardType == "toggle" and accentCol then
		local bar = mkFrame(card, {
			Position = UDim2.new(0,9,0.18,0),
			Size = UDim2.new(0,2.5,0.64,0),
			BackgroundColor3 = accentCol,
		})
		mkCorner(bar, 4)
	end

	local txtOff = (cardType == "toggle" and accentCol) and 18 or 10
	mkLabel(card, {
		Position = UDim2.new(0,txtOff,0,desc and 8 or 0),
		Size = UDim2.new(1,-70,desc and 0 or 1,0),
		AutomaticSize = desc and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		Text = title, Font = Enum.Font.GothamSemibold, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
	if desc then
		mkLabel(card, {
			Position = UDim2.new(0,txtOff,0,23),
			Size = UDim2.new(1,-70,0,16),
			Text = desc, TextColor3 = rgb(80,80,105),
			Font = Enum.Font.Gotham, TextSize = 10,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	if cardType == "toggle" then
		local _, getState = mkToggle(card, nil, nil, togDefault, function(v)
			if cfgKey then cfg[cfgKey] = v end
		end)
	elseif cardType == "slider" then
		mkSlider(card, 32, slMin, slMax, slDef, slSuf, function(v)
			if cfgKey then cfg[cfgKey] = v end
		end)
	end

	return card
end

local function buildAimPage()
	local p = buildScroll("aim"); pages["aim"] = p
	local n = 0
	local function s(t) n=n+1; addSection(p,n,t) end
	local function c(ti,de,ty,ac,def,a,b,d,e,k) n=n+1; addCard(p,n,ti,de,ty,ac,def,a,b,d,e,k) end
	local function info(t) n=n+1; addInfoBadge(p,n,t) end

	s("Targeting")
	c("Silent Aim","Warps bullets silently to nearest enemy","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"SilentAim")
	c("Aim Lock","Magnetically lock camera onto head","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"AimLock")
	c("Team Check","Never target your own teammates","toggle",rgb(239,68,68),true,nil,nil,nil,nil,"TeamCheck")
	c("Visible Check","Only aim at players in line-of-sight","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"VisibleCheck")
	s("Settings")
	info("Head-priority · Updates every 0.2s · Camera-smooth")
	c("FOV Size","Targeting radius in pixels","slider",nil,nil,10,500,150,"px","FOVSize")
	c("Smoothness","Camera interpolation speed","slider",nil,nil,1,100,35,"%","Smoothness")
	c("FOV Circle","Show targeting circle on screen","toggle",rgb(239,68,68),true,nil,nil,nil,nil,"FOVCircle")
	c("Prediction","Lead moving targets with velocity","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"Prediction")
	c("Prediction Strength","How far ahead to lead","slider",nil,nil,0,100,40,"%","PredictionStrength")
end

local function buildHitboxPage()
	local p = buildScroll("hitbox"); pages["hitbox"] = p
	local n = 0
	local function s(t) n=n+1; addSection(p,n,t) end
	local function c(ti,de,ty,ac,def,a,b,d,e,k) n=n+1; addCard(p,n,ti,de,ty,ac,def,a,b,d,e,k) end

	s("Expansion")
	c("Hitbox Expander","Inflate enemy body hitboxes invisibly","toggle",rgb(249,115,22),false,nil,nil,nil,nil,"HitboxExpand")
	c("Body Size","Scale of expanded hitboxes","slider",nil,nil,1,25,6,"×","HitboxSize")
	c("Head Only","Only expand head hitbox","toggle",rgb(249,115,22),false,nil,nil,nil,nil,"HeadOnly")
	c("Head Size","Head hitbox scale multiplier","slider",nil,nil,1,20,5,"×","HeadSize")
	s("Options")
	c("Team Check","Skip your own teammates","toggle",rgb(249,115,22),true,nil,nil,nil,nil,"HitboxTeamCheck")
end

local function buildAutoClickPage()
	local p = buildScroll("autoclick"); pages["autoclick"] = p
	local n = 0
	local function s(t) n=n+1; addSection(p,n,t) end
	local function c(ti,de,ty,ac,def,a,b,d,e,k) n=n+1; addCard(p,n,ti,de,ty,ac,def,a,b,d,e,k) end

	s("Click")
	c("Auto Click","Automatically fire at set rate","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"AutoClick")
	c("CPS","Clicks per second","slider",nil,nil,1,60,14," cps","CPS")
	s("Options")
	c("Randomize CPS","Humanize timing intervals","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"RandomizeCPS")
	c("Random Range","Variance percentage","slider",nil,nil,1,30,5,"%","RandomRange")
	c("Hold to Click","Only click while touch held","toggle",rgb(234,179,8),true,nil,nil,nil,nil,"HoldToClick")
	c("Jitter Aim","Micro-shake for recoil reduction","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"JitterAim")
	c("Jitter Strength","Shake intensity in pixels","slider",nil,nil,1,15,3,"px","JitterStrength")
end

local function buildSpeedPage()
	local p = buildScroll("speed"); pages["speed"] = p
	local n = 0
	local function s(t) n=n+1; addSection(p,n,t) end
	local function c(ti,de,ty,ac,def,a,b,d,e,k) n=n+1; addCard(p,n,ti,de,ty,ac,def,a,b,d,e,k) end

	s("Movement")
	c("Speed Hack","Override WalkSpeed immediately","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"SpeedHack")
	c("Walk Speed","Target walk speed in studs","slider",nil,nil,16,500,50," ws","WalkSpeed")
	s("Bypass")
	c("Speed Bypass","Tick-safe speed injection method","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"SpeedBypass")
	c("Noclip","Pass through all walls freely","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"Noclip")
	c("Long Jump","Extended jump distance","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"LongJump")
	c("Bunny Hop","Auto-jump at velocity peaks","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"BunnyHop")
end

local function buildFlyPage()
	local p = buildScroll("fly"); pages["fly"] = p
	local n = 0
	local function s(t) n=n+1; addSection(p,n,t) end
	local function c(ti,de,ty,ac,def,a,b,d,e,k) n=n+1; addCard(p,n,ti,de,ty,ac,def,a,b,d,e,k) end
	local function info(t) n=n+1; addInfoBadge(p,n,t) end

	s("Flight")
	c("Fly","Freely move and levitate","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"Fly")
	c("Fly Speed","Horizontal flight speed","slider",nil,nil,1,300,60," sp","FlySpeed")
	c("Vertical Speed","Up/Down movement speed","slider",nil,nil,1,200,40," sp","VerticalSpeed")
	s("Options")
	c("Noclip","Phase through walls while flying","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"FlyNoclip")
	c("Anti-Gravity","Hover in place when not moving","toggle",rgb(59,130,246),true,nil,nil,nil,nil,"AntiGravity")
	c("Smooth Fly","Ease in/out acceleration curve","toggle",rgb(59,130,246),true,nil,nil,nil,nil,"SmoothFly")
	s("Controls")
	info("Thumbstick → move · Jump = rise · Crouch = descend")

	n=n+1
	local infoCard = mkFrame(p, {
		Size = UDim2.new(1,-6,0,48),
		BackgroundColor3 = rgb(16,22,42),
		LayoutOrder = n,
	})
	mkCorner(infoCard, 9)
	mkStroke(infoCard, rgb(40,70,130), 1)
	mkLabel(infoCard, {
		Position = UDim2.new(0,12,0,0), Size = UDim2.new(1,-12,0.5,0),
		Text = "Default Roblox Thumbstick",
		Font = Enum.Font.GothamSemibold, TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	mkLabel(infoCard, {
		Position = UDim2.new(0,12,0.5,0), Size = UDim2.new(1,-12,0.5,0),
		Text = "Uses built-in mobile joystick + jump/crouch",
		TextColor3 = rgb(80,120,200), Font = Enum.Font.Gotham, TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
end

local function buildESPPage()
	local p = buildScroll("esp"); pages["esp"] = p
	local n = 0
	local function s(t) n=n+1; addSection(p,n,t) end
	local function c(ti,de,ty,ac,def,a,b,d,e,k) n=n+1; addCard(p,n,ti,de,ty,ac,def,a,b,d,e,k) end

	s("Visuals")
	c("Player ESP","Full player wallhack overlay","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"PlayerESP")
	c("Box ESP","2D bounding boxes on players","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"BoxESP")
	c("Corner Box","Stylized corner-only boxes","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"CornerBox")
	c("Name ESP","Usernames above player heads","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"NameESP")
	c("Distance","Show stud distance to player","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"DistanceESP")
	s("Health")
	c("Health Bar","Dynamic HP bar beside box","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"HealthBar")
	c("Health Text","Exact HP numbers","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"HealthText")
	s("Overlays")
	c("Tracers","Line from screen to player feet","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"Tracers")
	c("Chams","Highlight through walls","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"Chams")
	c("Skeleton","Bone structure rendering","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"SkeletonESP")
	c("Team Color","Color ESP per team","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"TeamColor")
	s("Range")
	c("Max Distance","Max render distance in studs","slider",nil,nil,50,5000,2500," st","ESPMaxDist")
end

local function buildMiscPage()
	local p = buildScroll("misc"); pages["misc"] = p
	local n = 0
	local function s(t) n=n+1; addSection(p,n,t) end
	local function c(ti,de,ty,ac,def,a,b,d,e,k) n=n+1; addCard(p,n,ti,de,ty,ac,def,a,b,d,e,k) end

	s("Player")
	c("Anti AFK","Auto-move to prevent server kick","toggle",rgb(236,72,153),true,nil,nil,nil,nil,"AntiAFK")
	c("Infinite Jump","Jump again mid-air endlessly","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"InfiniteJump")
	c("Jump Power","Jump force multiplier","slider",nil,nil,50,1000,100," jp","JumpPower")
	c("No Fall Damage","Survive any drop height","toggle",rgb(236,72,153),true,nil,nil,nil,nil,"NoFallDamage")
	c("God Mode","Health regenerates to maximum","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"GodMode")
	s("World")
	c("Fullbright","Remove shadows and darkness","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"Fullbright")
	c("No Fog","Clear all world fog","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"NoFog")
	c("Time of Day","World clock override (0-24)","slider",nil,nil,0,24,14,"h","TimeOfDay")
	s("Utility")
	c("Rejoin","Instantly rejoin the current game","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"Rejoin")
	c("No Animations","Remove character animations","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"NoAnimations")
end

buildAimPage()
buildHitboxPage()
buildAutoClickPage()
buildSpeedPage()
buildFlyPage()
buildESPPage()
buildMiscPage()

local function switchTab(id)
	for tabId, page in pairs(pages) do
		page.Visible = tabId == id
	end
	for tabId, btn in pairs(tabBtns) do
		local isActive = tabId == id
		btn.BackgroundTransparency = isActive and 0 or 1
		btn.BackgroundColor3 = isActive and rgb(28,28,44) or rgb(0,0,0)
		local lbl = btn:FindFirstChildWhichIsA("TextLabel")
		if lbl then lbl.TextColor3 = isActive and rgb(220,220,235) or rgb(90,90,115) end
	end
	for _, tab in ipairs(TABS) do
		if tab.id == id then
			tabLabel.Text = "| " .. tab.label .. " | v2.0"
			break
		end
	end
	activeTab = id
	for _, page in pairs(pages) do
		if page.Visible then page.CanvasPosition = Vector2.new(0,0) end
	end
end

for tabId, btn in pairs(tabBtns) do
	local id = tabId
	btn.MouseButton1Click:Connect(function() switchTab(id) end)
end

local isDragging, dragStart2, startPos2 = false, nil, nil
TITLEBAR.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		isDragging = true; dragStart2 = i.Position; startPos2 = ROOT.Position
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if isDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		local d = i.Position - dragStart2
		ROOT.Position = UDim2.new(startPos2.X.Scale, startPos2.X.Offset+d.X, startPos2.Y.Scale, startPos2.Y.Offset+d.Y)
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then isDragging = false end
end)

dotRedBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

dotOrangeBtn.MouseButton1Click:Connect(function()
	guiMinimized = not guiMinimized
	if guiMinimized then
		tw(BODY, { Size = UDim2.new(1,0,0,0) }, 0.2):Play()
		task.delay(0.2, function() BODY.Visible = false end)
		tw(ROOT, { Size = UDim2.new(0,490,0,36) }, 0.2):Play()
	else
		BODY.Visible = true
		tw(ROOT, { Size = UDim2.new(0,490,0,540) }, 0.2):Play()
		task.delay(0.05, function()
			tw(BODY, { Size = UDim2.new(1,0,1,-36) }, 0.18):Play()
		end)
	end
end)

dotGreenBtn.MouseButton1Click:Connect(function()
	sidebarVisible = not sidebarVisible
	if sidebarVisible then
		SIDEBAR.Visible = true
		CONTENT.Position = UDim2.new(0,152,0,0)
		CONTENT.Size = UDim2.new(1,-152,1,0)
	else
		SIDEBAR.Visible = false
		CONTENT.Position = UDim2.new(0,0,0,0)
		CONTENT.Size = UDim2.new(1,0,1,0)
	end
end)

local LOCK = mkFrame(gui, {
	Size = UDim2.new(1,0,1,0),
	BackgroundColor3 = rgb(6,6,12),
})

local KF = mkFrame(LOCK, {
	Position = UDim2.new(0.5,-160,0.5,-125),
	Size = UDim2.new(0,320,0,225),
	BackgroundColor3 = rgb(16,16,24),
})
mkCorner(KF, 14)
mkStroke(KF, rgb(35,35,55), 1.5)

local KT = mkFrame(KF, {
	Size = UDim2.new(1,0,0,36),
	BackgroundColor3 = rgb(8,8,14),
})
mkCorner(KT, 14)

local KTfix = mkFrame(KF, {
	Position = UDim2.new(0,0,0,20),
	Size = UDim2.new(1,0,0,16),
	BackgroundColor3 = rgb(8,8,14),
})

local kDotR, kDotRBtn = makeDot(14, rgb(255,95,87))
kDotR.Parent = KT
kDotRBtn.Parent = kDotR

local kDotO, kDotOBtn = makeDot(34, rgb(254,188,46))
kDotO.Parent = KT
kDotOBtn.Parent = kDotO

mkLabel(KT, {
	Position = UDim2.new(0,60,0,0), Size = UDim2.new(1,-60,1,0),
	Text = "Sparta  |  Key System",
	TextColor3 = rgb(90,90,115), Font = Enum.Font.GothamMedium, TextSize = 11,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local keyBody = mkFrame(KF, {
	Position = UDim2.new(0,0,0,36),
	Size = UDim2.new(1,0,1,-36),
	BackgroundTransparency = 1,
})

mkLabel(keyBody, {
	Position = UDim2.new(0,0,0,16), Size = UDim2.new(1,0,0,22),
	Text = "🔐  Enter Key",
	Font = Enum.Font.GothamBold, TextSize = 14,
})

mkLabel(keyBody, {
	Position = UDim2.new(0,0,0,40), Size = UDim2.new(1,0,0,16),
	Text = "Enter one valid passcode to access Sparta",
	TextColor3 = rgb(70,70,95), Font = Enum.Font.Gotham, TextSize = 10,
})

local keyInput = Instance.new("TextBox")
keyInput.Position = UDim2.new(0,16,0,70)
keyInput.Size = UDim2.new(1,-32,0,40)
keyInput.BackgroundColor3 = rgb(24,24,36)
keyInput.TextColor3 = rgb(220,220,235)
keyInput.Font = Enum.Font.Code
keyInput.TextSize = 15
keyInput.PlaceholderText = "Key..."
keyInput.PlaceholderColor3 = rgb(60,60,82)
keyInput.Text = ""
keyInput.BorderSizePixel = 0
keyInput.ClearTextOnFocus = false
keyInput.TextXAlignment = Enum.TextXAlignment.Center
mkCorner(keyInput, 10)
mkStroke(keyInput, rgb(40,40,60), 1.5)
keyInput.Parent = keyBody

local keyErr = mkLabel(keyBody, {
	Position = UDim2.new(0,0,0,114), Size = UDim2.new(1,0,0,14),
	Text = "", TextColor3 = rgb(255,75,75),
	Font = Enum.Font.GothamBold, TextSize = 10,
})

local keyBtn = mkBtn(keyBody, {
	Position = UDim2.new(0,16,0,130), Size = UDim2.new(1,-32,0,38),
	Text = "Unlock", Font = Enum.Font.GothamBold, TextSize = 13,
	BackgroundColor3 = rgb(28,28,44), BackgroundTransparency = 0,
	TextColor3 = rgb(180,180,210),
})
mkCorner(keyBtn, 10)
mkStroke(keyBtn, rgb(50,50,75), 1)

local keyCollapsed = false

local function shakeKF()
	local orig = KF.Position
	for _ = 1, 3 do
		tw(KF, { Position = UDim2.new(0.5,-168,0.5,-125) }, 0.05):Play()
		task.wait(0.05)
		tw(KF, { Position = UDim2.new(0.5,-152,0.5,-125) }, 0.05):Play()
		task.wait(0.05)
	end
	KF.Position = orig
end

local function tryUnlock()
	local raw = keyInput.Text:match("^%s*(.-)%s*$") or ""
	if VALID_KEYS[raw] or VALID_KEYS[raw:lower()] then
		tw(LOCK, { BackgroundTransparency = 1 }, 0.4):Play()
		task.delay(0.4, function()
			LOCK.Visible = false
			ROOT.Visible = true
			tw(ROOT, { Position = UDim2.new(0,18,0,50) }, 0.0):Play()
		end)
	else
		keyErr.Text = "✗  Invalid key. Try: 37, CM, or 217"
		shakeKF()
		tw(keyInput.Parent.Parent:FindFirstChildWhichIsA("UIStroke"), nil, 0)
		mkStroke(keyInput, rgb(180,40,40), 1.5)
		task.delay(1.2, function()
			keyErr.Text = ""
			mkStroke(keyInput, rgb(40,40,60), 1.5)
		end)
	end
end

keyBtn.MouseButton1Click:Connect(tryUnlock)
keyInput.FocusLost:Connect(function(enter) if enter then tryUnlock() end end)

kDotRBtn.MouseButton1Click:Connect(function() gui:Destroy() end)

kDotOBtn.MouseButton1Click:Connect(function()
	keyCollapsed = not keyCollapsed
	if keyCollapsed then
		tw(keyBody, { Size = UDim2.new(1,0,0,0) }, 0.18):Play()
		task.delay(0.18, function() keyBody.Visible = false end)
		tw(KF, { Size = UDim2.new(0,320,0,36) }, 0.18):Play()
	else
		keyBody.Visible = true
		tw(KF, { Size = UDim2.new(0,320,0,225) }, 0.18):Play()
		task.delay(0.05, function()
			tw(keyBody, { Size = UDim2.new(1,0,1,-36) }, 0.15):Play()
		end)
	end
end)

local flyBV = nil
local flyBG = nil
local currentVel = Vector3.new()

local function stopFly()
	if flyBV then pcall(function() flyBV:Destroy() end) flyBV = nil end
	if flyBG then pcall(function() flyBG:Destroy() end) flyBG = nil end
	local hum = getHum()
	if hum then hum.PlatformStand = false end
	currentVel = Vector3.new()
end

local function startFly()
	stopFly()
	local hrp = getHRP()
	local hum = getHum()
	if not hrp or not hum then return end
	hum.PlatformStand = true
	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
	flyBV.Velocity = Vector3.new()
	flyBV.Name = "SpartaFlyBV"
	flyBV.Parent = hrp
	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
	flyBG.P = 1e5
	flyBG.D = 1e3
	flyBG.Name = "SpartaFlyBG"
	flyBG.CFrame = hrp.CFrame
	flyBG.Parent = hrp
end

local espObjects = {}

local function clearESP()
	for _, obj in pairs(espObjects) do
		for _, d in pairs(obj) do pcall(function() d:Remove() end) end
	end
	espObjects = {}
end

local function getPlayerESPColor(plr)
	if not cfg.TeamColor then return Color3.new(1,0.3,0.3) end
	if plr.Team and lp.Team and plr.Team == lp.Team then
		return Color3.new(0.3,1,0.5)
	end
	return Color3.new(1,0.3,0.3)
end

local function getCharBounds(char)
	local head = char:FindFirstChild("Head")
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then return nil, nil end
	local topPos = head and head.Position + Vector3.new(0, head.Size.Y/2, 0) or hrp.Position + Vector3.new(0, 3.5, 0)
	local botPos = hrp.Position - Vector3.new(0, 3, 0)
	return topPos, botPos
end

local function w2s(pos)
	local sp, onScreen = Camera:WorldToViewportPoint(pos)
	return Vector2.new(sp.X, sp.Y), onScreen, sp.Z
end

local function newDraw(type, props)
	local ok, d = pcall(Drawing.new, type)
	if not ok then return nil end
	d.Visible = false
	for k,v in pairs(props or {}) do
		pcall(function() d[k] = v end)
	end
	return d
end

local function getOrCreateESP(plr)
	if not espObjects[plr.Name] then
		espObjects[plr.Name] = {
			box     = newDraw("Square",  { Thickness=1.5, Filled=false }),
			boxTL   = newDraw("Line",    { Thickness=2 }),
			boxTR   = newDraw("Line",    { Thickness=2 }),
			boxBL   = newDraw("Line",    { Thickness=2 }),
			boxBR   = newDraw("Line",    { Thickness=2 }),
			boxTLv  = newDraw("Line",    { Thickness=2 }),
			boxTRv  = newDraw("Line",    { Thickness=2 }),
			boxBLv  = newDraw("Line",    { Thickness=2 }),
			boxBRv  = newDraw("Line",    { Thickness=2 }),
			name    = newDraw("Text",    { Size=13, Center=true, Outline=true }),
			dist    = newDraw("Text",    { Size=11, Center=true, Outline=true }),
			hpBg    = newDraw("Square",  { Filled=true, Color=Color3.new(0.1,0.1,0.1) }),
			hpFill  = newDraw("Square",  { Filled=true }),
			hpText  = newDraw("Text",    { Size=10, Center=true, Outline=true }),
			tracer  = newDraw("Line",    { Thickness=1 }),
		}
	end
	return espObjects[plr.Name]
end

local function hideESP(obj)
	for _, d in pairs(obj) do
		if d then pcall(function() d.Visible = false end) end
	end
end

local aimTarget = nil
local aimTimer2 = 0
local autoClickTimer2 = 0
local godModeConn = nil
local jumpConn = nil
local fallConn = nil
local originalAnims = {}

RunService.Heartbeat:Connect(function(dt)
	chromaT = chromaT + dt
	if chromaT >= 0.18 then
		chromaT = 0
		chromaI = (chromaI % #CHROMA) + 1
	end
	pcall(function() rootStroke.Color = getChroma() end)
	pcall(function() chromaTitle.TextColor3 = getChroma(1) end)
end)

RunService.Heartbeat:Connect(function(dt)
	local char = getChar()
	local hrp = getHRP()
	local hum = getHum()
	if not char or not hrp or not hum then return end

	if cfg.GodMode then
		if not godModeConn then
			hum.MaxHealth = math.huge
			hum.Health = math.huge
			godModeConn = hum.HealthChanged:Connect(function()
				pcall(function() hum.Health = hum.MaxHealth end)
			end)
		end
	else
		if godModeConn then godModeConn:Disconnect() godModeConn = nil end
	end

	if cfg.InfiniteJump then
		if not jumpConn then
			jumpConn = hum.StateChanged:Connect(function(_, new)
				if new == Enum.HumanoidStateType.Freefall and cfg.InfiniteJump then
					task.wait(0.1)
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end)
		end
	else
		if jumpConn then jumpConn:Disconnect() jumpConn = nil end
	end

	if cfg.NoFallDamage then
		if not fallConn then
			fallConn = hum.HealthChanged:Connect(function(newHp)
				local delta = hum.MaxHealth * 0.05
				if newHp < hum.MaxHealth - delta and not cfg.GodMode then
					pcall(function() hum.Health = hum.MaxHealth end)
				end
			end)
		end
	else
		if fallConn then fallConn:Disconnect() fallConn = nil end
	end

	if cfg.SpeedHack then
		pcall(function() hum.WalkSpeed = cfg.WalkSpeed end)
	else
		pcall(function()
			if hum.WalkSpeed ~= 16 and not cfg.Fly then hum.WalkSpeed = 16 end
		end)
	end

	if cfg.JumpPower and cfg.InfiniteJump then
		pcall(function() hum.JumpPower = cfg.JumpPower end)
	end

	if cfg.Noclip and not cfg.Fly then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then
				p.CanCollide = false
			end
		end
	end

	if cfg.NoAnimations then
		for _, t in ipairs(hum:GetPlayingAnimationTracks()) do
			t:Stop(0)
		end
	end

	if cfg.BunnyHop then
		if hum.FloorMaterial ~= Enum.Material.Air then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
	end

	if cfg.Rejoin then
		cfg.Rejoin = false
		pcall(function()
			TeleportService:Teleport(game.PlaceId, lp)
		end)
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if cfg.Fullbright then
		pcall(function()
			Lighting.Brightness = 2
			Lighting.ClockTime = cfg.TimeOfDay
			Lighting.FogEnd = 1e8
			Lighting.GlobalShadows = false
			Lighting.Ambient = Color3.new(1,1,1)
			Lighting.OutdoorAmbient = Color3.new(1,1,1)
		end)
	elseif cfg.NoFog then
		pcall(function() Lighting.FogEnd = 1e8 end)
	end

	if cfg.Fly then
		local hrp = getHRP()
		local hum = getHum()
		if not hrp or not hum then stopFly(); return end

		if not flyBV or not flyBG then startFly() end
		if not flyBV then return end

		hum.PlatformStand = true

		if cfg.FlyNoclip then
			for _, p in ipairs((getChar() or {Workspace}):GetDescendants()) do
				if p:IsA("BasePart") then p.CanCollide = false end
			end
		end

		local movDir = hum.MoveDirection
		local camCF = Camera.CFrame
		local flatForward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z).Unit
		local flatRight = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z).Unit

		local worldDir = Vector3.new()
		if movDir.Magnitude > 0.05 then
			worldDir = (flatForward * movDir.Z * -1 + flatRight * movDir.X).Unit
		end

		local upDown = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDown = 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.ButtonL2) then upDown = -1 end
		if hum.Jump then upDown = math.max(upDown, 0.8) end

		local targetVel = worldDir * cfg.FlySpeed + Vector3.new(0, upDown * cfg.VerticalSpeed, 0)

		if cfg.SmoothFly then
			local lerpFactor = math.clamp(dt * 10, 0, 1)
			currentVel = Vector3.new(
				lerp(currentVel.X, targetVel.X, lerpFactor),
				lerp(currentVel.Y, targetVel.Y, lerpFactor),
				lerp(currentVel.Z, targetVel.Z, lerpFactor)
			)
		else
			currentVel = targetVel
		end

		if cfg.AntiGravity and targetVel.Magnitude < 0.5 then
			currentVel = Vector3.new(currentVel.X * 0.85, 0, currentVel.Z * 0.85)
		end

		pcall(function()
			flyBV.Velocity = currentVel
			flyBG.CFrame = camCF
		end)
	else
		if flyBV or flyBG then stopFly() end
	end
end)

RunService.Heartbeat:Connect(function(dt)
	if cfg.HitboxExpand then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == lp then continue end
			if cfg.HitboxTeamCheck and lp.Team and plr.Team == lp.Team then continue end
			local c = plr.Character
			if not c then continue end
			if not cfg.HeadOnly then
				local hrp2 = c:FindFirstChild("HumanoidRootPart")
				if hrp2 then
					pcall(function()
						hrp2.Size = Vector3.new(cfg.HitboxSize, cfg.HitboxSize, cfg.HitboxSize)
						hrp2.Transparency = 0.5
					end)
				end
			end
			local head = c:FindFirstChild("Head")
			if head then
				pcall(function()
					head.Size = Vector3.new(cfg.HeadSize, cfg.HeadSize, cfg.HeadSize)
					head.Transparency = 0.5
				end)
			end
		end
	end
end)

RunService.Heartbeat:Connect(function(dt)
	aimTimer2 = aimTimer2 + dt
	if aimTimer2 < 0.2 then return end
	aimTimer2 = 0

	if not cfg.SilentAim and not cfg.AimLock then
		aimTarget = nil
		return
	end

	local hrp = getHRP()
	if not hrp then aimTarget = nil; return end

	local vp = Camera.ViewportSize
	local center = Vector2.new(vp.X/2, vp.Y/2)
	local bestDist = cfg.FOVSize
	local bestPlayer = nil
	local bestHead = nil

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == lp then continue end
		if cfg.TeamCheck and lp.Team and plr.Team == lp.Team then continue end
		local c = plr.Character
		if not c then continue end
		local phum = c:FindFirstChildOfClass("Humanoid")
		if not phum or phum.Health <= 0 then continue end
		local head = c:FindFirstChild("Head")
		local phrp = c:FindFirstChild("HumanoidRootPart")
		local target = head or phrp
		if not target then continue end

		local vel = Vector3.new()
		if cfg.Prediction and phrp then
			pcall(function() vel = phrp.Velocity * (cfg.PredictionStrength / 500) end)
		end
		local predictedPos = target.Position + vel

		if cfg.VisibleCheck then
			local rayParams = RaycastParams.new()
			rayParams.FilterDescendantsInstances = { getChar(), c }
			rayParams.FilterType = Enum.RaycastFilterType.Exclude
			local result = Workspace:Raycast(Camera.CFrame.Position, (predictedPos - Camera.CFrame.Position).Unit * 5000, rayParams)
			if result then continue end
		end

		local sp, onScreen = Camera:WorldToViewportPoint(predictedPos)
		if not onScreen then continue end
		local screenPos2D = Vector2.new(sp.X, sp.Y)
		local dist2D = (screenPos2D - center).Magnitude

		if dist2D < bestDist then
			bestDist = dist2D
			bestPlayer = plr
			bestHead = target
		end
	end

	aimTarget = bestHead

	if cfg.AimLock and bestHead then
		local smooth = math.clamp(1 - (cfg.Smoothness / 100) * 0.95, 0.02, 1)
		local targetCF = CFrame.new(Camera.CFrame.Position, bestHead.Position)
		Camera.CFrame = Camera.CFrame:Lerp(targetCF, smooth)
	end
end)

pcall(function()
	local mm = getrawmetatable(mouse)
	local oldIndex = mm.__index
	setreadonly(mm, false)
	mm.__index = newcclosure(function(self, key)
		if (key == "Hit" or key == "Target") and cfg.SilentAim and aimTarget then
			if key == "Hit" then
				return CFrame.new(aimTarget.Position)
			elseif key == "Target" then
				return aimTarget
			end
		end
		return oldIndex(self, key)
	end)
	setreadonly(mm, true)
end)

RunService.RenderStepped:Connect(function()
	local hrp = getHRP()

	local anyESP = cfg.PlayerESP or cfg.BoxESP or cfg.CornerBox or cfg.NameESP or cfg.DistanceESP or cfg.HealthBar or cfg.Tracers or cfg.SkeletonESP

	if not anyESP then clearESP(); return end

	local rendered = {}

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == lp then continue end
		local c = plr.Character
		if not c then continue end
		local phum = c:FindFirstChildOfClass("Humanoid")
		if not phum then continue end
		local phrp = c:FindFirstChild("HumanoidRootPart")
		if not phrp then continue end

		local dist = hrp and (phrp.Position - hrp.Position).Magnitude or 0
		if dist > cfg.ESPMaxDist then continue end

		local topPos, botPos = getCharBounds(c)
		if not topPos or not botPos then continue end

		local topSP, topOnScreen, topZ = w2s(topPos)
		local botSP, botOnScreen = w2s(botPos)

		if not topOnScreen and not botOnScreen then continue end
		if topZ < 0 then continue end

		rendered[plr.Name] = true
		local obj = getOrCreateESP(plr)
		local espColor = getPlayerESPColor(plr)

		local boxW = math.abs(topSP.X - botSP.X) + math.clamp(500 / dist, 8, 60)
		local boxH = math.abs(topSP.Y - botSP.Y)
		local boxX = topSP.X - boxW/2
		local boxY = topSP.Y

		if (cfg.BoxESP) and obj.box then
			obj.box.Visible = true
			obj.box.Color = espColor
			obj.box.Position = Vector2.new(boxX, boxY)
			obj.box.Size = Vector2.new(boxW, boxH)
			obj.box.Transparency = 0.15
		elseif obj.box then obj.box.Visible = false end

		if cfg.CornerBox then
			local cLen = boxW * 0.25
			local pairs2 = {
				{ obj.boxTL, Vector2.new(boxX, boxY), Vector2.new(boxX+cLen, boxY) },
				{ obj.boxTLv, Vector2.new(boxX, boxY), Vector2.new(boxX, boxY+cLen) },
				{ obj.boxTR, Vector2.new(boxX+boxW, boxY), Vector2.new(boxX+boxW-cLen, boxY) },
				{ obj.boxTRv, Vector2.new(boxX+boxW, boxY), Vector2.new(boxX+boxW, boxY+cLen) },
				{ obj.boxBL, Vector2.new(boxX, boxY+boxH), Vector2.new(boxX+cLen, boxY+boxH) },
				{ obj.boxBLv, Vector2.new(boxX, boxY+boxH), Vector2.new(boxX, boxY+boxH-cLen) },
				{ obj.boxBR, Vector2.new(boxX+boxW, boxY+boxH), Vector2.new(boxX+boxW-cLen, boxY+boxH) },
				{ obj.boxBRv, Vector2.new(boxX+boxW, boxY+boxH), Vector2.new(boxX+boxW, boxY+boxH-cLen) },
			}
			for _, pair in ipairs(pairs2) do
				if pair[1] then
					pair[1].Visible = true
					pair[1].Color = espColor
					pair[1].From = pair[2]
					pair[1].To = pair[3]
				end
			end
		else
			for _, key in ipairs({"boxTL","boxTR","boxBL","boxBR","boxTLv","boxTRv","boxBLv","boxBRv"}) do
				if obj[key] then obj[key].Visible = false end
			end
		end

		if cfg.NameESP and obj.name then
			obj.name.Visible = true
			obj.name.Text = plr.DisplayName ~= plr.Name and (plr.DisplayName .. " [" .. plr.Name .. "]") or plr.Name
			obj.name.Color = espColor
			obj.name.Position = Vector2.new(topSP.X, topSP.Y - 16)
			obj.name.Size = math.clamp(14 - dist/200, 9, 14)
		elseif obj.name then obj.name.Visible = false end

		if cfg.DistanceESP and obj.dist then
			obj.dist.Visible = true
			obj.dist.Text = string.format("[%.0fst]", dist)
			obj.dist.Color = Color3.new(0.7,0.7,0.7)
			obj.dist.Position = Vector2.new(topSP.X, topSP.Y - (cfg.NameESP and 28 or 16))
			obj.dist.Size = 10
		elseif obj.dist then obj.dist.Visible = false end

		if cfg.HealthBar and phum and obj.hpBg and obj.hpFill then
			local hpPct = math.clamp(phum.Health / phum.MaxHealth, 0, 1)
			local barX = boxX - 6
			local barW = 4
			obj.hpBg.Visible = true
			obj.hpBg.Position = Vector2.new(barX, boxY)
			obj.hpBg.Size = Vector2.new(barW, boxH)
			obj.hpFill.Visible = true
			obj.hpFill.Position = Vector2.new(barX, boxY + boxH * (1-hpPct))
			obj.hpFill.Size = Vector2.new(barW, boxH * hpPct)
			obj.hpFill.Color = Color3.fromHSV(hpPct * 0.33, 1, 1)
		elseif obj.hpBg then obj.hpBg.Visible = false; if obj.hpFill then obj.hpFill.Visible = false end end

		if cfg.HealthText and phum and obj.hpText then
			obj.hpText.Visible = true
			obj.hpText.Text = tostring(math.floor(phum.Health))
			obj.hpText.Color = Color3.new(1,1,1)
			obj.hpText.Position = Vector2.new(boxX - 8, boxY + boxH/2)
			obj.hpText.Size = 9
		elseif obj.hpText then obj.hpText.Visible = false end

		if cfg.Tracers and obj.tracer then
			obj.tracer.Visible = true
			obj.tracer.Color = espColor
			obj.tracer.Transparency = 0.4
			obj.tracer.From = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
			obj.tracer.To = Vector2.new(botSP.X, botSP.Y)
		elseif obj.tracer then obj.tracer.Visible = false end

		if cfg.Chams then
			for _, part in ipairs(c:GetDescendants()) do
				if part:IsA("BasePart") and not part:FindFirstChildOfClass("SelectionBox") then
					pcall(function()
						local sb = Instance.new("SelectionBox")
						sb.Adornee = part
						sb.Color3 = espColor
						sb.LineThickness = 0.08
						sb.SurfaceTransparency = 0.6
						sb.SurfaceColor3 = espColor
						sb.Name = "SpartaChams"
						sb.Parent = part
					end)
				end
			end
		else
			for _, part in ipairs(c:GetDescendants()) do
				if part:IsA("SelectionBox") and part.Name == "SpartaChams" then
					part:Destroy()
				end
			end
		end
	end

	for name, obj in pairs(espObjects) do
		if not rendered[name] then hideESP(obj) end
	end
end)

RunService.Heartbeat:Connect(function(dt)
	autoClickTimer2 = autoClickTimer2 + dt
	if not cfg.AutoClick then return end

	local cps = cfg.CPS
	if cfg.RandomizeCPS then
		cps = cps * (1 + (math.random()-0.5) * cfg.RandomRange/100 * 2)
	end
	local interval = 1 / math.max(cps, 0.5)

	if autoClickTimer2 >= interval then
		autoClickTimer2 = 0

		if cfg.JitterAim then
			local hrp = getHRP()
			if hrp then
				pcall(function()
					Camera.CFrame = Camera.CFrame * CFrame.Angles(
						(math.random()-0.5) * math.rad(cfg.JitterStrength * 0.1),
						(math.random()-0.5) * math.rad(cfg.JitterStrength * 0.1),
						0
					)
				end)
			end
		end

		pcall(function()
			VirtualUser:ClickButton1(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), CFrame.new())
		end)
	end
end)

local fovCircle = nil
RunService.RenderStepped:Connect(function()
	if cfg.FOVCircle and (cfg.SilentAim or cfg.AimLock) then
		if not fovCircle then
			fovCircle = newDraw("Circle", { Thickness=1, Filled=false, NumSides=64 })
		end
		if fovCircle then
			fovCircle.Visible = true
			fovCircle.Radius = cfg.FOVSize
			fovCircle.Position = Camera.ViewportSize / 2
			fovCircle.Color = Color3.new(1,1,1)
			fovCircle.Transparency = 0.7
		end
	else
		if fovCircle then fovCircle.Visible = false end
	end
end)

if cfg.AntiAFK then
	lp.Idled:Connect(function()
		pcall(function()
			VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
			task.wait(0.5)
			VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
		end)
	end)
end

lp.CharacterAdded:Connect(function(newChar)
	godModeConn = nil; jumpConn = nil; fallConn = nil
	flyBV = nil; flyBG = nil; currentVel = Vector3.new()
	task.wait(0.5)

	local newHum = newChar:WaitForChild("Humanoid")
	if cfg.GodMode then
		newHum.MaxHealth = math.huge
		newHum.Health = math.huge
	end
end)

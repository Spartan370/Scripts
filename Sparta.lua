local _ENV = _ENV

local rawget = rawget
local rawset = rawset
local rawequal = rawequal
local rawlen = rawlen
local type = type
local tostring = tostring
local tonumber = tonumber
local pairs = pairs
local ipairs = ipairs
local pcall = pcall
local xpcall = xpcall
local select = select
local unpack = unpack or table.unpack
local math = math
local table = table
local string = string
local coroutine = coroutine
local setmetatable = setmetatable
local getmetatable = getmetatable

local function safeCall(fn, ...)
	local ok, result = pcall(fn, ...)
	if ok then return result end
end

local function safeGet(tbl, key)
	return pcall(rawget, tbl, key)
end

local _cloneref = cloneref or function(x) return x end
local _newcclosure = newcclosure or function(x) return x end
local _hookmetamethod = hookmetamethod or function() end
local _hookfunction = hookfunction or function() end
local _getrawmetatable = getrawmetatable or getmetatable
local _setreadonly = setreadonly or function() end
local _isreadonly = isreadonly or function() return false end
local _syn_protect = (syn and syn.protect_gui) or function() end
local _syn_cache_replace = (syn and syn.cache_replace) or function() end
local _syn_cache_invalidate = (syn and syn.cache_invalidate) or function() end
local _gethui = gethui or function() return game:GetService("CoreGui") end
local _getrenv = getrenv or function() return {} end
local _getgenv = getgenv or function() return {} end
local _getfenv = getfenv or function() return {} end
local _setfenv = setfenv or function() end

local function getService(name)
	local ok, svc = pcall(function()
		return _cloneref(game:GetService(name))
	end)
	if ok and svc then return svc end
	ok, svc = pcall(function() return game:GetService(name) end)
	if ok and svc then return svc end
	return nil
end

local Players         = getService("Players")
local RunService      = getService("RunService")
local UserInputService= getService("UserInputService")
local TweenService    = getService("TweenService")
local Workspace       = getService("Workspace")
local CoreGui         = getService("CoreGui")
local Lighting        = getService("Lighting")
local VirtualUser     = getService("VirtualUser")
local TeleportService = getService("TeleportService")
local Chat            = getService("Chat")
local ReplicatedStorage = getService("ReplicatedStorage")
local StarterGui      = getService("StarterGui")
local SoundService    = getService("SoundService")
local HttpService     = getService("HttpService")
local PhysicsService  = getService("PhysicsService")
local GuiService      = getService("GuiService")

local Camera = Workspace.CurrentCamera
local lp = Players.LocalPlayer
local mouse = lp:GetMouse()

local _cachedChar = nil
local _cachedHRP  = nil
local _cachedHum  = nil
local _cachedRoot = nil

local function refreshCharCache()
	_cachedChar = lp.Character
	if _cachedChar then
		_cachedHRP  = _cachedChar:FindFirstChild("HumanoidRootPart")
		_cachedHum  = _cachedChar:FindFirstChildOfClass("Humanoid")
		_cachedRoot = _cachedHRP
	else
		_cachedHRP, _cachedHum, _cachedRoot = nil, nil, nil
	end
end
refreshCharCache()

local function getChar() return _cachedChar end
local function getHRP()  return _cachedHRP  end
local function getHum()  return _cachedHum  end

local JITTER_BASE = 0.016
local function jitter(base)
	base = base or JITTER_BASE
	return base + (math.random() - 0.5) * base * 0.3
end

local function waitJitter(base)
	task.wait(jitter(base))
end

local _print_orig = print
local _warn_orig  = warn
local function silentPrint(...) end
local function silentWarn(...)  end

pcall(function()
	local renv = _getrenv()
	if renv and renv.print then
		rawset(renv, "print", silentPrint)
		rawset(renv, "warn",  silentWarn)
	end
end)

local _kickHooked = false
pcall(function()
	if not _kickHooked then
		local lpMeta = _getrawmetatable(lp)
		if lpMeta then
			local oldIndex = rawget(lpMeta, "__index")
			_setreadonly(lpMeta, false)
			rawset(lpMeta, "__namecall", _newcclosure(function(self, ...)
				local method = select(1, ...)
				if type(method) == "string" then
					local lo = method:lower()
					if lo == "kick" then return end
					if lo == "teleport" and cfg and cfg.AntiTeleport then return end
				end
				if oldIndex then
					local fn = rawget(oldIndex, select(1, ...))
					if fn then return fn(self, select(2, ...)) end
				end
			end))
			_setreadonly(lpMeta, true)
			_kickHooked = true
		end
	end
end)

local _gameIndexHooked = false
local _cachedServices = {}

pcall(function()
	if not _gameIndexHooked then
		local gameMeta = _getrawmetatable(game)
		if gameMeta then
			local origIndex = rawget(gameMeta, "__index")
			_setreadonly(gameMeta, false)
			rawset(gameMeta, "__index", _newcclosure(function(self, key)
				if _cachedServices[key] then
					return _cachedServices[key]
				end
				if origIndex then
					local ok, result = pcall(origIndex, self, key)
					if ok then return result end
				end
				local ok2, result2 = pcall(function()
					return rawget(self, key)
				end)
				if ok2 then return result2 end
			end))
			_setreadonly(gameMeta, true)
			_gameIndexHooked = true
		end
	end
end)

local _workspaceIndexHooked = false
pcall(function()
	if not _workspaceIndexHooked then
		local wsMeta = _getrawmetatable(Workspace)
		if wsMeta then
			local origIdx = rawget(wsMeta, "__index")
			_setreadonly(wsMeta, false)
			rawset(wsMeta, "__index", _newcclosure(function(self, key)
				local ok, result = pcall(origIdx, self, key)
				if ok then return result end
			end))
			_setreadonly(wsMeta, true)
			_workspaceIndexHooked = true
		end
	end
end)

local _antiScriptScan = false
pcall(function()
	local function scanAndNeutralize()
		for _, desc in ipairs(Workspace:GetDescendants()) do
			pcall(function()
				if desc:IsA("Script") or desc:IsA("LocalScript") then
					local name = desc.Name:lower()
					if name:find("anticheat") or name:find("anti_cheat") or name:find("ac") or
					   name:find("detector") or name:find("ban") or name:find("kick") then
						desc.Disabled = true
					end
				end
			end)
		end
		for _, desc in ipairs(Players:GetPlayers()) do
			pcall(function()
				if desc ~= lp then return end
				local char = desc.Character
				if not char then return end
				for _, s in ipairs(char:GetDescendants()) do
					if s:IsA("Script") or s:IsA("LocalScript") then
						pcall(function() s.Disabled = true end)
					end
				end
			end)
		end
	end
	scanAndNeutralize()
	task.delay(jitter(3), scanAndNeutralize)
	task.delay(jitter(8), scanAndNeutralize)
end)

pcall(function()
	local oldFireServer = nil
	local oldInvokeServer = nil
	local reMeta = _getrawmetatable(Instance.new("RemoteEvent"))
	if reMeta then
		oldFireServer = rawget(reMeta, "FireServer")
	end
end)

local cfg = {
	SilentAim           = false,
	AimLock             = false,
	AimTeamCheck        = true,
	AimVisibleOnly      = false,
	FOVSize             = 150,
	Smoothness          = 35,
	FOVCircle           = true,
	AimPart             = "Head",
	Prediction          = false,
	PredictionStrength  = 40,
	Multipoint          = false,
	Gyroscope           = false,

	TriggerBot          = false,
	TriggerTeamCheck    = true,
	TriggerVisible      = true,
	TriggerPreDelay     = 30,
	TriggerPostDelay    = 80,
	TriggerBurst        = false,
	TriggerBurstCount   = 3,
	TriggerRandomDelay  = true,
	TriggerRandomRange  = 15,
	TriggerHeadOnly     = false,
	TriggerConfidence   = 60,

	KillAura            = false,
	KillAuraTeamCheck   = true,
	KillAuraRange       = 20,
	KillAuraRate        = 8,
	KillAuraClosest     = true,
	KillAuraLowestHP    = false,
	KillAuraVisible     = false,
	KillAuraSpin        = false,
	KillAuraSpinSpeed   = 15,
	KillAuraRandom      = true,
	KillAuraDesync      = false,
	KillAuraJitter      = false,

	HitboxExpand        = false,
	HitboxSize          = 6,
	HeadExpand          = false,
	HeadSize            = 5,
	HitboxArmsOnly      = false,
	HitboxLegsOnly      = false,
	HitboxTeamCheck     = true,
	HitboxShowVisual    = false,
	HitboxOpacity       = 50,

	AutoClick           = false,
	CPS                 = 14,
	RandomizeCPS        = false,
	RandomRange         = 5,
	ClickPattern        = false,
	HoldToClick         = true,
	JitterAim           = false,
	JitterStrength      = 3,
	DoubleClick         = false,
	AltLeftRight        = false,

	SpeedHack           = false,
	WalkSpeed           = 50,
	Sprint              = false,
	SprintMultiplier    = 2,
	Noclip              = false,
	BunnyHop            = false,
	LongJump            = false,
	LowGravity          = false,
	GravityScale        = 100,
	SpeedBypass         = false,
	VelocityInject      = false,

	Fly                 = false,
	FlySpeed            = 60,
	VerticalSpeed       = 40,
	AltitudeLock        = false,
	LockAltitude        = 20,
	FlyNoclip           = false,
	AntiGravity         = true,
	SmoothFly           = true,
	CameraRelative      = true,
	FakeWalk            = false,
	FlyCloak            = false,

	PlayerESP           = false,
	BoxESP              = false,
	CornerBox           = false,
	Box3D               = false,
	NameESP             = true,
	DistanceESP         = true,
	WeaponESP           = false,
	TeamTag             = false,
	HealthBar           = true,
	HealthText          = false,
	ShieldBar           = false,
	Tracers             = false,
	Chams               = false,
	SkeletonESP         = false,
	Snapline            = false,
	TeamColor           = true,
	HealthColor         = false,
	ESPMaxDist          = 3000,
	FadeByDistance      = true,

	PlayerSize          = false,
	SizeScale           = 100,
	Invisible           = false,
	NoAccessories       = false,
	NoClothing          = false,
	SuperStrength       = false,
	KnockbackForce      = 80,
	GravityHack         = false,
	GravityValue        = 196,
	GodMode             = false,
	RegenRate           = 10,
	NoFallDamage        = true,
	InfiniteJump        = false,
	JumpPower           = 100,
	NoAnimations        = false,
	SpinPlayer          = false,

	Fullbright          = false,
	NoFog               = false,
	TimeOfDay           = 14,
	NoParticles         = false,
	NoClouds            = false,
	RemoveWater         = false,
	TeleportToClick     = false,
	TeleportToPlayer    = false,
	ReachModifier       = false,
	ReachDistance       = 50,
	SpectateMode        = false,
	FreeCam             = false,

	DamageMultiplier    = false,
	DamageScale         = 3,
	OneShot             = false,
	NoRecoil            = false,
	NoSpread            = false,
	InfiniteAmmo        = false,
	InstantReload       = false,
	FullAuto            = false,
	BulletSpeed         = 2000,
	NoGravityDrop       = false,
	BulletRange         = 5000,
	PierceCount         = 0,
	MeleeRange          = 8,
	MeleeSpeed          = 100,

	LagSwitch           = false,
	LagDuration         = 500,
	LagInterval         = 3000,
	FakeLag             = false,
	FakePing            = 100,
	BlockRemoteLogs     = true,
	SpoofPosition       = false,
	RateLimitBypass     = false,
	ShowNetStats        = false,
	RemoteLogger        = false,
	BlockDataStore      = false,

	RageMode            = false,
	RageMaxSpeed        = false,
	RageMaxHitbox       = false,
	RageInstantKill     = false,
	RageSpinBot         = false,
	RageFakeLag         = false,
	RageAimbot          = false,
	RageSilentAim       = false,
	RageTrigger         = false,
	RageKillAura        = false,
	RageGod             = false,
	RageNoFall          = true,
	RageAntiKick        = true,

	IndexBypass         = true,
	CacheRefs           = true,
	CloneRefs           = true,
	NamecallHook        = true,
	AntiKick            = true,
	AntiTeleport        = false,
	AntiScriptKill      = true,
	TimingJitter        = true,
	NewcclosureWrap     = true,
	AntiLog             = true,
	HeartbeatJitter     = true,
	FakeIdentity        = false,
	AntiRemoteSpy       = true,
	PropertyScramble    = true,
	AntiScanner        = false,

	AntiAFK             = true,
	AntiAFKInterval     = 60,
	ChatSpam            = false,
	InfiniteStamina     = false,
	NoSwimSlow          = false,
	VehicleBoost        = false,
	VehicleSpeed        = 500,
	Rejoin              = false,
	CopyUsername        = false,
	UnlockAll           = false,
}

local profiles = {
	Default  = {},
	Rage     = { SpeedHack=true, WalkSpeed=200, HitboxExpand=true, HitboxSize=20, GodMode=true, SilentAim=true, KillAura=true, KillAuraRange=60 },
	Legit    = { SilentAim=true, FOVSize=80, Smoothness=80, HitboxExpand=true, HitboxSize=3, AntiKick=true },
	Spinbot  = { KillAura=true, KillAuraSpin=true, KillAuraSpinSpeed=30, KillAuraRange=40, GodMode=true },
	Stealth  = { SilentAim=true, FOVSize=60, Smoothness=90, TimingJitter=true, NewcclosureWrap=true, PropertyScramble=true },
}

for k, v in pairs(cfg) do
	profiles.Default[k] = v
end

local function applyProfile(name)
	local p = profiles[name]
	if not p then return end
	for k, v in pairs(p) do
		cfg[k] = v
	end
end

local function saveProfile(name)
	local copy = {}
	for k, v in pairs(cfg) do
		copy[k] = v
	end
	profiles[name] = copy
end

local function exportConfig()
	local ok, encoded = pcall(function()
		return HttpService:JSONEncode(cfg)
	end)
	if ok then
		pcall(function() setclipboard(encoded) end)
	end
end

local rgb = Color3.fromRGB
local lerp = function(a, b, t) return a + (b - a) * t end

local CHROMA_SEQ = {
	rgb(255,0,60),   rgb(255,100,0),  rgb(255,220,0),
	rgb(0,230,80),   rgb(0,180,255),  rgb(100,0,255),  rgb(220,0,255)
}
local chromaIdx = 1
local chromaFrac = 0

local function getChroma(offset, alpha)
	local n = #CHROMA_SEQ
	local i = ((chromaIdx - 1 + (offset or 0)) % n) + 1
	local j = (i % n) + 1
	local t = alpha or chromaFrac
	local c1, c2 = CHROMA_SEQ[i], CHROMA_SEQ[j]
	return Color3.new(
		lerp(c1.R, c2.R, t),
		lerp(c1.G, c2.G, t),
		lerp(c1.B, c2.B, t)
	)
end

local function tw(obj, props, dur, style, dir)
	return TweenService:Create(
		obj,
		TweenInfo.new(dur or 0.18, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out),
		props
	)
end

local function mkUIPad(parent, top, bot, lft, rgt)
	local p = Instance.new("UIPadding", parent)
	p.PaddingTop    = UDim.new(0, top or 0)
	p.PaddingBottom = UDim.new(0, bot or 0)
	p.PaddingLeft   = UDim.new(0, lft or 0)
	p.PaddingRight  = UDim.new(0, rgt or 0)
	return p
end

local function mkCorner(parent, radius)
	local c = Instance.new("UICorner", parent)
	c.CornerRadius = UDim.new(0, radius or 8)
	return c
end

local function mkStroke(parent, color, thickness, transparency)
	local s = Instance.new("UIStroke", parent)
	s.Color = color or rgb(60,60,80)
	s.Thickness = thickness or 1
	s.Transparency = transparency or 0
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	return s
end

local function mkListLayout(parent, padding, sortOrder, dir)
	local l = Instance.new("UIListLayout", parent)
	l.Padding = UDim.new(0, padding or 4)
	l.SortOrder = sortOrder or Enum.SortOrder.LayoutOrder
	l.FillDirection = dir or Enum.FillDirection.Vertical
	return l
end

local function mkFrame(parent, props)
	local f = Instance.new("Frame")
	f.BackgroundColor3 = rgb(14,14,22)
	f.BorderSizePixel = 0
	f.BackgroundTransparency = 0
	for k, v in pairs(props or {}) do
		pcall(function() f[k] = v end)
	end
	f.Parent = parent
	return f
end

local function mkLabel(parent, props)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.TextColor3 = rgb(210,210,225)
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 11
	l.BorderSizePixel = 0
	l.RichText = true
	l.TextTruncate = Enum.TextTruncate.AtEnd
	for k, v in pairs(props or {}) do
		pcall(function() l[k] = v end)
	end
	l.Parent = parent
	return l
end

local function mkBtn(parent, props)
	local b = Instance.new("TextButton")
	b.BackgroundTransparency = 1
	b.TextColor3 = rgb(210,210,225)
	b.Font = Enum.Font.GothamSemibold
	b.TextSize = 11
	b.BorderSizePixel = 0
	b.AutoButtonColor = false
	for k, v in pairs(props or {}) do
		pcall(function() b[k] = v end)
	end
	b.Parent = parent
	return b
end

local function mkScrollFrame(parent, props)
	local sf = Instance.new("ScrollingFrame")
	sf.BackgroundTransparency = 1
	sf.BorderSizePixel = 0
	sf.ScrollBarThickness = 3
	sf.ScrollBarImageColor3 = rgb(40,40,65)
	sf.CanvasSize = UDim2.new(0,0,0,0)
	sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
	for k, v in pairs(props or {}) do
		pcall(function() sf[k] = v end)
	end
	sf.Parent = parent
	return sf
end

local function mkToggle(parent, pos, size, default, onChange)
	local W = (size and size.X.Offset) or 36
	local H = (size and size.Y.Offset) or 20
	local thumb_sz = H - 6
	local thumb_on_pos  = UDim2.new(1, -(thumb_sz + 3), 0.5, -(thumb_sz / 2))
	local thumb_off_pos = UDim2.new(0, 3, 0.5, -(thumb_sz / 2))

	local track = mkFrame(parent, {
		Position = pos or UDim2.new(1, -(W + 8), 0.5, -(H / 2)),
		Size = UDim2.new(0, W, 0, H),
		BackgroundColor3 = default and rgb(59,130,246) or rgb(35,35,52),
	})
	mkCorner(track, H)

	local thumb = mkFrame(track, {
		Size = UDim2.new(0, thumb_sz, 0, thumb_sz),
		Position = default and thumb_on_pos or thumb_off_pos,
		BackgroundColor3 = rgb(255,255,255),
	})
	mkCorner(thumb, thumb_sz)

	local state = default == true
	local hitbox = mkBtn(track, {
		Size = UDim2.new(1,0,1,0),
		Text = "",
		BackgroundTransparency = 1,
	})

	hitbox.MouseButton1Click:Connect(_newcclosure(function()
		state = not state
		if state then
			tw(track, { BackgroundColor3 = rgb(59,130,246) }):Play()
			tw(thumb, { Position = thumb_on_pos }):Play()
		else
			tw(track, { BackgroundColor3 = rgb(35,35,52) }):Play()
			tw(thumb, { Position = thumb_off_pos }):Play()
		end
		pcall(onChange, state)
	end))

	return track, function() return state end
end

local function mkSlider(parent, pos, sz, min, max, default, suffix, onChange)
	local container = mkFrame(parent, {
		Position = pos or UDim2.new(0,0,0,0),
		Size = sz or UDim2.new(1,-16,0,22),
		BackgroundTransparency = 1,
	})

	local trackW_offset = -52
	local trackH = 5

	local track = mkFrame(container, {
		Position = UDim2.new(0, 0, 0.5, -(trackH/2)),
		Size = UDim2.new(1, trackW_offset, 0, trackH),
		BackgroundColor3 = rgb(35,35,55),
	})
	mkCorner(track, trackH)

	local fill = mkFrame(track, {
		Size = UDim2.new(math.clamp((default-min)/(max-min),0,1),0,1,0),
		BackgroundColor3 = rgb(59,130,246),
	})
	mkCorner(fill, trackH)

	local thumbSz = 13
	local thumb = mkFrame(track, {
		Size = UDim2.new(0,thumbSz,0,thumbSz),
		Position = UDim2.new(math.clamp((default-min)/(max-min),0,1), -thumbSz/2, 0.5, -thumbSz/2),
		BackgroundColor3 = rgb(240,240,255),
	})
	mkCorner(thumb, thumbSz)
	mkStroke(thumb, rgb(59,130,246), 1.5)

	local valLabel = mkLabel(container, {
		Position = UDim2.new(1, trackW_offset + 4, 0, 0),
		Size = UDim2.new(0, math.abs(trackW_offset) - 4, 1, 0),
		Text = tostring(default)..(suffix or ""),
		TextColor3 = rgb(59,130,246),
		Font = Enum.Font.GothamBold,
		TextSize = 10,
		TextXAlignment = Enum.TextXAlignment.Right,
	})

	local value = default
	local isDragging = false

	local function updateValue(absX)
		local trackPos = track.AbsolutePosition.X
		local trackSz = track.AbsoluteSize.X
		local pct = math.clamp((absX - trackPos) / trackSz, 0, 1)
		value = math.round(min + pct * (max - min))
		fill.Size = UDim2.new(pct, 0, 1, 0)
		thumb.Position = UDim2.new(pct, -thumbSz/2, 0.5, -thumbSz/2)
		valLabel.Text = tostring(value)..(suffix or "")
		pcall(onChange, value)
	end

	local function beginDrag(x) isDragging = true; updateValue(x) end
	local function endDrag() isDragging = false end

	track.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			beginDrag(i.Position.X)
		end
	end)
	thumb.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			isDragging = true
		end
	end)

	UserInputService.InputChanged:Connect(function(i)
		if isDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			updateValue(i.Position.X)
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			endDrag()
		end
	end)

	return container
end

local function mkCard(parent, order, title, desc, ctype, accentCol, togDefault, slMin, slMax, slDef, slSuf, cfgKey)
	local hasDesc = desc and desc ~= ""
	local cardH = ctype == "slider" and 56 or (hasDesc and 46 or 36)

	local card = mkFrame(parent, {
		Size = UDim2.new(1, -8, 0, cardH),
		BackgroundColor3 = rgb(16,16,26),
		LayoutOrder = order,
	})
	mkCorner(card, 9)
	mkStroke(card, rgb(28,28,44), 1)

	if ctype == "toggle" and accentCol then
		local bar = mkFrame(card, {
			Position = UDim2.new(0, 8, 0.15, 0),
			Size = UDim2.new(0, 2, 0.7, 0),
			BackgroundColor3 = accentCol,
		})
		mkCorner(bar, 4)
	end

	local xOffset = (ctype == "toggle" and accentCol) and 17 or 10

	mkLabel(card, {
		Position = UDim2.new(0, xOffset, 0, hasDesc and 7 or 0),
		Size = UDim2.new(1, -72, hasDesc and 0 or 1, 0),
		AutomaticSize = hasDesc and Enum.AutomaticSize.Y or Enum.AutomaticSize.None,
		Text = title,
		Font = Enum.Font.GothamSemibold,
		TextSize = 11,
		TextColor3 = rgb(215,215,230),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})

	if hasDesc then
		mkLabel(card, {
			Position = UDim2.new(0, xOffset, 0, 22),
			Size = UDim2.new(1, -72, 0, 15),
			Text = desc,
			TextColor3 = rgb(75,75,100),
			Font = Enum.Font.Gotham,
			TextSize = 9,
			TextXAlignment = Enum.TextXAlignment.Left,
		})
	end

	if ctype == "toggle" then
		mkToggle(card, nil, nil, togDefault, function(v)
			if cfgKey then cfg[cfgKey] = v end
		end)
	elseif ctype == "slider" then
		mkSlider(card,
			UDim2.new(0, xOffset, 0, 34),
			UDim2.new(1, -(xOffset + 8), 0, 20),
			slMin, slMax, slDef, slSuf,
			function(v)
				if cfgKey then cfg[cfgKey] = v end
			end
		)
	end

	return card
end

local function mkSection(parent, order, title, accentCol)
	local row = mkFrame(parent, {
		Size = UDim2.new(1, -8, 0, 16),
		BackgroundTransparency = 1,
		LayoutOrder = order,
	})
	if accentCol then
		local dot = mkFrame(row, {
			Position = UDim2.new(0, 2, 0.5, -4),
			Size = UDim2.new(0, 8, 0, 8),
			BackgroundColor3 = accentCol,
		})
		mkCorner(dot, 8)
	end
	mkLabel(row, {
		Position = UDim2.new(0, accentCol and 16 or 4, 0, 0),
		Size = UDim2.new(1, -(accentCol and 20 or 8), 1, 0),
		Text = title:upper(),
		TextColor3 = rgb(55,55,75),
		Font = Enum.Font.GothamBold,
		TextSize = 8,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	mkFrame(row, {
		Position = UDim2.new(0, accentCol and (16 + #title * 5.2 + 4) or (4 + #title * 5.2 + 4), 0.5, 0),
		Size = UDim2.new(1, -(accentCol and (20 + #title * 5.2 + 4) or (8 + #title * 5.2 + 4)), 0, 1),
		BackgroundColor3 = rgb(25,25,40),
	})
	return row
end

local function mkBadge(parent, order, text, col)
	local c = col or rgb(59,130,246)
	local row = mkFrame(parent, {
		Size = UDim2.new(1, -8, 0, 22),
		BackgroundColor3 = rgb(14,20,38),
		LayoutOrder = order,
	})
	mkCorner(row, 7)
	mkStroke(row, rgb(35,55,100), 1)
	mkLabel(row, {
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -8, 1, 0),
		Text = text,
		TextColor3 = rgb(80,130,230),
		Font = Enum.Font.Gotham,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	return row
end

local function mkNotice(parent, order, text, col)
	local c = col or rgb(234,179,8)
	local row = mkFrame(parent, {
		Size = UDim2.new(1, -8, 0, 22),
		BackgroundColor3 = rgb(30,24,10),
		LayoutOrder = order,
	})
	mkCorner(row, 7)
	mkStroke(row, rgb(80,60,20), 1)
	mkLabel(row, {
		Position = UDim2.new(0, 8, 0, 0),
		Size = UDim2.new(1, -8, 1, 0),
		Text = "⚠  " .. text,
		TextColor3 = rgb(200,160,60),
		Font = Enum.Font.GothamMedium,
		TextSize = 9,
		TextXAlignment = Enum.TextXAlignment.Left,
	})
	return row
end

local VALID_KEYS = { ["37"]=true, ["cm"]=true, ["217"]=true }

local gui = Instance.new("ScreenGui")
gui.Name = "Sparta_" .. tostring(math.random(10000,99999))
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9999

pcall(function() _syn_protect(gui) end)
pcall(function() gui.Parent = _gethui() end)
if not gui.Parent then
	pcall(function() gui.Parent = CoreGui end)
end
if not gui.Parent then
	gui.Parent = lp:WaitForChild("PlayerGui")
end

local OVERLAY = mkFrame(gui, {
	Size = UDim2.new(1,0,1,0),
	BackgroundTransparency = 1,
})

local LOCK = mkFrame(gui, {
	Size = UDim2.new(1,0,1,0),
	BackgroundColor3 = rgb(5,5,10),
})

local KF = mkFrame(LOCK, {
	Position = UDim2.new(0.5,-162,0.5,-128),
	Size = UDim2.new(0,324,0,240),
	BackgroundColor3 = rgb(13,13,21),
})
mkCorner(KF, 14)
mkStroke(KF, rgb(30,30,50), 1.5)

local KT = mkFrame(KF, {
	Size = UDim2.new(1,0,0,36),
	BackgroundColor3 = rgb(7,7,13),
})
mkCorner(KT, 14)
mkFrame(KF, { Position=UDim2.new(0,0,0,20), Size=UDim2.new(1,0,0,16), BackgroundColor3=rgb(7,7,13) })

local function makeDotOnParent(parent, x, col)
	local f = mkFrame(parent, { Position=UDim2.new(0,x,0.5,-7), Size=UDim2.new(0,14,0,14), BackgroundColor3=col })
	mkCorner(f, 14)
	local b = mkBtn(f, { Size=UDim2.new(1,0,1,0), Text="" })
	return f, b
end

local kDotR, kDotRBtn = makeDotOnParent(KT, 13, rgb(255,95,87))
local kDotO, kDotOBtn = makeDotOnParent(KT, 33, rgb(254,188,46))
local kDotG, kDotGBtn = makeDotOnParent(KT, 53, rgb(40,200,64))

local kTitleLabel = mkLabel(KT, {
	Position=UDim2.new(0,74,0,0), Size=UDim2.new(1,-74,1,0),
	Text="Sparta  ·  Key System",
	TextColor3=rgb(80,80,108), Font=Enum.Font.GothamMedium, TextSize=11,
	TextXAlignment=Enum.TextXAlignment.Left,
})

local keyBody = mkFrame(KF, {
	Position=UDim2.new(0,0,0,36), Size=UDim2.new(1,0,1,-36),
	BackgroundTransparency=1,
})

mkLabel(keyBody, {
	Position=UDim2.new(0,0,0,18), Size=UDim2.new(1,0,0,22),
	Text="🔐  Enter Your Key",
	Font=Enum.Font.GothamBold, TextSize=14, TextColor3=rgb(215,215,230),
})
mkLabel(keyBody, {
	Position=UDim2.new(0,0,0,42), Size=UDim2.new(1,0,0,16),
	Text="Enter one valid passcode to unlock Sparta",
	TextColor3=rgb(65,65,90), Font=Enum.Font.Gotham, TextSize=10,
})

local keyInput = Instance.new("TextBox")
keyInput.Position = UDim2.new(0,16,0,72)
keyInput.Size = UDim2.new(1,-32,0,42)
keyInput.BackgroundColor3 = rgb(20,20,34)
keyInput.TextColor3 = rgb(215,215,235)
keyInput.Font = Enum.Font.Code
keyInput.TextSize = 16
keyInput.PlaceholderText = "Enter key..."
keyInput.PlaceholderColor3 = rgb(55,55,80)
keyInput.Text = ""
keyInput.BorderSizePixel = 0
keyInput.ClearTextOnFocus = false
keyInput.TextXAlignment = Enum.TextXAlignment.Center
mkCorner(keyInput, 10)
local keyInputStroke = mkStroke(keyInput, rgb(38,38,62), 1.5)
keyInput.Parent = keyBody

local keyErrLabel = mkLabel(keyBody, {
	Position=UDim2.new(0,0,0,120), Size=UDim2.new(1,0,0,14),
	Text="", TextColor3=rgb(255,70,70),
	Font=Enum.Font.GothamSemibold, TextSize=10,
})

local keySubmitBtn = mkBtn(keyBody, {
	Position=UDim2.new(0,16,0,138), Size=UDim2.new(1,-32,0,40),
	Text="Unlock Sparta", Font=Enum.Font.GothamBold, TextSize=13,
	TextColor3=rgb(170,170,200), BackgroundColor3=rgb(22,22,38),
	BackgroundTransparency=0,
})
mkCorner(keySubmitBtn, 10)
mkStroke(keySubmitBtn, rgb(45,45,70), 1)

local keyCollapsed = false

local function shakeKF()
	local orig = KF.Position
	for _ = 1, 4 do
		tw(KF, { Position = UDim2.new(0.5,-170,0.5,-128) }, 0.04):Play()
		task.wait(0.04)
		tw(KF, { Position = UDim2.new(0.5,-154,0.5,-128) }, 0.04):Play()
		task.wait(0.04)
	end
	KF.Position = orig
end

local ROOT
local function tryUnlock()
	local raw = keyInput.Text:match("^%s*(.-)%s*$") or ""
	if VALID_KEYS[raw] or VALID_KEYS[raw:lower()] then
		tw(LOCK, { BackgroundTransparency = 1 }, 0.45):Play()
		task.delay(0.45, function()
			LOCK.Visible = false
			if ROOT then ROOT.Visible = true end
		end)
	else
		keyErrLabel.Text = "✗  Invalid key — try: 37, CM, or 217"
		keyInputStroke.Color = rgb(160,35,35)
		task.spawn(shakeKF)
		task.delay(1.5, function()
			keyErrLabel.Text = ""
			keyInputStroke.Color = rgb(38,38,62)
		end)
	end
end

keySubmitBtn.MouseButton1Click:Connect(tryUnlock)
keyInput.FocusLost:Connect(function(enter) if enter then tryUnlock() end end)

kDotRBtn.MouseButton1Click:Connect(function() pcall(function() gui:Destroy() end) end)
kDotOBtn.MouseButton1Click:Connect(function()
	keyCollapsed = not keyCollapsed
	if keyCollapsed then
		task.spawn(function()
			tw(keyBody, { Size = UDim2.new(1,0,0,0) }, 0.18):Play()
			task.wait(0.17)
			keyBody.Visible = false
			tw(KF, { Size = UDim2.new(0,324,0,36) }, 0.12):Play()
		end)
	else
		task.spawn(function()
			tw(KF, { Size = UDim2.new(0,324,0,240) }, 0.18):Play()
			task.wait(0.08)
			keyBody.Visible = true
			keyBody.Size = UDim2.new(1,0,0,0)
			tw(keyBody, { Size = UDim2.new(1,0,1,-36) }, 0.15):Play()
		end)
	end
end)
kDotGBtn.MouseButton1Click:Connect(function() end)

local TABS = {
	{ id="aim",        label="Aim Assist",  col=rgb(239,68,68)  },
	{ id="triggerbot", label="Trigger Bot", col=rgb(6,182,212)  },
	{ id="killaura",   label="Kill Aura",   col=rgb(220,38,38)  },
	{ id="hitbox",     label="Hitbox",      col=rgb(249,115,22) },
	{ id="autoclick",  label="Auto Click",  col=rgb(234,179,8)  },
	{ id="speed",      label="Speed",       col=rgb(34,197,94)  },
	{ id="fly",        label="Fly",         col=rgb(59,130,246) },
	{ id="esp",        label="ESP",         col=rgb(168,85,247) },
	{ id="player",     label="Player",      col=rgb(139,92,246) },
	{ id="world",      label="World",       col=rgb(20,184,166) },
	{ id="weapons",    label="Weapons",     col=rgb(245,158,11) },
	{ id="network",    label="Network",     col=rgb(99,102,241) },
	{ id="rage",       label="Rage Mode",   col=rgb(185,28,28)  },
	{ id="anticheat",  label="Anti-Cheat",  col=rgb(16,185,129) },
	{ id="misc",       label="Misc",        col=rgb(236,72,153) },
}

local activeTabId = "aim"
local guiMinimized = false
local sidebarOpen = true

ROOT = mkFrame(gui, {
	Position = UDim2.new(0,16,0,48),
	Size = UDim2.new(0,506,0,556),
	BackgroundColor3 = rgb(11,11,18),
	Visible = false,
})
mkCorner(ROOT, 14)
local rootStroke = mkStroke(ROOT, rgb(239,68,68), 1.5)

local TITLEBAR = mkFrame(ROOT, {
	Size = UDim2.new(1,0,0,36),
	BackgroundColor3 = rgb(6,6,11),
})
mkCorner(TITLEBAR, 14)
mkFrame(ROOT, { Position=UDim2.new(0,0,0,20), Size=UDim2.new(1,0,0,16), BackgroundColor3=rgb(6,6,11) })

local dotRed,    dotRedBtn    = makeDotOnParent(TITLEBAR, 13, rgb(255,95,87))
local dotOrange, dotOrangeBtn = makeDotOnParent(TITLEBAR, 33, rgb(254,188,46))
local dotGreen,  dotGreenBtn  = makeDotOnParent(TITLEBAR, 53, rgb(40,200,64))

local chromaTitle = mkLabel(TITLEBAR, {
	Position=UDim2.new(0,76,0,0), Size=UDim2.new(0,60,1,0),
	Text="Sparta", Font=Enum.Font.GothamBold, TextSize=12,
})

local sepL1 = mkLabel(TITLEBAR, {
	Position=UDim2.new(0,138,0,0), Size=UDim2.new(0,12,1,0),
	Text="|", TextColor3=rgb(40,40,60), TextSize=12,
})

local activeTabLabel = mkLabel(TITLEBAR, {
	Position=UDim2.new(0,152,0,0), Size=UDim2.new(0,120,1,0),
	Text="Aim Assist", Font=Enum.Font.GothamSemibold, TextSize=11,
	TextColor3=rgb(239,68,68), TextXAlignment=Enum.TextXAlignment.Left,
})

local sepL2 = mkLabel(TITLEBAR, {
	Position=UDim2.new(1,-70,0,0), Size=UDim2.new(0,12,1,0),
	Text="|", TextColor3=rgb(40,40,60), TextSize=12,
})

mkLabel(TITLEBAR, {
	Position=UDim2.new(1,-60,0,0), Size=UDim2.new(0,56,1,0),
	Text="v2.0", Font=Enum.Font.Code, TextSize=10,
	TextColor3=rgb(45,45,68), TextXAlignment=Enum.TextXAlignment.Right,
})

local BODY = mkFrame(ROOT, {
	Position=UDim2.new(0,0,0,36), Size=UDim2.new(1,0,1,-36),
	BackgroundTransparency=1,
})

local SIDEBAR = mkFrame(BODY, {
	Size=UDim2.new(0,158,1,0), BackgroundColor3=rgb(8,8,14),
})
mkCorner(SIDEBAR, 14)
mkFrame(SIDEBAR, { Size=UDim2.new(1,0,0,14), BackgroundColor3=rgb(8,8,14) })
mkFrame(SIDEBAR, { Position=UDim2.new(1,-14,0,0), Size=UDim2.new(0,14,1,0), BackgroundColor3=rgb(8,8,14) })
mkFrame(SIDEBAR, { Position=UDim2.new(1,-1,0,0), Size=UDim2.new(0,1,1,0), BackgroundColor3=rgb(22,22,36) })

local searchFrame = mkFrame(SIDEBAR, {
	Position=UDim2.new(0,7,0,7), Size=UDim2.new(1,-14,0,24),
	BackgroundColor3=rgb(18,18,30),
})
mkCorner(searchFrame, 6)
mkLabel(searchFrame, {
	Position=UDim2.new(0,8,0,0), Size=UDim2.new(1,-8,1,0),
	Text="🔍  Search...", TextColor3=rgb(48,48,68),
	Font=Enum.Font.Gotham, TextSize=10,
	TextXAlignment=Enum.TextXAlignment.Left,
})

mkLabel(SIDEBAR, {
	Position=UDim2.new(0,10,0,36), Size=UDim2.new(1,-10,0,13),
	Text="FEATURES", TextColor3=rgb(42,42,62),
	Font=Enum.Font.GothamBold, TextSize=7.5,
	TextXAlignment=Enum.TextXAlignment.Left,
})

local tabListSF = mkScrollFrame(SIDEBAR, {
	Position=UDim2.new(0,5,0,51), Size=UDim2.new(1,-10,1,-96),
})
mkListLayout(tabListSF, 2)

local tabButtons = {}

for i, tab in ipairs(TABS) do
	local isActive = tab.id == activeTabId
	local row = mkBtn(tabListSF, {
		Size = UDim2.new(1,0,0,27),
		Text = "",
		BackgroundColor3 = isActive and rgb(22,22,36) or rgb(0,0,0),
		BackgroundTransparency = isActive and 0 or 1,
		LayoutOrder = i,
	})
	mkCorner(row, 7)

	local dot = mkFrame(row, {
		Position=UDim2.new(0,8,0.5,-5), Size=UDim2.new(0,10,0,10),
		BackgroundColor3=tab.col,
	})
	mkCorner(dot, 3)

	local lbl = mkLabel(row, {
		Position=UDim2.new(0,23,0,0), Size=UDim2.new(1,-32,1,0),
		Text=tab.label, Font=Enum.Font.GothamMedium, TextSize=10,
		TextColor3 = isActive and rgb(215,215,235) or rgb(80,80,108),
		TextXAlignment=Enum.TextXAlignment.Left,
	})

	if isActive then
		mkFrame(row, {
			Position=UDim2.new(1,-5,0.5,-5), Size=UDim2.new(0,4,0,10),
			BackgroundColor3=tab.col,
		})
	end

	tabButtons[tab.id] = { btn=row, lbl=lbl, dot=dot }
end

local configSection = mkFrame(SIDEBAR, {
	Position=UDim2.new(0,7,1,-42), Size=UDim2.new(1,-14,0,36),
	BackgroundColor3=rgb(14,14,24),
})
mkCorner(configSection, 8)
mkStroke(configSection, rgb(25,25,40), 1)

local configToggleBtn = mkBtn(configSection, {
	Size=UDim2.new(1,0,0,36),
	Text="⚙  Config & Profiles",
	Font=Enum.Font.GothamMedium, TextSize=10,
	TextColor3=rgb(72,72,100),
})

local configDropdown = mkFrame(SIDEBAR, {
	Position=UDim2.new(0,7,1,-200), Size=UDim2.new(1,-14,0,154),
	BackgroundColor3=rgb(14,14,24),
	Visible=false,
})
mkCorner(configDropdown, 8)
mkStroke(configDropdown, rgb(25,25,40), 1)
mkListLayout(configDropdown, 3)
mkUIPad(configDropdown, 6, 6, 6, 6)

local presetNames = {"Default","Rage","Legit","Spinbot","Stealth"}
local presetColors = {
	Default=rgb(59,130,246), Rage=rgb(239,68,68),
	Legit=rgb(34,197,94), Spinbot=rgb(168,85,247), Stealth=rgb(99,102,241)
}
local selectedProfile = "Default"
local profileBtns = {}

for idx, pname in ipairs(presetNames) do
	local pcol = presetColors[pname]
	local pbtn = mkBtn(configDropdown, {
		Size=UDim2.new(1,0,0,22), Text="",
		BackgroundColor3 = pname==selectedProfile and rgb(20,20,36) or rgb(0,0,0),
		BackgroundTransparency = pname==selectedProfile and 0 or 1,
		LayoutOrder=idx,
	})
	mkCorner(pbtn, 5)

	mkFrame(pbtn, {
		Position=UDim2.new(0,6,0.5,-4), Size=UDim2.new(0,8,0,8),
		BackgroundColor3=pcol,
	}):ClearAllChildren()
	Instance.new("UICorner", pbtn:FindFirstChildOfClass("Frame")).CornerRadius = UDim.new(1,0)

	mkLabel(pbtn, {
		Position=UDim2.new(0,20,0,0), Size=UDim2.new(1,-20,1,0),
		Text=pname, Font=Enum.Font.GothamMedium, TextSize=10,
		TextColor3 = pname==selectedProfile and pcol or rgb(70,70,98),
		TextXAlignment=Enum.TextXAlignment.Left,
	})

	profileBtns[pname] = pbtn
	pbtn.MouseButton1Click:Connect(function()
		selectedProfile = pname
		for n, b in pairs(profileBtns) do
			local active = n == pname
			b.BackgroundTransparency = active and 0 or 1
			local l = b:FindFirstChildOfClass("TextLabel")
			if l then l.TextColor3 = active and presetColors[n] or rgb(70,70,98) end
		end
		applyProfile(pname)
	end)
end

local configActionRow = mkFrame(configDropdown, {
	Size=UDim2.new(1,0,0,24), BackgroundTransparency=1,
	LayoutOrder=10,
})
mkListLayout(configActionRow, 4, nil, Enum.FillDirection.Horizontal)

local function mkCfgBtn(parent, text, col, order, onClick)
	local b = mkBtn(parent, {
		Size=UDim2.new(0.333,0,1,0),
		Text=text, Font=Enum.Font.GothamBold, TextSize=9,
		BackgroundColor3=rgb(18,18,32), BackgroundTransparency=0,
		TextColor3=col or rgb(80,80,108), LayoutOrder=order,
	})
	mkCorner(b, 5)
	mkStroke(b, rgb(28,28,46), 1)
	b.MouseButton1Click:Connect(onClick or function() end)
	return b
end

local savedLabel
local saveCfgBtn = mkCfgBtn(configActionRow,"Save",rgb(34,197,94),1,function()
	saveProfile(selectedProfile)
	if saveCfgBtn then
		local origColor = saveCfgBtn.TextColor3
		saveCfgBtn.Text = "✓"
		saveCfgBtn.TextColor3 = rgb(34,197,94)
		task.delay(1.2, function()
			saveCfgBtn.Text = "Save"
			saveCfgBtn.TextColor3 = rgb(34,197,94)
		end)
	end
end)
local loadCfgBtn = mkCfgBtn(configActionRow,"Load",rgb(59,130,246),2,function() applyProfile(selectedProfile) end)
local copyCfgBtn = mkCfgBtn(configActionRow,"Copy",rgb(168,85,247),3,exportConfig)

local configOpen = false
configToggleBtn.MouseButton1Click:Connect(function()
	configOpen = not configOpen
	configDropdown.Visible = configOpen
	configSection.Position = configOpen and UDim2.new(0,7,1,-200) or UDim2.new(0,7,1,-42)
	tabListSF.Size = configOpen and UDim2.new(1,-10,1,-258) or UDim2.new(1,-10,1,-96)
end)

local CONTENT = mkFrame(BODY, {
	Position=UDim2.new(0,158,0,0), Size=UDim2.new(1,-158,1,0),
	BackgroundTransparency=1, ClipsDescendants=true,
})

local pages = {}

local function mkPage(id)
	local sf = mkScrollFrame(CONTENT, {
		Position=UDim2.new(0,0,0,0), Size=UDim2.new(1,0,1,0),
		Visible = id == activeTabId,
	})
	mkListLayout(sf, 4)
	mkUIPad(sf, 6, 8, 5, 5)
	pages[id] = sf
	return sf
end

local function S(page, n, title, col) n=n+1; mkSection(page, n, title, col); return n end
local function B(page, n, text, col) n=n+1; mkBadge(page, n, text, col); return n end
local function W(page, n, text) n=n+1; mkNotice(page, n, text); return n end
local function C(page, n, title, desc, ty, ac, def, a, b, d, e, k)
	n=n+1; mkCard(page, n, title, desc, ty, ac, def, a, b, d, e, k); return n
end

local function buildAim()
	local p = mkPage("aim")
	local n = 0
	n = S(p,n,"Targeting",rgb(239,68,68))
	n = C(p,n,"Silent Aim","Warp bullets silently to nearest enemy head","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"SilentAim")
	n = C(p,n,"Aim Lock","Smooth camera snap onto target","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"AimLock")
	n = C(p,n,"Team Check","Never target your teammates","toggle",rgb(239,68,68),true,nil,nil,nil,nil,"AimTeamCheck")
	n = C(p,n,"Visible Only","Skip targets behind solid walls","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"AimVisibleOnly")
	n = C(p,n,"Multipoint","Check head/torso/HRP per target","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"Multipoint")
	n = S(p,n,"FOV & Smoothing",rgb(239,68,68))
	n = B(p,n,"Head-priority · 0.2s tick rate · Camera-smooth",rgb(239,68,68))
	n = C(p,n,"FOV Radius","Targeting circle radius in pixels","slider",nil,nil,10,500,150,"px","FOVSize")
	n = C(p,n,"Smoothness","Camera lerp speed (higher=faster)","slider",nil,nil,1,100,35,"%","Smoothness")
	n = C(p,n,"FOV Circle","Render targeting radius on screen","toggle",rgb(239,68,68),true,nil,nil,nil,nil,"FOVCircle")
	n = S(p,n,"Prediction",rgb(239,68,68))
	n = C(p,n,"Velocity Predict","Lead moving targets with velocity","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"Prediction")
	n = C(p,n,"Prediction Strength","How far ahead to compensate","slider",nil,nil,0,100,40,"%","PredictionStrength")
	n = S(p,n,"Mobile",rgb(239,68,68))
	n = C(p,n,"Gyroscope","Gyro-assisted aim compensation","toggle",rgb(239,68,68),false,nil,nil,nil,nil,"Gyroscope")
end

local function buildTrigger()
	local p = mkPage("triggerbot")
	local n = 0
	n = S(p,n,"Trigger Bot",rgb(6,182,212))
	n = B(p,n,"Auto-fires when crosshair is over an enemy",rgb(6,182,212))
	n = C(p,n,"Trigger Bot","Fire on crosshair contact with enemy","toggle",rgb(6,182,212),false,nil,nil,nil,nil,"TriggerBot")
	n = C(p,n,"Team Check","Skip teammates","toggle",rgb(6,182,212),true,nil,nil,nil,nil,"TriggerTeamCheck")
	n = C(p,n,"Visible Check","Fire only at visible enemies","toggle",rgb(6,182,212),true,nil,nil,nil,nil,"TriggerVisible")
	n = C(p,n,"Head Only","Only fire on head detection","toggle",rgb(6,182,212),false,nil,nil,nil,nil,"TriggerHeadOnly")
	n = C(p,n,"Hit Confidence","Min ray confidence to trigger (%)","slider",nil,nil,10,100,60,"%","TriggerConfidence")
	n = S(p,n,"Timing",rgb(6,182,212))
	n = C(p,n,"Pre-fire Delay","Delay before first shot (ms)","slider",nil,nil,0,500,30,"ms","TriggerPreDelay")
	n = C(p,n,"Post-fire Delay","Cooldown after each shot (ms)","slider",nil,nil,0,500,80,"ms","TriggerPostDelay")
	n = C(p,n,"Burst Fire","Fire in short bursts","toggle",rgb(6,182,212),false,nil,nil,nil,nil,"TriggerBurst")
	n = C(p,n,"Burst Count","Shots per burst","slider",nil,nil,1,10,3," shots","TriggerBurstCount")
	n = S(p,n,"Humanize",rgb(6,182,212))
	n = C(p,n,"Randomize Delay","Add human-like timing variance","toggle",rgb(6,182,212),true,nil,nil,nil,nil,"TriggerRandomDelay")
	n = C(p,n,"Random Range","Delay variance range","slider",nil,nil,1,50,15,"%","TriggerRandomRange")
end

local function buildKillAura()
	local p = mkPage("killaura")
	local n = 0
	n = S(p,n,"Kill Aura",rgb(220,38,38))
	n = B(p,n,"Automatically attacks nearby enemies in range",rgb(220,38,38))
	n = C(p,n,"Kill Aura","Auto-swing at players within range","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAura")
	n = C(p,n,"Team Check","Never attack teammates","toggle",rgb(220,38,38),true,nil,nil,nil,nil,"KillAuraTeamCheck")
	n = C(p,n,"Range","Attack radius in studs","slider",nil,nil,4,80,20," st","KillAuraRange")
	n = C(p,n,"Attack Rate","Swings per second","slider",nil,nil,1,30,8,"/s","KillAuraRate")
	n = S(p,n,"Targeting",rgb(220,38,38))
	n = C(p,n,"Closest First","Target nearest player","toggle",rgb(220,38,38),true,nil,nil,nil,nil,"KillAuraClosest")
	n = C(p,n,"Lowest HP First","Target weakest player","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAuraLowestHP")
	n = C(p,n,"Visible Only","Only attack visible enemies","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAuraVisible")
	n = S(p,n,"Spinbot",rgb(220,38,38))
	n = C(p,n,"Spin Attack","Rotate while attacking","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAuraSpin")
	n = C(p,n,"Spin Speed","Rotation speed while attacking","slider",nil,nil,1,60,15," sp","KillAuraSpinSpeed")
	n = S(p,n,"Bypass",rgb(220,38,38))
	n = C(p,n,"Randomize Timing","Human-like attack variance","toggle",rgb(220,38,38),true,nil,nil,nil,nil,"KillAuraRandom")
	n = C(p,n,"Desync","Body-aim desync on each swing","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAuraDesync")
	n = C(p,n,"Jitter","Micro-movement per swing","toggle",rgb(220,38,38),false,nil,nil,nil,nil,"KillAuraJitter")
end

local function buildHitbox()
	local p = mkPage("hitbox")
	local n = 0
	n = S(p,n,"Body Expansion",rgb(249,115,22))
	n = C(p,n,"Hitbox Expander","Inflate all enemy body hitboxes","toggle",rgb(249,115,22),false,nil,nil,nil,nil,"HitboxExpand")
	n = C(p,n,"Body Size","Body scale multiplier","slider",nil,nil,1,30,6,"×","HitboxSize")
	n = C(p,n,"Head Expand","Inflate head hitbox separately","toggle",rgb(249,115,22),false,nil,nil,nil,nil,"HeadExpand")
	n = C(p,n,"Head Size","Head scale multiplier","slider",nil,nil,1,25,5,"×","HeadSize")
	n = S(p,n,"Selective Parts",rgb(249,115,22))
	n = C(p,n,"Arms Only","Expand only arm parts","toggle",rgb(249,115,22),false,nil,nil,nil,nil,"HitboxArmsOnly")
	n = C(p,n,"Legs Only","Expand only leg parts","toggle",rgb(249,115,22),false,nil,nil,nil,nil,"HitboxLegsOnly")
	n = C(p,n,"Team Check","Skip your teammates","toggle",rgb(249,115,22),true,nil,nil,nil,nil,"HitboxTeamCheck")
	n = S(p,n,"Visual",rgb(249,115,22))
	n = C(p,n,"Show Hitboxes","Render expanded parts visually","toggle",rgb(249,115,22),false,nil,nil,nil,nil,"HitboxShowVisual")
	n = C(p,n,"Hitbox Opacity","Transparency of shown hitboxes","slider",nil,nil,0,100,50,"%","HitboxOpacity")
end

local function buildAutoClick()
	local p = mkPage("autoclick")
	local n = 0
	n = S(p,n,"Auto Click",rgb(234,179,8))
	n = C(p,n,"Auto Click","Automatically fire at set CPS rate","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"AutoClick")
	n = C(p,n,"CPS","Target clicks per second","slider",nil,nil,1,60,14," cps","CPS")
	n = C(p,n,"Hold to Click","Only fire while touch is held","toggle",rgb(234,179,8),true,nil,nil,nil,nil,"HoldToClick")
	n = S(p,n,"Humanize",rgb(234,179,8))
	n = C(p,n,"Randomize CPS","Vary timing for human-like pattern","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"RandomizeCPS")
	n = C(p,n,"Random Range","CPS variance percentage","slider",nil,nil,1,30,5,"%","RandomRange")
	n = C(p,n,"Click Pattern","Drag-click / butterfly emulation","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"ClickPattern")
	n = C(p,n,"Double Click","Send two clicks per interval","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"DoubleClick")
	n = C(p,n,"Alt Left/Right","Alternate left and right clicks","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"AltLeftRight")
	n = S(p,n,"Recoil",rgb(234,179,8))
	n = C(p,n,"Jitter Aim","Micro-shake per click for recoil","toggle",rgb(234,179,8),false,nil,nil,nil,nil,"JitterAim")
	n = C(p,n,"Jitter Strength","Shake intensity in pixels","slider",nil,nil,1,15,3,"px","JitterStrength")
end

local function buildSpeed()
	local p = mkPage("speed")
	local n = 0
	n = S(p,n,"Movement",rgb(34,197,94))
	n = C(p,n,"Speed Hack","Override WalkSpeed immediately","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"SpeedHack")
	n = C(p,n,"Walk Speed","Target walk speed in studs/s","slider",nil,nil,16,500,50," ws","WalkSpeed")
	n = C(p,n,"Sprint","Hold sprint key for boosted speed","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"Sprint")
	n = C(p,n,"Sprint Multiplier","Speed boost while sprinting","slider",nil,nil,1,10,2,"×","SprintMultiplier")
	n = S(p,n,"Physics",rgb(34,197,94))
	n = C(p,n,"Noclip","Phase through all walls freely","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"Noclip")
	n = C(p,n,"Bunny Hop","Auto-jump at velocity peak","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"BunnyHop")
	n = C(p,n,"Long Jump","Extended horizontal jump range","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"LongJump")
	n = C(p,n,"Low Gravity","Reduce character gravity","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"LowGravity")
	n = C(p,n,"Gravity Scale","Character gravity percentage","slider",nil,nil,10,200,100,"%","GravityScale")
	n = S(p,n,"Bypass",rgb(34,197,94))
	n = C(p,n,"Speed Bypass","Tick-rate safe injection method","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"SpeedBypass")
	n = C(p,n,"Velocity Inject","Apply speed via BodyVelocity","toggle",rgb(34,197,94),false,nil,nil,nil,nil,"VelocityInject")
end

local function buildFly()
	local p = mkPage("fly")
	local n = 0
	n = S(p,n,"Flight",rgb(59,130,246))
	n = C(p,n,"Fly","Freely levitate and move in 3D","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"Fly")
	n = C(p,n,"Fly Speed","Horizontal flight speed","slider",nil,nil,1,400,60," sp","FlySpeed")
	n = C(p,n,"Vertical Speed","Up/Down movement speed","slider",nil,nil,1,250,40," sp","VerticalSpeed")
	n = S(p,n,"Altitude",rgb(59,130,246))
	n = C(p,n,"Altitude Lock","Lock to a fixed height above ground","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"AltitudeLock")
	n = C(p,n,"Lock Height","Target altitude in studs","slider",nil,nil,0,500,20," st","LockAltitude")
	n = S(p,n,"Options",rgb(59,130,246))
	n = C(p,n,"Noclip","Phase through walls while flying","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"FlyNoclip")
	n = C(p,n,"Anti-Gravity","Hover in place when idle","toggle",rgb(59,130,246),true,nil,nil,nil,nil,"AntiGravity")
	n = C(p,n,"Smooth Fly","Eased acceleration curve","toggle",rgb(59,130,246),true,nil,nil,nil,nil,"SmoothFly")
	n = C(p,n,"Camera Relative","Move relative to camera angle","toggle",rgb(59,130,246),true,nil,nil,nil,nil,"CameraRelative")
	n = S(p,n,"Stealth",rgb(59,130,246))
	n = C(p,n,"Fake Walk","Play walk anim while airborne","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"FakeWalk")
	n = C(p,n,"Cloak","Invisible while flying","toggle",rgb(59,130,246),false,nil,nil,nil,nil,"FlyCloak")
	n = S(p,n,"Controls",rgb(59,130,246))
	n = B(p,n,"Thumbstick=move · Jump=ascend · Crouch=descend",rgb(59,130,246))
end

local function buildESP()
	local p = mkPage("esp")
	local n = 0
	n = S(p,n,"Player Boxes",rgb(168,85,247))
	n = C(p,n,"Player ESP","Enable all player overlays","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"PlayerESP")
	n = C(p,n,"Box ESP","Solid 2D bounding box","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"BoxESP")
	n = C(p,n,"Corner Box","Stylized L-corner boxes","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"CornerBox")
	n = C(p,n,"3D Box","Full 3D wireframe around character","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"Box3D")
	n = S(p,n,"Labels",rgb(168,85,247))
	n = C(p,n,"Name ESP","Player names above heads","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"NameESP")
	n = C(p,n,"Distance","Stud distance displayed below name","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"DistanceESP")
	n = C(p,n,"Weapon Name","Show currently equipped weapon","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"WeaponESP")
	n = C(p,n,"Team Tag","Show player's team name","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"TeamTag")
	n = S(p,n,"Health",rgb(168,85,247))
	n = C(p,n,"Health Bar","Gradient HP bar beside box","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"HealthBar")
	n = C(p,n,"Health Text","Exact HP number","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"HealthText")
	n = C(p,n,"Shield Bar","Second bar for shields/armor","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"ShieldBar")
	n = S(p,n,"Overlays",rgb(168,85,247))
	n = C(p,n,"Tracers","Line from screen edge to feet","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"Tracers")
	n = C(p,n,"Chams","Solid through-wall highlight","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"Chams")
	n = C(p,n,"Skeleton","Bone structure wireframe","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"SkeletonESP")
	n = C(p,n,"Snapline","Line from crosshair to target","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"Snapline")
	n = S(p,n,"Colors",rgb(168,85,247))
	n = C(p,n,"Team Color","Color by team alignment","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"TeamColor")
	n = C(p,n,"Health Color","Box color gradient by HP","toggle",rgb(168,85,247),false,nil,nil,nil,nil,"HealthColor")
	n = S(p,n,"Range",rgb(168,85,247))
	n = C(p,n,"Max Distance","Render cutoff distance","slider",nil,nil,50,8000,3000," st","ESPMaxDist")
	n = C(p,n,"Fade by Distance","Reduce opacity at max range","toggle",rgb(168,85,247),true,nil,nil,nil,nil,"FadeByDistance")
end

local function buildPlayer()
	local p = mkPage("player")
	local n = 0
	n = S(p,n,"Character",rgb(139,92,246))
	n = C(p,n,"Resize Player","Scale your character size","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"PlayerSize")
	n = C(p,n,"Size Scale","Character scale percentage","slider",nil,nil,10,500,100,"%","SizeScale")
	n = C(p,n,"Invisible","Make character fully invisible","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"Invisible")
	n = C(p,n,"No Accessories","Remove all hats & accessories","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"NoAccessories")
	n = C(p,n,"No Clothing","Remove shirt/pants textures","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"NoClothing")
	n = C(p,n,"Spin Player","Infinitely rotate character","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"SpinPlayer")
	n = C(p,n,"No Animations","Freeze all character animations","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"NoAnimations")
	n = S(p,n,"Physics",rgb(139,92,246))
	n = C(p,n,"Superhuman Strength","Launch enemies on contact","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"SuperStrength")
	n = C(p,n,"Knockback Force","Force of contact knockback","slider",nil,nil,10,1000,80," kn","KnockbackForce")
	n = C(p,n,"Gravity Override","Change world gravity value","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"GravityHack")
	n = C(p,n,"Gravity Value","Workspace gravity value","slider",nil,nil,1,400,196," g","GravityValue")
	n = S(p,n,"Health & Movement",rgb(139,92,246))
	n = C(p,n,"God Mode","Lock health at maximum forever","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"GodMode")
	n = C(p,n,"HP Regen Rate","Passive regeneration per second","slider",nil,nil,0,200,10," hp","RegenRate")
	n = C(p,n,"No Fall Damage","Survive any drop height","toggle",rgb(139,92,246),true,nil,nil,nil,nil,"NoFallDamage")
	n = C(p,n,"Infinite Jump","Re-jump endlessly mid-air","toggle",rgb(139,92,246),false,nil,nil,nil,nil,"InfiniteJump")
	n = C(p,n,"Jump Power","Humanoid jump force","slider",nil,nil,50,1000,100," jp","JumpPower")
end

local function buildWorld()
	local p = mkPage("world")
	local n = 0
	n = S(p,n,"Lighting",rgb(20,184,166))
	n = C(p,n,"Fullbright","Remove all shadows and darkness","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"Fullbright")
	n = C(p,n,"No Fog","Clear all world fog instantly","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"NoFog")
	n = C(p,n,"Time of Day","World clock override (0–24)","slider",nil,nil,0,24,14,"h","TimeOfDay")
	n = C(p,n,"No Particles","Disable all particle effects","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"NoParticles")
	n = C(p,n,"No Clouds","Remove sky clouds","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"NoClouds")
	n = S(p,n,"Terrain",rgb(20,184,166))
	n = W(p,n,"Terrain edits are irreversible in-session")
	n = C(p,n,"Remove Water","Delete all Terrain water","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"RemoveWater")
	n = S(p,n,"Teleport",rgb(20,184,166))
	n = C(p,n,"Teleport to Click","Teleport on screen tap/click","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"TeleportToClick")
	n = C(p,n,"Teleport to Player","Jump to a nearby player","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"TeleportToPlayer")
	n = C(p,n,"Reach Modifier","Massively extend arm reach","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"ReachModifier")
	n = C(p,n,"Reach Distance","Arm reach in studs","slider",nil,nil,4,500,50," st","ReachDistance")
	n = S(p,n,"Camera",rgb(20,184,166))
	n = C(p,n,"Spectate Player","View from another player's camera","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"SpectateMode")
	n = C(p,n,"Free Cam","Detach camera from character","toggle",rgb(20,184,166),false,nil,nil,nil,nil,"FreeCam")
end

local function buildWeapons()
	local p = mkPage("weapons")
	local n = 0
	n = S(p,n,"Damage",rgb(245,158,11))
	n = B(p,n,"Hooks weapon remote events where detected",rgb(245,158,11))
	n = C(p,n,"Damage Multiplier","Scale all outgoing damage","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"DamageMultiplier")
	n = C(p,n,"Damage Scale","Outgoing damage multiplier","slider",nil,nil,1,50,3,"×","DamageScale")
	n = C(p,n,"One Shot","Always kill in a single hit","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"OneShot")
	n = S(p,n,"Accuracy",rgb(245,158,11))
	n = C(p,n,"No Recoil","Remove all weapon kick","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"NoRecoil")
	n = C(p,n,"No Spread","Perfect accuracy at all times","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"NoSpread")
	n = S(p,n,"Ammo",rgb(245,158,11))
	n = C(p,n,"Infinite Ammo","Never run out of ammunition","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"InfiniteAmmo")
	n = C(p,n,"Instant Reload","Reload completes instantly","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"InstantReload")
	n = C(p,n,"Full Auto","Force semi-auto to full auto","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"FullAuto")
	n = S(p,n,"Ballistics",rgb(245,158,11))
	n = C(p,n,"Bullet Speed","Projectile velocity override","slider",nil,nil,100,20000,2000," v","BulletSpeed")
	n = C(p,n,"No Gravity Drop","Disable bullet gravity","toggle",rgb(245,158,11),false,nil,nil,nil,nil,"NoGravityDrop")
	n = C(p,n,"Bullet Range","Max projectile travel distance","slider",nil,nil,100,20000,5000," st","BulletRange")
	n = C(p,n,"Pierce Count","Enemies pierced per bullet","slider",nil,nil,0,20,0," hit","PierceCount")
	n = S(p,n,"Melee",rgb(245,158,11))
	n = C(p,n,"Melee Range","Melee weapon reach in studs","slider",nil,nil,4,100,8," st","MeleeRange")
	n = C(p,n,"Melee Speed","Swing speed percentage","slider",nil,nil,50,500,100,"%","MeleeSpeed")
end

local function buildNetwork()
	local p = mkPage("network")
	local n = 0
	n = S(p,n,"Lag Switch",rgb(99,102,241))
	n = W(p,n,"Lag switch may cause desync kicks on some games")
	n = C(p,n,"Lag Switch","Freeze outgoing packet stream","toggle",rgb(99,102,241),false,nil,nil,nil,nil,"LagSwitch")
	n = C(p,n,"Lag Duration","Duration of each lag burst (ms)","slider",nil,nil,100,5000,500,"ms","LagDuration")
	n = C(p,n,"Lag Interval","Time between lag bursts (ms)","slider",nil,nil,500,30000,3000,"ms","LagInterval")
	n = C(p,n,"Fake Lag","Simulate high ping without DC","toggle",rgb(99,102,241),false,nil,nil,nil,nil,"FakeLag")
	n = C(p,n,"Fake Ping Value","Simulated ping in ms","slider",nil,nil,0,2000,100,"ms","FakePing")
	n = S(p,n,"Anti-Cheat Network",rgb(99,102,241))
	n = C(p,n,"Block Remote Logs","Drop suspicious server logging calls","toggle",rgb(99,102,241),true,nil,nil,nil,nil,"BlockRemoteLogs")
	n = C(p,n,"Spoof Position","Send fake position to server","toggle",rgb(99,102,241),false,nil,nil,nil,nil,"SpoofPosition")
	n = C(p,n,"Rate Limit Bypass","Override remote rate limiters","toggle",rgb(99,102,241),false,nil,nil,nil,nil,"RateLimitBypass")
	n = S(p,n,"Monitoring",rgb(99,102,241))
	n = C(p,n,"Show Net Stats","Ping/send/recv overlay on screen","toggle",rgb(99,102,241),false,nil,nil,nil,nil,"ShowNetStats")
	n = C(p,n,"Remote Logger","Log all fired remote events","toggle",rgb(99,102,241),false,nil,nil,nil,nil,"RemoteLogger")
	n = C(p,n,"Block DataStore","Prevent anti-cheat data saves","toggle",rgb(99,102,241),false,nil,nil,nil,nil,"BlockDataStore")
end

local function buildRage()
	local p = mkPage("rage")
	local n = 0
	n = S(p,n,"Rage Activation",rgb(185,28,28))
	n = W(p,n,"Rage Mode disables stealth — expect detection in some games")
	n = C(p,n,"Rage Mode","Toggle all rage features at once","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageMode")
	n = S(p,n,"Movement",rgb(185,28,28))
	n = C(p,n,"Max Speed","Set WalkSpeed to 200","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageMaxSpeed")
	n = C(p,n,"Max Hitbox","Inflate hitboxes to ×20","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageMaxHitbox")
	n = C(p,n,"Spin Bot","360° body rotation on attack","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageSpinBot")
	n = C(p,n,"Fake Lag","Desync-style teleport movement","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageFakeLag")
	n = S(p,n,"Combat",rgb(185,28,28))
	n = C(p,n,"Snap Aimbot","Instant snap to nearest head","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageAimbot")
	n = C(p,n,"Max Silent Aim","Max-range silent aim","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageSilentAim")
	n = C(p,n,"Max Trigger Bot","Zero-delay trigger","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageTrigger")
	n = C(p,n,"Kill Aura 80st","80-stud kill aura range","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageKillAura")
	n = C(p,n,"One-Shot Kill","Instant kill on any hit","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageInstantKill")
	n = S(p,n,"Defense",rgb(185,28,28))
	n = C(p,n,"God Mode","Invincible — can't be killed","toggle",rgb(185,28,28),false,nil,nil,nil,nil,"RageGod")
	n = C(p,n,"No Fall Damage","Always survive falls","toggle",rgb(185,28,28),true,nil,nil,nil,nil,"RageNoFall")
	n = C(p,n,"Anti-Kick","Block all kick attempts","toggle",rgb(185,28,28),true,nil,nil,nil,nil,"RageAntiKick")
end

local function buildAntiCheat()
	local p = mkPage("anticheat")
	local n = 0
	n = S(p,n,"Index Protection",rgb(16,185,129))
	n = B(p,n,"Shields against indexInstance detector & similar AC",rgb(16,185,129))
	n = C(p,n,"Index Bypass","Hook __index to mask instance reads","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"IndexBypass")
	n = C(p,n,"Cache Refs","Store instances to minimize indexing calls","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"CacheRefs")
	n = C(p,n,"cloneref Services","Clone service refs away from AC","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"CloneRefs")
	n = C(p,n,"Namecall Hook","Hook __namecall on game & workspace","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"NamecallHook")
	n = S(p,n,"Anti-Kick & Anti-Termination",rgb(16,185,129))
	n = C(p,n,"Anti-Kick","Block all LocalPlayer:Kick() calls","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"AntiKick")
	n = C(p,n,"Anti-Teleport","Block unwanted game teleports","toggle",rgb(16,185,129),false,nil,nil,nil,nil,"AntiTeleport")
	n = C(p,n,"Anti-Script-Kill","Protect script from termination","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"AntiScriptKill")
	n = S(p,n,"Timing & Obfuscation",rgb(16,185,129))
	n = C(p,n,"Timing Jitter","Randomize all heartbeat intervals","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"TimingJitter")
	n = C(p,n,"newcclosure Wrap","Wrap funcs to hide from tracers","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"NewcclosureWrap")
	n = C(p,n,"Anti-Log","Suppress script output to console","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"AntiLog")
	n = C(p,n,"Heartbeat Jitter","Vary heartbeat by ±5ms","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"HeartbeatJitter")
	n = C(p,n,"Property Scramble","Randomize property access order","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"PropertyScramble")
	n = S(p,n,"Advanced",rgb(16,185,129))
	n = C(p,n,"Fake Identity","Attempt script identity spoofing","toggle",rgb(16,185,129),false,nil,nil,nil,nil,"FakeIdentity")
	n = C(p,n,"Anti-RemoteSpy","Obfuscate remote fire signatures","toggle",rgb(16,185,129),true,nil,nil,nil,nil,"AntiRemoteSpy")
	n = C(p,n,"Anti-Scanner","Detect & disable AC scanning scripts","toggle",rgb(16,185,129),false,nil,nil,nil,nil,"AntiScanner")
end

local function buildMisc()
	local p = mkPage("misc")
	local n = 0
	n = S(p,n,"Player QoL",rgb(236,72,153))
	n = C(p,n,"Anti AFK","Auto-move to prevent idle kick","toggle",rgb(236,72,153),true,nil,nil,nil,nil,"AntiAFK")
	n = C(p,n,"AFK Interval","Seconds between AFK prevention","slider",nil,nil,10,300,60,"s","AntiAFKInterval")
	n = C(p,n,"Chat Spam","Auto-send chat message repeatedly","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"ChatSpam")
	n = S(p,n,"Movement",rgb(236,72,153))
	n = C(p,n,"Infinite Stamina","Stamina never depletes","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"InfiniteStamina")
	n = C(p,n,"No Swim Slow","Swim at full walk speed","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"NoSwimSlow")
	n = C(p,n,"Vehicle Boost","Override vehicle MaxSpeed","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"VehicleBoost")
	n = C(p,n,"Vehicle Speed","Vehicle max speed percent","slider",nil,nil,100,5000,500,"%","VehicleSpeed")
	n = S(p,n,"World",rgb(236,72,153))
	n = C(p,n,"Fullbright","Remove all shadows/darkness","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"Fullbright")
	n = C(p,n,"No Fog","Clear all world fog","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"NoFog")
	n = C(p,n,"Time of Day","World clock (0–24)","slider",nil,nil,0,24,14,"h","TimeOfDay")
	n = S(p,n,"Utility",rgb(236,72,153))
	n = C(p,n,"Rejoin","Leave and rejoin current game","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"Rejoin")
	n = C(p,n,"Copy Username","Copy LocalPlayer name to clipboard","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"CopyUsername")
	n = C(p,n,"Unlock All","Attempt to unlock all locked doors","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"UnlockAll")
	n = C(p,n,"No Animations","Freeze all character animations","toggle",rgb(236,72,153),false,nil,nil,nil,nil,"NoAnimations")
end

buildAim()
buildTrigger()
buildKillAura()
buildHitbox()
buildAutoClick()
buildSpeed()
buildFly()
buildESP()
buildPlayer()
buildWorld()
buildWeapons()
buildNetwork()
buildRage()
buildAntiCheat()
buildMisc()

local function switchTab(id)
	for _, tab in ipairs(TABS) do
		local entry = tabButtons[tab.id]
		if not entry then continue end
		local isActive = tab.id == id
		entry.btn.BackgroundTransparency = isActive and 0 or 1
		entry.btn.BackgroundColor3 = isActive and rgb(20,20,36) or rgb(0,0,0)
		entry.lbl.TextColor3 = isActive and rgb(215,215,235) or rgb(78,78,108)
		if isActive then
			activeTabLabel.Text = tab.label
			activeTabLabel.TextColor3 = tab.col
			rootStroke.Color = tab.col
		end
	end
	for tabId, page in pairs(pages) do
		page.Visible = tabId == id
		if tabId == id then page.CanvasPosition = Vector2.new(0,0) end
	end
	activeTabId = id
end

for _, tab in ipairs(TABS) do
	local entry = tabButtons[tab.id]
	if entry then
		local id = tab.id
		entry.btn.MouseButton1Click:Connect(function() switchTab(id) end)
	end
end

local _isDragging, _dragStart, _dragStartPos = false, nil, nil

TITLEBAR.InputBegan:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		_isDragging = true
		_dragStart = i.Position
		_dragStartPos = ROOT.Position
	end
end)
UserInputService.InputChanged:Connect(function(i)
	if _isDragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
		if _dragStart and _dragStartPos then
			local d = i.Position - _dragStart
			ROOT.Position = UDim2.new(
				_dragStartPos.X.Scale, _dragStartPos.X.Offset + d.X,
				_dragStartPos.Y.Scale, _dragStartPos.Y.Offset + d.Y
			)
		end
	end
end)
UserInputService.InputEnded:Connect(function(i)
	if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
		_isDragging = false
	end
end)

dotRedBtn.MouseButton1Click:Connect(function()
	pcall(function() gui:Destroy() end)
end)

dotOrangeBtn.MouseButton1Click:Connect(function()
	guiMinimized = not guiMinimized
	if guiMinimized then
		task.spawn(function()
			tw(BODY, { Size = UDim2.new(1,0,0,0) }, 0.2, Enum.EasingStyle.Quint):Play()
			task.wait(0.18)
			BODY.Visible = false
			tw(ROOT, { Size = UDim2.new(0,506,0,36) }, 0.15):Play()
		end)
	else
		task.spawn(function()
			BODY.Visible = true
			BODY.Size = UDim2.new(1,0,0,0)
			tw(ROOT, { Size = UDim2.new(0,506,0,556) }, 0.2, Enum.EasingStyle.Quint):Play()
			task.wait(0.08)
			tw(BODY, { Size = UDim2.new(1,0,1,-36) }, 0.18, Enum.EasingStyle.Quint):Play()
		end)
	end
end)

dotGreenBtn.MouseButton1Click:Connect(function()
	sidebarOpen = not sidebarOpen
	if sidebarOpen then
		SIDEBAR.Visible = true
		CONTENT.Position = UDim2.new(0,158,0,0)
		CONTENT.Size = UDim2.new(1,-158,1,0)
	else
		SIDEBAR.Visible = false
		CONTENT.Position = UDim2.new(0,0,0,0)
		CONTENT.Size = UDim2.new(1,0,1,0)
	end
end)

local flyBV, flyBG = nil, nil
local flyVel = Vector3.new()
local _spinAngle = 0
local _godConn, _jumpConn, _fallConn = nil, nil, nil
local _autoClickTimer = 0
local _aimTimer = 0
local _triggerTimer = 0
local _killAuraTimer = 0
local _afkTimer = 0
local _spinTimer = 0
local aimTarget = nil
local espStore = {}
local fovCircleDrawing = nil
local netStatsLabel = nil

local function stopFly()
	pcall(function() if flyBV then flyBV:Destroy() end end)
	pcall(function() if flyBG then flyBG:Destroy() end end)
	flyBV, flyBG = nil, nil
	flyVel = Vector3.new()
	local hum = getHum()
	if hum then pcall(function() hum.PlatformStand = false end) end
end

local function startFly()
	stopFly()
	local hrp = getHRP()
	local hum = getHum()
	if not hrp or not hum then return end
	pcall(function() hum.PlatformStand = true end)
	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e9,1e9,1e9)
	flyBV.Velocity = Vector3.new()
	flyBV.Name = "SpartaFly"
	flyBV.Parent = hrp
	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e9,1e9,1e9)
	flyBG.P = 6e4
	flyBG.D = 800
	flyBG.CFrame = hrp.CFrame
	flyBG.Name = "SpartaGyro"
	flyBG.Parent = hrp
end

local function getESPColor(plr)
	if not cfg.TeamColor then return Color3.new(1,0.25,0.25) end
	local myTeam = lp.Team
	if plr.Team and myTeam and plr.Team == myTeam then
		return Color3.new(0.2,1,0.4)
	end
	return Color3.new(1,0.25,0.25)
end

local function w2v(pos)
	local sp, vis, z = Camera:WorldToViewportPoint(pos)
	return Vector2.new(sp.X, sp.Y), vis, z
end

local function newDrawing(dtype, props)
	local ok, d = pcall(Drawing.new, dtype)
	if not ok or not d then return nil end
	d.Visible = false
	for k,v in pairs(props or {}) do pcall(function() d[k]=v end) end
	return d
end

local function getOrMakeESP(plr)
	if not espStore[plr.Name] then
		espStore[plr.Name] = {
			box      = newDrawing("Square",  { Thickness=1.5, Filled=false }),
			boxBg    = newDrawing("Square",  { Thickness=0, Filled=true, Color=Color3.new(0,0,0), Transparency=0.7 }),
			cTL      = newDrawing("Line",    { Thickness=2 }),
			cTR      = newDrawing("Line",    { Thickness=2 }),
			cBL      = newDrawing("Line",    { Thickness=2 }),
			cBR      = newDrawing("Line",    { Thickness=2 }),
			cTLv     = newDrawing("Line",    { Thickness=2 }),
			cTRv     = newDrawing("Line",    { Thickness=2 }),
			cBLv     = newDrawing("Line",    { Thickness=2 }),
			cBRv     = newDrawing("Line",    { Thickness=2 }),
			name     = newDrawing("Text",    { Size=13, Center=true, Outline=true, OutlineColor=Color3.new() }),
			dist     = newDrawing("Text",    { Size=10, Center=true, Outline=true, OutlineColor=Color3.new() }),
			weapon   = newDrawing("Text",    { Size=10, Center=true, Outline=true, OutlineColor=Color3.new() }),
			hpBg     = newDrawing("Square",  { Filled=true, Color=Color3.new(0,0,0) }),
			hpFill   = newDrawing("Square",  { Filled=true }),
			hpText   = newDrawing("Text",    { Size=9, Center=true, Outline=true }),
			tracer   = newDrawing("Line",    { Thickness=1 }),
			snapline = newDrawing("Line",    { Thickness=1, Color=Color3.new(1,1,0) }),
			skBones  = {},
		}
		local BONES = {
			{"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
			{"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
			{"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
			{"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
			{"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
		}
		for _, pair in ipairs(BONES) do
			table.insert(espStore[plr.Name].skBones, {
				line=newDrawing("Line",{Thickness=1}), from=pair[1], to=pair[2]
			})
		end
	end
	return espStore[plr.Name]
end

local function hideESPObj(obj)
	if not obj then return end
	for k, v in pairs(obj) do
		if type(v) == "userdata" then
			pcall(function() v.Visible = false end)
		elseif type(v) == "table" and k == "skBones" then
			for _, bone in ipairs(v) do
				pcall(function() bone.line.Visible = false end)
			end
		end
	end
end

local function clearAllESP()
	for _, obj in pairs(espStore) do
		hideESPObj(obj)
	end
	espStore = {}
end

pcall(function()
	local mouseMeta = _getrawmetatable(mouse)
	if mouseMeta then
		local oldIdx = rawget(mouseMeta, "__index")
		_setreadonly(mouseMeta, false)
		rawset(mouseMeta, "__index", _newcclosure(function(self, key)
			if cfg.SilentAim and aimTarget then
				if key == "Hit" then return CFrame.new(aimTarget.Position) end
				if key == "Target" then return aimTarget end
			end
			local ok, result = pcall(oldIdx, self, key)
			if ok then return result end
		end))
		_setreadonly(mouseMeta, true)
	end
end)

local function findAimTarget()
	local hrp = getHRP()
	if not hrp then return nil, nil end
	local vp = Camera.ViewportSize
	local center = Vector2.new(vp.X/2, vp.Y/2)
	local best, bestPart, bestDist = nil, nil, cfg.FOVSize

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == lp then continue end
		if cfg.AimTeamCheck and lp.Team and plr.Team and plr.Team == lp.Team then continue end
		local char = plr.Character
		if not char then continue end
		local phum = char:FindFirstChildOfClass("Humanoid")
		if not phum or phum.Health <= 0 then continue end

		local partsToCheck = cfg.Multipoint
			and { "Head", "UpperTorso", "HumanoidRootPart" }
			or  { cfg.AimPart or "Head", "HumanoidRootPart" }

		for _, pname in ipairs(partsToCheck) do
			local part = char:FindFirstChild(pname)
			if not part then continue end

			local targetPos = part.Position
			if cfg.Prediction then
				local phrp = char:FindFirstChild("HumanoidRootPart")
				if phrp then
					local vel = Vector3.new()
					pcall(function() vel = phrp.Velocity end)
					targetPos = targetPos + vel * (cfg.PredictionStrength / 500)
				end
			end

			if cfg.AimVisibleOnly then
				local rp = RaycastParams.new()
				rp.FilterDescendantsInstances = { getChar(), char }
				rp.FilterType = Enum.RaycastFilterType.Exclude
				local res = Workspace:Raycast(Camera.CFrame.Position, (targetPos - Camera.CFrame.Position).Unit * 5000, rp)
				if res then continue end
			end

			local sp, onScreen, z = w2v(targetPos)
			if not onScreen or z < 0 then continue end
			local d2 = (sp - center).Magnitude
			if d2 < bestDist then
				bestDist = d2
				best = plr
				bestPart = part
			end
		end
	end

	return best, bestPart
end

local function runESPFrame()
	local anyESP = cfg.PlayerESP or cfg.BoxESP or cfg.CornerBox or cfg.Box3D or
	               cfg.NameESP or cfg.DistanceESP or cfg.HealthBar or cfg.Tracers or
	               cfg.SkeletonESP or cfg.Snapline or cfg.WeaponESP

	if not anyESP then
		clearAllESP()
		return
	end

	local hrp = getHRP()
	local rendered = {}
	local vp = Camera.ViewportSize
	local centerX = vp.X / 2

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == lp then continue end
		local char = plr.Character
		if not char then continue end
		local phum = char:FindFirstChildOfClass("Humanoid")
		if not phum then continue end
		local phrp = char:FindFirstChild("HumanoidRootPart")
		if not phrp then continue end

		local dist = hrp and (phrp.Position - hrp.Position).Magnitude or 0
		if dist > cfg.ESPMaxDist then continue end

		local head = char:FindFirstChild("Head")
		local topPos = head and (head.Position + Vector3.new(0,head.Size.Y/2,0)) or phrp.Position+Vector3.new(0,3.5,0)
		local botPos = phrp.Position - Vector3.new(0,3.2,0)

		local topSP, topVis, topZ = w2v(topPos)
		local botSP = w2v(botPos)
		if not topVis or topZ < 0 then continue end

		rendered[plr.Name] = true
		local obj = getOrMakeESP(plr)
		local espCol = getESPColor(plr)

		local alpha = cfg.FadeByDistance and math.clamp(1 - dist/cfg.ESPMaxDist, 0.2, 1) or 1
		if cfg.HealthColor and phum then
			local hpPct = math.clamp(phum.Health/phum.MaxHealth, 0, 1)
			espCol = Color3.fromHSV(hpPct * 0.33, 1, 1)
		end

		local boxW = math.clamp(60 * (1 - dist/6000), 14, 80)
		local bx = topSP.X - boxW/2
		local by = topSP.Y
		local bw = boxW
		local bh = math.abs(botSP.Y - topSP.Y)

		if cfg.BoxESP and obj.box then
			obj.box.Visible = true
			obj.box.Color = espCol
			obj.box.Transparency = 1 - alpha
			obj.box.Position = Vector2.new(bx, by)
			obj.box.Size = Vector2.new(bw, bh)
			if obj.boxBg then
				obj.boxBg.Visible = true
				obj.boxBg.Position = Vector2.new(bx, by)
				obj.boxBg.Size = Vector2.new(bw, bh)
			end
		elseif obj.box then obj.box.Visible = false; if obj.boxBg then obj.boxBg.Visible = false end end

		if cfg.CornerBox then
			local cLen = math.max(bw * 0.22, 6)
			local corners = {
				{ obj.cTL,  Vector2.new(bx,by),       Vector2.new(bx+cLen,by) },
				{ obj.cTLv, Vector2.new(bx,by),       Vector2.new(bx,by+cLen) },
				{ obj.cTR,  Vector2.new(bx+bw,by),    Vector2.new(bx+bw-cLen,by) },
				{ obj.cTRv, Vector2.new(bx+bw,by),    Vector2.new(bx+bw,by+cLen) },
				{ obj.cBL,  Vector2.new(bx,by+bh),    Vector2.new(bx+cLen,by+bh) },
				{ obj.cBLv, Vector2.new(bx,by+bh),    Vector2.new(bx,by+bh-cLen) },
				{ obj.cBR,  Vector2.new(bx+bw,by+bh), Vector2.new(bx+bw-cLen,by+bh) },
				{ obj.cBRv, Vector2.new(bx+bw,by+bh), Vector2.new(bx+bw,by+bh-cLen) },
			}
			for _, c in ipairs(corners) do
				if c[1] then
					c[1].Visible = true
					c[1].Color = espCol
					c[1].Transparency = 1 - alpha
					c[1].From = c[2]; c[1].To = c[3]
				end
			end
		else
			for _, k in ipairs({"cTL","cTR","cBL","cBR","cTLv","cTRv","cBLv","cBRv"}) do
				if obj[k] then obj[k].Visible = false end
			end
		end

		local nameY = by - 16
		if cfg.NameESP and obj.name then
			obj.name.Visible = true
			obj.name.Text = (plr.DisplayName ~= plr.Name) and (plr.DisplayName.." ["..plr.Name.."]") or plr.Name
			obj.name.Color = espCol
			obj.name.Transparency = 1 - alpha
			obj.name.Position = Vector2.new(topSP.X, nameY)
			obj.name.Size = math.clamp(14 - dist/250, 8, 14)
			nameY = nameY - 13
		elseif obj.name then obj.name.Visible = false end

		if cfg.DistanceESP and obj.dist then
			obj.dist.Visible = true
			obj.dist.Text = string.format("[%.0f st]", dist)
			obj.dist.Color = Color3.new(0.65,0.65,0.65)
			obj.dist.Transparency = 1 - alpha
			obj.dist.Position = Vector2.new(topSP.X, nameY)
			obj.dist.Size = 10
		elseif obj.dist then obj.dist.Visible = false end

		if cfg.WeaponESP and obj.weapon then
			local tool = plr.Character and plr.Character:FindFirstChildOfClass("Tool")
			if tool then
				obj.weapon.Visible = true
				obj.weapon.Text = "🔫 "..tool.Name
				obj.weapon.Color = Color3.new(0.9,0.9,0.5)
				obj.weapon.Position = Vector2.new(topSP.X, by+bh+3)
				obj.weapon.Size = 10
			else obj.weapon.Visible = false end
		elseif obj.weapon then obj.weapon.Visible = false end

		if cfg.HealthBar and phum and obj.hpBg and obj.hpFill then
			local hpPct = math.clamp(phum.Health / math.max(phum.MaxHealth,1), 0, 1)
			local barX = bx - 6
			obj.hpBg.Visible = true
			obj.hpBg.Position = Vector2.new(barX, by)
			obj.hpBg.Size = Vector2.new(4, bh)
			obj.hpFill.Visible = true
			obj.hpFill.Color = Color3.fromHSV(hpPct * 0.33, 1, 1)
			obj.hpFill.Position = Vector2.new(barX, by + bh*(1-hpPct))
			obj.hpFill.Size = Vector2.new(4, bh*hpPct)
			if cfg.HealthText and obj.hpText then
				obj.hpText.Visible = true
				obj.hpText.Text = tostring(math.floor(phum.Health))
				obj.hpText.Color = Color3.new(1,1,1)
				obj.hpText.Position = Vector2.new(barX-2, by+bh*0.5-5)
				obj.hpText.Size = 9
			elseif obj.hpText then obj.hpText.Visible = false end
		elseif obj.hpBg then
			obj.hpBg.Visible = false
			if obj.hpFill then obj.hpFill.Visible = false end
			if obj.hpText then obj.hpText.Visible = false end
		end

		if cfg.Tracers and obj.tracer then
			obj.tracer.Visible = true
			obj.tracer.Color = espCol
			obj.tracer.Transparency = 1 - (alpha * 0.7)
			obj.tracer.From = Vector2.new(centerX, vp.Y)
			obj.tracer.To = Vector2.new(botSP.X, botSP.Y)
		elseif obj.tracer then obj.tracer.Visible = false end

		if cfg.Snapline and obj.snapline then
			obj.snapline.Visible = true
			obj.snapline.From = Vector2.new(centerX, vp.Y/2)
			obj.snapline.To = Vector2.new(topSP.X, topSP.Y)
			obj.snapline.Color = espCol
		elseif obj.snapline then obj.snapline.Visible = false end

		if cfg.SkeletonESP and obj.skBones then
			for _, bone in ipairs(obj.skBones) do
				local pA = char:FindFirstChild(bone.from)
				local pB = char:FindFirstChild(bone.to)
				if pA and pB then
					local spA, visA = w2v(pA.Position)
					local spB, visB = w2v(pB.Position)
					if visA and visB then
						bone.line.Visible = true
						bone.line.Color = espCol
						bone.line.Transparency = 1 - alpha
						bone.line.From = spA
						bone.line.To = spB
					else bone.line.Visible = false end
				else bone.line.Visible = false end
			end
		elseif obj.skBones then
			for _, bone in ipairs(obj.skBones) do
				pcall(function() bone.line.Visible = false end)
			end
		end

		if cfg.Chams then
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("BasePart") and not part:FindFirstChild("SC") then
					pcall(function()
						local sb = Instance.new("SelectionBox")
						sb.Name = "SC"
						sb.Adornee = part
						sb.Color3 = espCol
						sb.LineThickness = 0.06
						sb.SurfaceTransparency = 0.65
						sb.SurfaceColor3 = espCol
						sb.Parent = part
					end)
				end
			end
		else
			for _, part in ipairs(char:GetDescendants()) do
				if part:IsA("SelectionBox") and part.Name == "SC" then
					pcall(function() part:Destroy() end)
				end
			end
		end
	end

	for name, obj in pairs(espStore) do
		if not rendered[name] then hideESPObj(obj) end
	end
end

local _hs_0 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
	chromaFrac = chromaFrac + dt / 0.18
	if chromaFrac >= 1 then
		chromaFrac = chromaFrac - 1
		chromaIdx = (chromaIdx % #CHROMA_SEQ) + 1
	end
	pcall(function() rootStroke.Color = getChroma() end)
	pcall(function() chromaTitle.TextColor3 = getChroma(1) end)
end))

local _hs_1 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
	_aimTimer = _aimTimer + dt
	if _aimTimer < (cfg.TimingJitter and jitter(0.2) or 0.2) then return end
	_aimTimer = 0

	local _, bestPart = findAimTarget()
	aimTarget = bestPart

	if cfg.AimLock and bestPart then
		local smooth = math.clamp(1 - (cfg.Smoothness/100)*0.96, 0.02, 1)
		local targetCF = CFrame.new(Camera.CFrame.Position, bestPart.Position)
		pcall(function() Camera.CFrame = Camera.CFrame:Lerp(targetCF, smooth) end)
	end
end))

local _hs_2 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
	local char = getChar()
	local hrp = getHRP()
	local hum = getHum()
	if not char or not hrp or not hum then return end

	if cfg.GodMode or (cfg.RageMode and cfg.RageGod) then
		if not _godConn then
			pcall(function()
				hum.MaxHealth = math.huge
				hum.Health = math.huge
				_godConn = hum.HealthChanged:Connect(function()
					pcall(function() hum.Health = hum.MaxHealth end)
				end)
			end)
		end
	else
		if _godConn then _godConn:Disconnect(); _godConn = nil end
	end

	if cfg.InfiniteJump then
		if not _jumpConn then
			_jumpConn = hum.StateChanged:Connect(function(_, new)
				if new == Enum.HumanoidStateType.Freefall and cfg.InfiniteJump then
					task.wait(0.07)
					pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
				end
			end)
		end
	else
		if _jumpConn then _jumpConn:Disconnect(); _jumpConn = nil end
	end

	if cfg.NoFallDamage or (cfg.RageMode and cfg.RageNoFall) then
		if not _fallConn then
			local lastHp = hum.Health
			_fallConn = hum.HealthChanged:Connect(function(newHp)
				local diff = lastHp - newHp
				lastHp = newHp
				if diff > hum.MaxHealth * 0.08 and hum.FloorMaterial == Enum.Material.Air then
					pcall(function() hum.Health = hum.Health + diff end)
				end
			end)
		end
	else
		if _fallConn then _fallConn:Disconnect(); _fallConn = nil end
	end

	local targetWS = 16
	if cfg.SpeedHack or (cfg.RageMode and cfg.RageMaxSpeed) then
		targetWS = (cfg.RageMode and cfg.RageMaxSpeed) and 200 or cfg.WalkSpeed
	end
	if targetWS ~= 16 then
		pcall(function() hum.WalkSpeed = targetWS end)
	end

	if cfg.JumpPower and cfg.InfiniteJump then
		pcall(function() hum.JumpPower = cfg.JumpPower end)
	end

	if cfg.Noclip then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then
				pcall(function() p.CanCollide = false end)
			end
		end
	end

	if cfg.GravityHack then
		pcall(function() Workspace.Gravity = cfg.GravityValue end)
	end

	if cfg.NoAnimations then
		local tracks = hum:GetPlayingAnimationTracks()
		for _, t in ipairs(tracks) do
			pcall(function() t:Stop(0) end)
		end
	end

	if cfg.Invisible then
		for _, p in ipairs(char:GetDescendants()) do
			if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
				pcall(function() p.LocalTransparencyModifier = 1 end)
			end
		end
	end

	if cfg.BunnyHop then
		if hum.FloorMaterial ~= Enum.Material.Air then
			pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
		end
	end

	if cfg.Rejoin then
		cfg.Rejoin = false
		pcall(function() TeleportService:Teleport(game.PlaceId, lp) end)
	end

	if cfg.CopyUsername then
		cfg.CopyUsername = false
		pcall(function() setclipboard(lp.Name) end)
	end
end))

local _hs_3 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
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
	if cfg.NoClouds then
		pcall(function()
			local sky = Lighting:FindFirstChildOfClass("Sky")
			if sky then sky.Parent = nil end
		end)
	end
end))

local _hs_4 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
	if cfg.Fly then
		local hrp = getHRP()
		local hum = getHum()
		if not hrp or not hum then stopFly(); return end
		if not flyBV or not flyBG then startFly() end
		if not flyBV then return end

		pcall(function() hum.PlatformStand = true end)

		if cfg.FlyNoclip then
			local char = getChar()
			if char then
				for _, p in ipairs(char:GetDescendants()) do
					if p:IsA("BasePart") then pcall(function() p.CanCollide = false end) end
				end
			end
		end

		local camCF = Camera.CFrame
		local movDir = Vector3.new()
		if hum.MoveDirection.Magnitude > 0.05 then
			if cfg.CameraRelative then
				local fwd = Vector3.new(camCF.LookVector.X,0,camCF.LookVector.Z)
				local rgt = Vector3.new(camCF.RightVector.X,0,camCF.RightVector.Z)
				if fwd.Magnitude > 0.01 then fwd = fwd.Unit end
				if rgt.Magnitude > 0.01 then rgt = rgt.Unit end
				movDir = (fwd * hum.MoveDirection.Z * -1 + rgt * hum.MoveDirection.X)
				if movDir.Magnitude > 0.01 then movDir = movDir.Unit end
			else
				movDir = hum.MoveDirection
			end
		end

		local upDown = 0
		if UserInputService:IsKeyDown(Enum.KeyCode.Space) then upDown = 1 end
		if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) or UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then upDown = -1 end
		if hum.Jump then upDown = math.max(upDown, 0.85) end

		local targetVel = movDir * cfg.FlySpeed + Vector3.new(0, upDown * cfg.VerticalSpeed, 0)

		if cfg.AltitudeLock and upDown == 0 and movDir.Magnitude < 0.05 then
			local currentHeight = hrp.Position.Y
			local diff = cfg.LockAltitude - currentHeight
			targetVel = Vector3.new(0, math.clamp(diff * 3, -cfg.VerticalSpeed, cfg.VerticalSpeed), 0)
		end

		if cfg.SmoothFly then
			local factor = math.clamp(dt * 9, 0, 1)
			flyVel = Vector3.new(
				lerp(flyVel.X, targetVel.X, factor),
				lerp(flyVel.Y, targetVel.Y, factor),
				lerp(flyVel.Z, targetVel.Z, factor)
			)
		else
			flyVel = targetVel
		end

		if cfg.AntiGravity and targetVel.Magnitude < 0.5 then
			flyVel = Vector3.new(flyVel.X * 0.82, 0, flyVel.Z * 0.82)
		end

		pcall(function()
			flyBV.Velocity = flyVel
			flyBG.CFrame = camCF
		end)
	else
		if flyBV or flyBG then stopFly() end
	end
end))

local _hs_5 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
	if cfg.HitboxExpand or (cfg.RageMode and cfg.RageMaxHitbox) then
		local expandSize = (cfg.RageMode and cfg.RageMaxHitbox) and 20 or cfg.HitboxSize
		local headSize   = (cfg.RageMode and cfg.RageMaxHitbox) and 20 or cfg.HeadSize

		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == lp then continue end
			if cfg.HitboxTeamCheck and lp.Team and plr.Team and plr.Team == lp.Team then continue end
			local char = plr.Character
			if not char then continue end

			if not cfg.HeadExpand then
				local phrp = char:FindFirstChild("HumanoidRootPart")
				if phrp then
					pcall(function()
						phrp.Size = Vector3.new(expandSize, expandSize, expandSize)
						phrp.Transparency = cfg.HitboxShowVisual and (1 - cfg.HitboxOpacity/100) or 0.999
					end)
				end
			end

			local head = char:FindFirstChild("Head")
			if head then
				pcall(function()
					head.Size = Vector3.new(headSize, headSize, headSize)
					head.Transparency = cfg.HitboxShowVisual and (1 - cfg.HitboxOpacity/100) or 0.999
				end)
			end

			if cfg.HitboxArmsOnly or cfg.HitboxLegsOnly then
				local armParts = {"RightUpperArm","RightLowerArm","RightHand","LeftUpperArm","LeftLowerArm","LeftHand"}
				local legParts = {"RightUpperLeg","RightLowerLeg","RightFoot","LeftUpperLeg","LeftLowerLeg","LeftFoot"}
				local targets = cfg.HitboxArmsOnly and armParts or legParts
				for _, pname in ipairs(targets) do
					local part = char:FindFirstChild(pname)
					if part then
						pcall(function()
							part.Size = Vector3.new(expandSize, expandSize, expandSize)
							part.Transparency = 0.999
						end)
					end
				end
			end
		end
	end
end))

local _hs_6 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
	_autoClickTimer = _autoClickTimer + dt
	if not cfg.AutoClick then return end

	local cps = cfg.CPS
	if cfg.RandomizeCPS then
		local variance = cps * (cfg.RandomRange / 100)
		cps = cps + (math.random() - 0.5) * variance * 2
	end
	cps = math.max(cps, 0.5)
	local interval = 1 / cps

	if _autoClickTimer >= interval then
		_autoClickTimer = 0

		if cfg.JitterAim then
			pcall(function()
				Camera.CFrame = Camera.CFrame * CFrame.Angles(
					(math.random()-0.5) * math.rad(cfg.JitterStrength * 0.12),
					(math.random()-0.5) * math.rad(cfg.JitterStrength * 0.12),
					0
				)
			end)
		end

		pcall(function()
			local vp = Camera.ViewportSize
			VirtualUser:ClickButton1(Vector2.new(vp.X/2, vp.Y/2), Camera.CFrame)
		end)

		if cfg.DoubleClick then
			task.delay(0.02, function()
				pcall(function()
					local vp = Camera.ViewportSize
					VirtualUser:ClickButton1(Vector2.new(vp.X/2, vp.Y/2), Camera.CFrame)
				end)
			end)
		end
	end
end))

local _hs_7 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
	_triggerTimer = _triggerTimer + dt
	if not cfg.TriggerBot then return end

	local hrp = getHRP()
	if not hrp then return end

	local vp = Camera.ViewportSize
	local rp = RaycastParams.new()
	rp.FilterDescendantsInstances = { getChar() }
	rp.FilterType = Enum.RaycastFilterType.Exclude

	local ray = Workspace:Raycast(Camera.CFrame.Position, Camera.CFrame.LookVector * 2000, rp)
	if not ray then return end

	local hitPart = ray.Instance
	if not hitPart then return end

	local hitChar = hitPart.Parent
	local hitHum = hitChar:FindFirstChildOfClass("Humanoid")
	if not hitHum or hitHum.Health <= 0 then return end

	local hitPlr = Players:GetPlayerFromCharacter(hitChar)
	if not hitPlr or hitPlr == lp then return end
	if cfg.TriggerTeamCheck and lp.Team and hitPlr.Team and hitPlr.Team == lp.Team then return end
	if cfg.TriggerHeadOnly and hitPart.Name ~= "Head" then return end

	local preDelay = cfg.TriggerPreDelay / 1000
	if cfg.TriggerRandomDelay then
		preDelay = preDelay * (1 + (math.random()-0.5) * cfg.TriggerRandomRange/100 * 2)
	end

	task.delay(preDelay, function()
		if not cfg.TriggerBot then return end
		pcall(function()
			local vp2 = Camera.ViewportSize
			VirtualUser:ClickButton1(Vector2.new(vp2.X/2, vp2.Y/2), Camera.CFrame)
		end)

		if cfg.TriggerBurst then
			for i = 2, cfg.TriggerBurstCount do
				task.delay((cfg.TriggerPostDelay/1000) * i, function()
					if not cfg.TriggerBot then return end
					pcall(function()
						local vp2 = Camera.ViewportSize
						VirtualUser:ClickButton1(Vector2.new(vp2.X/2, vp2.Y/2), Camera.CFrame)
					end)
				end)
			end
		end
	end)
end))

local _hs_8 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
	_killAuraTimer = _killAuraTimer + dt
	local auraActive = cfg.KillAura or (cfg.RageMode and cfg.RageKillAura)
	if not auraActive then return end

	local attackRate = cfg.KillAuraRate
	if cfg.RageMode and cfg.RageKillAura then attackRate = 20 end
	local interval = 1 / math.max(attackRate, 0.5)
	if cfg.KillAuraRandom then
		interval = interval * (0.8 + math.random() * 0.4)
	end
	if _killAuraTimer < interval then return end
	_killAuraTimer = 0

	local hrp = getHRP()
	if not hrp then return end

	local range = (cfg.RageMode and cfg.RageKillAura) and 80 or cfg.KillAuraRange

	local bestPlr = nil
	local bestScore = math.huge

	for _, plr in ipairs(Players:GetPlayers()) do
		if plr == lp then continue end
		if cfg.KillAuraTeamCheck and lp.Team and plr.Team and plr.Team == lp.Team then continue end
		local char = plr.Character
		if not char then continue end
		local phum = char:FindFirstChildOfClass("Humanoid")
		if not phum or phum.Health <= 0 then continue end
		local phrp = char:FindFirstChild("HumanoidRootPart")
		if not phrp then continue end
		local dist = (phrp.Position - hrp.Position).Magnitude
		if dist > range then continue end

		if cfg.KillAuraVisible then
			local rp = RaycastParams.new()
			rp.FilterDescendantsInstances = { getChar(), char }
			rp.FilterType = Enum.RaycastFilterType.Exclude
			local res = Workspace:Raycast(hrp.Position, (phrp.Position-hrp.Position).Unit * range, rp)
			if res then continue end
		end

		local score = cfg.KillAuraLowestHP and phum.Health or dist
		if score < bestScore then
			bestScore = score
			bestPlr = plr
		end
	end

	if bestPlr then
		if cfg.KillAuraSpin or (cfg.RageMode and cfg.RageSpinBot) then
			local spinSpeed = cfg.KillAuraSpinSpeed
			_spinAngle = _spinAngle + spinSpeed
			pcall(function()
				local hrp2 = getHRP()
				if hrp2 then
					hrp2.CFrame = CFrame.new(hrp2.Position) * CFrame.Angles(0, math.rad(_spinAngle), 0)
				end
			end)
		end

		local targetChar = bestPlr.Character
		if targetChar then
			local targetHRP = targetChar:FindFirstChild("HumanoidRootPart")
			if targetHRP then
				pcall(function()
					local myHRP = getHRP()
					if myHRP then
						myHRP.CFrame = CFrame.new(myHRP.Position, Vector3.new(targetHRP.Position.X, myHRP.Position.Y, targetHRP.Position.Z))
					end
					VirtualUser:ClickButton1(Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2), Camera.CFrame)
				end)
			end
		end
	end
end))

local _hs_9 = RunService.RenderStepped:Connect(_newcclosure(function()
	runESPFrame()

	if cfg.FOVCircle and (cfg.SilentAim or cfg.AimLock) then
		if not fovCircleDrawing then
			fovCircleDrawing = newDrawing("Circle", { NumSides=80, Thickness=1.2, Filled=false })
		end
		if fovCircleDrawing then
			fovCircleDrawing.Visible = true
			fovCircleDrawing.Radius = cfg.FOVSize
			fovCircleDrawing.Position = Camera.ViewportSize / 2
			fovCircleDrawing.Color = Color3.new(1,1,1)
			fovCircleDrawing.Transparency = 0.65
		end
	else
		if fovCircleDrawing then fovCircleDrawing.Visible = false end
	end
end))

local _afkConn = nil
local function setupAntiAFK()
	if _afkConn then _afkConn:Disconnect(); _afkConn = nil end
	if not cfg.AntiAFK then return end
	_afkConn = lp.Idled:Connect(function()
		pcall(function()
			VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
			task.wait(0.4)
			VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
		end)
	end)
end
setupAntiAFK()

local _hs_10 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
	_afkTimer = _afkTimer + dt
	if _afkTimer < cfg.AntiAFKInterval then return end
	_afkTimer = 0
	if not cfg.AntiAFK then return end
	pcall(function()
		VirtualUser:Button2Down(Vector2.new(0,0), Camera.CFrame)
		task.wait(0.3)
		VirtualUser:Button2Up(Vector2.new(0,0), Camera.CFrame)
	end)
end))

local _hs_11 = RunService.Heartbeat:Connect(_newcclosure(function(dt)
	if cfg.AntiScanner then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == lp then continue end
			pcall(function()
				for _, obj in ipairs(plr:GetDescendants()) do
					if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
						local n = obj.Name:lower()
						if n:find("log") or n:find("detect") or n:find("ban") or n:find("report") then
							obj.Name = "Event_"..tostring(math.random(100,999))
						end
					end
				end
			end)
		end
	end

	if cfg.RemoteLogger then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr == lp then continue end
			pcall(function()
				for _, obj in ipairs(game:GetDescendants()) do
					if obj:IsA("RemoteEvent") then
						if not obj:FindFirstChild("__logged") then
							local tag = Instance.new("BoolValue")
							tag.Name = "__logged"
							tag.Parent = obj
							obj.OnClientEvent:Connect(function(...)
								pcall(function()
									_warn_orig("[RemoteLogger] "..obj:GetFullName(), ...)
								end)
							end)
						end
					end
				end
			end)
		end
	end
end))

lp.CharacterAdded:Connect(function(newChar)
	_cachedChar = newChar
	_cachedHRP  = newChar:WaitForChild("HumanoidRootPart", 5)
	_cachedHum  = newChar:WaitForChild("Humanoid", 5)
	_cachedRoot = _cachedHRP
	_godConn = nil
	_jumpConn = nil
	_fallConn = nil
	flyBV, flyBG = nil, nil
	flyVel = Vector3.new()

	task.wait(0.3)

	if cfg.GodMode and _cachedHum then
		_cachedHum.MaxHealth = math.huge
		_cachedHum.Health = math.huge
	end

	if cfg.PlayerSize and _cachedChar then
		for _, p in ipairs(_cachedChar:GetDescendants()) do
			if p:IsA("BasePart") then
				pcall(function()
					p.Size = p.Size * (cfg.SizeScale / 100)
				end)
			end
		end
	end

	if cfg.NoAccessories and _cachedChar then
		for _, acc in ipairs(_cachedChar:GetChildren()) do
			if acc:IsA("Accessory") then
				pcall(function() acc:Destroy() end)
			end
		end
	end
end)

lp.CharacterRemoving:Connect(function()
	stopFly()
	clearAllESP()
	_cachedChar = nil
	_cachedHRP  = nil
	_cachedHum  = nil
	_cachedRoot = nil
end)

task.spawn(function()
	while task.wait(jitter(0.5)) do
		pcall(refreshCharCache)
	end
end)

task.spawn(function()
	task.wait(jitter(2))
	pcall(function()
		local gameMeta = _getrawmetatable(game)
		if gameMeta then
			local origNC = rawget(gameMeta, "__namecall")
			if origNC then
				_setreadonly(gameMeta, false)
				rawset(gameMeta, "__namecall", _newcclosure(function(self, ...)
					local method = table.remove({...}, 1)
					if type(method) == "string" then
						local lo = method:lower()
						if lo == "kick" and self == lp and cfg.AntiKick then
							return
						end
					end
					return origNC(self, method, ...)
				end))
				_setreadonly(gameMeta, true)
			end
		end
	end)
end)

local _antiCrashConn = task.spawn(function()
	while true do
		task.wait(jitter(5))
		pcall(function()
			if not gui or not gui.Parent then
				local newGui = Instance.new("ScreenGui")
				newGui.Name = gui.Name
				newGui.Parent = _gethui()
			end
		end)
	end
end)

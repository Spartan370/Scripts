local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local PlayerGui = player:WaitForChild("PlayerGui")

local FLY_SPEED = 50
local BOOST_MULT = 1.4
local flying = false
local bodyVelocity, bodyGyro
local ControlModule

pcall(function()
	ControlModule = require(player:WaitForChild("PlayerScripts"):WaitForChild("PlayerModule")):GetControls()
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SystemHUD"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 220, 0, 148)
mainFrame.Position = UDim2.new(0.5, -110, 0.5, -74)
mainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
mainFrame.BorderSizePixel = 0
mainFrame.ClipsDescendants = false
mainFrame.Active = true
mainFrame.Parent = screenGui

local mainCorner = Instance.new("UICorner")
mainCorner.CornerRadius = UDim.new(0, 16)
mainCorner.Parent = mainFrame

local mainStroke = Instance.new("UIStroke")
mainStroke.Thickness = 2.5
mainStroke.Color = Color3.fromRGB(255, 0, 0)
mainStroke.Parent = mainFrame

local speedBar = Instance.new("Frame")
speedBar.Size = UDim2.new(0, 220, 0, 44)
speedBar.Position = UDim2.new(0, 0, 0, -52)
speedBar.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
speedBar.BorderSizePixel = 0
speedBar.Visible = false
speedBar.Parent = mainFrame

local speedBarCorner = Instance.new("UICorner")
speedBarCorner.CornerRadius = UDim.new(0, 12)
speedBarCorner.Parent = speedBar

local speedBarStroke = Instance.new("UIStroke")
speedBarStroke.Thickness = 2
speedBarStroke.Color = Color3.fromRGB(255, 0, 0)
speedBarStroke.Parent = speedBar

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(0, 70, 1, 0)
speedLabel.Position = UDim2.new(0, 10, 0, 0)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed:"
speedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
speedLabel.TextSize = 13
speedLabel.Font = Enum.Font.GothamBold
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Parent = speedBar

local speedBox = Instance.new("TextBox")
speedBox.Size = UDim2.new(0, 90, 0, 30)
speedBox.Position = UDim2.new(0, 72, 0.5, -15)
speedBox.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
speedBox.BorderSizePixel = 0
speedBox.Text = tostring(FLY_SPEED)
speedBox.TextColor3 = Color3.fromRGB(255, 255, 255)
speedBox.TextSize = 14
speedBox.Font = Enum.Font.GothamBold
speedBox.PlaceholderText = "Speed"
speedBox.PlaceholderColor3 = Color3.fromRGB(110, 110, 120)
speedBox.ClearTextOnFocus = true
speedBox.Parent = speedBar

local speedBoxCorner = Instance.new("UICorner")
speedBoxCorner.CornerRadius = UDim.new(0, 8)
speedBoxCorner.Parent = speedBox

local speedBoxStroke = Instance.new("UIStroke")
speedBoxStroke.Thickness = 1.5
speedBoxStroke.Color = Color3.fromRGB(90, 90, 110)
speedBoxStroke.Parent = speedBox

local setBtn = Instance.new("TextButton")
setBtn.Size = UDim2.new(0, 36, 0, 30)
setBtn.Position = UDim2.new(0, 168, 0.5, -15)
setBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 200)
setBtn.Text = "Set"
setBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
setBtn.TextSize = 12
setBtn.Font = Enum.Font.GothamBold
setBtn.AutoButtonColor = false
setBtn.Parent = speedBar

local setBtnCorner = Instance.new("UICorner")
setBtnCorner.CornerRadius = UDim.new(0, 8)
setBtnCorner.Parent = setBtn

local function applySpeed()
	local val = tonumber(speedBox.Text)
	if val and val > 0 then
		FLY_SPEED = val
		speedBox.Text = tostring(val)
		speedBoxStroke.Color = Color3.fromRGB(80, 255, 80)
		task.delay(0.5, function()
			speedBoxStroke.Color = Color3.fromRGB(90, 90, 110)
		end)
	else
		speedBoxStroke.Color = Color3.fromRGB(255, 60, 60)
		speedBox.Text = tostring(FLY_SPEED)
		task.delay(0.5, function()
			speedBoxStroke.Color = Color3.fromRGB(90, 90, 110)
		end)
	end
end

setBtn.TouchTap:Connect(applySpeed)
speedBox.FocusLost:Connect(function(enter)
	if enter then applySpeed() end
end)

local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 36)
titleBar.Position = UDim2.new(0, 0, 0, 0)
titleBar.BackgroundTransparency = 1
titleBar.Parent = mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -90, 1, 0)
title.Position = UDim2.new(0, 12, 0, 0)
title.BackgroundTransparency = 1
title.Text = "✈ MOBILE FLY"
title.TextColor3 = Color3.fromRGB(255, 80, 80)
title.TextSize = 15
title.Font = Enum.Font.GothamBold
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = titleBar

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 26, 0, 26)
plusBtn.Position = UDim2.new(1, -88, 0.5, -13)
plusBtn.BackgroundColor3 = Color3.fromRGB(30, 100, 200)
plusBtn.Text = "+"
plusBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
plusBtn.TextSize = 18
plusBtn.Font = Enum.Font.GothamBold
plusBtn.AutoButtonColor = false
plusBtn.Parent = titleBar

local plusCorner = Instance.new("UICorner")
plusCorner.CornerRadius = UDim.new(0, 8)
plusCorner.Parent = plusBtn

local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, 26, 0, 26)
collapseBtn.Position = UDim2.new(1, -58, 0.5, -13)
collapseBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
collapseBtn.Text = "−"
collapseBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
collapseBtn.TextSize = 18
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.AutoButtonColor = false
collapseBtn.Parent = titleBar

local collapseCorner = Instance.new("UICorner")
collapseCorner.CornerRadius = UDim.new(0, 8)
collapseCorner.Parent = collapseBtn

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -30, 0.5, -13)
closeBtn.BackgroundColor3 = Color3.fromRGB(190, 40, 50)
closeBtn.Text = "×"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 16
closeBtn.Font = Enum.Font.GothamBold
closeBtn.AutoButtonColor = false
closeBtn.Parent = titleBar

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 8)
closeCorner.Parent = closeBtn

local divider = Instance.new("Frame")
divider.Size = UDim2.new(1, -20, 0, 1)
divider.Position = UDim2.new(0, 10, 0, 36)
divider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
divider.BorderSizePixel = 0
divider.Parent = mainFrame

local bodyContainer = Instance.new("Frame")
bodyContainer.Size = UDim2.new(1, 0, 1, -37)
bodyContainer.Position = UDim2.new(0, 0, 0, 37)
bodyContainer.BackgroundTransparency = 1
bodyContainer.ClipsDescendants = true
bodyContainer.Parent = mainFrame

local toggleBtn = Instance.new("TextButton")
toggleBtn.Size = UDim2.new(0, 100, 0, 45)
toggleBtn.Position = UDim2.new(0.5, -50, 0, 10)
toggleBtn.BackgroundColor3 = Color3.fromRGB(55, 18, 18)
toggleBtn.Text = "OFF"
toggleBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
toggleBtn.TextSize = 18
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.AutoButtonColor = false
toggleBtn.Parent = bodyContainer

local btnCorner = Instance.new("UICorner")
btnCorner.CornerRadius = UDim.new(0, 12)
btnCorner.Parent = toggleBtn

local btnStroke = Instance.new("UIStroke")
btnStroke.Thickness = 2
btnStroke.Color = Color3.fromRGB(255, 60, 60)
btnStroke.Parent = toggleBtn

local statusLabel = Instance.new("TextLabel")
statusLabel.Size = UDim2.new(1, -20, 0, 24)
statusLabel.Position = UDim2.new(0, 10, 0, 62)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Tap to Enable"
statusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
statusLabel.TextSize = 12
statusLabel.Font = Enum.Font.Gotham
statusLabel.TextXAlignment = Enum.TextXAlignment.Center
statusLabel.Parent = bodyContainer

local function tweenProp(obj, goal)
	TweenService:Create(obj, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), goal):Play()
end

local collapsed = false
local EXPANDED_H = 148
local COLLAPSED_H = 40

collapseBtn.TouchTap:Connect(function()
	collapsed = not collapsed
	if collapsed then
		tweenProp(mainFrame, { Size = UDim2.new(0, 220, 0, COLLAPSED_H) })
		collapseBtn.Text = "+"
		speedBar.Visible = false
	else
		tweenProp(mainFrame, { Size = UDim2.new(0, 220, 0, EXPANDED_H) })
		collapseBtn.Text = "−"
	end
end)

local speedBarVisible = false
plusBtn.TouchTap:Connect(function()
	if collapsed then return end
	speedBarVisible = not speedBarVisible
	speedBar.Visible = speedBarVisible
	tweenProp(plusBtn, {
		BackgroundColor3 = speedBarVisible
			and Color3.fromRGB(60, 180, 60)
			or Color3.fromRGB(30, 100, 200)
	})
end)

closeBtn.TouchTap:Connect(function()
	mainFrame.Visible = false
	if flying then
		flying = false
		local char = player.Character
		if char and char:FindFirstChild("Humanoid") then
			char.Humanoid.PlatformStand = false
		end
		if bodyGyro then bodyGyro:Destroy() end
		if bodyVelocity then bodyVelocity:Destroy() end
	end
end)

local dragging = false
local dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = true
		dragStart = input.Position
		startPos = mainFrame.Position
	end
end)

UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.Touch then
		local delta = input.Position - dragStart
		mainFrame.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
end)

UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.Touch then
		dragging = false
	end
end)

local function startFly()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChild("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not root then return end

	flying = true
	humanoid.PlatformStand = true

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(4e5, 4e5, 4e5)
	bodyGyro.P = 3000
	bodyGyro.Parent = root

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.MaxForce = Vector3.new(4e5, 4e5, 4e5)
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.Parent = root

	toggleBtn.Text = "ON"
	tweenProp(toggleBtn, {
		BackgroundColor3 = Color3.fromRGB(18, 110, 18),
		TextColor3 = Color3.fromRGB(255, 255, 255),
	})
	statusLabel.Text = "FLYING ACTIVE ✓"
	statusLabel.TextColor3 = Color3.fromRGB(90, 255, 90)
end

local function stopFly()
	flying = false
	local character = player.Character
	if character and character:FindFirstChild("Humanoid") then
		character.Humanoid.PlatformStand = false
	end
	if bodyGyro then bodyGyro:Destroy() end
	if bodyVelocity then bodyVelocity:Destroy() end

	toggleBtn.Text = "OFF"
	tweenProp(toggleBtn, {
		BackgroundColor3 = Color3.fromRGB(55, 18, 18),
		TextColor3 = Color3.fromRGB(200, 200, 200),
	})
	statusLabel.Text = "Tap to Enable"
	statusLabel.TextColor3 = Color3.fromRGB(170, 170, 170)
end

toggleBtn.TouchTap:Connect(function()
	if flying then stopFly() else startFly() end
end)

local chromaHue = 0
RunService.RenderStepped:Connect(function(dt)
	chromaHue = (chromaHue + dt * 0.28) % 1
	local c = Color3.fromHSV(chromaHue, 1, 1)
	mainStroke.Color = c
	speedBarStroke.Color = c
	if not flying then
		btnStroke.Color = c
	end

	if flying then
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChild("Humanoid")
		local cam = workspace.CurrentCamera

		if root and humanoid and cam and bodyVelocity and bodyGyro then
			local moveVec = ControlModule and ControlModule:GetMoveVector() or Vector3.zero
			local vertBoost = humanoid.Jump and (FLY_SPEED * BOOST_MULT) or 0

			bodyVelocity.Velocity =
				cam.CFrame.RightVector * (moveVec.X * FLY_SPEED) +
				cam.CFrame.LookVector * (-moveVec.Z * FLY_SPEED) +
				Vector3.new(0, vertBoost, 0)

			bodyGyro.CFrame = cam.CFrame
		end
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(0.5)
	if flying then startFly() end
end)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
local humanoid = character:WaitForChild("Humanoid")

local flySpeed = 50
local flying = false
local flyConnection = nil
local bodyVelocity = nil
local bodyGyro = nil
local camera = workspace.CurrentCamera

player.CharacterAdded:Connect(function(char)
	character = char
	humanoidRootPart = char:WaitForChild("HumanoidRootPart")
	humanoid = char:WaitForChild("Humanoid")
end)

local function startFly()
	if flying then return end
	flying = true
	humanoid.PlatformStand = true

	bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = Vector3.zero
	bodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	bodyVelocity.Parent = humanoidRootPart

	bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	bodyGyro.P = 1e4
	bodyGyro.Parent = humanoidRootPart

	flyConnection = RunService.Heartbeat:Connect(function()
		if not flying then return end

		local camCF = camera.CFrame
		local moveDir = humanoid.MoveDirection

		local forward = Vector3.new(camCF.LookVector.X, 0, camCF.LookVector.Z)
		if forward.Magnitude > 0 then forward = forward.Unit end
		local right = Vector3.new(camCF.RightVector.X, 0, camCF.RightVector.Z)
		if right.Magnitude > 0 then right = right.Unit end

		local velocity = Vector3.zero
		if moveDir.Magnitude > 0 then
			local localX = moveDir:Dot(Vector3.new(1, 0, 0))
			local localZ = moveDir:Dot(Vector3.new(0, 0, 1))
			velocity = (forward * -localZ + right * localX) * flySpeed
		end

		bodyVelocity.Velocity = velocity
		bodyGyro.CFrame = camCF
	end)
end

local function stopFly()
	if not flying then return end
	flying = false
	humanoid.PlatformStand = false

	if flyConnection then
		flyConnection:Disconnect()
		flyConnection = nil
	end
	if bodyVelocity then
		bodyVelocity:Destroy()
		bodyVelocity = nil
	end
	if bodyGyro then
		bodyGyro:Destroy()
		bodyGyro = nil
	end
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SystemOverlay"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.IgnoreGuiInset = true
screenGui.Parent = player.PlayerGui

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0, 240, 0, 120)
mainFrame.Position = UDim2.new(0, 20, 0.5, -60)
mainFrame.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Parent = screenGui

Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 18)

local mainStroke = Instance.new("UIStroke")
mainStroke.Color = Color3.fromRGB(60, 60, 80)
mainStroke.Thickness = 1
mainStroke.Parent = mainFrame

local quickBtn = Instance.new("TextButton")
quickBtn.Size = UDim2.new(0, 36, 1, 0)
quickBtn.Position = UDim2.new(0, 0, 0, 0)
quickBtn.BackgroundColor3 = Color3.fromRGB(99, 82, 255)
quickBtn.BorderSizePixel = 0
quickBtn.Text = "⚡"
quickBtn.TextSize = 16
quickBtn.Font = Enum.Font.GothamBold
quickBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
quickBtn.AutoButtonColor = false
quickBtn.Parent = mainFrame

Instance.new("UICorner", quickBtn).CornerRadius = UDim.new(0, 18)

local quickMask = Instance.new("Frame")
quickMask.Size = UDim2.new(0, 18, 1, 0)
quickMask.Position = UDim2.new(1, -18, 0, 0)
quickMask.BackgroundColor3 = Color3.fromRGB(12, 12, 14)
quickMask.BorderSizePixel = 0
quickMask.ZIndex = 2
quickMask.Parent = quickBtn

local rightPanel = Instance.new("Frame")
rightPanel.Size = UDim2.new(1, -36, 1, 0)
rightPanel.Position = UDim2.new(0, 36, 0, 0)
rightPanel.BackgroundTransparency = 1
rightPanel.Parent = mainFrame

local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(1, -50, 0, 28)
titleLabel.Position = UDim2.new(0, 10, 0, 8)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Fly"
titleLabel.TextColor3 = Color3.fromRGB(200, 200, 220)
titleLabel.TextSize = 13
titleLabel.Font = Enum.Font.GothamSemibold
titleLabel.TextXAlignment = Enum.TextXAlignment.Left
titleLabel.Parent = rightPanel

local collapseBtn = Instance.new("TextButton")
collapseBtn.Size = UDim2.new(0, 26, 0, 26)
collapseBtn.Position = UDim2.new(1, -54, 0, 6)
collapseBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
collapseBtn.BorderSizePixel = 0
collapseBtn.Text = "−"
collapseBtn.TextSize = 15
collapseBtn.Font = Enum.Font.GothamBold
collapseBtn.TextColor3 = Color3.fromRGB(160, 160, 180)
collapseBtn.AutoButtonColor = false
collapseBtn.Parent = rightPanel
Instance.new("UICorner", collapseBtn).CornerRadius = UDim.new(0, 8)

local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -26, 0, 6)
closeBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 60)
closeBtn.BorderSizePixel = 0
closeBtn.Text = "×"
closeBtn.TextSize = 15
closeBtn.Font = Enum.Font.GothamBold
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.AutoButtonColor = false
closeBtn.Parent = rightPanel
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)

local controlsFrame = Instance.new("Frame")
controlsFrame.Size = UDim2.new(1, -10, 0, 54)
controlsFrame.Position = UDim2.new(0, 5, 0, 42)
controlsFrame.BackgroundTransparency = 1
controlsFrame.Parent = rightPanel

local controlsLayout = Instance.new("UIListLayout")
controlsLayout.FillDirection = Enum.FillDirection.Horizontal
controlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
controlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
controlsLayout.Padding = UDim.new(0, 8)
controlsLayout.Parent = controlsFrame

local minusBtn = Instance.new("TextButton")
minusBtn.Size = UDim2.new(0, 46, 0, 40)
minusBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
minusBtn.BorderSizePixel = 0
minusBtn.Text = "−"
minusBtn.TextSize = 22
minusBtn.Font = Enum.Font.GothamBold
minusBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
minusBtn.AutoButtonColor = false
minusBtn.Parent = controlsFrame
Instance.new("UICorner", minusBtn).CornerRadius = UDim.new(0, 12)

local flyToggleBtn = Instance.new("TextButton")
flyToggleBtn.Size = UDim2.new(0, 80, 0, 40)
flyToggleBtn.BackgroundColor3 = Color3.fromRGB(99, 82, 255)
flyToggleBtn.BorderSizePixel = 0
flyToggleBtn.Text = "Fly"
flyToggleBtn.TextSize = 14
flyToggleBtn.Font = Enum.Font.GothamBold
flyToggleBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
flyToggleBtn.AutoButtonColor = false
flyToggleBtn.Parent = controlsFrame
Instance.new("UICorner", flyToggleBtn).CornerRadius = UDim.new(0, 12)

local plusBtn = Instance.new("TextButton")
plusBtn.Size = UDim2.new(0, 46, 0, 40)
plusBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 36)
plusBtn.BorderSizePixel = 0
plusBtn.Text = "+"
plusBtn.TextSize = 22
plusBtn.Font = Enum.Font.GothamBold
plusBtn.TextColor3 = Color3.fromRGB(200, 200, 220)
plusBtn.AutoButtonColor = false
plusBtn.Parent = controlsFrame
Instance.new("UICorner", plusBtn).CornerRadius = UDim.new(0, 12)

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -10, 0, 18)
speedLabel.Position = UDim2.new(0, 5, 1, -20)
speedLabel.BackgroundTransparency = 1
speedLabel.Text = "Speed: " .. flySpeed
speedLabel.TextColor3 = Color3.fromRGB(120, 120, 150)
speedLabel.TextSize = 11
speedLabel.Font = Enum.Font.Gotham
speedLabel.TextXAlignment = Enum.TextXAlignment.Center
speedLabel.Parent = rightPanel

local miniFlyBtn = Instance.new("TextButton")
miniFlyBtn.Size = UDim2.new(0, 52, 0, 52)
miniFlyBtn.Position = mainFrame.Position
miniFlyBtn.BackgroundColor3 = Color3.fromRGB(99, 82, 255)
miniFlyBtn.BorderSizePixel = 0
miniFlyBtn.Text = "⚡"
miniFlyBtn.TextSize = 20
miniFlyBtn.Font = Enum.Font.GothamBold
miniFlyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
miniFlyBtn.AutoButtonColor = false
miniFlyBtn.Visible = false
miniFlyBtn.Parent = screenGui
Instance.new("UICorner", miniFlyBtn).CornerRadius = UDim.new(0, 16)

local miniFlyStroke = Instance.new("UIStroke")
miniFlyStroke.Color = Color3.fromRGB(99, 82, 255)
miniFlyStroke.Thickness = 2
miniFlyStroke.Parent = miniFlyBtn

local function updateFlyBtnState()
	if flying then
		flyToggleBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
		flyToggleBtn.Text = "Stop"
		miniFlyBtn.BackgroundColor3 = Color3.fromRGB(60, 200, 120)
	else
		flyToggleBtn.BackgroundColor3 = Color3.fromRGB(99, 82, 255)
		flyToggleBtn.Text = "Fly"
		miniFlyBtn.BackgroundColor3 = Color3.fromRGB(99, 82, 255)
	end
end

local function makeDraggable(frame)
	local dragging = false
	local dragStart = nil
	local startPos = nil

	frame.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = frame.Position
		end
	end)

	frame.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.Touch then
			local delta = input.Position - dragStart
			frame.Position = UDim2.new(
				startPos.X.Scale,
				startPos.X.Offset + delta.X,
				startPos.Y.Scale,
				startPos.Y.Offset + delta.Y
			)
		end
	end)

	frame.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)
end

makeDraggable(mainFrame)
makeDraggable(miniFlyBtn)

local collapsed = false

collapseBtn.TouchTap:Connect(function()
	collapsed = not collapsed
	if collapsed then
		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 240, 0, 44)
		}):Play()
		controlsFrame.Visible = false
		speedLabel.Visible = false
		collapseBtn.Text = "+"
	else
		controlsFrame.Visible = true
		speedLabel.Visible = true
		TweenService:Create(mainFrame, TweenInfo.new(0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, 240, 0, 120)
		}):Play()
		collapseBtn.Text = "−"
	end
end)

closeBtn.TouchTap:Connect(function()
	mainFrame.Visible = false
	stopFly()
	updateFlyBtnState()
end)

flyToggleBtn.TouchTap:Connect(function()
	if flying then stopFly() else startFly() end
	updateFlyBtnState()
end)

minusBtn.TouchTap:Connect(function()
	flySpeed = math.max(10, flySpeed - 10)
	speedLabel.Text = "Speed: " .. flySpeed
end)

plusBtn.TouchTap:Connect(function()
	flySpeed = math.min(500, flySpeed + 10)
	speedLabel.Text = "Speed: " .. flySpeed
end)

quickBtn.TouchTap:Connect(function()
	if not flying then startFly() end
	updateFlyBtnState()
	miniFlyBtn.Position = mainFrame.Position
	mainFrame.Visible = false
	miniFlyBtn.Visible = true
end)

miniFlyBtn.TouchTap:Connect(function()
	if flying then stopFly() else startFly() end
	updateFlyBtnState()
end)

miniFlyBtn.TouchLongPress:Connect(function()
	mainFrame.Position = miniFlyBtn.Position
	mainFrame.Visible = true
	miniFlyBtn.Visible = false
end)

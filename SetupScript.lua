local UIS = game:GetService("UserInputService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")
local ContentProvider = game:GetService("ContentProvider")
local VirtualInputManager = game:GetService("VirtualInputManager")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer

local teleportEnabled = false
local teleportThread = nil
local currentTarget = nil
local BypassAirKickEnabled = true
local NpcDistanceY = 0

local EntitiesHitBoxEnabled = false
local EntitiesHitBoxSize = 3
local ShowHitBox = false

local AutoClickEnabled


local visitedTargets = {}

local function teleportToNPC(targetNPC)
	if not LocalPlayer.Character or not targetNPC then return end
	local localRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	local targetRoot = targetNPC:FindFirstChild("HumanoidRootPart")
	if localRoot and targetRoot then
		localRoot.CFrame = targetRoot.CFrame + Vector3.new(0, NpcDistanceY, 0)
	end
end

local function getNextTarget()
	local npcs = game.Workspace.Entities:GetChildren()
	for _, npc in ipairs(npcs) do
		if not visitedTargets[npc] and npc:FindFirstChild("Humanoid") and not Players:GetPlayerFromCharacter(npc) then
			visitedTargets[npc] = true
			return npc
		end
	end
	visitedTargets = {}
	return getNextTarget()
end

local function teleportationCycle()
	while teleportEnabled do
		if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
			LocalPlayer.CharacterAdded:Wait()
			task.wait(0.5)
		end

		if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart") then
			local humanoid = currentTarget:FindFirstChild("Humanoid")
			local diedConnection

			if humanoid then
				diedConnection = humanoid.Died:Connect(function()
					currentTarget = getNextTarget()
				end)
			end
			
			local ExecuteBypass = 0
			local EveryBypassCount = 200
			while teleportEnabled and humanoid and humanoid.Health > 0 do
				teleportToNPC(currentTarget)
				if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
					break
				end
				
				ExecuteBypass += 0.1
				if ExecuteBypass > EveryBypassCount and BypassAirKickEnabled == true then
					EveryBypassCount += 200
					
					local humanoidRootPart = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					
					local rayOrigin = humanoidRootPart.Position + Vector3.new(200, 3, 0)
					local rayDirection = Vector3.new(0, -500, 0)

					local raycastParams = RaycastParams.new()
					raycastParams.FilterDescendantsInstances = {LocalPlayer.Character}

					local raycastResult = workspace:Raycast(rayOrigin, rayDirection, raycastParams)

					if raycastResult then
						local groundPosition = raycastResult.Position
						humanoidRootPart.CFrame = CFrame.new(groundPosition + Vector3.new(0, 2, 0))
						task.wait(2)
					else

						local rayDirection2 = Vector3.new(0, 500, 0)
						local raycastResult2 = workspace:Raycast(rayOrigin, rayDirection2, raycastParams)

						if raycastResult2 then
							local groundPosition = raycastResult2.Position
							humanoidRootPart.CFrame = CFrame.new(groundPosition + Vector3.new(0, 2, 0))
							task.wait(2)
						end
					end
				end

				task.wait()
			end

			if diedConnection then diedConnection:Disconnect() end
		else
			currentTarget = getNextTarget()
		end

		task.wait(0.1)
	end
end

local function SendNotification(title, text, duration)
	local success, errorMessage = pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = title;
			Text = text;
			Duration = duration or 5;
		})
	end)
end

local function CreateUIStroke(Parent, Color, ApplyMode)
	if not Parent then return end

	local UIStroke = Instance.new("UIStroke", Parent)
	UIStroke.ApplyStrokeMode = ApplyMode or Enum.ApplyStrokeMode.Border
	UIStroke.Color = Color or Color3.new(0, 0, 0)
	UIStroke.Thickness = 1
	return UIStroke
end

local function CreateUICorner(Parent, CornerRadius)
	if not Parent then return end

	local UICorner = Instance.new("UICorner", Parent)
	UICorner.CornerRadius = CornerRadius or UDim.new(1, 0)
	return UICorner
end

local function CreateUIAspectRatioConstraint(Parent)
	if not Parent then return end

	local UIAspectRatioConstraint = Instance.new("UIAspectRatioConstraint", Parent)
	return UIAspectRatioConstraint
end

local function createGui()
	if game.CoreGui:FindFirstChild("TeleportGui") then
		game.CoreGui:FindFirstChild("TeleportGui"):Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Parent = game.CoreGui
	screenGui.Name = "TeleportGui"

	local toggleButton = Instance.new("TextButton", screenGui)
	toggleButton.Name = "toggleButton"
	toggleButton.Parent = screenGui
	toggleButton.Size = UDim2.new(0.042, 0,0.074, 0)
	toggleButton.Position = UDim2.new(0.693, 0,0.025, 0)
	toggleButton.Text = "Amassa Menu"
	toggleButton.BackgroundColor3 = Color3.new(0, 0, 0)
	toggleButton.BackgroundTransparency = 0.5
	toggleButton.Font = Enum.Font.Highway
	toggleButton.TextColor3 = Color3.new(0, 0.666667, 1)
	toggleButton.TextScaled = true
	toggleButton.TextWrapped = true

	CreateUIStroke(toggleButton)
	CreateUIStroke(toggleButton, nil, Enum.ApplyStrokeMode.Contextual)
	CreateUICorner(toggleButton)
	CreateUIAspectRatioConstraint(toggleButton)

	local teleportButton = Instance.new("TextButton", screenGui)
	teleportButton.Parent = screenGui
	teleportButton.Size = UDim2.new(0.042, 0,0.074, 0)
	teleportButton.Position = UDim2.new(0.652, 0,0.125, 0)
	teleportButton.Text = "Npc Teleport (Disabled)"
	teleportButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	teleportButton.BackgroundTransparency = 0.5
	teleportButton.Font = Enum.Font.Highway
	teleportButton.TextColor3 = Color3.new(0, 0, 0)
	teleportButton.TextScaled = true
	teleportButton.TextWrapped = true

	teleportButton.Visible = false
	CreateUIStroke(teleportButton)
	local ActiveUIStroke = CreateUIStroke(teleportButton, Color3.new(1, 0.219608, 0.219608), Enum.ApplyStrokeMode.Contextual)
	CreateUICorner(teleportButton)
	CreateUIAspectRatioConstraint(teleportButton)

	local npcListButton = Instance.new("TextButton", screenGui)
	npcListButton.Size = UDim2.new(0.042, 0,0.074, 0)
	npcListButton.Position = UDim2.new(0.601, 0,0.125, 0)
	npcListButton.Text = "NPC List"
	npcListButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	npcListButton.BackgroundTransparency = 0.5
	npcListButton.Font = Enum.Font.Highway
	npcListButton.TextColor3 = Color3.new(0, 0, 0)
	npcListButton.TextScaled = true
	npcListButton.TextWrapped = true
	npcListButton.Visible = false

	CreateUIStroke(npcListButton)
	CreateUIStroke(npcListButton, Color3.new(1, 1, 1), Enum.ApplyStrokeMode.Contextual)
	CreateUICorner(npcListButton)
	CreateUIAspectRatioConstraint(npcListButton)
	
	local BypassAirKick = Instance.new("TextButton", screenGui)
	BypassAirKick.Size = UDim2.new(0.042, 0,0.074, 0)
	BypassAirKick.Position = UDim2.new(0.651, 0,0.025, 0)
	BypassAirKick.Text = "Bypass Air Kick (Enabled)"
	BypassAirKick.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	BypassAirKick.BackgroundTransparency = 0.5
	BypassAirKick.Font = Enum.Font.Highway
	BypassAirKick.TextColor3 = Color3.new(0, 0, 0)
	BypassAirKick.TextScaled = true
	BypassAirKick.TextWrapped = true
	BypassAirKick.Visible = false

	CreateUIStroke(BypassAirKick)
	local BypassAirKickUIStroke = CreateUIStroke(BypassAirKick, Color3.new(0.333333, 1, 0.498039), Enum.ApplyStrokeMode.Contextual)
	CreateUICorner(BypassAirKick)
	CreateUIAspectRatioConstraint(BypassAirKick)
	
	local AutoClickButton = Instance.new("TextButton", screenGui)
	AutoClickButton.Size = UDim2.new(0.042, 0,0.074, 0)
	AutoClickButton.Position = UDim2.new(0.752, 0,0.025, 0)
	AutoClickButton.Text = "Auto Click (Disabled)"
	AutoClickButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	AutoClickButton.BackgroundTransparency = 0.5
	AutoClickButton.Font = Enum.Font.Highway
	AutoClickButton.TextColor3 = Color3.new(0, 0, 0)
	AutoClickButton.TextScaled = true
	AutoClickButton.TextWrapped = true
	AutoClickButton.Visible = false

	CreateUIStroke(AutoClickButton)
	local AutoClickUIStroke = CreateUIStroke(AutoClickButton, Color3.new(1, 0.219608, 0.219608), Enum.ApplyStrokeMode.Contextual)
	CreateUICorner(AutoClickButton)
	CreateUIAspectRatioConstraint(AutoClickButton)
	
	local HitBoxButton = Instance.new("TextButton", screenGui)
	HitBoxButton.Size = UDim2.new(0.042, 0,0.074, 0)
	HitBoxButton.Position = UDim2.new(0.73, 0, 0.125, 0)
	HitBoxButton.Text = "Extend HitBox (Disabled)"
	HitBoxButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	HitBoxButton.BackgroundTransparency = 0.5
	HitBoxButton.Font = Enum.Font.Highway
	HitBoxButton.TextColor3 = Color3.new(0, 0, 0)
	HitBoxButton.TextScaled = true
	HitBoxButton.TextWrapped = true
	HitBoxButton.Visible = false

	CreateUIStroke(HitBoxButton)
	local ActiveUIStrokeHBS = CreateUIStroke(HitBoxButton, Color3.new(1, 0.219608, 0.219608), Enum.ApplyStrokeMode.Contextual)
	CreateUICorner(HitBoxButton)
	CreateUIAspectRatioConstraint(HitBoxButton)
	
	local ShowHBButton = Instance.new("TextButton", screenGui)
	ShowHBButton.Size = UDim2.new(0.042, 0,0.074, 0)
	ShowHBButton.Position = UDim2.new(0.73, 0, 0.225, 0)
	ShowHBButton.Text = "Show HitBox (Disabled)"
	ShowHBButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	ShowHBButton.BackgroundTransparency = 0.5
	ShowHBButton.Font = Enum.Font.Highway
	ShowHBButton.TextColor3 = Color3.new(0, 0, 0)
	ShowHBButton.TextScaled = true
	ShowHBButton.TextWrapped = true
	ShowHBButton.Visible = false

	CreateUIStroke(ShowHBButton)
	local ActiveUIStrokeSHB = CreateUIStroke(ShowHBButton, Color3.new(1, 0.219608, 0.219608), Enum.ApplyStrokeMode.Contextual)
	CreateUICorner(ShowHBButton)
	CreateUIAspectRatioConstraint(ShowHBButton)
	
	local HitBoxTextBox = Instance.new("TextBox", screenGui)
	HitBoxTextBox.Size = UDim2.new(0.042, 0,0.074, 0)
	HitBoxTextBox.Position = UDim2.new(0.78, 0, 0.125, 0)
	HitBoxTextBox.Text = ""
	HitBoxTextBox.PlaceholderText = "Place HB Size (Number)"
	HitBoxTextBox.PlaceholderColor3 = Color3.new(0, 0, 0)
	HitBoxTextBox.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	HitBoxTextBox.BackgroundTransparency = 0.5
	HitBoxTextBox.Font = Enum.Font.Highway
	HitBoxTextBox.TextColor3 = Color3.new(0, 0, 0)
	HitBoxTextBox.TextScaled = true
	HitBoxTextBox.TextWrapped = true
	HitBoxTextBox.Visible = false
	
	CreateUIStroke(HitBoxTextBox)
	CreateUIStroke(HitBoxTextBox, Color3.new(1, 1, 1), Enum.ApplyStrokeMode.Contextual)
	CreateUICorner(HitBoxTextBox)
	CreateUIAspectRatioConstraint(HitBoxTextBox)
	
	local npcTeleportDistance = Instance.new("TextBox", screenGui)
	npcTeleportDistance.Size = UDim2.new(0.042, 0,0.074, 0)
	npcTeleportDistance.Position = UDim2.new(0.55, 0, 0.125, 0)
	npcTeleportDistance.Text = ""
	npcTeleportDistance.PlaceholderText = "Distance Y (Number)"
	npcTeleportDistance.PlaceholderColor3 = Color3.new(0, 0, 0)
	npcTeleportDistance.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	npcTeleportDistance.BackgroundTransparency = 0.5
	npcTeleportDistance.Font = Enum.Font.Highway
	npcTeleportDistance.TextColor3 = Color3.new(0, 0, 0)
	npcTeleportDistance.TextScaled = true
	npcTeleportDistance.TextWrapped = true
	npcTeleportDistance.Visible = false

	CreateUIStroke(npcTeleportDistance)
	CreateUIStroke(npcTeleportDistance, Color3.new(1, 1, 1), Enum.ApplyStrokeMode.Contextual)
	CreateUICorner(npcTeleportDistance)
	CreateUIAspectRatioConstraint(npcTeleportDistance)

	local npcListFrame = Instance.new("ScrollingFrame", npcListButton)
	npcListFrame.Size = UDim2.new(4, 0, 4, 0)
	npcListFrame.Position = UDim2.new(0.5, 0, 3.2, 0)
	npcListFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	npcListFrame.Transparency = 0.5
	npcListFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	npcListFrame.BorderSizePixel = 0
	npcListFrame.Visible = false
	npcListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	npcListFrame.ScrollBarThickness = 10

	CreateUIStroke(npcListFrame, nil, Enum.ApplyStrokeMode.Contextual)
	CreateUICorner(npcListFrame, UDim.new(0, 12))
	CreateUIAspectRatioConstraint(npcListFrame)

	local function updateNPCList()
		npcListFrame:ClearAllChildren()
		local yOffset = 0

		local noneButton = Instance.new("TextButton")
		noneButton.Parent = npcListFrame
		noneButton.Size = UDim2.new(1, -10, 0, 30)
		noneButton.Position = UDim2.new(0, 5, 0, yOffset + 5)
		noneButton.Text = "None (Random)"
		noneButton.Transparency = 0.35
		noneButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
		noneButton.TextColor3 = Color3.new(1, 1, 1)
		noneButton.Font = Enum.Font.Highway
		noneButton.TextSize = 16
		noneButton.TextScaled = true
		noneButton.BorderSizePixel = 0

		CreateUIStroke(noneButton)
		CreateUIStroke(noneButton, Color3.new(0, 0, 0), Enum.ApplyStrokeMode.Contextual)
		CreateUICorner(noneButton, UDim.new(0,4))

		noneButton.MouseButton1Click:Connect(function()
			currentTarget = nil
			visitedTargets = {}
			npcListFrame.Visible = false
		end)

		yOffset = yOffset + 35

		for _, npc in ipairs(game.Workspace.Entities:GetChildren()) do
			if npcListFrame:FindFirstChild(npc.Name) and not Players:GetPlayerFromCharacter(npc) then continue end
			local npcButton = Instance.new("TextButton", npcListFrame)
			npcButton.Size = UDim2.new(1, -10, 0, 30)
			npcButton.Position = UDim2.new(0, 5, 0, yOffset + 5)
			npcButton.Name = npc.Name
			npcButton.Text = npc.Name
			npcButton.Transparency = 0.35
			npcButton.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
			npcButton.TextColor3 = Color3.new(1, 1, 1)
			npcButton.Font = Enum.Font.Highway
			npcButton.TextSize = 16
			npcButton.TextScaled = true
			npcButton.BorderSizePixel = 0

			CreateUIStroke(npcButton)
			CreateUIStroke(noneButton, Color3.new(0, 0, 0), Enum.ApplyStrokeMode.Contextual)
			CreateUICorner(npcButton, UDim.new(0,4))

			npcButton.MouseButton1Click:Connect(function()
				currentTarget = npc
				visitedTargets = {[npc] = true}
				npcListFrame.Visible = false
			end)

			yOffset = yOffset + 35
		end
		npcListFrame.CanvasSize = UDim2.new(0, 0, 0, yOffset)
	end
	
	local UIVisible = false
	toggleButton.MouseButton1Click:Connect(function()
		for _, TextButton in screenGui:GetChildren() do
			if TextButton.Name ~= "toggleButton" then
				TextButton.Visible = not UIVisible
			end
		end
		
		UIVisible = not UIVisible
	end)

	npcListButton.MouseButton1Click:Connect(function()
		npcListFrame.Visible = not npcListFrame.Visible
	end)
	
	HitBoxTextBox:GetPropertyChangedSignal("Text"):Connect(function()
		if not tonumber(HitBoxTextBox.Text) then HitBoxTextBox.Text = "" return end
		EntitiesHitBoxSize = tonumber(HitBoxTextBox.Text)
	end)
	
	npcTeleportDistance:GetPropertyChangedSignal("Text"):Connect(function()
		if npcTeleportDistance.Text == "-" or tonumber(npcTeleportDistance.Text) then
			NpcDistanceY = tonumber(npcTeleportDistance.Text)
		else
			npcTeleportDistance.Text = ""
		end
	end)
	
	ShowHBButton.MouseButton1Up:Connect(function()
		ShowHitBox = not ShowHitBox
		
		if ShowHitBox then
			ShowHBButton.Text = "Show HitBox (Enabled)"
			ActiveUIStrokeSHB.Color = Color3.new(0.333333, 1, 0.498039)
			
			while ShowHitBox do
				for _, Character in workspace:GetDescendants() do
					if Character:IsA("Model") and Character:FindFirstChildOfClass("Humanoid") then
						local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")

						if HumanoidRootPart then
							HumanoidRootPart.Transparency = 0.5
							HumanoidRootPart.Color = Color3.new(0.8, 0.164706, 0.164706)
							HumanoidRootPart.Material = Enum.Material.Neon
						end
					end
				end
				
				task.wait(0.5)
			end
		else
			for _, Character in workspace:GetDescendants() do
				if Character:IsA("Model") and Character:FindFirstChildOfClass("Humanoid") then
					local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
					
					if HumanoidRootPart then
						HumanoidRootPart.Transparency = 1
					end
				end
			end
			
			ShowHBButton.Text = "Show HitBox (Disabled)"
			ActiveUIStrokeSHB.Color = Color3.new(1, 0.219608, 0.219608)
		end
	end)
	
	HitBoxButton.MouseButton1Up:Connect(function()
		EntitiesHitBoxEnabled = not EntitiesHitBoxEnabled
		
		if EntitiesHitBoxEnabled then
			
			HitBoxButton.Text = "Extend HitBox (Enabled)"
			ActiveUIStrokeHBS.Color = Color3.new(0.333333, 1, 0.498039)
			
			while EntitiesHitBoxEnabled do
				for _, Character in workspace:GetDescendants() do
					if Character:IsA("Model") and Character:FindFirstChildOfClass("Humanoid") and Character.Name ~= LocalPlayer.Name then
						local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
						
						local IsPartyMember = false
						
						if LocalPlayer.PlayerGui and LocalPlayer.PlayerGui:FindFirstChild("Interface") and 
							LocalPlayer.PlayerGui:FindFirstChild("Interface"):FindFirstChild("SquadDisplayFrame") and
							LocalPlayer.PlayerGui:FindFirstChild("Interface"):FindFirstChild("SquadDisplayFrame"):FindFirstChild("SquadList") then
							
							local SquadList = LocalPlayer.PlayerGui:FindFirstChild("Interface"):FindFirstChild("SquadDisplayFrame"):FindFirstChild("SquadList")
							
							for _, Frame in SquadList:GetChildren() do
								if Frame:IsA("Frame") and Players:FindFirstChild(Character.Name) == Frame.Name then
									IsPartyMember = true
								end
							end
						end
						
						if HumanoidRootPart and IsPartyMember == false then
							local HitBoxSize = EntitiesHitBoxSize or 3
							
							HumanoidRootPart.CanCollide = false
							HumanoidRootPart.Size = Vector3.new(HitBoxSize, HitBoxSize, HitBoxSize)
							
						elseif HumanoidRootPart and IsPartyMember == true then
							HumanoidRootPart.Size = Vector3.new(1, 1, 1)
						
						end
					end
				end
				
				task.wait(1)
			end
			
		else
			for _, Character in workspace:GetDescendants() do
				if Character:IsA("Model") and Character:FindFirstChildOfClass("Humanoid") then
					local HumanoidRootPart = Character:FindFirstChild("HumanoidRootPart")
					
					if HumanoidRootPart then
						HumanoidRootPart.Size = Vector3.new(1, 1, 1)
					end
				end
			end
			
			HitBoxButton.Text = "Extend HitBox (Disabled)"
			ActiveUIStrokeHBS.Color = Color3.new(1, 0.219608, 0.219608)
		end
	end)
	
	BypassAirKick.MouseButton1Up:Connect(function()
		BypassAirKickEnabled = not BypassAirKickEnabled
		if BypassAirKickEnabled then
			BypassAirKickUIStroke.Color = Color3.new(0.333333, 1, 0.498039)
			BypassAirKick.Text = "Bypass Air Kick (Enabled)"
		else
			
			SendNotification("⚠ WARNING! 🚨", "Disabling This Has a 50% Chance Of Getting Kicked By Air Timer")
			
			BypassAirKickUIStroke.Color = Color3.new(1, 0.219608, 0.219608)
			BypassAirKick.Text = "Bypass Air Kick (Disabled)"
		end
	end)
	
	local AutoClickConnection
	AutoClickButton.MouseButton1Up:Connect(function()
		AutoClickEnabled = not AutoClickEnabled
		
		
		if AutoClickEnabled then
			if AutoClickConnection then AutoClickConnection:Disconnect() AutoClickConnection = nil end
			
			local ClickPosition = Vector2.new(500, 300)
			
			AutoClickButton.Text = "Auto Click (Enabled)"
			AutoClickUIStroke.Color = Color3.new(0.333333, 1, 0.498039)

			AutoClickConnection = RunService.RenderStepped:Connect(function()
				VirtualInputManager:SendMouseButtonEvent(ClickPosition.X, ClickPosition.Y, 0, true, game, 1)
				task.wait(0.025)
				VirtualInputManager:SendMouseButtonEvent(ClickPosition.X, ClickPosition.Y, 0, false, game, 1)
			end)
			
		else
			if AutoClickConnection then AutoClickConnection:Disconnect() end
			AutoClickConnection = nil
			
			AutoClickButton.Text = "Auto Click (Disabled)"
			AutoClickUIStroke.Color = Color3.new(1, 0.219608, 0.219608)
		end

	end)

	teleportButton.MouseButton1Click:Connect(function()
		teleportEnabled = not teleportEnabled

		if teleportEnabled then
			teleportButton.Text = "Npc Teleport (Enabled)"
			ActiveUIStroke.Color = Color3.new(0.333333, 1, 0.498039)

			teleportThread = coroutine.create(teleportationCycle)
			coroutine.resume(teleportThread)
		else
			teleportButton.Text = "Npc Teleport (Disabled)"
			ActiveUIStroke.Color = Color3.new(1, 0.219608, 0.219608)

			if teleportThread and coroutine.status(teleportThread) == "running" then
				teleportThread = nil
			end
		end
	end)

	game.Workspace.Entities.ChildAdded:Connect(updateNPCList)
	game.Workspace.Entities.ChildRemoved:Connect(updateNPCList)
	updateNPCList()
end

task.spawn(function()
	SendNotification("Welcome! Developed by juauduamassa!", "Loading...", 6)
	task.wait(2)
	local assets = workspace:GetDescendants()
	local totalAssets = #assets
	for i, asset in ipairs(assets) do
		local progress = i / totalAssets
		task.spawn(function()
			ContentProvider:PreloadAsync({asset})
		end)
	end

	SendNotification("Completed.", "Loading Was Completed Successfully.", 2)
	task.wait(1)
	SendNotification("Good Game!", "Sorry To Bother You, Good Game.", 3)
	createGui()
end)

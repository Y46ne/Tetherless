-------------------------------------------------------------------------------
-- 1. SERVICES & REFERENCES
-------------------------------------------------------------------------------
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Custom Modules & Events
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local moduleFolder = ReplicatedStorage:WaitForChild("Modules")
local tweenModule = require(moduleFolder:WaitForChild("Tween"))
local weaponState = require(sharedFolder:WaitForChild("WeaponState"))

local updateHUDEvent = sharedFolder:WaitForChild("UpdateHUD")
local remoteEventsFolder = ReplicatedStorage:WaitForChild("RemoteEvents")
local hitmarkerEvent = remoteEventsFolder:WaitForChild("Hitmarker")
local matchStatusEvent = remoteEventsFolder:FindFirstChild("MatchStatus")
	or remoteEventsFolder:FindFirstChild("MatchUpdate")

-------------------------------------------------------------------------------
-- 2. UI ELEMENT PATHS
-------------------------------------------------------------------------------
local hubFolder = script.Parent:WaitForChild("HUD")

-- Game Info
local gameInfoFrame = hubFolder:WaitForChild("GameInfo")
local GameVersion = gameInfoFrame:WaitForChild("GameVersionText")
local ServerRegion = gameInfoFrame:WaitForChild("ServerRegion")
local ServerUptime = gameInfoFrame:WaitForChild("ServerUptime")
local playerUser = gameInfoFrame:WaitForChild("PlayerUsername")

-- Player Stats & Status
local HealthBar = hubFolder:WaitForChild("HpBarBackGround"):WaitForChild("HpBar")
local hpAmountText = HealthBar:WaitForChild("HpAmount")
local playerStatusFrame = hubFolder:WaitForChild("PlayerStatus")
local playerStatusText = playerStatusFrame:WaitForChild("playerStatus")
local speedometerText = hubFolder:WaitForChild("Speedometer")

-- Weapons
local LeftGunFrame = hubFolder:WaitForChild("LeftGunFrame")
local LeftGunName = LeftGunFrame:WaitForChild("GunName")
local LeftGunAmmo = LeftGunFrame:WaitForChild("AmmoText")

local RightGunFrame = hubFolder:WaitForChild("RightGunFrame")
local RightGunName = RightGunFrame:WaitForChild("GunName")
local RightGunAmmo = RightGunFrame:WaitForChild("AmmoText")

-- Crosshair
local crosshairContainer = hubFolder:WaitForChild("CrosshairContainer")
local topLine = crosshairContainer:WaitForChild("Top")
local bottomLine = crosshairContainer:WaitForChild("Bottom")
local leftLine = crosshairContainer:WaitForChild("Left")
local rightLine = crosshairContainer:WaitForChild("Right")

-------------------------------------------------------------------------------
-- 3. CROSSHAIR SETUP
-------------------------------------------------------------------------------
UserInputService.MouseIconEnabled = false

crosshairContainer.AnchorPoint = Vector2.new(0.5, 0.5)
crosshairContainer.Position = UDim2.new(0.5, 0, 0.5, 0)
crosshairContainer.Size = UDim2.new(0, 0, 0, 0)

topLine.AnchorPoint = Vector2.new(0.5, 1)
bottomLine.AnchorPoint = Vector2.new(0.5, 0)
leftLine.AnchorPoint = Vector2.new(1, 0.5)
rightLine.AnchorPoint = Vector2.new(0, 0.5)

topLine.Size = UDim2.new(0, 1, 0, 6)
bottomLine.Size = UDim2.new(0, 1, 0, 6)
leftLine.Size = UDim2.new(0, 6, 0, 1)
rightLine.Size = UDim2.new(0, 6, 0, 1)

topLine.Position = UDim2.new(0.5, 0, 0.5, -2)
bottomLine.Position = UDim2.new(0.5, 0, 0.5, 2)
leftLine.Position = UDim2.new(0.5, -2, 0.5, 0)
rightLine.Position = UDim2.new(0.5, 2, 0.5, 0)

local centerDot = crosshairContainer:FindFirstChild("CenterDot")
if not centerDot then
	centerDot = Instance.new("Frame")
	centerDot.Name = "CenterDot"
	centerDot.Size = UDim2.new(0, 2, 0, 2)
	centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
	centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
	centerDot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	centerDot.BorderSizePixel = 0
	centerDot.Parent = crosshairContainer
end

local hitmarkerX = Instance.new("Frame")
hitmarkerX.Name = "HitmarkerX"
hitmarkerX.BackgroundTransparency = 1
hitmarkerX.Size = UDim2.new(0, 24, 0, 24)
hitmarkerX.Position = UDim2.new(0.5, 0, 0.5, 0)
hitmarkerX.AnchorPoint = Vector2.new(0.5, 0.5)
hitmarkerX.Parent = crosshairContainer

local hLine1 = Instance.new("Frame")
hLine1.Size = UDim2.new(0, 2, 1, 0)
hLine1.Position = UDim2.new(0.5, 0, 0.5, 0)
hLine1.AnchorPoint = Vector2.new(0.5, 0.5)
hLine1.Rotation = 45
hLine1.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
hLine1.BorderSizePixel = 0
hLine1.BackgroundTransparency = 1
hLine1.Parent = hitmarkerX

local hLine2 = hLine1:Clone()
hLine2.Rotation = -45
hLine2.Parent = hitmarkerX

-------------------------------------------------------------------------------
-- 4. CROSSHAIR ANIMATIONS
-------------------------------------------------------------------------------
local function playHitmarkerAnimation(isKill, isHeadshot)
	local hitColor = isHeadshot and Color3.fromRGB(255, 150, 0) or Color3.fromRGB(255, 0, 0)
	hLine1.BackgroundColor3 = hitColor
	hLine2.BackgroundColor3 = hitColor

	hLine1.BackgroundTransparency = 0
	hLine2.BackgroundTransparency = 0
	hitmarkerX.Size = UDim2.new(0, 16, 0, 16)

	tweenModule.play(hitmarkerX, { Size = UDim2.new(0, 24, 0, 24) }, 0.2)
	tweenModule.play(hLine1, { BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tweenModule.play(hLine2, { BackgroundTransparency = 1 }, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.In)

	if isKill then
		for _, line in ipairs({ topLine, bottomLine, leftLine, rightLine }) do
			line.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
			tweenModule.play(line, { BackgroundColor3 = Color3.fromRGB(255, 255, 255) }, 0.3)
		end

		crosshairContainer.Rotation = 0
		tweenModule.play(crosshairContainer, { Rotation = 90 }, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	end
end

hitmarkerEvent.OnClientEvent:Connect(function(isHeadshot, isKill)
	playHitmarkerAnimation(isKill, isHeadshot)
end)

-------------------------------------------------------------------------------
-- 5. HUD UPDATE LOGIC
-------------------------------------------------------------------------------
local function initGameInfo()
	playerUser.Text = "STRAFER_NAME: @" .. player.Name .. " (" .. player.UserId .. ")"
	GameVersion.Text = "VERSION: v0.0.1"
	ServerRegion.Text = "REGION: Global"

	task.spawn(function()
		while task.wait(1) do
			local uptime = Workspace.DistributedGameTime
			local hours = math.floor(uptime / 3600)
			local mins = math.floor((uptime % 3600) / 60)
			local secs = math.floor(uptime % 60)

			if hours > 0 then
				ServerUptime.Text = string.format("SERVER_UPTIME: %02d:%02d:%02d", hours, mins, secs)
			else
				ServerUptime.Text = string.format("SERVER_UPTIME: %02d:%02d", mins, secs)
			end
		end
	end)
end

local function updateHealthBar(health)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChild("Humanoid")
		if humanoid then
			local healthPercent = health / humanoid.MaxHealth
			tweenModule.play(HealthBar, { Size = UDim2.new(healthPercent, 0, 1, 0) }, 0.2)
			hpAmountText.Text = math.floor(health) .. "+"
		end
	end
end

local function updatePlayerStatus()
	local char = player.Character
	if not char then
		return
	end

	if char:GetAttribute("IsFrozen") then
		playerStatusText.Text = "WARNING: MOTOR FUNCTIONS FROZEN"
		playerStatusText.TextColor3 = Color3.fromRGB(0, 200, 255)
	else
		playerStatusText.Text = ""
	end
end

local function updateAmmoDisplay()
	local char = player.Character
	if not char then
		return
	end

	local rightWeapon = char:GetAttribute("RightWeapon")
	local leftWeapon = char:GetAttribute("LeftWeapon")

	if rightWeapon and rightWeapon ~= "None" then
		local ammoData = weaponState.getAmmo(rightWeapon)
		RightGunName.Text = string.upper(rightWeapon)
		RightGunAmmo.Text = ammoData and string.format("%02d", ammoData.Mag) or "00"
	else
		RightGunName.Text = "[ EMPTY ]"
		RightGunAmmo.Text = "--"
	end

	if leftWeapon and leftWeapon ~= "None" then
		local ammoData = weaponState.getAmmo(leftWeapon)
		LeftGunName.Text = string.upper(leftWeapon)
		LeftGunAmmo.Text = ammoData and string.format("%02d", ammoData.Mag) or "00"
	else
		LeftGunName.Text = "[ EMPTY ]"
		LeftGunAmmo.Text = "--"
	end
end

-------------------------------------------------------------------------------
-- 5.5. VISUAL SCOREBOARD LOGIC (FIXED 4-PLAYER SLOTS)
-------------------------------------------------------------------------------
local playerPoints = hubFolder:WaitForChild("PlayerPoints")

local MapNumber = playerPoints:FindFirstChild("Mapnumber") or playerPoints:FindFirstChild("MapNumber")
local roundTime = playerPoints:FindFirstChild("RoundTime")

-- Gather your 4 fixed slots
local slots = {
	playerPoints:WaitForChild("Player1"),
	playerPoints:WaitForChild("Player2"),
	playerPoints:WaitForChild("Player3"),
	playerPoints:WaitForChild("Player4"),
}

-- Hide them all initially
for _, slot in ipairs(slots) do
	if slot then
		slot.Visible = false
	end
end

-- Function to toggle center info visibility
local function setCenterInfoVisible(isVisible)
	if MapNumber then
		MapNumber.Visible = isVisible
	end
	if roundTime then
		roundTime.Visible = isVisible
	end
end

-- Hide the center Map & Time info initially
setCenterInfoVisible(false)

-- Dictionary to keep track of which player owns which slot
local assignedSlots = {}
local slotOwners = {}

local function getSlotViewport(slot)
	if not slot then
		return nil
	end
	local playerCharacter = slot:FindFirstChild("PlayerCharacter") or slot:WaitForChild("PlayerCharacter", 2)
	if not playerCharacter then
		return nil
	end
	return playerCharacter:FindFirstChild("ViewportFrame") or playerCharacter:WaitForChild("ViewportFrame", 2)
end

local function setupViewportCharacter(char, viewportFrame)
	if not char or not viewportFrame then
		return false
	end

	-- Ensure character is fully loaded before cloning
	local humanoid = char:FindFirstChild("Humanoid")
	local humanoidRootPart = char:FindFirstChild("HumanoidRootPart")
	local head = char:FindFirstChild("Head")

	if not humanoid or not humanoidRootPart or not head then
		return false
	end

	-- Clear old viewport render content
	for _, child in ipairs(viewportFrame:GetChildren()) do
		if child:IsA("Model") or child:IsA("Camera") or child:IsA("WorldModel") then
			child:Destroy()
		end
	end

	viewportFrame.Ambient = Color3.fromRGB(200, 200, 200)
	viewportFrame.LightColor = Color3.fromRGB(255, 255, 255)
	viewportFrame.LightDirection = Vector3.new(-1, -1, -1)

	local previousArchivable = char.Archivable
	char.Archivable = true
	local clone = char:Clone()
	char.Archivable = previousArchivable
	if not clone then
		return false
	end

	clone.Name = "Character"

	-- Anchor parts and destroy scripts to prevent physics bugs in Viewport
	for _, obj in ipairs(clone:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.Anchored = true
			obj.CanCollide = false
		elseif obj:IsA("Script") or obj:IsA("LocalScript") then
			obj:Destroy()
		end
	end

	local worldModel = Instance.new("WorldModel")
	worldModel.Name = "ViewportWorld"
	worldModel.Parent = viewportFrame

	clone.Parent = worldModel
	clone:PivotTo(CFrame.new(0, 0, 0))

	local vcam = Instance.new("Camera")
	vcam.FieldOfView = 33

	-- Safely get bounding box with fallback
	local success, bboxCFrame, bboxSize = pcall(function()
		return clone:GetBoundingBox()
	end)

	local focus, distance
	if success and bboxSize and bboxSize.Magnitude > 0 then
		focus = bboxCFrame.Position + Vector3.new(0, bboxSize.Y * 0.12, 0)
		local largestAxis = math.max(bboxSize.X, bboxSize.Y, bboxSize.Z)
		distance = math.max(4, largestAxis * 1.6)
		vcam.CFrame = CFrame.lookAt(focus + Vector3.new(0, 0, distance), focus)
	end

	local root = clone:FindFirstChild("HumanoidRootPart")
	if root then
		local rootFocus = root.Position + Vector3.new(0, 1.2, 0)
		local largestAxis = bboxSize and math.max(bboxSize.X, bboxSize.Y, bboxSize.Z) or 2
		local rootDistance = math.max(4, largestAxis * 1.5)
		vcam.CFrame = CFrame.lookAt(rootFocus + (root.CFrame.LookVector * rootDistance), rootFocus)
	end

	local cloneHead = clone:FindFirstChild("Head")
	if cloneHead and root then
		local headFocus = cloneHead.Position + Vector3.new(0, -0.2, 0)
		local headDistance = 2.2
		vcam.CFrame = CFrame.lookAt(headFocus + (root.CFrame.LookVector * headDistance), headFocus)
	elseif cloneHead then
		local headFocus = cloneHead.Position + Vector3.new(0, -0.2, 0)
		vcam.CFrame = CFrame.lookAt(headFocus + Vector3.new(0, 0, 2.2), headFocus)
	else
		-- Fallback camera if head is missing
		vcam.CFrame = CFrame.lookAt(Vector3.new(0, 2, 3), Vector3.new(0, 1, 0))
	end

	viewportFrame.CurrentCamera = vcam
	vcam.Parent = viewportFrame

	return true
end

local function refreshViewportForPlayer(p, slot, preferredChar)
	local maxAttempts = 30 -- Increased from 10 to 30 attempts

	for _ = 1, maxAttempts do
		if assignedSlots[p.Name] ~= slot or slotOwners[slot] ~= p.Name then
			return
		end

		local viewport = getSlotViewport(slot)
		local char = preferredChar
		if not char or not char.Parent then
			char = p.Character
		end

		if viewport and char and char.Parent then
			if setupViewportCharacter(char, viewport) then
				return
			end
		end

		task.wait(0.3) -- Increased from 0.2 to 0.3 seconds for more stable loading
	end
end

local function animateFillBox(boxFrame, isFilled)
	if not boxFrame then
		return
	end

	local fill = boxFrame:FindFirstChild("Fill")
	if not fill then
		fill = Instance.new("Frame")
		fill.Name = "Fill"
		fill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		fill.BorderSizePixel = 0
		fill.AnchorPoint = Vector2.new(0, 1)
		fill.Position = UDim2.new(0, 0, 1, 0)
		fill.Size = UDim2.new(1, 0, 0, 0)
		fill.Parent = boxFrame
	end

	if isFilled then
		tweenModule.play(fill, { Size = UDim2.new(1, 0, 1, 0) }, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	else
		tweenModule.play(fill, { Size = UDim2.new(1, 0, 0, 0) }, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	end
end

-- Update the visuals for ONE specific player's slot
local function updatePlayerSlot(p)
	local slot = assignedSlots[p.Name]
	if not slot then
		return
	end

	local mapWins = p:GetAttribute("Wins") or 0
	local roundWins = p:GetAttribute("RoundWins") or 0

	local mapPointsContainer = slot:FindFirstChild("MapPoints")
	if mapPointsContainer then
		animateFillBox(mapPointsContainer:FindFirstChild("Map1"), mapWins >= 1)
		animateFillBox(mapPointsContainer:FindFirstChild("Map2"), mapWins >= 2)
		animateFillBox(mapPointsContainer:FindFirstChild("Map3"), mapWins >= 3)
	end

	local roundPointsContainer = slot:FindFirstChild("RoundPoints")
	if roundPointsContainer then
		animateFillBox(roundPointsContainer:FindFirstChild("Round1"), roundWins >= 1)
		animateFillBox(roundPointsContainer:FindFirstChild("Round2"), roundWins >= 2)
		animateFillBox(roundPointsContainer:FindFirstChild("Round3"), roundWins >= 3)
		animateFillBox(roundPointsContainer:FindFirstChild("Round4"), roundWins >= 4)
	end
end

-- Assigns a player to the first empty slot when they join
local function assignSlot(p)
	if assignedSlots[p.Name] then
		return
	end

	local mySlot = nil
	for _, slot in ipairs(slots) do
		if slot and not slotOwners[slot] then
			mySlot = slot
			break
		end
	end

	if not mySlot then
		return
	end

	assignedSlots[p.Name] = mySlot
	slotOwners[mySlot] = p.Name
	mySlot.Visible = true

	local nameLabel = mySlot:FindFirstChild("PlayerNameText")
	if nameLabel then
		nameLabel.Text = p.Name
	end

	refreshViewportForPlayer(p, mySlot, p.Character)

	p.CharacterAdded:Connect(function(newChar)
		task.defer(function()
			refreshViewportForPlayer(p, mySlot, newChar)
		end)
	end)

	p.CharacterAppearanceLoaded:Connect(function(loadedChar)
		task.defer(function()
			refreshViewportForPlayer(p, mySlot, loadedChar)
		end)
	end)

	p:GetAttributeChangedSignal("Wins"):Connect(function()
		updatePlayerSlot(p)
	end)
	p:GetAttributeChangedSignal("RoundWins"):Connect(function()
		updatePlayerSlot(p)
	end)

	updatePlayerSlot(p)
end

-- Free up the slot when a player leaves
local function freeSlot(p)
	local slot = assignedSlots[p.Name]
	if slot then
		local viewport = getSlotViewport(slot)
		if viewport then
			for _, child in ipairs(viewport:GetChildren()) do
				if child:IsA("Model") or child:IsA("Camera") or child:IsA("WorldModel") then
					child:Destroy()
				end
			end
		end
		slotOwners[slot] = nil
		local nameLabel = slot:FindFirstChild("PlayerNameText")
		if nameLabel then
			nameLabel.Text = ""
		end
		slot.Visible = false
		assignedSlots[p.Name] = nil
	end
end

local function initVisualScoreboard()
	for _, p in ipairs(Players:GetPlayers()) do
		assignSlot(p)
	end
	Players.PlayerAdded:Connect(assignSlot)
	Players.PlayerRemoving:Connect(freeSlot)
end

-------------------------------------------------------------------------------
-- LOCAL CHARACTER SETUP WRAPPER
-------------------------------------------------------------------------------
local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	updateHealthBar(humanoid.Health)
	updatePlayerStatus()
	updateAmmoDisplay()

	humanoid.HealthChanged:Connect(function(health)
		updateHealthBar(health)
	end)

	character:GetAttributeChangedSignal("IsFrozen"):Connect(updatePlayerStatus)
	character:GetAttributeChangedSignal("RightWeapon"):Connect(updateAmmoDisplay)
	character:GetAttributeChangedSignal("LeftWeapon"):Connect(updateAmmoDisplay)
end

-------------------------------------------------------------------------------
-- 6. PHYSICS RENDER LOOP (Speedometer)
-------------------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local char = player.Character
	if char then
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			local speed = math.floor(root.AssemblyLinearVelocity.Magnitude)
			speedometerText.Text = tostring(speed) .. " u/s"

			if speed >= 45 then
				speedometerText.TextColor3 = Color3.fromRGB(255, 215, 0)
			else
				speedometerText.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end
end)

-------------------------------------------------------------------------------
-- 7. INITIALIZATION & NETWORK LISTENERS
-------------------------------------------------------------------------------
initGameInfo()
initVisualScoreboard()

updateHUDEvent.Event:Connect(function()
	updateAmmoDisplay()
end)

-- The Timer & Map Text Listener
if matchStatusEvent then
	matchStatusEvent.OnClientEvent:Connect(function(statusText, timerValue)
		if typeof(statusText) ~= "string" then
			return
		end

		if statusText == "WAITING FOR PLAYERS..." then
			setCenterInfoVisible(false)
		else
			setCenterInfoVisible(true)

			if MapNumber then
				MapNumber.Text = statusText
			end

			if roundTime and timerValue then
				local mins = math.floor(timerValue / 60)
				local secs = timerValue % 60
				roundTime.Text = string.format("%d:%02d", mins, secs)
			end
		end
	end)
else
	warn("MainHUD: no MatchStatus/MatchUpdate RemoteEvent found; map/timer HUD will stay hidden")
end

player.CharacterAdded:Connect(function(character)
	setupCharacter(character)
end)

if player.Character then
	setupCharacter(player.Character)
end

local WeaponController = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local weaponsFolder = sharedFolder:WaitForChild("Weapons")

local weaponState = require(sharedFolder:WaitForChild("WeaponState"))
local TweenHelpers = require(sharedFolder:WaitForChild("Utils"):WaitForChild("TweenHelper"))
local AnimationIDs = require(sharedFolder:WaitForChild("Configs"):WaitForChild("AnimationIDs"))

local ViewmodelController = require(script.Parent:WaitForChild("ViewmodelController"))
local InputController = require(script.Parent:WaitForChild("InputController"))
local ViewModelRouter = require(script.Parent:WaitForChild("ViewModelRouter"))
local AnimationController = require(script.Parent:WaitForChild("AnimationController"))
local SoundController = require(script.Parent:WaitForChild("SoundController"))

local shootEvent = remoteEvents:WaitForChild("Shoot")
local dropWeaponEvent = remoteEvents:WaitForChild("DropWeapon")
local updateHUDEvent = sharedFolder:WaitForChild("UpdateHUD")
local syncAmmoEvent = remoteEvents:WaitForChild("SyncAmmo")

local lastFireTimeRight = 0
local lastFireTimeLeft = 0
local isTossing = false
local mouseHeldRight = false
local mouseHeldLeft = false
local firingTokenRight = nil
local firingTokenLeft = nil

-----------------------------
-- HELPER FUNCTIONS --
-----------------------------
local function getWeaponModule(weaponName)
	if weaponName and weaponName ~= "None" then
		local node = weaponsFolder:FindFirstChild(weaponName)
		return node and require(node) or nil
	end
	return nil
end

local function isAutomaticWeapon(weaponName)
	local module = getWeaponModule(weaponName)
	if not module or not module.Stats or not module.Stats.Traits then
		return false
	end

	for _, trait in ipairs(module.Stats.Traits) do
		if trait == "Full-Automatic" or trait == "Burst Fire" then
			return true
		end
	end
	return false
end

local function isWeaponTwoHanded(weaponName)
	local module = getWeaponModule(weaponName)
	local stats = module and module.Stats
	if not stats then
		return false
	end
	if stats.DualWieldable == false then
		return true
	end
	if stats.Traits then
		for _, t in ipairs(stats.Traits) do
			if t == "Two-Handed" then
				return true
			end
		end
	end
	return false
end

local function createTracer(startPos, endPos)
	local distance = (endPos - startPos).Magnitude
	local tracer = Instance.new("Part")
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.Massless = true
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 0, 4)
	tracer.Size = Vector3.new(0.05, 0.05, distance)
	tracer.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
	tracer.Parent = workspace

	local tween = TweenHelpers.play(tracer, { Transparency = 1, Size = Vector3.new(0, 0, distance) }, 0.05)
	tween.Completed:Connect(function()
		tracer:Destroy()
	end)
end

local function tossWeapon(hand)
	local char = player.Character
	if not char then
		return
	end

	local weaponName = char:GetAttribute(hand .. "Weapon")
	if not weaponName or weaponName == "None" then
		return
	end

	local ammoData = weaponState.getAmmo(hand)
	local ammoToDrop = ammoData and ammoData.Mag or 0
	local lookDir = workspace.CurrentCamera.CFrame.LookVector

	dropWeaponEvent:FireServer("Drop" .. hand, lookDir, ammoToDrop)
	updateHUDEvent:Fire("None", 0, hand)
end

local function tryToFire(hand)
	local char = player.Character
	if not char then
		return
	end

	local weaponName = char:GetAttribute(hand .. "Weapon")
	if not weaponName or weaponName == "None" then
		return
	end

	local activeModule = getWeaponModule(weaponName)
	local stats = activeModule and activeModule.Stats
	local ammoData = weaponState.getAmmo(hand)
	if not stats or not ammoData then
		return
	end

	local currentTime = tick()
	local lastFireTime = (hand == "Right") and lastFireTimeRight or lastFireTimeLeft

	if ammoData.Mag > 0 then
		if currentTime - lastFireTime >= stats.FireRate then
			if hand == "Right" then
				lastFireTimeRight = currentTime
			else
				lastFireTimeLeft = currentTime
			end

			ammoData.Mag -= 1
			updateHUDEvent:Fire(weaponName, ammoData.Mag, hand)

			SoundController.PlayFire(weaponName)
			local muzzlePos = ViewmodelController.PlayShootEffect(hand)
			local payload = activeModule.FireClient(player, hand, workspace.CurrentCamera, mouse.Hit)

			if payload and payload.Origin and payload.Direction and stats.HasTracer ~= false then
				local range = 200
				local endPoint = payload.Origin + (payload.Direction * range)
				createTracer(muzzlePos or payload.Origin, endPoint)
			end

			shootEvent:FireServer(weaponName, payload, hand)
		end
	else
		if not isTossing then
			isTossing = true
			tossWeapon(hand)
			task.wait(0.2)
			isTossing = false
		end
	end
end

local function startFireLoop(hand)
	local token = {}
	if hand == "Right" then
		firingTokenRight = token
	else
		firingTokenLeft = token
	end

	task.spawn(function()
		while token == (hand == "Right" and firingTokenRight or firingTokenLeft) do
			if (hand == "Right" and mouseHeldRight) or (hand == "Left" and mouseHeldLeft) then
				tryToFire(hand)

				local char = player.Character
				if not char then
					break
				end
				local weaponName = char:GetAttribute(hand .. "Weapon")
				local module = getWeaponModule(weaponName)
				local fireRate = module and module.Stats and module.Stats.FireRate or 0.1

				task.wait(fireRate)
			else
				break
			end
		end
	end)
end

local function setupCharacter(char)
	local prevRight = nil
	local prevLeft = nil

	local function onWeaponChanged()
		local currentRight = char:GetAttribute("RightWeapon")
		local currentLeft = char:GetAttribute("LeftWeapon")

		if currentRight and currentRight ~= "None" then
			if currentRight ~= prevRight then
				weaponState.resetAmmo("Right", currentRight)
			end

			local ammoData = weaponState.getAmmo("Right")
			if ammoData then
				updateHUDEvent:Fire(currentRight, ammoData.Mag, "Right")
			end
		else
			updateHUDEvent:Fire("None", 0, "Right")
		end
		prevRight = currentRight

		if currentLeft and currentLeft ~= "None" then
			if currentLeft ~= prevLeft then
				weaponState.resetAmmo("Left", currentLeft)
			end

			local ammoData = weaponState.getAmmo("Left")
			if ammoData then
				updateHUDEvent:Fire(currentLeft, ammoData.Mag, "Left")
			end
		else
			updateHUDEvent:Fire("None", 0, "Left")
		end
		prevLeft = currentLeft

		-- Update third-person arm pose animations so other players see the correct hold.
		-- Played on the character Animator so Roblox auto-replicates to all clients.
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
		if animator then
			AnimationController.stop(animator, AnimationIDs.RightArmWeapon.id)
			AnimationController.stop(animator, AnimationIDs.LeftArmWeapon.id)
			AnimationController.stop(animator, AnimationIDs.BothArmsWeapon.id)

			local hasRight = currentRight and currentRight ~= "None"
			local hasLeft = currentLeft and currentLeft ~= "None"

			if hasRight and isWeaponTwoHanded(currentRight) then
				-- Non-dual-wieldable (AK, RocketLauncher, etc.) — both arms locked together
				AnimationController.play(animator, AnimationIDs.BothArmsWeapon.id, Enum.AnimationPriority.Action)
			elseif hasRight and hasLeft then
				-- Dual wielding — each arm plays its own animation simultaneously
				AnimationController.play(animator, AnimationIDs.RightArmWeapon.id, Enum.AnimationPriority.Action)
				AnimationController.play(animator, AnimationIDs.LeftArmWeapon.id, Enum.AnimationPriority.Action)
			elseif hasRight then
				AnimationController.play(animator, AnimationIDs.RightArmWeapon.id, Enum.AnimationPriority.Action)
			elseif hasLeft then
				AnimationController.play(animator, AnimationIDs.LeftArmWeapon.id, Enum.AnimationPriority.Action)
			end
		end
	end

	char:GetAttributeChangedSignal("RightWeapon"):Connect(onWeaponChanged)
	char:GetAttributeChangedSignal("LeftWeapon"):Connect(onWeaponChanged)
	onWeaponChanged()
end

-----------------------------
-- MAIN INIT --
-----------------------------
function WeaponController.Init()
	print("WeaponController: Initializing...")

	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		setupCharacter(player.Character)
	end

	ViewModelRouter.Init()

	local inputEvents = InputController.GetEvents()

	inputEvents.TossWeapon:Connect(function()
		if not isTossing then
			isTossing = true
			local char = player.Character
			if char then
				local leftWeapon = char:GetAttribute("LeftWeapon")
				local rightWeapon = char:GetAttribute("RightWeapon")

				if leftWeapon and leftWeapon ~= "None" then
					tossWeapon("Left")
				elseif rightWeapon and rightWeapon ~= "None" then
					tossWeapon("Right")
				end
			end
			task.wait(0.2)
			isTossing = false
		end
	end)

	inputEvents.FireRight:Connect(function()
		mouseHeldRight = true
		local char = player.Character
		if not char then
			return
		end
		local weaponName = char:GetAttribute("RightWeapon")

		if isAutomaticWeapon(weaponName) then
			startFireLoop("Right")
		else
			tryToFire("Right")
		end
	end)

	inputEvents.FireLeft:Connect(function()
		mouseHeldLeft = true
		local char = player.Character
		if not char then
			return
		end
		local weaponName = char:GetAttribute("LeftWeapon")

		if isAutomaticWeapon(weaponName) then
			startFireLoop("Left")
		else
			tryToFire("Left")
		end
	end)

	-- ====================================
	-- HARPOON GRAPPLE RELEASE DETECTION
	-- ====================================
	UserInputService.InputEnded:Connect(function(input, _)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			mouseHeldRight = false
			firingTokenRight = nil

			local char = player.Character
			if char then
				local rightWeapon = char:GetAttribute("RightWeapon")
				print(rightWeapon)
				if rightWeapon == "Harpoon" then
					shootEvent:FireServer("Harpoon", { Action = "StopGrapple" }, "Right")
				end
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			mouseHeldLeft = false
			firingTokenLeft = nil

			local char = player.Character
			if char then
				local leftWeapon = char:GetAttribute("LeftWeapon")
				print(leftWeapon)
				if leftWeapon == "Harpoon" then
					shootEvent:FireServer("Harpoon", { Action = "StopGrapple" }, "Left")
				end
			end
		end
	end)

	syncAmmoEvent.OnClientEvent:Connect(function(hand, _, ammoCount)
		local ammoData = weaponState.getAmmo(hand)
		if ammoData then
			ammoData.Mag = ammoCount
		end
	end)

	-- Display tracers broadcast by the server for OTHER players' shots.
	-- The local shooter already draws their own tracer immediately on fire (line ~134),
	-- so we skip the server echo for ourselves to avoid a visible duplicate.
	local bulletTracerEvent = remoteEvents:WaitForChild("BulletTracer")
	bulletTracerEvent.OnClientEvent:Connect(function(startPos, endPos, shooterName)
		if shooterName ~= player.Name then
			createTracer(startPos, endPos)
		end
	end)

	print("WeaponController: Initialized successfully!")
end

return WeaponController

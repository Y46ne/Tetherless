local WeaponController = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local mouse = player:GetMouse()

-- Folders
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local moduleFolders = ReplicatedStorage:WaitForChild("Modules")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local configsFolder = sharedFolder:WaitForChild("Configs")
local utilsFolder = sharedFolder:WaitForChild("Utils")

-- Modules
local weaponModule = require(configsFolder:WaitForChild("WeaponConfig"))
local weaponState = require(sharedFolder:WaitForChild("WeaponState"))
local TweenHelpers = require(ReplicatedStorage.Shared.Utils.TweenHelpers)

-- Controllers
local ViewmodelController = require(script.Parent:WaitForChild("ViewmodelController"))
local InputController = require(script.Parent:WaitForChild("InputController"))

-- Events
local shootEvent = remoteEvents:WaitForChild("Shoot")
local dropWeaponEvent = remoteEvents:WaitForChild("DropWeapon")
local updateHUDEvent = sharedFolder:WaitForChild("UpdateHUD")
local pickupOffhandEvent = remoteEvents:WaitForChild("PickupOffhand")
local syncAmmoEvent = remoteEvents:WaitForChild("SyncAmmo")
local hitmarkerEvent = remoteEvents:WaitForChild("Hitmarker")

-----------------------------
-- PRIVATE VARIABLES --
-----------------------------
local lastFireTimeRight = 0
local lastFireTimeLeft = 0
local isTossing = false -- Safety debounce for dropping weapons

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function getCurrentWeaponName()
	local character = player.Character
	if not character then
		return nil
	end
	return character:GetAttribute("EquippedWeapon")
end

local function createTracer(startPos, endPos)
	local distance = (endPos - startPos).Magnitude

	-- Create a glowing bullet streak
	local tracer = Instance.new("Part")
	tracer.Anchored = true
	tracer.CanCollide = false
	tracer.Massless = true
	tracer.Material = Enum.Material.Neon
	tracer.Color = Color3.fromRGB(255, 0, 4) -- Bright red/yellow
	tracer.Size = Vector3.new(0.05, 0.05, distance)

	-- Position it exactly between the barrel and the target
	tracer.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
	tracer.Parent = workspace

	-- Custom TweenManager implementation
	local goals = {
		Transparency = 1,
		Size = Vector3.new(0, 0, distance),
	}
	local tween = TweenHelpers.play(tracer, goals, 0.05)

	tween.Completed:Connect(function()
		tracer:Destroy()
	end)
end

local function tryToFire(hand)
	local weaponName = getCurrentWeaponName()
	if not weaponName then
		return
	end

	local stats = weaponModule[weaponName]
	local ammoData = weaponState.getAmmo(weaponName)
	local isDual = player.Character:GetAttribute("IsDualWielding")
	local singleHand = player.Character:GetAttribute("SingleWieldHand") or "Right"
	local camera = workspace.CurrentCamera

	if stats and ammoData then
		local currentTime = tick()
		local fireRate = stats.FireRate
		local range = stats.AmmoType and stats.AmmoType.Range or 200

		local canFire = false

		if hand == "Right" and (isDual or singleHand == "Right") and ammoData.Mag > 0 then
			if currentTime - lastFireTimeRight >= fireRate then
				lastFireTimeRight = currentTime
				ammoData.Mag -= 1
				updateHUDEvent:Fire(weaponName, ammoData.Mag)
				canFire = true
			end
		elseif hand == "Left" and (isDual or singleHand == "Left") then
			local currentAmmo = isDual and ammoData.LeftMag or ammoData.Mag
			if currentAmmo > 0 and (currentTime - lastFireTimeLeft >= fireRate) then
				lastFireTimeLeft = currentTime
				if isDual then
					ammoData.LeftMag -= 1
					-- ==========================================
					-- FIXED: FIRE THE HUD UPDATE FOR THE LEFT HAND
					-- ==========================================
					updateHUDEvent:Fire(weaponName, ammoData.LeftMag)
				else
					ammoData.Mag -= 1
					updateHUDEvent:Fire(weaponName, ammoData.Mag)
				end
				canFire = true
			end
		end

		if canFire then
			-- 1. TRIGGER VISUAL EFFECTS
			local muzzlePos = ViewmodelController.PlayShootEffect(hand)

			-- 2. CALCULATE THE HIT POINT
			local origin = camera.CFrame.Position
			local direction = (mouse.Hit.Position - origin).Unit

			local params = RaycastParams.new()
			params.FilterDescendantsInstances = { player.Character, workspace.CurrentCamera }
			params.FilterType = Enum.RaycastFilterType.Exclude

			local rayResult = workspace:Raycast(origin, direction * range, params)
			local endPoint = rayResult and rayResult.Position or (origin + direction * range)

			-- 3. DRAW THE TRACER
			local finalStartPos = muzzlePos or origin
			createTracer(finalStartPos, endPoint)

			-- 4. SERVER DAMAGE
			shootEvent:FireServer(origin, direction, weaponName)
		end
	end
end

local function tossWeapon()
	local char = player.Character
	if not char then
		return
	end

	local weaponName = char:GetAttribute("EquippedWeapon")
	if not weaponName then
		return
	end

	local isDual = char:GetAttribute("IsDualWielding")
	local ammoData = weaponState.getAmmo(weaponName)
	local camera = workspace.CurrentCamera
	local lookDir = camera.CFrame.LookVector

	if isDual then
		local ammoToDrop = ammoData and ammoData.LeftMag or 0

		char:SetAttribute("IsDualWielding", false)
		char:SetAttribute("SingleWieldHand", "Right")

		dropWeaponEvent:FireServer("DropLeft", lookDir, ammoToDrop)

		if ammoData then
			ammoData.LeftMag = 0
		end
		updateHUDEvent:Fire(weaponName, ammoData.Mag)
	else
		local ammoToDrop = ammoData and ammoData.Mag or 0
		char:SetAttribute("EquippedWeapon", nil)
		char:SetAttribute("IsDualWielding", false)
		char:SetAttribute("SingleWieldHand", "Right")

		dropWeaponEvent:FireServer("DropRemaining", lookDir, ammoToDrop)

		if ammoData then
			ammoData.Mag = 0
		end
		updateHUDEvent:Fire("None", 0)
	end
end

local function updateViewmodelAttributes(char)
	local weaponName = char:GetAttribute("EquippedWeapon")
	local isDual = char:GetAttribute("IsDualWielding") or false
	local singleHand = char:GetAttribute("SingleWieldHand") or "Right"

	if weaponName then
		ViewmodelController.EquipWeapon(weaponName, isDual, singleHand)
	else
		ViewmodelController.EquipWeapon("None", false, "Right")
	end
end

local function setupCharacter(char)
	char:GetAttributeChangedSignal("EquippedWeapon"):Connect(function()
		updateViewmodelAttributes(char)
	end)
	char:GetAttributeChangedSignal("IsDualWielding"):Connect(function()
		updateViewmodelAttributes(char)
	end)
	char:GetAttributeChangedSignal("SingleWieldHand"):Connect(function()
		updateViewmodelAttributes(char)
	end)

	char:GetAttributeChangedSignal("EquippedWeapon"):Connect(function()
		local weaponName = char:GetAttribute("EquippedWeapon")
		if weaponName then
			weaponState.resetAmmo(weaponName, false)
			local ammoData = weaponState.getAmmo(weaponName)
			updateHUDEvent:Fire(weaponName, ammoData.Mag)
		end
	end)

	updateViewmodelAttributes(char)
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function WeaponController.Init()
	print("WeaponController: Initializing...")

	-- 1. Character Setup Listeners
	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		setupCharacter(player.Character)
	end

	-- ==========================================
	-- WIRE TO INPUT CONTROLLER EVENTS
	-- ==========================================
	local inputEvents = InputController.GetEvents()

	inputEvents.TossWeapon:Connect(function()
		local char = player.Character
		if not char then
			return
		end
		tossWeapon()
	end)

	inputEvents.FireRight:Connect(function()
		local char = player.Character
		if not char then
			return
		end
		local weaponName = char:GetAttribute("EquippedWeapon")
		if not weaponName or weaponName == "None" then
			return
		end

		local isDual = char:GetAttribute("IsDualWielding")
		if isDual then
			tryToFire("Left")
		else
			local singleHand = char:GetAttribute("SingleWieldHand") or "Right"
			tryToFire(singleHand)
		end
	end)

	inputEvents.FireLeft:Connect(function()
		local char = player.Character
		if not char then
			return
		end
		local weaponName = char:GetAttribute("EquippedWeapon")
		if not weaponName or weaponName == "None" then
			return
		end

		local isDual = char:GetAttribute("IsDualWielding")
		if isDual then
			tryToFire("Right")
		end
	end)

	-- 3. Remote Event Listeners
	pickupOffhandEvent.OnClientEvent:Connect(function(weaponName)
		weaponState.resetAmmo(weaponName, true)
		local ammoData = weaponState.getAmmo(weaponName)
		updateHUDEvent:Fire(weaponName, ammoData.Mag)
	end)

	syncAmmoEvent.OnClientEvent:Connect(function(weaponName, hand, ammoCount)
		local ammoData = weaponState.getAmmo(weaponName)
		if not ammoData then
			return
		end

		if hand == "Left" then
			ammoData.LeftMag = ammoCount
		else
			ammoData.Mag = ammoCount
			updateHUDEvent:Fire(weaponName, ammoData.Mag)
		end
	end)

	hitmarkerEvent.OnClientEvent:Connect(function(isHeadshot)
		if isHeadshot then
			print("CRITICAL HIT! Headshot!")
		else
			print("Hit confirmed!")
		end
	end)
end

return WeaponController

local DropService = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local dropWeaponEvent = remoteEvents:WaitForChild("DropWeapon")
local syncAmmoEvent = remoteEvents:WaitForChild("SyncAmmo")
local offhandEvent = remoteEvents:WaitForChild("PickupOffhand")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configsFolder = sharedFolder:WaitForChild("Configs")
local weaponModule = require(configsFolder:WaitForChild("WeaponConfig"))

local assets = ReplicatedStorage:FindFirstChild("Assets")
local weaponsFolder = assets and assets:FindFirstChild("Weapons")

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function handlePickup(picker, droppedGun, weaponName, ammoToDrop)
	local pickerChar = picker.Character
	if not pickerChar or not pickerChar:FindFirstChild("Humanoid") then
		return
	end

	local currentWeapon = pickerChar:GetAttribute("EquippedWeapon")
	local stats = weaponModule[weaponName]

	if currentWeapon then
		if currentWeapon == weaponName and stats and stats.DualWieldable then
			if pickerChar:GetAttribute("IsDualWielding") == true then
				return
			end

			pickerChar:SetAttribute("IsDualWielding", true)
			offhandEvent:FireClient(picker, weaponName)

			task.wait(0.05)
			syncAmmoEvent:FireClient(picker, weaponName, "Left", ammoToDrop)

			droppedGun:Destroy()
			return
		else
			return
		end
	end

	pickerChar:SetAttribute("EquippedWeapon", weaponName)
	pickerChar:SetAttribute("IsDualWielding", false)
	pickerChar:SetAttribute("SingleWieldHand", "Right")

	task.wait(0.05)
	syncAmmoEvent:FireClient(picker, weaponName, "Right", ammoToDrop)

	droppedGun:Destroy()
end

local function handleDrop(player, dropAction, cameraLookVector, ammoToDrop)
	ammoToDrop = ammoToDrop or 0
	local character = player.Character
	if not character then
		return
	end

	local weaponName = character:GetAttribute("EquippedWeapon")

	if dropAction == "DropLeft" then
		character:SetAttribute("IsDualWielding", false)
		character:SetAttribute("SingleWieldHand", "Right")
	elseif dropAction == "DropRight" then
		character:SetAttribute("IsDualWielding", false)
		character:SetAttribute("SingleWieldHand", "Left")
	else
		character:SetAttribute("EquippedWeapon", nil)
		character:SetAttribute("IsDualWielding", false)
		character:SetAttribute("SingleWieldHand", "Right")
	end

	-- If they somehow tried to drop without a weapon equipped, stop here
	if not weaponName then
		return
	end

	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if weaponsFolder and rootPart then
		local weaponTemplate = weaponsFolder:FindFirstChild(weaponName)
		if weaponTemplate then
			local droppedGun = weaponTemplate:Clone()

			for _, part in pairs(droppedGun:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = true
				end
			end

			if droppedGun.PrimaryPart then
				droppedGun:PivotTo(rootPart.CFrame * CFrame.new(0, 0.5, -2))

				local playerVelocity = rootPart.AssemblyLinearVelocity
				local lookDir = typeof(cameraLookVector) == "Vector3" and cameraLookVector.Unit
					or rootPart.CFrame.LookVector.Unit

				local tossPower = 60

				droppedGun.PrimaryPart.AssemblyLinearVelocity = playerVelocity + (lookDir * tossPower)
				droppedGun.PrimaryPart.AssemblyAngularVelocity = rootPart.CFrame.RightVector * 12

				local attachment = Instance.new("Attachment")
				attachment.Parent = droppedGun.PrimaryPart

				local floatForce = Instance.new("VectorForce")
				floatForce.Attachment0 = attachment
				floatForce.ApplyAtCenterOfMass = true
				floatForce.RelativeTo = Enum.ActuatorRelativeTo.World

				local gravityCounter = droppedGun.PrimaryPart.AssemblyMass * workspace.Gravity * 0.75
				floatForce.Force = Vector3.new(0, gravityCounter, 0)
				floatForce.Parent = droppedGun.PrimaryPart

				task.delay(1.8, function()
					if floatForce then
						floatForce:Destroy()
					end
					if attachment then
						attachment:Destroy()
					end
				end)
			end

			droppedGun.Parent = workspace
			droppedGun:SetAttribute("IsDroppedWeapon", true)

			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Pickup"
			prompt.ObjectText = weaponName .. " [" .. tostring(ammoToDrop) .. "]"
			prompt.KeyboardKeyCode = Enum.KeyCode.E
			prompt.RequiresLineOfSight = false
			prompt.Parent = droppedGun.PrimaryPart or droppedGun

			local despawnTime = (ammoToDrop > 0) and 10 or 5
			Debris:AddItem(droppedGun, despawnTime)

			prompt.Triggered:Connect(function(picker)
				handlePickup(picker, droppedGun, weaponName, ammoToDrop)
			end)
		end
	end
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function DropService.Init()
	print("DropService: Initializing...")
	dropWeaponEvent.OnServerEvent:Connect(handleDrop)
end

return DropService

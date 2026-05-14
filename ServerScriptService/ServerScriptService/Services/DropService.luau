local DropService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local dropWeaponEvent = remoteEvents:WaitForChild("DropWeapon")
local syncAmmoEvent = remoteEvents:WaitForChild("SyncAmmo")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local weaponModulesFolder = sharedFolder:WaitForChild("Weapons")

local assets = ReplicatedStorage:FindFirstChild("Assets")
local weaponsFolder = assets and assets:FindFirstChild("Weapons")

local function getTrashCanFolder()
	local trashCan = workspace:FindFirstChild("TrashCan")
	if not trashCan then
		trashCan = Instance.new("Folder")
		trashCan.Name = "TrashCan"
		trashCan.Parent = workspace
	end

	return trashCan
end

local function handlePickup(picker, droppedGun, weaponName, ammoToDrop)
	local char = picker.Character
	if not char or not char:FindFirstChild("Humanoid") then
		return
	end

	local moduleNode = weaponModulesFolder:FindFirstChild(weaponName)
	local stats = moduleNode and require(moduleNode).Stats
	if not stats then
		return
	end

	local rightWeapon = char:GetAttribute("RightWeapon")
	local leftWeapon = char:GetAttribute("LeftWeapon")

	if not rightWeapon then
		char:SetAttribute("RightWeapon", weaponName)
		syncAmmoEvent:FireClient(picker, "Right", weaponName, ammoToDrop)
		droppedGun:Destroy()
	elseif not leftWeapon then
		local rightModule = weaponModulesFolder:FindFirstChild(rightWeapon)
		local rightStats = rightModule and require(rightModule).Stats

		if rightStats and rightStats.DualWieldable and stats.DualWieldable then
			char:SetAttribute("LeftWeapon", weaponName)
			syncAmmoEvent:FireClient(picker, "Left", weaponName, ammoToDrop)
			droppedGun:Destroy()
		end
	end
end

local function handleDrop(player, dropAction, cameraLookVector, ammoToDrop)
	local char = player.Character
	if not char then
		return
	end

	-- Figure out which hand we are dropping based on the string sent by the client
	local hand = (dropAction == "DropLeft") and "Left" or "Right"
	local weaponName = char:GetAttribute(hand .. "Weapon")
	if not weaponName then
		return
	end

	-- 1. CLEAR THE ATTRIBUTE (This fixes the visual bug!)
	char:SetAttribute(hand .. "Weapon", nil)

	-- 2. SPAWN THE DROPPED GUN
	local rootPart = char:FindFirstChild("HumanoidRootPart")
	if weaponsFolder and rootPart then
		local template = weaponsFolder:FindFirstChild(weaponName)
		if template then
			local droppedGun = template:Clone()
			for _, part in pairs(droppedGun:GetDescendants()) do
				if part:IsA("BasePart") then
					part.Anchored = false
					part.CanCollide = true
				end
			end

			if droppedGun.PrimaryPart then
				droppedGun:PivotTo(rootPart.CFrame * CFrame.new(0, 0.5, -2))
				local lookDir = typeof(cameraLookVector) == "Vector3" and cameraLookVector.Unit
					or rootPart.CFrame.LookVector.Unit
				droppedGun.PrimaryPart.AssemblyLinearVelocity = rootPart.AssemblyLinearVelocity + (lookDir * 60)
			end

			droppedGun.Parent = getTrashCanFolder()
			droppedGun:SetAttribute("IsDroppedWeapon", true)

			local prompt = Instance.new("ProximityPrompt")
			prompt.ActionText = "Pickup"
			prompt.ObjectText = weaponName .. " [" .. tostring(ammoToDrop or 0) .. "]"
			prompt.Parent = droppedGun.PrimaryPart or droppedGun

			Debris:AddItem(droppedGun, (ammoToDrop and ammoToDrop > 0) and 10 or 5)
			prompt.Triggered:Connect(function(picker)
				handlePickup(picker, droppedGun, weaponName, ammoToDrop)
			end)
		end
	end
end

function DropService.Init()
	dropWeaponEvent.OnServerEvent:Connect(handleDrop)
end

return DropService

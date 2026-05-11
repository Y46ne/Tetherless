local SpawnerService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local weaponModulesFolder = sharedFolder:WaitForChild("Weapons")
local weaponModelsFolder = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Weapons")

local activeSpawners = {}

local function clearSpawner(spawnLocation)
	local existing = activeSpawners[spawnLocation]
	if existing then
		if existing.pickupVisual then
			existing.pickupVisual:Destroy()
		end
		activeSpawners[spawnLocation] = nil
	end
end

local function buildFallbackPickupVisual(weaponName)
	local model = Instance.new("Model")
	model.Name = weaponName .. "Pickup"

	local part = Instance.new("Part")
	part.Name = "Primary"
	part.Size = Vector3.new(2, 0.6, 2)
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 170, 60)
	part.Anchored = true
	part.CanCollide = false
	part.Parent = model

	model.PrimaryPart = part
	return model
end

local function createSpawner(spawnLocation)
	clearSpawner(spawnLocation)

	local weaponName = spawnLocation.Name
	local moduleNode = weaponModulesFolder:FindFirstChild(weaponName)
	local stats = moduleNode and require(moduleNode).Stats
	if not stats then
		return
	end

	local isAvailable = true
	local template = weaponModelsFolder:FindFirstChild(weaponName)
	local pickupVisual = template and template:Clone() or buildFallbackPickupVisual(weaponName)
	pickupVisual:PivotTo(spawnLocation.CFrame * CFrame.new(0, 3, 0))
	pickupVisual.Parent = spawnLocation

	for _, part in pairs(pickupVisual:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Equip"
	prompt.ObjectText = weaponName
	prompt.Parent = pickupVisual.PrimaryPart or pickupVisual

	activeSpawners[spawnLocation] = {
		pickupVisual = pickupVisual,
		prompt = prompt,
	}

	task.spawn(function()
		while true do
			task.wait()
			-- THE FIX: We must break the loop if the map gets deleted!
			if pickupVisual and pickupVisual.Parent then
				pickupVisual:PivotTo(pickupVisual:GetPivot() * CFrame.Angles(0, math.rad(2), 0))
			else
				break -- Kills the loop so it doesn't leak memory
			end
		end
	end)

	prompt.Triggered:Connect(function(player)
		if not isAvailable then
			return
		end
		local char = player.Character
		if not char or not char:FindFirstChild("Humanoid") then
			return
		end

		local rightWeapon = char:GetAttribute("RightWeapon")
		local leftWeapon = char:GetAttribute("LeftWeapon")

		if not rightWeapon then
			isAvailable, prompt.Enabled, pickupVisual.Parent = false, false, nil
			char:SetAttribute("RightWeapon", weaponName)
			task.wait(10)
			if spawnLocation and spawnLocation.Parent then -- Make sure map still exists
				isAvailable, prompt.Enabled, pickupVisual.Parent = true, true, spawnLocation
			end
		elseif not leftWeapon then
			local rightStats = require(weaponModulesFolder:FindFirstChild(rightWeapon)).Stats
			if rightStats and rightStats.DualWieldable and stats.DualWieldable then
				isAvailable, prompt.Enabled, pickupVisual.Parent = false, false, nil
				char:SetAttribute("LeftWeapon", weaponName)
				task.wait(10)
				if spawnLocation and spawnLocation.Parent then
					isAvailable, prompt.Enabled, pickupVisual.Parent = true, true, spawnLocation
				end
			end
		end
	end)
end

function SpawnerService.ResetMapSpawners(mapModel)
	for spawnLocation in pairs(activeSpawners) do
		clearSpawner(spawnLocation)
	end

	if not mapModel then
		return
	end

	local weaponSpawnsFolder = mapModel:FindFirstChild("WeaponSpawns")
	if not weaponSpawnsFolder then
		warn("SpawnerService: No 'WeaponSpawns' folder found in the loaded map!")
		return
	end

	for _, spawnLocation in pairs(weaponSpawnsFolder:GetChildren()) do
		if spawnLocation:IsA("BasePart") then
			spawnLocation.CanCollide = false
			createSpawner(spawnLocation)
		end
	end
end

-- NEW: Instead of running once at startup, we run this every time a Map loads
function SpawnerService.SetupMapSpawners(mapModel)
	SpawnerService.ResetMapSpawners(mapModel)
end

function SpawnerService.Init()
	print("SpawnerService: Initialized (Waiting for map load...)")
end

return SpawnerService

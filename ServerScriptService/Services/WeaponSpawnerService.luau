local SpawnerService = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local workspace = game:GetService("Workspace")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local weaponModule = require(sharedFolder:WaitForChild("WeaponData"))

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local offhandEvent = remoteEvents:WaitForChild("PickupOffhand") -- Moved to top for performance!

local weaponSpawnsFolder = workspace:WaitForChild("WeaponSpawns")
local assetsFolder = ReplicatedStorage:WaitForChild('Assets')
local weaponsFolder = assetsFolder:WaitForChild('Weapons')

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function createSpawner(spawnLocation)
	local weaponName = spawnLocation.Name
	local stats = weaponModule[weaponName]
	if not stats then return end

	local respawnTime = 10 
	local isAvailable = true

	-- Setup Visuals
	local pickupVisual = weaponsFolder:FindFirstChild(weaponName):Clone()
	pickupVisual:PivotTo(spawnLocation.CFrame * CFrame.new(0, 3, 0))
	pickupVisual.Parent = spawnLocation

	for _, part in pairs(pickupVisual:GetDescendants()) do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
		end
	end

	-- Setup Prompt
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Equip"
	prompt.ObjectText = weaponName
	prompt.KeyboardKeyCode = Enum.KeyCode.E 
	prompt.RequiresLineOfSight = false
	prompt.Parent = pickupVisual.PrimaryPart or pickupVisual

	-- The Spinning Animation Loop
	task.spawn(function()
		while true do
			task.wait()
			if pickupVisual and pickupVisual.Parent then
				pickupVisual:PivotTo(pickupVisual:GetPivot() * CFrame.Angles(0, math.rad(2), 0))
			end
		end
	end)

	-- Pickup Logic
	prompt.Triggered:Connect(function(player)
		if not isAvailable then return end
		local character = player.Character
		if not character or not character:FindFirstChild("Humanoid") then return end

		local currentWeapon = character:GetAttribute("EquippedWeapon")

		-- DUAL WIELD CHECK
		if currentWeapon then
			if currentWeapon == weaponName and stats.DualWieldable then
				if character:GetAttribute("IsDualWielding") == true then return end

				-- Upgrade to Akimbo!
				isAvailable = false
				pickupVisual.Parent = nil
				prompt.Enabled = false

				character:SetAttribute("IsDualWielding", true)
				offhandEvent:FireClient(player, weaponName)

				task.wait(respawnTime)
				isAvailable = true
				pickupVisual.Parent = spawnLocation
				prompt.Enabled = true
				return
			else
				return -- Hands full with a different gun
			end
		end

		-- NORMAL PICKUP
		isAvailable = false
		prompt.Enabled = false 
		pickupVisual.Parent = nil 

		character:SetAttribute("EquippedWeapon", weaponName)
		character:SetAttribute("IsDualWielding", false)
		character:SetAttribute("SingleWieldHand", "Right") 

		task.wait(respawnTime)
		isAvailable = true
		pickupVisual.Parent = spawnLocation 
		prompt.Enabled = true 
	end)
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function SpawnerService.Init()
	print("SpawnerService: Initializing...")

	-- Loop through all spawn blocks in the workspace and activate them
	for _, spawnLocation in pairs(weaponSpawnsFolder:GetChildren()) do
		if spawnLocation:IsA("BasePart") then
			spawnLocation.CanCollide = false
			createSpawner(spawnLocation)
		end
	end
end

return SpawnerService
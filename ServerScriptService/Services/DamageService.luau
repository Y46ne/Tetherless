local WeaponService = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players") -- Added for player lookups
local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local weaponModule = require(sharedFolder:WaitForChild("WeaponData"))
local DamageLogService = require(script.Parent.DamageLogService)

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local shootEvent = remoteEvents:WaitForChild("Shoot")

local hitmarkerEvent 

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------

-- UPDATED: Now accepts the attacker and weapon name for the log
local function triggerTrickshotExplosion(position, attacker, weaponName)
	local explosion = Instance.new("Explosion")
	explosion.Position = position
	explosion.BlastRadius = 20 
	explosion.BlastPressure = 5000000 
	explosion.DestroyJointRadiusPercent = 0 
	explosion.Parent = workspace

	local explId = "Explosion_" .. tostring(tick())

	explosion.Hit:Connect(function(hitPart, distance)
		local hitModel = hitPart:FindFirstAncestorOfClass("Model")
		if hitModel then
			local hum = hitModel:FindFirstChild("Humanoid")
			if hum and hum.Health > 0 then

				if not hum:GetAttribute(explId) then
					hum:SetAttribute(explId, true)

					local explosionDamage = 60
					hum:TakeDamage(explosionDamage) 

					-- LOG EXPLOSION DAMAGE
					local victimPlayer = Players:GetPlayerFromCharacter(hitModel)
					if victimPlayer then
						-- Tagging it as a Trickshot in the log
						DamageLogService.LogDamage(victimPlayer, attacker.Name, weaponName .. " [TRICKSHOT]", explosionDamage, false)
					end

					task.delay(1, function()
						if hum then hum:SetAttribute(explId, nil) end
					end)
				end
			end
		end
	end)
end

-- UPDATED: Now accepts weaponName as an argument
local function handleHit(player, result, ammoStats, weaponName)
	local hitPart = result.Instance
	local model = hitPart:FindFirstAncestorOfClass("Model")

	if model then
		-- TRICKSHOT CHECK
		if model:GetAttribute("IsDroppedWeapon") then
			triggerTrickshotExplosion(model:GetPivot().Position, player, weaponName)
			model:Destroy() 
			return 
		end

		-- NORMAL DAMAGE CHECK
		local humanoid = model:FindFirstChild("Humanoid")

		if humanoid and humanoid.Health > 0 then
			local damage = ammoStats.Damage or 20
			local isHeadshot = false

			if hitPart.Name == "Head" then
				damage = damage * (ammoStats.HeadshotMultiplier or 2.0)
				isHeadshot = true
			end

			humanoid:TakeDamage(damage)

			-- FIXED: Used Players service instead of the 'player' variable
			local victimPlayer = Players:GetPlayerFromCharacter(model)
			if victimPlayer then
				-- We now have the weaponName passed in!
				DamageLogService.LogDamage(victimPlayer, player.Name, weaponName, damage, isHeadshot)
			end

			if hitmarkerEvent then
				hitmarkerEvent:FireClient(player, isHeadshot)
			end
		end
	end
end

-- UPDATED: Now accepts weaponName to pass it forward
local function performRaycast(player, origin, direction, ammoStats, weaponName)
	local range = ammoStats.Range or 200

	local params = RaycastParams.new()
	params.FilterDescendantsInstances = {player.Character}
	params.FilterType = Enum.RaycastFilterType.Exclude

	local rayResult = workspace:Raycast(origin, direction * range, params)

	if rayResult then
		handleHit(player, rayResult, ammoStats, weaponName)
	end
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function WeaponService.Init()
	print("WeaponService: Initializing...")

	hitmarkerEvent = remoteEvents:FindFirstChild("Hitmarker") 
	if not hitmarkerEvent then
		hitmarkerEvent = Instance.new("RemoteEvent")
		hitmarkerEvent.Name = "Hitmarker"
		hitmarkerEvent.Parent = remoteEvents
	end

	shootEvent.OnServerEvent:Connect(function(player, origin, direction, weaponName)
		local character = player.Character
		if not character or not character:FindFirstChild("Humanoid") then return end

		-- Verify they are actually holding what they say they are shooting
		local equipped = character:GetAttribute("EquippedWeapon")
		if equipped ~= weaponName then return end

		local stats = weaponModule[weaponName]
		if stats then
			local ammoStats = stats.AmmoType
			if ammoStats then
				-- Pass the weaponName into the physics chain
				performRaycast(player, origin, direction, ammoStats, weaponName)
			end
		end
	end)
end

return WeaponService
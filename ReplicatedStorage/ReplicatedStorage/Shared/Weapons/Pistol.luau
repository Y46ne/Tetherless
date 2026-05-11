local Pistol = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local configs = shared:WaitForChild("Configs")
local utils = shared:WaitForChild("Utils")

local BulletsData = require(configs:WaitForChild("BulletsConfig"))
local RaycastUtils = require(utils:WaitForChild("RaycastUtils"))
local MathUtils = require(utils:WaitForChild("MathUtils"))

-- 1. THE STATS
Pistol.Stats = {
	DisplayName = "9mm Pistol",
	FireRate = 0.1,
	AmmoType = BulletsData["9mm"],
	Magazine = 15,
	Category = "Pistol",
	DualWieldable = true,
	Traits = { "One-Handed", "Semi-Automatic", "Hit-Scan" },
}

-- 2. CLIENT LOGIC (Calculates the aim vector)
function Pistol.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	local direction = (mouseHit.Position - origin).Unit

	-- We return this payload so the Client can send it to the Server
	return {
		Origin = origin,
		Direction = direction,
	}
end

-- 3. SERVER LOGIC (Advanced Ballistics Loop)
function Pistol.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local direction = payload.Direction
	local ammoStats = Pistol.Stats.AmmoType

	local currentPos = origin
	local velocity = direction * ammoStats.MuzzleVelocity
	local gravity = Vector3.new(0, -workspace.Gravity * (ammoStats.GravityScale or 1), 0)
	local distanceTraveled = 0
	local startTime = tick()
	local maxLifetime = 3 -- Despawn bullet after 3 seconds

	-- The Physics Simulation Loop
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if tick() - startTime > maxLifetime then
			connection:Disconnect()
			return
		end

		-- 1. Apply Gravity to Velocity
		velocity = velocity + (gravity * dt)
		local displacement = velocity * dt
		local nextPos = currentPos + displacement

		-- 2. Check for collisions
		local rayResult = RaycastUtils.Raycast(currentPos, displacement, { attacker.Character })

		if rayResult then
			connection:Disconnect()

			-- 3. Calculate Velocity-Based Damage
			distanceTraveled = distanceTraveled + (rayResult.Position - currentPos).Magnitude
			local alpha = math.clamp(distanceTraveled / ammoStats.MaxRange, 0, 1)
			local finalDamage = MathUtils.lerp(ammoStats.Damage, ammoStats.MinDamage, alpha)

			-- 4. Check for headshot
			local isHeadshot = false
			if rayResult.Instance.Name == "Head" then
				finalDamage = finalDamage * (ammoStats.HeadshotMultiplier or 2.0)
				isHeadshot = true
			end

			-- 5. Tell DamageService we hit something!
			onHitCallback(rayResult, finalDamage, isHeadshot)
		else
			currentPos = nextPos
			distanceTraveled = distanceTraveled + displacement.Magnitude
		end
	end)
end

return Pistol

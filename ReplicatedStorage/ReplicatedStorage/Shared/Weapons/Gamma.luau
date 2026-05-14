-- Gamma
-- Two-handed energy rifle. Fires large glowing bolts in a perfectly straight line
-- with no gravity drop. Fast projectile, high-ish damage, big magazine.
-- The lack of gravity means leading targets requires a different instinct than hitscan.

local Gamma = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

Gamma.Stats = {
	DisplayName = "Gamma",
	FireRate = 0.2,
	Magazine = 50,
	Category = "Heavy",
	DualWieldable = false,
	Traits = { "Two-Handed", "Full-Automatic", "Projectile" },
	Power = 37.5,
	HeadshotMultiplier = 2,
	MovementFactor = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	ProjectileSpeed = 380,
}

function Gamma.FireClient(_player, _hand, camera, _mouseHit)
	return {
		Origin = camera.CFrame.Position,
		Direction = camera.CFrame.LookVector,
	}
end

function Gamma.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local direction = payload.Direction.Unit

	local bolt = Instance.new("Part")
	bolt.Name = "GammaBolt"
	bolt.Size = Vector3.new(0.35, 0.35, 2.8)
	bolt.Material = Enum.Material.Neon
	bolt.Color = Color3.fromRGB(60, 255, 120)
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanTouch = false
	bolt.CanQuery = false
	bolt.CFrame = CFrame.lookAt(origin, origin + direction)
	bolt.Parent = workspace

	local currentPos = origin
	local velocity = direction * Gamma.Stats.ProjectileSpeed
	local alive = true

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not alive or not bolt.Parent then
			if connection then connection:Disconnect() end
			return
		end

		-- No gravity — laser bolt travels in a perfectly straight line
		local nextPos = currentPos + velocity * dt
		local rayResult = RaycastUtils.Raycast(currentPos, nextPos - currentPos, { attacker.Character, bolt })
		if rayResult then
			alive = false
			bolt:Destroy()
			if connection then connection:Disconnect() end
			local isHeadshot = rayResult.Instance.Name == "Head"
			local damage = Gamma.Stats.Power * (isHeadshot and Gamma.Stats.HeadshotMultiplier or 1)
			onHitCallback(rayResult, damage, isHeadshot)
			return
		end

		currentPos = nextPos
		bolt.CFrame = CFrame.lookAt(currentPos, currentPos + velocity.Unit)
	end)

	Debris:AddItem(bolt, 3)
end

return Gamma

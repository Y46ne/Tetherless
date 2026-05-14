-- BeamLoad
-- One-handed charged energy pistol with infinite ammo.
-- Fires a fast bright bolt that deals 100 damage — effectively an instakill per shot.
-- The 4× headshot multiplier means a headshot is always lethal regardless of health.
-- Slow fire rate (1s) is the balancing factor for the raw power.

local BeamLoad = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

BeamLoad.Stats = {
	DisplayName = "Beam Load",
	FireRate = 1.0,
	Magazine = 9999, -- infinite
	Category = "Pistol",
	DualWieldable = true,
	Traits = { "One-Handed", "Semi-Automatic", "Projectile", "Insta-gib", "Special" },
	Power = 100,
	HeadshotMultiplier = 4,
	MovementFactor = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	ProjectileSpeed = 650,
}

function BeamLoad.FireClient(_player, _hand, camera, _mouseHit)
	return {
		Origin = camera.CFrame.Position,
		Direction = camera.CFrame.LookVector,
	}
end

function BeamLoad.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local direction = payload.Direction.Unit

	-- Bright golden charged bolt — visually distinct from regular projectiles
	local bolt = Instance.new("Part")
	bolt.Name = "BeamLoadBolt"
	bolt.Size = Vector3.new(0.22, 0.22, 3.2)
	bolt.Material = Enum.Material.Neon
	bolt.Color = Color3.fromRGB(255, 210, 30)
	bolt.Anchored = true
	bolt.CanCollide = false
	bolt.CanTouch = false
	bolt.CanQuery = false
	bolt.CFrame = CFrame.lookAt(origin, origin + direction)
	bolt.Parent = workspace

	local currentPos = origin
	local velocity = direction * BeamLoad.Stats.ProjectileSpeed
	local alive = true

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not alive or not bolt.Parent then
			if connection then connection:Disconnect() end
			return
		end

		local nextPos = currentPos + velocity * dt
		local rayResult = RaycastUtils.Raycast(currentPos, nextPos - currentPos, { attacker.Character, bolt })
		if rayResult then
			alive = false
			bolt:Destroy()
			if connection then connection:Disconnect() end
			local isHeadshot = rayResult.Instance.Name == "Head"
			local damage = BeamLoad.Stats.Power * (isHeadshot and BeamLoad.Stats.HeadshotMultiplier or 1)
			onHitCallback(rayResult, damage, isHeadshot)
			return
		end

		currentPos = nextPos
		bolt.CFrame = CFrame.lookAt(currentPos, currentPos + velocity.Unit)
	end)

	Debris:AddItem(bolt, 2)
end

return BeamLoad

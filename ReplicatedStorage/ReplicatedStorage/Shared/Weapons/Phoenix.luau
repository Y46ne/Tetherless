-- Phoenix
-- One-handed flamethrower. Low damage per tick but flames pass through walls.
-- Implemented by checking all players within a forward cone without raycasting geometry,
-- so barriers don't block it. Devastating at close range when dual-wielded.

local Phoenix = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Phoenix.Stats = {
	DisplayName = "Phoenix",
	FireRate = 0.1,
	Magazine = 100,
	Category = "Special",
	DualWieldable = true,
	Traits = { "One-Handed", "Full-Automatic", "Special" },
	Power = 5,
	HeadshotMultiplier = 1, -- fire doesn't headshot
	MovementFactor = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	Range = 22,           -- flame range in studs
	ConeAngle = 35,       -- half-angle of the damage cone in degrees
}

function Phoenix.FireClient(_player, _hand, camera, _mouseHit)
	return {
		Origin = camera.CFrame.Position,
		Direction = camera.CFrame.LookVector,
	}
end

function Phoenix.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local direction = payload.Direction.Unit
	local range = Phoenix.Stats.Range
	local cosAngle = math.cos(math.rad(Phoenix.Stats.ConeAngle))

	-- Check all players by geometry, not raycasting — flames go through walls
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer == attacker then continue end

		local char = otherPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChild("Humanoid")
		if not root or not hum or hum.Health <= 0 then continue end

		local toTarget = root.Position - origin
		local dist = toTarget.Magnitude
		if dist > range or dist < 0.01 then continue end

		-- Is the target within the forward cone?
		if toTarget.Unit:Dot(direction) >= cosAngle then
			onHitCallback(
				{ Instance = root, Position = root.Position },
				Phoenix.Stats.Power,
				false
			)
		end
	end
end

return Phoenix

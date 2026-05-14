-- Repulsar
-- One-handed knockback tool. Deals no damage but blasts nearby enemies away.
-- Knockback force is doubled when the target is airborne.
-- Excellent for launching enemies off ledges or into walls.

local Repulsar = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

Repulsar.Stats = {
	DisplayName = "Repulsar",
	FireRate = 0.5,
	Magazine = 9999,
	Category = "Special",
	DualWieldable = true,
	Traits = { "One-Handed", "Semi-Automatic", "Special", "Equipment" },
	Power = 0, -- no damage
	HeadshotMultiplier = 1,
	MovementFactor = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	BlastRadius = 12,
	KnockbackForce = 120,
	AirborneMultiplier = 2.0, -- double force on airborne targets
}

function Repulsar.FireClient(_player, _hand, camera, _mouseHit)
	return {
		Origin = camera.CFrame.Position,
		Direction = camera.CFrame.LookVector,
	}
end

function Repulsar.FireServer(attacker, payload, onHitCallback)
	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerRoot then return end

	local origin = attackerRoot.Position -- blast emanates from the attacker's position

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer == attacker then continue end

		local char = otherPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChild("Humanoid")
		if not root or not hum or hum.Health <= 0 then continue end

		local dist = (root.Position - origin).Magnitude
		if dist > Repulsar.Stats.BlastRadius then continue end

		local pushDir = (root.Position - origin)
		if pushDir.Magnitude < 0.1 then pushDir = Vector3.new(0, 1, 0) end
		pushDir = (pushDir.Unit + Vector3.new(0, 0.3, 0)).Unit

		local isAirborne = hum.FloorMaterial == Enum.Material.Air
		local force = Repulsar.Stats.KnockbackForce * (isAirborne and Repulsar.Stats.AirborneMultiplier or 1)

		-- Change state to allow knockback to override ground friction
		hum:ChangeState(Enum.HumanoidStateType.Freefall)
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
		root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + pushDir * force
		root:ApplyImpulse(pushDir * force * root.AssemblyMass)
	end

	-- No onHitCallback — Repulsar deals no damage, no hitmarker
end

return Repulsar

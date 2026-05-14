-- Katana
-- Two-handed melee that grants passive speed, jump height, and wall-jump bonuses.
-- Primary slash: 37.5 damage. Each swing also nudges the attacker forward slightly.
-- Secondary (right-click payload): dashes toward the aim point and instakills on contact.

local Katana = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

Katana.Stats = {
	DisplayName = "The Katana",
	FireRate = 0.7,
	Magazine = 9999,
	Category = "Melee",
	DualWieldable = false,
	Traits = { "Two-Handed", "Melee", "Special" },
	Power = 37.5,
	SecondaryPower = 9999, -- instakill
	HeadshotMultiplier = 2,
	MovementFactor = 1.15, -- passive speed boost while held
	JumpFactor = 1.2,      -- slightly higher jump
	WallJumpFactor = 2,    -- double wall-jump force
	MaxWallJumps = 3,      -- three wall jumps before landing
	Reach = 8,
	DashRange = 40,        -- secondary dash range (studs)
	DashSpeed = 120,       -- lunge velocity
	SwingNudge = 18,       -- how much the primary swing nudges the attacker forward
}

function Katana.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	return {
		Origin = origin,
		Direction = (mouseHit.Position - origin).Unit,
	}
end

function Katana.FireServer(attacker, payload, onHitCallback)
	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerChar or not attackerRoot then return end

	local isSecondary = payload.Secondary == true

	if isSecondary then
		-- Dash toward aim, instakill on contact
		local dashDir = payload.Direction.Unit
		attackerRoot.AssemblyLinearVelocity = dashDir * Katana.Stats.DashSpeed

		local rayResult = RaycastUtils.Raycast(
			payload.Origin,
			dashDir * Katana.Stats.DashRange,
			{ attackerChar }
		)
		if rayResult then
			local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				onHitCallback(rayResult, Katana.Stats.SecondaryPower, false)
			end
		end
		return
	end

	-- Primary slash — nudge attacker forward, check for hit
	local nudgeDir = Vector3.new(payload.Direction.X, 0, payload.Direction.Z)
	if nudgeDir.Magnitude > 0.01 then
		attackerRoot.AssemblyLinearVelocity = attackerRoot.AssemblyLinearVelocity
			+ nudgeDir.Unit * Katana.Stats.SwingNudge
	end

	local origin = payload.Origin + payload.Direction.Unit * 2
	local rayResult = RaycastUtils.Raycast(origin, payload.Direction.Unit * Katana.Stats.Reach, { attackerChar })
	if not rayResult then return end

	local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
	local humanoid = model and model:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health > 0 then
		local isHeadshot = rayResult.Instance.Name == "Head"
		local damage = Katana.Stats.Power * (isHeadshot and Katana.Stats.HeadshotMultiplier or 1)
		onHitCallback(rayResult, damage, isHeadshot)
	end
end

return Katana

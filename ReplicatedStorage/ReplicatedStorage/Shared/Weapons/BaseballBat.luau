local BaseballBat = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

BaseballBat.Stats = {
	["Damage"] = 12.5,
	["Headshot Multiplier"] = 2,
	["Capacity"] = "N/A",
	["Fire-Rate"] = 0.25,
	["Movement Factor"] = 1,
	["Max Wall Jumps"] = 1,
	["Jump Factor"] = 1,
	["Wall Jump Factor"] = 1,
	Traits = { "One-Handed", "Melee", "Special" },
	Power = 12.5,
	HeadshotMultiplier = 2,
	Magazine = 9999,
	FireRate = 0.25,
	MovementFactor = 1,
	MaxWallJumps = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	DualWieldable = true,
	Category = "Melee",
	Reach = 8,
	Knockback = 85,
	PogoBoost = 110,
}

function BaseballBat.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	local direction = (mouseHit.Position - origin).Unit

	return {
		Origin = origin,
		Direction = direction,
	}
end

function BaseballBat.FireServer(attacker, payload, onHitCallback)
	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerChar or not attackerRoot then
		return
	end

	local origin = payload.Origin + (payload.Direction.Unit * 2)
	local direction = payload.Direction.Unit
	local rayResult = RaycastUtils.Raycast(origin, direction * BaseballBat.Stats.Reach, { attackerChar })

	if rayResult then
		local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		local targetRoot = model and model:FindFirstChild("HumanoidRootPart")

		if humanoid and targetRoot and humanoid.Health > 0 then
			local damage = BaseballBat.Stats.Power
			local isHeadshot = rayResult.Instance.Name == "Head"
			if isHeadshot then
				damage = damage * BaseballBat.Stats.HeadshotMultiplier
			end

			humanoid:TakeDamage(damage)

			-- CRITICAL: Change humanoid state FIRST to prevent ground friction from canceling knockback
			humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)

			-- Apply knockback with double method (impulse + velocity)
			targetRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity
				+ (direction * BaseballBat.Stats.Knockback)
				+ Vector3.new(0, 18, 0)
			targetRoot:ApplyImpulse(
				(direction + Vector3.new(0, 0.25, 0)).Unit * (BaseballBat.Stats.Knockback * targetRoot.AssemblyMass)
			)

			onHitCallback(rayResult, damage, isHeadshot)
			return
		end

		if direction.Y < -0.35 then
			attackerRoot.AssemblyLinearVelocity = attackerRoot.AssemblyLinearVelocity
				+ Vector3.new(0, BaseballBat.Stats.PogoBoost, 0)
			attackerRoot:ApplyImpulse(Vector3.new(0, BaseballBat.Stats.PogoBoost * attackerRoot.AssemblyMass, 0))
		end
	end
end

return BaseballBat

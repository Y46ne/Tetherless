-- Flamberge
-- One-handed blade with extreme aerial mobility (same jump stats as CurvedKnife).
-- Primary slash deals 50 damage. Secondary (right mouse on same hand) lunges forward
-- and deals 100 damage — effectively an instakill.
-- Secondary is sent as a special payload action from the client.

local Flamberge = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

Flamberge.Stats = {
	DisplayName = "Flamberge",
	FireRate = 0.7,
	Magazine = 9999,
	Category = "Melee",
	DualWieldable = true,
	Traits = { "One-Handed", "Melee", "Special" },
	Power = 50,
	SecondaryPower = 100,
	HeadshotMultiplier = 2,
	MovementFactor = 1,
	JumpFactor = 3,
	WallJumpFactor = 3,
	MaxWallJumps = 3,
	Reach = 7,
	LungeSpeed = 90,   -- forward lunge velocity on secondary attack
	LungeRange = 12,   -- extended reach during lunge
}

function Flamberge.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	return {
		Origin = origin,
		Direction = (mouseHit.Position - origin).Unit,
	}
end

function Flamberge.FireServer(attacker, payload, onHitCallback)
	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerChar or not attackerRoot then return end

	local isSecondary = payload.Secondary == true
	local damage = isSecondary and Flamberge.Stats.SecondaryPower or Flamberge.Stats.Power
	local reach = isSecondary and Flamberge.Stats.LungeRange or Flamberge.Stats.Reach

	if isSecondary then
		-- Lunge the attacker forward before checking for hits
		local lDir = payload.Direction.Unit
		attackerRoot.AssemblyLinearVelocity = Vector3.new(lDir.X, 0, lDir.Z).Unit * Flamberge.Stats.LungeSpeed
			+ Vector3.new(0, attackerRoot.AssemblyLinearVelocity.Y, 0)
	end

	local origin = payload.Origin + payload.Direction.Unit * 2
	local rayResult = RaycastUtils.Raycast(origin, payload.Direction.Unit * reach, { attackerChar })
	if not rayResult then return end

	local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
	local humanoid = model and model:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health > 0 then
		local isHeadshot = rayResult.Instance.Name == "Head"
		local finalDamage = damage * (isHeadshot and Flamberge.Stats.HeadshotMultiplier or 1)
		onHitCallback(rayResult, finalDamage, isHeadshot)
	end
end

return Flamberge

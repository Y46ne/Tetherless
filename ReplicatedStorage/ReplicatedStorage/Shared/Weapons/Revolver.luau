-- Revolver
-- High-damage semi-auto pistol. Perfectly accurate when walking or sliding,
-- but spread becomes unmanageable while sprinting or airborne.
-- Reward: methodical, controlled movement. Punish: spray-and-pray.

local Revolver = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

Revolver.Stats = {
	DisplayName = "Revolver",
	FireRate = 0.1,
	Magazine = 6,
	Category = "Pistol",
	DualWieldable = true,
	Traits = { "One-Handed", "Semi-Automatic", "Hit-Scan" },
	Power = 50,
	HeadshotMultiplier = 2,
	MovementFactor = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	SprintSpread = 0.18, -- radians of random cone when moving fast or airborne
}

function Revolver.FireClient(player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	local direction = (mouseHit.Position - origin).Unit

	-- Determine if the shot should be inaccurate.
	-- Inaccurate when: airborne, or sprinting (speed > ~22).
	local char = player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local isAirborne = hum and hum.FloorMaterial == Enum.Material.Air
	local speed = root and Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude or 0
	local isInaccurate = isAirborne or speed > 22

	return {
		Origin = origin,
		Direction = direction,
		Inaccurate = isInaccurate,
	}
end

function Revolver.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local direction = payload.Direction.Unit

	if payload.Inaccurate then
		local spread = Revolver.Stats.SprintSpread
		local randX = (math.random() - 0.5) * 2 * spread
		local randY = (math.random() - 0.5) * 2 * spread
		local right = direction:Cross(Vector3.new(0, 1, 0))
		if right.Magnitude < 0.001 then right = Vector3.new(1, 0, 0) end
		right = right.Unit
		local up = right:Cross(direction).Unit
		direction = (direction + right * randX + up * randY).Unit
	end

	local rayResult = RaycastUtils.Raycast(origin, direction * 300, { attacker.Character })
	if rayResult and rayResult.Instance then
		local isHeadshot = rayResult.Instance.Name == "Head"
		local damage = Revolver.Stats.Power * (isHeadshot and Revolver.Stats.HeadshotMultiplier or 1)
		onHitCallback(rayResult, damage, isHeadshot)
	end
end

return Revolver

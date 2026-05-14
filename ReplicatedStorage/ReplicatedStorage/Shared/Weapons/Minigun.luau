-- Minigun
-- Massive magazine, blistering fire rate, slight movement penalty.
-- Constant small spread keeps it honest at range.

local Minigun = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

Minigun.Stats = {
	DisplayName = "Minigun",
	FireRate = 0.04,
	Magazine = 144,
	Category = "Heavy",
	DualWieldable = false,
	Traits = { "Two-Handed", "Full-Automatic", "Hit-Scan" },
	Power = 25,
	HeadshotMultiplier = 2,
	MovementFactor = 0.9, -- 10% speed penalty while holding
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	Spread = 0.03, -- constant cone spread in radians
}

function Minigun.FireClient(_player, _hand, camera, _mouseHit)
	return {
		Origin = camera.CFrame.Position,
		Direction = camera.CFrame.LookVector,
	}
end

function Minigun.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local direction = payload.Direction.Unit

	-- Apply constant spread — Minigun is imprecise by design
	local spread = Minigun.Stats.Spread
	local randX = (math.random() - 0.5) * 2 * spread
	local randY = (math.random() - 0.5) * 2 * spread
	local right = direction:Cross(Vector3.new(0, 1, 0))
	if right.Magnitude < 0.001 then right = Vector3.new(1, 0, 0) end
	right = right.Unit
	local up = right:Cross(direction).Unit
	direction = (direction + right * randX + up * randY).Unit

	local rayResult = RaycastUtils.Raycast(origin, direction * 400, { attacker.Character })
	if rayResult and rayResult.Instance then
		local isHeadshot = rayResult.Instance.Name == "Head"
		local damage = Minigun.Stats.Power * (isHeadshot and Minigun.Stats.HeadshotMultiplier or 1)
		onHitCallback(rayResult, damage, isHeadshot)
	end
end

return Minigun

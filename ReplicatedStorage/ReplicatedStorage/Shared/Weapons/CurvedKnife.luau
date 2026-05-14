-- CurvedKnife
-- One-handed melee with extreme aerial mobility: 3× jump height, 3× wall-jump force,
-- and up to 3 consecutive wall jumps. Great for assassins who attack from above.

local CurvedKnife = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

CurvedKnife.Stats = {
	DisplayName = "Curved Knife",
	FireRate = 0.25,
	Magazine = 9999,
	Category = "Melee",
	DualWieldable = true,
	Traits = { "One-Handed", "Melee", "Special" },
	Power = 37.5,
	HeadshotMultiplier = 2,
	MovementFactor = 1,
	JumpFactor = 3,       -- grants triple jump height while held
	WallJumpFactor = 3,   -- grants triple wall-jump force while held
	MaxWallJumps = 3,     -- up to 3 wall jumps before landing
	Reach = 7,
}

function CurvedKnife.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	return {
		Origin = origin,
		Direction = (mouseHit.Position - origin).Unit,
	}
end

function CurvedKnife.FireServer(attacker, payload, onHitCallback)
	local attackerChar = attacker.Character
	if not attackerChar then return end

	local origin = payload.Origin + payload.Direction.Unit * 2
	local rayResult = RaycastUtils.Raycast(origin, payload.Direction.Unit * CurvedKnife.Stats.Reach, { attackerChar })
	if not rayResult then return end

	local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
	local humanoid = model and model:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health > 0 then
		local isHeadshot = rayResult.Instance.Name == "Head"
		local damage = CurvedKnife.Stats.Power * (isHeadshot and CurvedKnife.Stats.HeadshotMultiplier or 1)
		onHitCallback(rayResult, damage, isHeadshot)
	end
end

return CurvedKnife

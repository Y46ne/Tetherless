-- HandCannon
-- Two-handed power weapon with unlimited ammo and wall penetration.
-- 100 damage per shot, penetrates through walls and multiple enemies in a line.
-- Slow fire rate (1.2s) is the cost for raw stopping power.
-- Penetration is implemented by continuing the ray past character hits (ignoring world geo).

local HandCannon = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

HandCannon.Stats = {
	DisplayName = "Hand Cannon",
	FireRate = 1.2,
	Magazine = 9999, -- unlimited
	Category = "Heavy",
	DualWieldable = false,
	Traits = { "Two-Handed", "Semi-Automatic", "Hit-Scan", "Power Weapon", "Special" },
	Power = 100,
	HeadshotMultiplier = 2,
	MovementFactor = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	Range = 500,
	MaxPierces = 5, -- max enemies the shot can pass through
}

function HandCannon.FireClient(_player, _hand, camera, _mouseHit)
	return {
		Origin = camera.CFrame.Position,
		Direction = camera.CFrame.LookVector,
	}
end

function HandCannon.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local direction = payload.Direction.Unit
	local range = HandCannon.Stats.Range

	-- Build a list of all players along the shot line, ignoring walls entirely.
	-- This is the "penetrates walls" mechanic: geometry is never checked.
	local hits = {}
	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer == attacker then continue end

		local char = otherPlayer.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChild("Humanoid")
		if not root or not hum or hum.Health <= 0 then continue end

		local toTarget = root.Position - origin
		local distAlongRay = toTarget:Dot(direction)
		if distAlongRay <= 0 or distAlongRay > range then continue end

		-- Perpendicular distance from the shot line — must be within ~3 studs
		local perpDist = (toTarget - direction * distAlongRay).Magnitude
		if perpDist > 3 then continue end

		table.insert(hits, { dist = distAlongRay, root = root, hum = hum, char = char })
	end

	-- Sort by distance so near targets are registered first
	table.sort(hits, function(a, b) return a.dist < b.dist end)

	for i, hit in ipairs(hits) do
		if i > HandCannon.Stats.MaxPierces then break end

		local isHeadshot = false -- wall-pierce shots don't headshot (body center used)
		local damage = HandCannon.Stats.Power * (isHeadshot and HandCannon.Stats.HeadshotMultiplier or 1)
		onHitCallback(
			{ Instance = hit.root, Position = hit.root.Position },
			damage,
			isHeadshot
		)
	end
end

return HandCannon

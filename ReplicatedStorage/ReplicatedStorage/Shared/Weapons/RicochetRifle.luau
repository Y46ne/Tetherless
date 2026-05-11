local RicochetRifle = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

RicochetRifle.Stats = {
	DisplayName = "Ricochet Rifle",
	FireRate = 0.5,
	Magazine = 8,
	Category = "Rifle",
	DualWieldable = false,
	Traits = { "Two-Handed", "Semi-Automatic", "Hit-Scan", "Power Weapon" },
}

function RicochetRifle.FireClient(_player, _hand, camera, _mouseHit)
	return { Origin = camera.CFrame.Position, Direction = camera.CFrame.LookVector }
end

function RicochetRifle.FireServer(attacker, payload, onHitCallback)
	local currentPos = payload.Origin
	local currentDir = payload.Direction
	local maxBounces = 100
	local maxRange = 300

	-- We use a loop to instantly calculate the bounces
	for _ = 1, maxBounces do
		local rayResult = RaycastUtils.Raycast(currentPos, currentDir * maxRange, { attacker.Character })

		if rayResult then
			local hitModel = rayResult.Instance:FindFirstAncestorOfClass("Model")
			if hitModel and hitModel:FindFirstChild("Humanoid") then
				-- We hit a player! Check for headshot and deal damage.
				local isHeadshot = (rayResult.Instance.Name == "Head")
				local damage = isHeadshot and 75 or 35

				onHitCallback(rayResult, damage, isHeadshot)
				break -- Stop bouncing, bullet absorbed
			else
				-- We hit a wall! Calculate the math to reflect the bullet angle
				local normal = rayResult.Normal
				local reflectionDir = currentDir - (2 * currentDir:Dot(normal) * normal)

				-- Set up the next bounce
				currentDir = reflectionDir
				currentPos = rayResult.Position + (currentDir * 0.1) -- Push it slightly off the wall so it doesn't get stuck
			end
		else
			-- Bullet went into the sky and hit nothing
			break
		end
	end
end

return RicochetRifle

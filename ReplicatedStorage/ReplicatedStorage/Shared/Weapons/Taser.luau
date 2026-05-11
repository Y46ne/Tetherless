local Taser = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

Taser.Stats = {
	DisplayName = "Stasis Taser",
	FireRate = 0.8,
	Magazine = 6,
	Category = "Special",
	DualWieldable = true,
	Traits = { "One-Handed", "Semi-Automatic", "Hit-Scan", "Stun" },
}

function Taser.FireClient(_player, _hand, camera, _mouseHit)
	return { Origin = camera.CFrame.Position, Direction = camera.CFrame.LookVector }
end

function Taser.FireServer(attacker, payload, onHitCallback)
	local rayResult = RaycastUtils.Raycast(payload.Origin, payload.Direction * 150, { attacker.Character })

	if rayResult and rayResult.Instance then
		local model = rayResult.Instance:FindFirstAncestorOfClass("Model")
		local targetRoot = model and model:FindFirstChild("HumanoidRootPart")
		local targetChar = model

		if targetRoot and targetChar:FindFirstChild("Humanoid") then
			-- 1. Deal 5 damage
			onHitCallback(rayResult, 5, false)

			-- 2. Kill all momentum instantly
			targetRoot.AssemblyLinearVelocity = Vector3.new(0, -50, 0) -- Slams them into the ground

			-- 3. Freeze their inputs (Your MovementController already checks for this attribute!)
			targetChar:SetAttribute("IsFrozen", true)

			-- 4. Unfreeze after 1.5 seconds
			task.delay(1.5, function()
				if targetChar then
					targetChar:SetAttribute("IsFrozen", false)
				end
			end)
		end
	end
end

return Taser

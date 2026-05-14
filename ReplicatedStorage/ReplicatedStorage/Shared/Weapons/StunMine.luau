-- StunMine
-- One-handed placeable mine that stuns anyone who walks into its trigger radius.
-- Stun duration (2.5s) is longer than both Taser (1.5s) and StunGrenade (2.0s).
-- The mine is visible (yellow neon sphere) and must be manually placed on a surface.
-- Same placement pattern as ProximityMine.

local StunMine = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

StunMine.Stats = {
	DisplayName = "Stun Mine",
	FireRate = 0.8,
	Magazine = 3,
	Category = "Throwable",
	DualWieldable = true,
	Traits = { "One-Handed", "Stun", "Equipment", "Explosive" },
	Power = 0,
	HeadshotMultiplier = 1,
	MovementFactor = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	TriggerRadius = 8,
	StunDuration = 2.5,
	MineLifetime = 60, -- auto-destroys after 60 seconds if never triggered
}

function StunMine.FireClient(_player, _hand, camera, _mouseHit)
	return {
		Origin = camera.CFrame.Position,
		Direction = camera.CFrame.LookVector,
	}
end

function StunMine.FireServer(attacker, payload, _onHitCallback)
	local attackerChar = attacker.Character
	if not attackerChar then return end

	-- Place the mine at the first surface hit in front of the player
	local rayResult = RaycastUtils.Raycast(payload.Origin, payload.Direction.Unit * 20, { attackerChar })
	local placePos = rayResult and rayResult.Position or (payload.Origin + payload.Direction.Unit * 4)

	local mine = Instance.new("Part")
	mine.Name = "StunMine"
	mine.Size = Vector3.new(1.2, 0.4, 1.2)
	mine.Material = Enum.Material.Neon
	mine.Color = Color3.fromRGB(255, 220, 50)
	mine.Anchored = true
	mine.CanCollide = false
	mine.CanTouch = false
	mine.CanQuery = false
	mine.CFrame = CFrame.new(placePos)
	mine:SetAttribute("IsDroppedWeapon", false)
	mine.Parent = workspace

	local triggered = false

	-- Poll for nearby players every 0.1s — lightweight and reliable
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if triggered or not mine.Parent then
			if connection then connection:Disconnect() end
			return
		end

		local overlapParams = OverlapParams.new()
		overlapParams.FilterDescendantsInstances = { attackerChar, mine }
		overlapParams.FilterType = Enum.RaycastFilterType.Exclude

		local parts = workspace:GetPartBoundsInRadius(mine.Position, StunMine.Stats.TriggerRadius, overlapParams)
		for _, part in ipairs(parts) do
			local model = part:FindFirstAncestorOfClass("Model")
			local humanoid = model and model:FindFirstChild("Humanoid")
			local root = model and model:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health > 0 then
				triggered = true
				mine:Destroy()
				if connection then connection:Disconnect() end

				-- Stun all characters in the trigger radius
				local stunParams = OverlapParams.new()
				stunParams.FilterType = Enum.RaycastFilterType.Exclude
				local nearbyParts = workspace:GetPartBoundsInRadius(placePos, StunMine.Stats.TriggerRadius, stunParams)
				local stunned = {}
				for _, nearPart in ipairs(nearbyParts) do
					local nearModel = nearPart:FindFirstAncestorOfClass("Model")
					local nearHum = nearModel and nearModel:FindFirstChild("Humanoid")
					local nearRoot = nearModel and nearModel:FindFirstChild("HumanoidRootPart")
					if nearHum and nearRoot and nearHum.Health > 0 and not stunned[nearModel] then
						stunned[nearModel] = true
						nearRoot.AssemblyLinearVelocity = Vector3.new(0, -50, 0)
						nearModel:SetAttribute("IsFrozen", true)
						task.delay(StunMine.Stats.StunDuration, function()
							if nearModel and nearModel.Parent then
								nearModel:SetAttribute("IsFrozen", false)
							end
						end)
					end
				end
				return
			end
		end
	end)

	Debris:AddItem(mine, StunMine.Stats.MineLifetime)
end

return StunMine

-- StunGrenade
-- One-handed throwable that stuns everyone in a large radius (no damage).
-- Stun effect mirrors the Taser: sets IsFrozen=true for StunDuration seconds.
-- Larger blast radius than HandGrenade compensates for the zero lethality.

local StunGrenade = {}

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

StunGrenade.Stats = {
	DisplayName = "Stun Grenade",
	FireRate = 0.5,
	Magazine = 1,
	Category = "Throwable",
	DualWieldable = true,
	Traits = { "One-Handed", "Throwable", "Stun", "Explosive" },
	Power = 0, -- no damage
	HeadshotMultiplier = 1,
	MovementFactor = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	ProjectileSpeed = 95,
	ThrowUpwardBoost = 25,
	FuseTime = 2.5,
	BlastRadius = 20, -- larger than HandGrenade to compensate for no damage
	StunDuration = 2.0, -- slightly longer than Taser (1.5s)
}

local function detonate(origin, attacker, projectile)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = { attacker.Character, projectile }
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local parts = workspace:GetPartBoundsInRadius(origin, StunGrenade.Stats.BlastRadius, overlapParams)
	local hitModels = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		local root = model and model:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 and not hitModels[model] then
			hitModels[model] = true

			-- Kill momentum and freeze (same pattern as Taser)
			root.AssemblyLinearVelocity = Vector3.new(0, -50, 0)
			model:SetAttribute("IsFrozen", true)
			task.delay(StunGrenade.Stats.StunDuration, function()
				if model and model.Parent then
					model:SetAttribute("IsFrozen", false)
				end
			end)
		end
	end

	local explosion = Instance.new("Explosion")
	explosion.Position = origin
	explosion.BlastRadius = StunGrenade.Stats.BlastRadius
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
	Debris:AddItem(explosion, 2)
end

function StunGrenade.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	return {
		Origin = origin,
		Direction = (mouseHit.Position - origin).Unit,
	}
end

function StunGrenade.FireServer(attacker, payload, onHitCallback)
	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerChar or not attackerRoot then return end

	local origin = payload.Origin + payload.Direction.Unit * 2
	local velocity = payload.Direction.Unit * StunGrenade.Stats.ProjectileSpeed
		+ Vector3.new(0, StunGrenade.Stats.ThrowUpwardBoost, 0)

	local projectile = Instance.new("Part")
	projectile.Name = "StunGrenade"
	projectile.Size = Vector3.new(0.7, 0.7, 0.7)
	projectile.Shape = Enum.PartType.Ball
	projectile.Material = Enum.Material.Neon
	projectile.Color = Color3.fromRGB(255, 220, 50)
	projectile.Anchored = true
	projectile.CanCollide = false
	projectile.CanTouch = false
	projectile.CanQuery = false
	projectile.CFrame = CFrame.new(origin)
	projectile.Parent = workspace

	local currentPos = origin
	local gravity = Vector3.new(0, -workspace.Gravity, 0)
	local detonated = false
	local startTime = os.clock()

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if detonated or not projectile.Parent then
			if connection then connection:Disconnect() end
			return
		end

		if os.clock() - startTime >= StunGrenade.Stats.FuseTime then
			detonated = true
			local pos = currentPos
			projectile:Destroy()
			detonate(pos, attacker, projectile)
			if connection then connection:Disconnect() end
			return
		end

		velocity = velocity + gravity * dt
		local nextPos = currentPos + velocity * dt
		local rayResult = RaycastUtils.Raycast(currentPos, nextPos - currentPos, { attackerChar, projectile })
		if rayResult then
			detonated = true
			currentPos = rayResult.Position
			projectile:Destroy()
			detonate(currentPos, attacker, projectile)
			if connection then connection:Disconnect() end
			return
		end

		currentPos = nextPos
		projectile.CFrame = CFrame.new(currentPos)
	end)

	-- onHitCallback not called — StunGrenade deals no damage, no hitmarker
	Debris:AddItem(projectile, StunGrenade.Stats.FuseTime + 1)
end

return StunGrenade

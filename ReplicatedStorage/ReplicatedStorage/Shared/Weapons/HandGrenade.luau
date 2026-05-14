-- HandGrenade
-- One-handed throwable instakill. 250 damage to anyone in blast radius.
-- Explosion damage uses GetPartBoundsInRadius (no line-of-sight check),
-- so it kills through walls just like the original.
-- Magazine = 1 so it auto-drops on fire (WeaponController handles that).

local HandGrenade = {}

local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

HandGrenade.Stats = {
	DisplayName = "Hand Grenade",
	FireRate = 0.5,
	Magazine = 1,
	Category = "Throwable",
	DualWieldable = true,
	Traits = { "One-Handed", "Throwable", "Explosive", "Insta-gib" },
	Power = 250,
	HeadshotMultiplier = 1,
	MovementFactor = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	MaxWallJumps = 1,
	ProjectileSpeed = 100,
	ThrowUpwardBoost = 25,
	FuseTime = 3.0,
	BlastRadius = 14,
}

local function detonate(origin, attacker, onHitCallback, projectile)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = { projectile }
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	-- GetPartBoundsInRadius ignores walls — explosion reaches through geometry
	local parts = workspace:GetPartBoundsInRadius(origin, HandGrenade.Stats.BlastRadius, overlapParams)
	local hitModels = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		local root = model and model:FindFirstChild("HumanoidRootPart")
		if humanoid and root and humanoid.Health > 0 and not hitModels[model] then
			hitModels[model] = true
			-- Instakill: full 250 damage regardless of distance within radius
			onHitCallback({ Instance = root, Position = origin }, HandGrenade.Stats.Power, false)
		end
	end

	local explosion = Instance.new("Explosion")
	explosion.Position = origin
	explosion.BlastRadius = HandGrenade.Stats.BlastRadius
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
	Debris:AddItem(explosion, 2)
end

function HandGrenade.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	return {
		Origin = origin,
		Direction = (mouseHit.Position - origin).Unit,
	}
end

function HandGrenade.FireServer(attacker, payload, onHitCallback)
	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerChar or not attackerRoot then return end

	local origin = payload.Origin + payload.Direction.Unit * 2
	local velocity = payload.Direction.Unit * HandGrenade.Stats.ProjectileSpeed
		+ Vector3.new(0, HandGrenade.Stats.ThrowUpwardBoost, 0)

	local projectile = Instance.new("Part")
	projectile.Name = "HandGrenade"
	projectile.Size = Vector3.new(0.8, 0.8, 0.8)
	projectile.Shape = Enum.PartType.Ball
	projectile.Material = Enum.Material.SmoothPlastic
	projectile.Color = Color3.fromRGB(80, 100, 60)
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

		if os.clock() - startTime >= HandGrenade.Stats.FuseTime then
			detonated = true
			local pos = currentPos
			projectile:Destroy()
			detonate(pos, attacker, onHitCallback, projectile)
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
			detonate(currentPos, attacker, onHitCallback, projectile)
			if connection then connection:Disconnect() end
			return
		end

		currentPos = nextPos
		projectile.CFrame = CFrame.new(currentPos)
	end)

	Debris:AddItem(projectile, HandGrenade.Stats.FuseTime + 1)
end

return HandGrenade

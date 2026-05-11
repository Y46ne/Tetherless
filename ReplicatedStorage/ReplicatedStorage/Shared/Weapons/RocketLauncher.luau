local RocketLauncher = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

RocketLauncher.Stats = {
	["Damage"] = 2500,
	["Headshot Multiplier"] = 2,
	["Capacity"] = 4,
	["Fire-Rate"] = 0.4,
	["Movement Factor"] = 1,
	["Max Wall Jumps"] = 1,
	["Jump Factor"] = 1,
	["Wall Jump Factor"] = 1,
	Traits = { "Two-Handed", "Semi-Automatic", "Explosive", "Projectile", "Power Weapon", "Special" },
	Power = 2500,
	HeadshotMultiplier = 2,
	Magazine = 4,
	FireRate = 0.4,
	MovementFactor = 1,
	MaxWallJumps = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	DualWieldable = false,
	Category = "Heavy",
	ProjectileSpeed = 220,
	ExplosionRadius = 35,
	RocketJumpForce = 200,
	DirectImpactDamage = 100,
	ExplosionDamage = 75,
	DirectImpactKnockback = 150, -- Changed from 1 billion to reasonable value!
	ExplosionKnockback = 100,
}

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	elseif value > maxValue then
		return maxValue
	end

	return value
end

local function damagePlayer(character, damageAmount)
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid:TakeDamage(damageAmount)
	end
end

local function applyKnockback(origin, targetRoot, targetHum, force)
	if not targetRoot or not targetHum then return end

	-- CRITICAL: Change humanoid state to prevent ground friction from canceling knockback
	targetHum:ChangeState(Enum.HumanoidStateType.Freefall)
	targetHum:ChangeState(Enum.HumanoidStateType.Jumping)

	local pushDirection = (targetRoot.Position - origin)
	if pushDirection.Magnitude < 0.1 then
		pushDirection = Vector3.new(0, 1, 0)
	end

	local impulse = (pushDirection.Unit + Vector3.new(0, 0.3, 0)).Unit * force * targetRoot.AssemblyMass
	targetRoot:ApplyImpulse(impulse)

	-- Also apply velocity for extra push (some games use this instead of impulse)
	local velocityPush = (pushDirection.Unit + Vector3.new(0, 0.3, 0)).Unit * force
	targetRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity + velocityPush
end

local function applyExplosionDamage(origin, attacker, onHitCallback)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = {}
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local parts = workspace:GetPartBoundsInRadius(origin, RocketLauncher.Stats.ExplosionRadius, overlapParams)
	local hitModels = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		local root = model and model:FindFirstChild("HumanoidRootPart")

		if model and humanoid and root and humanoid.Health > 0 and not hitModels[model] then
			hitModels[model] = true

			if model == attacker.Character then
				-- Rocket jump: knockback the attacker (shooter)
				applyKnockback(origin, root, humanoid, RocketLauncher.Stats.RocketJumpForce)
			else
				-- Enemy: damage + knockback
				damagePlayer(model, RocketLauncher.Stats.ExplosionDamage)
				applyKnockback(origin, root, humanoid, RocketLauncher.Stats.ExplosionKnockback)
			end
		end
	end
end

function RocketLauncher.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	local direction = (mouseHit.Position - origin).Unit

	return {
		Origin = origin,
		Direction = direction,
	}
end

function RocketLauncher.FireServer(attacker, payload, onHitCallback)
	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerChar or not attackerRoot then
		return
	end

	local origin = payload.Origin
	local direction = payload.Direction.Unit
	local projectile = Instance.new("Part")
	projectile.Name = "RocketProjectile"
	projectile.Size = Vector3.new(0.8, 0.8, 2.4)
	projectile.Material = Enum.Material.Neon
	projectile.Color = Color3.fromRGB(255, 160, 40)
	projectile.CanCollide = false
	projectile.CanTouch = false
	projectile.CanQuery = false
	projectile.Anchored = true
	projectile.CFrame = CFrame.lookAt(origin + direction * 2, origin + direction * 4)
	projectile.Parent = workspace

	local currentPos = projectile.Position
	local velocity = direction * RocketLauncher.Stats.ProjectileSpeed
	local alive = true

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not alive or not projectile.Parent then
			if connection then
				connection:Disconnect()
			end
			return
		end

		local nextPos = currentPos + (velocity * dt)
		local rayResult = RaycastUtils.Raycast(currentPos, nextPos - currentPos, { projectile })
		if rayResult then
			alive = false
			projectile:Destroy()

			-- Check what was hit
			local hitPart = rayResult.Instance
			local hitModel = hitPart:FindFirstAncestorOfClass("Model")
			local hitHumanoid = hitModel and hitModel:FindFirstChild("Humanoid")
			local hitRoot = hitModel and hitModel:FindFirstChild("HumanoidRootPart")

			-- Direct impact damage and knockback (but NOT to the attacker)
			if hitModel and hitHumanoid and hitRoot and hitModel ~= attackerChar then
				damagePlayer(hitModel, RocketLauncher.Stats.DirectImpactDamage)
				applyKnockback(rayResult.Position, hitRoot, hitHumanoid, RocketLauncher.Stats.DirectImpactKnockback)
			end

			-- Explosion damage and knockback (including rocket jump for attacker)
			applyExplosionDamage(rayResult.Position, attacker, onHitCallback)

			-- Create explosion effect
			local explosion = Instance.new("Explosion")
			explosion.Position = rayResult.Position
			explosion.BlastRadius = RocketLauncher.Stats.ExplosionRadius
			explosion.BlastPressure = 0
			explosion.DestroyJointRadiusPercent = 0
			explosion.Parent = workspace

			Debris:AddItem(explosion, 2)
			return
		end

		currentPos = nextPos
		projectile.CFrame = CFrame.lookAt(currentPos, currentPos + velocity.Unit)
	end)

	Debris:AddItem(projectile, 4)
end

return RocketLauncher
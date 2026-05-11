local BombLauncher = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

BombLauncher.Stats = {
	["Damage"] = 120,
	["Headshot Multiplier"] = 1,
	["Capacity"] = 5,
	["Fire-Rate"] = 0.55,
	["Movement Factor"] = 1,
	["Max Wall Jumps"] = 1,
	["Jump Factor"] = 1,
	["Wall Jump Factor"] = 1,
	Traits = { "Two-Handed", "Semi-Automatic", "Projectile", "Explosive", "Power Weapon", "Special" },
	Power = 120,
	Magazine = 5,
	FireRate = 0.55,
	MovementFactor = 1,
	MaxWallJumps = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	DualWieldable = false,
	Category = "Explosive",
	ProjectileSpeed = 150,
	FuseTime = 3,
	BlastRadius = 32,
	DirectImpactDamage = 60,
	ExplosionDamage = 50,
	DirectImpactKnockback = 120,
	ExplosionKnockback = 100,
	BombJumpForce = 200,
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

	local impulse = (pushDirection.Unit + Vector3.new(0, 0.35, 0)).Unit * force * targetRoot.AssemblyMass
	targetRoot:ApplyImpulse(impulse)

	-- Also apply velocity for extra push
	local velocityPush = (pushDirection.Unit + Vector3.new(0, 0.35, 0)).Unit * force
	targetRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity + velocityPush
end

local function detonate(origin, attacker, onHitCallback, projectile)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = { projectile }
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local parts = workspace:GetPartBoundsInRadius(origin, BombLauncher.Stats.BlastRadius, overlapParams)
	local hitModels = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		local root = model and model:FindFirstChild("HumanoidRootPart")
		if model and humanoid and root and humanoid.Health > 0 and not hitModels[model] then
			hitModels[model] = true

			if model == attacker.Character then
				-- Bomb jump: knockback the attacker (shooter)
				applyKnockback(origin, root, humanoid, BombLauncher.Stats.BombJumpForce)
			else
				-- Enemy: damage + knockback
				damagePlayer(model, BombLauncher.Stats.ExplosionDamage)
				applyKnockback(origin, root, humanoid, BombLauncher.Stats.ExplosionKnockback)
			end
		end
	end

	local explosion = Instance.new("Explosion")
	explosion.Position = origin
	explosion.BlastRadius = BombLauncher.Stats.BlastRadius
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
	Debris:AddItem(explosion, 2)
end

function BombLauncher.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	local direction = (mouseHit.Position - origin).Unit

	return {
		Origin = origin,
		Direction = direction,
	}
end

function BombLauncher.FireServer(attacker, payload, onHitCallback)
	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerChar or not attackerRoot then
		return
	end

	local origin = payload.Origin + (payload.Direction.Unit * 2)
	local velocity = (payload.Direction.Unit * BombLauncher.Stats.ProjectileSpeed) + Vector3.new(0, 40, 0)
	local projectile = Instance.new("Part")
	projectile.Name = "BombProjectile"
	projectile.Size = Vector3.new(1.2, 1.2, 1.2)
	projectile.Shape = Enum.PartType.Ball
	projectile.Material = Enum.Material.Neon
	projectile.Color = Color3.fromRGB(255, 210, 50)
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
			if connection then
				connection:Disconnect()
			end
			return
		end

		if os.clock() - startTime >= BombLauncher.Stats.FuseTime then
			detonated = true
			projectile:Destroy()
			detonate(currentPos, attacker, onHitCallback, projectile)
			if connection then
				connection:Disconnect()
			end
			return
		end

		velocity = velocity + (gravity * dt)
		local nextPos = currentPos + (velocity * dt)
		local rayResult = RaycastUtils.Raycast(currentPos, nextPos - currentPos, { projectile })
		if rayResult then
			detonated = true
			currentPos = rayResult.Position

			-- Check what was hit
			local hitPart = rayResult.Instance
			local hitModel = hitPart:FindFirstAncestorOfClass("Model")
			local hitHumanoid = hitModel and hitModel:FindFirstChild("Humanoid")
			local hitRoot = hitModel and hitModel:FindFirstChild("HumanoidRootPart")

			-- Direct impact damage and knockback (but NOT to the attacker)
			if hitModel and hitHumanoid and hitRoot and hitModel ~= attackerChar then
				damagePlayer(hitModel, BombLauncher.Stats.DirectImpactDamage)
				applyKnockback(currentPos, hitRoot, hitHumanoid, BombLauncher.Stats.DirectImpactKnockback)
			end

			projectile:Destroy()
			detonate(currentPos, attacker, onHitCallback, projectile)
			if connection then
				connection:Disconnect()
			end
			return
		end

		currentPos = nextPos
		projectile.CFrame = CFrame.lookAt(currentPos, currentPos + velocity.Unit)
	end)

	Debris:AddItem(projectile, BombLauncher.Stats.FuseTime + 2)
end

return BombLauncher
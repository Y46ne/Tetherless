local Bomb = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

Bomb.Stats = {
	["Damage"] = 90,
	["Headshot Multiplier"] = 1,
	["Capacity"] = 3,
	["Fire-Rate"] = 0.65,
	["Movement Factor"] = 1,
	["Max Wall Jumps"] = 1,
	["Jump Factor"] = 1,
	["Wall Jump Factor"] = 1,
	Traits = { "One-Handed", "Throwable", "Explosive", "Special" },
	Power = 90,
	Magazine = 3,
	FireRate = 0.65,
	MovementFactor = 1,
	MaxWallJumps = 1,
	JumpFactor = 1,
	WallJumpFactor = 1,
	DualWieldable = true,
	Category = "Throwable",
	ProjectileSpeed = 110,
	FuseTime = 2.5,
	BlastRadius = 12,
	ThrowUpwardBoost = 30,
	Knockback = 75,
	BombJumpForce = 110, -- For when you throw at your own feet
}

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	elseif value > maxValue then
		return maxValue
	end

	return value
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

	local impulse = (pushDirection.Unit + Vector3.new(0, 0.25, 0)).Unit * force * targetRoot.AssemblyMass
	targetRoot:ApplyImpulse(impulse)

	-- Also apply velocity for extra push
	local velocityPush = (pushDirection.Unit + Vector3.new(0, 0.25, 0)).Unit * force
	targetRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity + velocityPush
end

local function detonate(origin, attacker, onHitCallback, projectile)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = { attacker.Character, projectile }
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	local parts = workspace:GetPartBoundsInRadius(origin, Bomb.Stats.BlastRadius, overlapParams)
	local hitModels = {}

	for _, part in ipairs(parts) do
		local model = part:FindFirstAncestorOfClass("Model")
		local humanoid = model and model:FindFirstChild("Humanoid")
		local root = model and model:FindFirstChild("HumanoidRootPart")
		if model and humanoid and root and humanoid.Health > 0 and not hitModels[model] then
			hitModels[model] = true

			if model == attacker.Character then
				-- Bomb jump: knockback the thrower
				applyKnockback(origin, root, humanoid, Bomb.Stats.BombJumpForce)
			else
				-- Enemy: damage + knockback
				local distance = (root.Position - origin).Magnitude
				local falloff = 1 - clamp(distance / Bomb.Stats.BlastRadius, 0, 1)
				local damage = math.max(15, Bomb.Stats.Power * falloff)
				humanoid:TakeDamage(damage)
				applyKnockback(origin, root, humanoid, Bomb.Stats.Knockback)
				onHitCallback({ Instance = root, Position = origin }, damage, false)
			end
		end
	end

	local explosion = Instance.new("Explosion")
	explosion.Position = origin
	explosion.BlastRadius = Bomb.Stats.BlastRadius
	explosion.BlastPressure = 0
	explosion.DestroyJointRadiusPercent = 0
	explosion.Parent = workspace
	Debris:AddItem(explosion, 2)
end

function Bomb.FireClient(_player, _hand, camera, mouseHit)
	local origin = camera.CFrame.Position
	local direction = (mouseHit.Position - origin).Unit

	return {
		Origin = origin,
		Direction = direction,
	}
end

function Bomb.FireServer(attacker, payload, onHitCallback)
	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	if not attackerChar or not attackerRoot then
		return
	end

	local origin = payload.Origin + (payload.Direction.Unit * 2)
	local velocity = (payload.Direction.Unit * Bomb.Stats.ProjectileSpeed)
		+ Vector3.new(0, Bomb.Stats.ThrowUpwardBoost, 0)
	local projectile = Instance.new("Part")
	projectile.Name = "ThrowableBomb"
	projectile.Size = Vector3.new(1, 1, 1)
	projectile.Shape = Enum.PartType.Ball
	projectile.Material = Enum.Material.SmoothPlastic
	projectile.Color = Color3.fromRGB(80, 80, 80)
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

		if os.clock() - startTime >= Bomb.Stats.FuseTime then
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
		local rayResult = RaycastUtils.Raycast(currentPos, nextPos - currentPos, { attackerChar, projectile })
		if rayResult then
			detonated = true
			currentPos = rayResult.Position
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

	Debris:AddItem(projectile, Bomb.Stats.FuseTime + 2)
end

return Bomb

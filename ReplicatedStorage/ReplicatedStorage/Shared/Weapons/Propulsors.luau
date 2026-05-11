local Propulsor = {}

-- 1. THE STATS
Propulsor.Stats = {
	DisplayName = "Shockwave Propulsor",
	FireRate = 1.0,
	Magazine = 5,
	Category = "Special",
	DualWieldable = true,
	HasTracer = false,
	Traits = { "One-Handed", "Special", "Power Weapon" },
}

local function clamp(value, minValue, maxValue)
	if value < minValue then
		return minValue
	elseif value > maxValue then
		return maxValue
	end

	return value
end

-- 2. CLIENT LOGIC
function Propulsor.FireClient(_player, _hand, camera, _mouseHit)
	local origin = camera.CFrame.Position
	local direction = camera.CFrame.LookVector

	-- ==========================================
	-- EFFECT 1: SHOOTER RECOIL (ON CLIENT)
	-- ==========================================
	local char = _player.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChild("Humanoid")

	if root and hum then
		-- Jump to prevent ground friction
		if hum.FloorMaterial ~= Enum.Material.Air then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end

		local recoilVelocity = (-direction * 50)
		root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + recoilVelocity
	end

	return {
		Origin = origin,
		Direction = direction,
	}
end

-- 3. SERVER LOGIC (The Custom Physics)
function Propulsor.FireServer(attacker, payload, onHitCallback)
	local origin = payload.Origin
	local direction = payload.Direction
	local maxRange = 55
	local dualWieldMultiplier = 1

	local attackerChar = attacker.Character
	if attackerChar then
		local rightWeapon = attackerChar:GetAttribute("RightWeapon")
		local leftWeapon = attackerChar:GetAttribute("LeftWeapon")
		if rightWeapon == "Propulsors" and leftWeapon == "Propulsors" then
			dualWieldMultiplier = 1.9
		end
	end

	local function pushCharacter(model, targetRoot, targetHum, distance)
		if not targetRoot or not targetHum or targetHum.Health <= 0 then
			return false
		end

		local awayVector = targetRoot.Position - origin
		if awayVector.Magnitude < 0.1 then
			awayVector = direction
		end

		local horizontalPush = Vector3.new(awayVector.X, 0, awayVector.Z)
		if horizontalPush.Magnitude < 0.1 then
			horizontalPush = direction
		end

		local normalized = horizontalPush.Unit
		local distanceFalloff = clamp(1 - (distance / maxRange), 0.15, 1)
		local pushStrength = 120 * distanceFalloff * dualWieldMultiplier
		local upwardStrength = 25 * dualWieldMultiplier

		-- CRITICAL: Change humanoid state FIRST before applying impulse
		targetHum:ChangeState(Enum.HumanoidStateType.Freefall)
		task.wait(0.01) -- Small delay to ensure state change takes effect
		targetHum:ChangeState(Enum.HumanoidStateType.Jumping)

		local impulseDirection = (normalized + Vector3.new(0, 0.35, 0)).Unit

		-- Apply both impulse and velocity for stronger effect
		targetRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity
			+ (impulseDirection * pushStrength)
			+ Vector3.new(0, upwardStrength, 0)
		targetRoot:ApplyImpulse(impulseDirection * (pushStrength * targetRoot.AssemblyMass))

		if model then
			model:SetAttribute("LastPropulsedAt", os.clock())
		end

		return true
	end

	-- ==========================================
	-- EFFECT 2: THE CONE BLAST
	-- ==========================================
	local overlapParams = OverlapParams.new()
	overlapParams.FilterDescendantsInstances = { attackerChar }
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude

	-- Grab everything in a large radius around the player
	local partsInRadius = workspace:GetPartBoundsInRadius(origin, maxRange, overlapParams)
	local modelsHit = {}

	for _, hitPart in ipairs(partsInRadius) do
		local model = hitPart:FindFirstAncestorOfClass("Model")

		if model and not modelsHit[model] then
			local targetRoot = model:FindFirstChild("HumanoidRootPart")
			local targetHum = model:FindFirstChild("Humanoid")

			if targetRoot and targetHum and targetHum.Health > 0 then
				local toTarget = targetRoot.Position - origin
				local distance = toTarget.Magnitude
				if distance < 0.1 then
					distance = 0.1 -- Prevent math errors if they are inside you
				end
				local dirToTarget = toTarget.Unit

				local aimAlignment = direction:Dot(dirToTarget)

				if aimAlignment > 0.2 then
					modelsHit[model] = true
					pushCharacter(model, targetRoot, targetHum, distance)

					-- Register the hitmarker
					local fakeRayResult = { Instance = targetRoot, Position = targetRoot.Position }
					onHitCallback(fakeRayResult, 0, false)
				end
			end
		end
	end
end

return Propulsor
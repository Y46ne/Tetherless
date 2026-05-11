local Harpoon = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

Harpoon.Stats = {
	DisplayName = "Grapple Harpoon",
	FireRate = 0.8,
	Magazine = 1,
	Category = "Special",
	DualWieldable = true,
	Traits = { "One-Handed", "Projectile", "Special", "Grapple" },
	GrappleRange = 300,
	WallPullForce = 45,
	PlayerYankForce = 60,
	ContinuousPullForce = 20,
	GrappleDuration = 5,
	GrappleDamage = 25,
}

-- Track active grapples per player using UserId
local activeGrapples = {}

local function createHarpoonLine(startPos, endPos)
	local distance = (endPos - startPos).Magnitude
	local line = Instance.new("Part")
	line.Name = "HarpoonLine"
	line.Size = Vector3.new(0.1, 0.1, distance)
	line.Material = Enum.Material.Neon
	line.Color = Color3.fromRGB(100, 200, 255)
	line.CanCollide = false
	line.CanTouch = false
	line.CanQuery = false
	line.Anchored = true
	line.CFrame = CFrame.lookAt(startPos, endPos) * CFrame.new(0, 0, -distance / 2)
	line.TopSurface = Enum.SurfaceType.Smooth
	line.BottomSurface = Enum.SurfaceType.Smooth
	line.Parent = workspace

	return line
end

local function stopGrapple(playerId)
	if activeGrapples[playerId] then
		local grappleData = activeGrapples[playerId]
		grappleData.active = false

		-- Destroy line
		if grappleData.line and grappleData.line.Parent then
			grappleData.line:Destroy()
		end

		-- Disconnect the loop
		if grappleData.connection then
			grappleData.connection:Disconnect()
		end

		-- Reduce the carry-over momentum so stopping feels immediate
		if grappleData.root and grappleData.root.Parent then
			grappleData.root.AssemblyLinearVelocity = grappleData.root.AssemblyLinearVelocity * 0.15
		end

		print("🪝 Grapple stopped for player")
		activeGrapples[playerId] = nil
	end
end

function Harpoon.FireClient(_player, _hand, camera, _mouseHit)
	return { Origin = camera.CFrame.Position, Direction = camera.CFrame.LookVector }
end

function Harpoon.FireServer(attacker, payload, onHitCallback)
	local playerId = attacker.UserId
	if payload and payload.Action == "StopGrapple" then
		stopGrapple(playerId)
		return
	end

	local attackerChar = attacker.Character
	local attackerRoot = attackerChar and attackerChar:FindFirstChild("HumanoidRootPart")
	local attackerHum = attackerChar and attackerChar:FindFirstChild("Humanoid")

	if not attackerChar or not attackerRoot or not attackerHum then
		return
	end

	-- If player already grappling, stop the old one
	if activeGrapples[playerId] then
		stopGrapple(playerId)
	end

	local origin = payload.Origin
	local direction = payload.Direction.Unit
	local rayResult = RaycastUtils.Raycast(origin, direction * Harpoon.Stats.GrappleRange, { attackerChar })

	if rayResult then
		local hitModel = rayResult.Instance:FindFirstAncestorOfClass("Model")
		local targetRoot = hitModel and hitModel:FindFirstChild("HumanoidRootPart")
		local targetHum = hitModel and hitModel:FindFirstChild("Humanoid")

		-- ====================================
		-- HIT A PLAYER! Pull them toward you
		-- ====================================
		if targetRoot and targetHum and targetHum.Health > 0 then
			onHitCallback(rayResult, Harpoon.Stats.GrappleDamage, false)

			-- Change their state
			targetHum:ChangeState(Enum.HumanoidStateType.Freefall)
			targetHum:ChangeState(Enum.HumanoidStateType.Jumping)

			-- Initial yank toward attacker
			local yankDirection = (attackerRoot.Position - targetRoot.Position).Unit
			targetRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity
				+ (yankDirection * Harpoon.Stats.PlayerYankForce)
				+ Vector3.new(0, 20, 0)
			targetRoot:ApplyImpulse(
				(yankDirection + Vector3.new(0, 0.3, 0)).Unit
					* (Harpoon.Stats.PlayerYankForce * targetRoot.AssemblyMass)
			)

			-- ====================================
			-- HIT A WALL! Pull yourself to it
			-- ====================================
		else
			-- Store the STATIC grapple point (it never moves!)
			local grappleData = {
				attacker = attacker,
				root = attackerRoot,
				targetPos = rayResult.Position, -- STATIC - never changes
				startTime = os.clock(),
				startPos = attackerRoot.Position,
				line = createHarpoonLine(attackerRoot.Position, rayResult.Position),
				active = true,
			}

			activeGrapples[playerId] = grappleData
			print("🪝 Grapple started! Point at: " .. tostring(grappleData.targetPos))

			-- Continuous grapple loop
			local connection
			connection = RunService.Heartbeat:Connect(function(dt)
				-- Check if grapple should end
				if
					not grappleData.active
					or not grappleData.line.Parent
					or os.clock() - grappleData.startTime > Harpoon.Stats.GrappleDuration
					or not attackerRoot.Parent
				then
					if grappleData.line then
						grappleData.line:Destroy()
					end
					activeGrapples[playerId] = nil
					if connection then
						connection:Disconnect()
					end
					return
				end

				-- Update line from player to STATIC grapple point
				local distance = (grappleData.targetPos - attackerRoot.Position).Magnitude
				local midPoint = (attackerRoot.Position + grappleData.targetPos) / 2
				grappleData.line.Size = Vector3.new(0.1, 0.1, distance)
				grappleData.line.CFrame = CFrame.lookAt(midPoint, grappleData.targetPos)

				-- Pull the attacker toward the grapple point
				local pullDirection = (grappleData.targetPos - attackerRoot.Position).Unit
				local distanceToTarget = (grappleData.targetPos - attackerRoot.Position).Magnitude

				-- Stronger pull as you get closer
				local pullForce = math.min(
					Harpoon.Stats.ContinuousPullForce * (1 + (1 - math.clamp(distanceToTarget / 300, 0, 1))),
					Harpoon.Stats.ContinuousPullForce * 2
				)

				attackerRoot.AssemblyLinearVelocity = attackerRoot.AssemblyLinearVelocity
					+ (pullDirection * pullForce)
					+ Vector3.new(0, 15, 0)
				attackerRoot:ApplyImpulse(
					(pullDirection + Vector3.new(0, 0.2, 0)).Unit * (pullForce * attackerRoot.AssemblyMass * 0.5)
				)
			end)

			grappleData.connection = connection

			-- Auto-cleanup after max duration
			Debris:AddItem(grappleData.line, Harpoon.Stats.GrappleDuration + 1)
		end
	end
end

-- Function to stop grapple (called when player releases button)
function Harpoon.StopGrapple(attacker)
	local playerId = attacker.UserId
	print("🪝 StopGrapple called for player: " .. attacker.Name)
	stopGrapple(playerId)
end

return Harpoon

local MovementController = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local configsFolder = sharedFolder:WaitForChild("Configs")
local utilsFolder = sharedFolder:WaitForChild("Utils")
local config = require(configsFolder:WaitForChild("MovementConfig"))
local RaycastUtils = require(ReplicatedStorage.Shared.Utils.RaycastUtils)

local animationModule = require(script.Parent:WaitForChild("AnimationController"))
local animationStorageModule = require(script.Parent:WaitForChild("AnimationsStorage"))
local InputController = require(script.Parent:WaitForChild("InputController"))

-----------------------------
-- STATE VARIABLES --
-----------------------------
local states = {
	isSprinting = false,
	isSliding = false,
	isWallRunning = false,
	activeWallRunAnim = nil, -- NEW: Tracks which wall run animation is currently playing
}

local slideConnection = nil
local slideStartTime = 0
local slideDirection = Vector3.new()

-- Momentum Variables
local lastLandTime = 0
local currentSpeedBoost = 0
local jumpDebounce = false
local currentVelocity = Vector3.new()
local targetSpeed = 0

-- Wall Run Variables
local currentWallNormal = nil
local wallRunDebounce = 0

-- Camera Tilt Variable
local currentCameraTilt = 0

-- Camera Recoil Tracking
local cameraRecoilRotation = Vector3.new()
local cameraRecoilRecoveryTime = 0

-----------------------------
-- HELPER FUNCTIONS --
-----------------------------
local function getCharVars()
	local char = player.Character
	if not char then
		return nil, nil, nil, nil
	end
	local hum = char:FindFirstChild("Humanoid")
	local root = char:FindFirstChild("HumanoidRootPart")
	local anim = hum and hum:FindFirstChild("Animator")
	return char, hum, root, anim
end

-----------------------------
-- SLIDE LOGIC --
-----------------------------
local function endSlide()
	if not states.isSliding then
		return
	end
	local _, hum, _, anim = getCharVars()

	states.isSliding = false
	if anim then
		animationModule.stop(anim, animationStorageModule["Sliding"].id)
	end

	if slideConnection then
		slideConnection:Disconnect()
		slideConnection = nil
	end

	if hum then
		TweenService:Create(
			hum,
			TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{ CameraOffset = Vector3.new(0, 0, 0) }
		):Play()
	end
end

local function startSlide()
	local _, hum, root, anim = getCharVars()
	if not hum or not root then
		return
	end

	if states.isSliding or hum.MoveDirection.Magnitude == 0 then
		return
	end
	if hum.FloorMaterial == Enum.Material.Air then
		return
	end

	states.isSliding = true
	slideStartTime = tick()
	slideDirection = root.CFrame.LookVector

	if anim then
		animationModule.play(anim, animationStorageModule["Sliding"].id, Enum.AnimationPriority.Action)
	end
	TweenService:Create(
		hum,
		TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CameraOffset = config.CameraDip }
	):Play()

	slideConnection = RunService.Heartbeat:Connect(function()
		local timeElapsed = tick() - slideStartTime

		if timeElapsed >= config.SlideDuration then
			endSlide()
		else
			local progress = timeElapsed / config.SlideDuration
			local decayMultiplier = config.SlideMomentumDecay ^ progress
			local currentSpeed = config.SlidePower * decayMultiplier

			root.AssemblyLinearVelocity = Vector3.new(
				slideDirection.X * currentSpeed,
				root.AssemblyLinearVelocity.Y,
				slideDirection.Z * currentSpeed
			)
		end
	end)
end

-----------------------------
-- INITIALIZATION --
-----------------------------
function MovementController.Init()
	print("MovementController: Initializing...")

	-- Get InputController events
	local inputEvents = InputController.GetEvents()

	inputEvents.SprintToggle:Connect(function()
		local char = player.Character
		if char and char:GetAttribute("IsFrozen") then
			return
		end
		states.isSprinting = not states.isSprinting
	end)

	inputEvents.SlidePressed:Connect(function()
		local char = player.Character
		if char and char:GetAttribute("IsFrozen") then
			return
		end
		startSlide()
	end)

	inputEvents.SlideReleased:Connect(function()
		endSlide()
	end)

	inputEvents.JumpPressed:Connect(function()
		local char = player.Character
		if char and char:GetAttribute("IsFrozen") then
			return
		end

		local _, hum, root, anim = getCharVars()
		if not hum or not root then
			return
		end

		-- Check if within coyote time (can jump shortly after leaving ground)
		local canJump = (hum.FloorMaterial ~= Enum.Material.Air) or (tick() - lastLandTime < config.CoyoteTime)

		if states.isWallRunning and currentWallNormal then
			-- ==========================================
			-- WALL JUMP
			-- ==========================================
			if anim and states.activeWallRunAnim then
				animationModule.stop(anim, animationStorageModule[states.activeWallRunAnim].id)
				states.activeWallRunAnim = nil
			end

			states.isWallRunning = false
			wallRunDebounce = tick() + 0.2

			local jumpVel = (currentWallNormal * config.WallJumpOutwardBoost)
				+ Vector3.new(0, config.WallJumpUpwardBoost, 0)
			local lookDir = root.CFrame.LookVector
			local forwardVel = Vector3.new(lookDir.X, 0, lookDir.Z).Unit * (currentSpeedBoost + 20)

			root.AssemblyLinearVelocity = jumpVel + forwardVel
			currentSpeedBoost = math.clamp(currentSpeedBoost + 15, 0, config.MaxBhopBoost)
		elseif canJump then
			-- ==========================================
			-- NORMAL JUMP WITH COYOTE TIME
			-- ==========================================
			if hum then
				-- `hum` is already the Humanoid from getCharVars()
				if hum.SetStateEnabled then
					hum:SetStateEnabled(Enum.HumanoidStateType.Climbing, false)
				end
				if hum.ChangeState then
					hum:ChangeState(Enum.HumanoidStateType.Jumping)
				end
			end
			lastLandTime = 0 -- Consume coyote time
		end
	end)

	local function setupCharacter(char)
		states.isSprinting = false
		states.isSliding = false
		states.isWallRunning = false
		states.activeWallRunAnim = nil -- Wipe anim memory

		if slideConnection then
			slideConnection:Disconnect()
			slideConnection = nil
		end

		currentSpeedBoost = 0
		lastLandTime = tick()
		jumpDebounce = false
		currentWallNormal = nil
		currentCameraTilt = 0

		char:SetAttribute("IsFrozen", false)

		local hum = char:WaitForChild("Humanoid")

		hum.StateChanged:Connect(function(oldState, newState)
			local _, _, root = getCharVars()
			if not root then
				return
			end

			if newState == Enum.HumanoidStateType.Landed then
				lastLandTime = tick()
				jumpDebounce = false
				states.isWallRunning = false
			elseif newState == Enum.HumanoidStateType.Jumping then
				if jumpDebounce then
					return
				end
				jumpDebounce = true

				if tick() - lastLandTime <= config.BhopWindow then
					currentSpeedBoost = math.clamp(currentSpeedBoost + config.BhopAcceleration, 0, config.MaxBhopBoost)
				else
					currentSpeedBoost = 0
				end

				if states.isSliding then
					endSlide()
					local lookDir = root.CFrame.LookVector
					root.AssemblyLinearVelocity = Vector3.new(
						lookDir.X * config.SlideJumpForwardBoost,
						config.SlideJumpUpwardBoost,
						lookDir.Z * config.SlideJumpForwardBoost
					)
					currentSpeedBoost = math.clamp(currentSpeedBoost + 15, 0, config.MaxBhopBoost)
				end
			end
		end)
	end

	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		setupCharacter(player.Character)
	end

	-- ==========================================
	-- RENDER STEP (Wall Detection & Animation)
	-- ==========================================
	RunService:BindToRenderStep("MovementPhysicsLoop", Enum.RenderPriority.Camera.Value + 1, function(dt)
		-- NEW: Capture 'anim' so we can trigger animations
		local char, hum, root, anim = getCharVars()
		if not hum or not root then
			return
		end

		if char:GetAttribute("IsFrozen") then
			root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
			hum.WalkSpeed = 0
			return
		end

		if hum.FloorMaterial ~= Enum.Material.Air and (tick() - lastLandTime > config.BhopWindow) then
			if not states.isSliding then
				currentSpeedBoost = 0
			end
		end

		local baseSpeed = states.isSprinting and config.SprintSpeed or config.WalkSpeed

		-- Track coyote time (can jump up to CoyoteTime seconds after leaving ground)
		if hum.FloorMaterial ~= Enum.Material.Air then
			lastLandTime = tick()
		end

		if hum.FloorMaterial == Enum.Material.Air and tick() > wallRunDebounce then
			local rightRay = RaycastUtils.Raycast(
				root.Position,
				root.CFrame.RightVector * config.WallRunRayDistance,
				{ char, camera }
			)
			local leftRay = RaycastUtils.Raycast(
				root.Position,
				-root.CFrame.RightVector * config.WallRunRayDistance,
				{ char, camera }
			)
			local hit = rightRay or leftRay

			if hit and math.abs(hit.Normal.Y) < 0.3 then
				if not states.isWallRunning then
					states.isWallRunning = true
					if states.isSliding then
						endSlide()
					end

					-- ==========================================
					-- NEW: PLAY THE WALL RUN ANIMATION
					-- ==========================================
					-- If normal dot right-vector is negative, the wall is on our right side
					local rightDot = hit.Normal:Dot(root.CFrame.RightVector)
					local isRightWall = rightDot < 0

					states.activeWallRunAnim = isRightWall and "RightWallRun" or "LeftWallRun"

					if anim and animationStorageModule[states.activeWallRunAnim] then
						animationModule.play(
							anim,
							animationStorageModule[states.activeWallRunAnim].id,
							Enum.AnimationPriority.Action
						)
					end
				end
				currentWallNormal = hit.Normal
			else
				-- ==========================================
				-- NEW: STOP ANIMATION IF WE FALL OFF THE WALL
				-- ==========================================
				if states.isWallRunning then
					if anim and states.activeWallRunAnim then
						animationModule.stop(anim, animationStorageModule[states.activeWallRunAnim].id)
						states.activeWallRunAnim = nil
					end
				end
				states.isWallRunning = false
				currentWallNormal = nil
			end
		else
			-- Catch-all stop if we land on the ground
			if states.isWallRunning then
				if anim and states.activeWallRunAnim then
					animationModule.stop(anim, animationStorageModule[states.activeWallRunAnim].id)
					states.activeWallRunAnim = nil
				end
			end
			states.isWallRunning = false
			currentWallNormal = nil
		end

		if states.isWallRunning and currentWallNormal then
			local moveDir = hum.MoveDirection
			if moveDir.Magnitude > 0 then
				local wallDir = moveDir - (moveDir:Dot(currentWallNormal) * currentWallNormal)
				if wallDir.Magnitude > 0 then
					wallDir = wallDir.Unit
					local runSpeed = math.max(config.WallRunBaseSpeed, baseSpeed + currentSpeedBoost)
					root.AssemblyLinearVelocity = Vector3.new(wallDir.X * runSpeed, 0, wallDir.Z * runSpeed)
				end
			else
				root.AssemblyLinearVelocity = Vector3.new(0, -2, 0)
			end
		else
			if not states.isSliding then
				-- Calculate target speed with acceleration/deceleration
				targetSpeed = baseSpeed + currentSpeedBoost
				local accelTime = (targetSpeed > hum.WalkSpeed) and config.AccelerationTime or config.DecelerationTime
				hum.WalkSpeed = math.lerp(hum.WalkSpeed, targetSpeed, dt / accelTime)

				-- Apply air control when airborne
				if hum.FloorMaterial == Enum.Material.Air and hum.MoveDirection.Magnitude > 0 then
					local horizontalVel = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z)
					local moveDir = hum.MoveDirection * hum.WalkSpeed * config.AirControlMultiplier
					local newHorizontalVel = horizontalVel + (moveDir - horizontalVel) * math.min(dt * 5, 1)
					root.AssemblyLinearVelocity =
						Vector3.new(newHorizontalVel.X, root.AssemblyLinearVelocity.Y, newHorizontalVel.Z)
				end
			end
		end

		local flatVelocity = Vector3.new(root.AssemblyLinearVelocity.X, 0, root.AssemblyLinearVelocity.Z).Magnitude
		local fovAlpha = math.clamp(flatVelocity / config.FOVSpeedCap, 0, 1)
		local targetFOV = config.BaseFOV + ((config.MaxFOV - config.BaseFOV) * fovAlpha)
		camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * 10 * dt

		local targetTilt = 0
		if states.isWallRunning and currentWallNormal then
			local rightDot = currentWallNormal:Dot(root.CFrame.RightVector)
			targetTilt = rightDot * config.WallRunCameraTilt
		end

		currentCameraTilt = currentCameraTilt + (targetTilt - currentCameraTilt) * 10 * dt
		camera.CFrame = camera.CFrame * CFrame.Angles(0, 0, math.rad(currentCameraTilt))
	end)
end

return MovementController

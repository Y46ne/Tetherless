local MovementController = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local moduleFolder = ReplicatedStorage:WaitForChild("Modules")
local configsFolder = sharedFolder:WaitForChild("Configs")
local utilsFolder = sharedFolder:WaitForChild("Utils")

local config = require(configsFolder:WaitForChild("MovementConfig"))
local RaycastUtils = require(utilsFolder:WaitForChild("RaycastUtils"))
local tweenModule = require(moduleFolder:WaitForChild("Tween"))

local weaponsFolder = sharedFolder:WaitForChild("Weapons")

local animationModule = require(script.Parent:WaitForChild("AnimationController"))
local animationStorageModule = require(script.Parent:WaitForChild("AnimationsStorage"))
local InputController = require(script.Parent:WaitForChild("InputController"))

-----------------------------
-- STATE & CACHE --
-----------------------------
local C = {
	char = nil,
	hum = nil,
	root = nil,
	anim = nil
}

local states = {
	isSprinting = false,
	isSliding = false,
	isCrouching = false,
}

local slideConnection = nil
local slideStartTime = 0
local slideDirection = Vector3.new()

local lastLandTime = 0      
local lastGroundTime = 0    
local currentSpeedBoost = 0
local jumpDebounce = false
local targetSpeed = 0

local currentWallNormal = nil
local wallJumpDebounce = 0
local hasJumped = false
local wallJumpCount = 0      -- tracks wall jumps since last landing
local cachedWeaponStats = nil -- cached right-hand weapon stats, updated on weapon change

-- Re-caches the active right-hand weapon's stats so per-frame movement code
-- doesn't need to call require() or do attribute lookups every frame.
local function refreshWeaponStats()
	if not C.char then
		cachedWeaponStats = nil
		return
	end
	local rightWeapon = C.char:GetAttribute("RightWeapon")
	if not rightWeapon or rightWeapon == "None" then
		cachedWeaponStats = nil
		return
	end
	local node = weaponsFolder:FindFirstChild(rightWeapon)
	if not node then
		cachedWeaponStats = nil
		return
	end
	local ok, mod = pcall(require, node)
	cachedWeaponStats = (ok and mod and mod.Stats) or nil
end

-----------------------------
-- CROUCH LOGIC --
-----------------------------
local function endCrouch()
	if not states.isCrouching then return end
	states.isCrouching = false

	if C.anim then
		animationModule.stop(C.anim, animationStorageModule["Crouch"].id)
	end
	if C.hum then
		tweenModule.play(C.hum, { CameraOffset = Vector3.new(0, 0, 0) }, config.CrouchTransitionTime)
	end
	if C.char then
		C.char:SetAttribute("IsCrouching", false)
	end
end

local function startCrouch()
	if not C.hum or not C.root then return end
	if states.isSliding or states.isCrouching then return end

	states.isCrouching = true

	if C.anim then
		animationModule.play(C.anim, animationStorageModule["Crouch"].id, Enum.AnimationPriority.Action)
	end
	tweenModule.play(C.hum, { CameraOffset = config.CrouchCameraOffset }, config.CrouchTransitionTime)
	if C.char then
		C.char:SetAttribute("IsCrouching", true)
	end
end

-----------------------------
-- SLIDE LOGIC --
-----------------------------
local function endSlide()
	if not states.isSliding then return end

	states.isSliding = false
	if C.anim then animationModule.stop(C.anim, animationStorageModule["Sliding"].id) end

	if slideConnection then
		slideConnection:Disconnect()
		slideConnection = nil
	end

	if C.hum then
		tweenModule.play(C.hum, { CameraOffset = Vector3.new(0, 0, 0) }, 0.3)
	end
end

local function startSlide()
	if not C.hum or not C.root then return end
	if states.isSliding or C.hum.MoveDirection.Magnitude == 0 then return end
	if C.hum.FloorMaterial == Enum.Material.Air then return end
	endCrouch()

	states.isSliding = true
	slideStartTime = tick()
	slideDirection = C.root.CFrame.LookVector

	if C.anim then
		animationModule.play(C.anim, animationStorageModule["Sliding"].id, Enum.AnimationPriority.Action)
	end

	tweenModule.play(C.hum, { CameraOffset = config.CameraDip }, 0.15)

	slideConnection = RunService.Heartbeat:Connect(function()
		local timeElapsed = tick() - slideStartTime

		if timeElapsed >= config.SlideDuration then
			endSlide()
		else
			local progress = timeElapsed / config.SlideDuration
			local decayMultiplier = config.SlideMomentumDecay ^ progress
			local currentSpeed = config.SlidePower * decayMultiplier

			C.root.AssemblyLinearVelocity = Vector3.new(
				slideDirection.X * currentSpeed,
				C.root.AssemblyLinearVelocity.Y,
				slideDirection.Z * currentSpeed
			)
		end
	end)
end

-----------------------------
-- PHYSICS LOOP --
-----------------------------
local function onRenderStep(dt)
	if not C.hum or not C.root then return end

	if C.char:GetAttribute("IsFrozen") then
		C.root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
		C.hum.WalkSpeed = 0
		return
	end

	if C.hum.FloorMaterial ~= Enum.Material.Air then
		lastGroundTime = tick()
	end

	if C.hum.FloorMaterial ~= Enum.Material.Air then
		if C.hum.MoveDirection.Magnitude == 0 then
			currentSpeedBoost = 0
		elseif (tick() - lastLandTime > config.BhopWindow) and not states.isSliding then
			currentSpeedBoost = math.max(0, currentSpeedBoost - (dt * config.FrictionDecayRate)) 
		end
	end

	local moveFactor = (cachedWeaponStats and cachedWeaponStats.MovementFactor) or 1
	local baseSpeed = states.isCrouching and config.CrouchSpeed
		or (states.isSprinting and config.SprintSpeed or config.WalkSpeed) * moveFactor

	-- WALL DETECT LOGIC (Only to allow jumping off them)
	if C.hum.FloorMaterial == Enum.Material.Air and tick() > wallJumpDebounce then
		local rightRay = RaycastUtils.Raycast(C.root.Position, C.root.CFrame.RightVector * config.WallRayDistance, { C.char, camera })
		local leftRay = RaycastUtils.Raycast(C.root.Position, -C.root.CFrame.RightVector * config.WallRayDistance, { C.char, camera })
		local hit = rightRay or leftRay

		if hit and math.abs(hit.Normal.Y) < 0.3 then
			currentWallNormal = hit.Normal
			local maxWJ = (cachedWeaponStats and cachedWeaponStats.MaxWallJumps) or 1
			if wallJumpCount < maxWJ then
				hasJumped = false  -- unlock jump only if we have remaining wall jumps
			end
			if states.isSliding then endSlide() end
		else
			currentWallNormal = nil
		end
	else
		currentWallNormal = nil
	end

	-- APPLY BASE SPEEDS (No more gravity suspending or wall hovering!)
	if not states.isSliding then
		targetSpeed = baseSpeed + currentSpeedBoost
		local accelTime = (targetSpeed > C.hum.WalkSpeed) and config.AccelerationTime or config.DecelerationTime
		C.hum.WalkSpeed = math.lerp(C.hum.WalkSpeed, targetSpeed, dt / accelTime)

		if C.hum.FloorMaterial == Enum.Material.Air and C.hum.MoveDirection.Magnitude > 0 then
			local horizontalVel = Vector3.new(C.root.AssemblyLinearVelocity.X, 0, C.root.AssemblyLinearVelocity.Z)
			local moveDir = C.hum.MoveDirection * C.hum.WalkSpeed * config.AirControlMultiplier
			local newHorizontalVel = horizontalVel + (moveDir - horizontalVel) * math.min(dt * 5, 1)
			C.root.AssemblyLinearVelocity = Vector3.new(newHorizontalVel.X, C.root.AssemblyLinearVelocity.Y, newHorizontalVel.Z)
		end
	end

	-- CAMERA EFFECTS (FOV Warp only)
	local flatVelocity = Vector3.new(C.root.AssemblyLinearVelocity.X, 0, C.root.AssemblyLinearVelocity.Z).Magnitude
	local fovAlpha = math.clamp(flatVelocity / config.FOVSpeedCap, 0, 1)
	local targetFOV = config.BaseFOV + ((config.MaxFOV - config.BaseFOV) * fovAlpha)
	camera.FieldOfView = camera.FieldOfView + (targetFOV - camera.FieldOfView) * 10 * dt
end

-----------------------------
-- INITIALIZATION --
-----------------------------
function MovementController.Init()
	print("MovementController: Initializing...")

	local inputEvents = InputController.GetEvents()

	inputEvents.SprintToggle:Connect(function()
		if not C.char or C.char:GetAttribute("IsFrozen") then return end
		states.isSprinting = not states.isSprinting
	end)

	inputEvents.SlidePressed:Connect(function()
		if not C.char or C.char:GetAttribute("IsFrozen") then return end
		startSlide()
	end)

	inputEvents.SlideReleased:Connect(function()
		endSlide()
	end)

	inputEvents.CrouchToggle:Connect(function()
		if not C.char or C.char:GetAttribute("IsFrozen") then return end
		if states.isCrouching then
			endCrouch()
		else
			startCrouch()
		end
	end)

	inputEvents.JumpPressed:Connect(function()
		if not C.char or not C.hum or not C.root or C.char:GetAttribute("IsFrozen") then return end

		if hasJumped then return end 

		local canJump = (C.hum.FloorMaterial ~= Enum.Material.Air) or (tick() - lastGroundTime < config.CoyoteTime)

		if currentWallNormal then
			hasJumped = true
			wallJumpCount += 1
			wallJumpDebounce = tick() + 0.2

			local wjFactor = (cachedWeaponStats and cachedWeaponStats.WallJumpFactor) or 1
			local jumpVel = (currentWallNormal * config.WallJumpOutwardBoost * wjFactor)
				+ Vector3.new(0, config.WallJumpUpwardBoost * wjFactor, 0)
			local lookDir = C.root.CFrame.LookVector
			local forwardVel = Vector3.new(lookDir.X, 0, lookDir.Z).Unit * (currentSpeedBoost + config.WallJumpForwardBoost)

			C.root.AssemblyLinearVelocity = jumpVel + forwardVel
			currentSpeedBoost = math.clamp(currentSpeedBoost + 15, 0, config.MaxBhopBoost)

		elseif canJump then
			hasJumped = true

			if C.hum.FloorMaterial == Enum.Material.Air then
				local currentVel = C.root.AssemblyLinearVelocity
				C.root.AssemblyLinearVelocity = Vector3.new(currentVel.X, config.CoyoteJumpForce, currentVel.Z)
			else
				local jumpFactor = (cachedWeaponStats and cachedWeaponStats.JumpFactor) or 1
				C.hum.JumpPower = config.DefaultJumpPower * jumpFactor
				C.hum:ChangeState(Enum.HumanoidStateType.Jumping)
				-- Restore default after the frame so other systems aren't affected
				task.defer(function()
					if C.hum then C.hum.JumpPower = config.DefaultJumpPower end
				end)
			end
			lastGroundTime = 0 
		end
	end)

	local function setupCharacter(char)
		C.char = char
		C.hum = char:WaitForChild("Humanoid")
		C.root = char:WaitForChild("HumanoidRootPart")
		C.anim = C.hum:WaitForChild("Animator")

		states.isSprinting = false
		states.isSliding = false
		states.isCrouching = false

		if slideConnection then
			slideConnection:Disconnect()
			slideConnection = nil
		end

		currentSpeedBoost = 0
		lastLandTime = tick()
		lastGroundTime = tick()
		jumpDebounce = false
		currentWallNormal = nil
		hasJumped = false
		wallJumpCount = 0
		cachedWeaponStats = nil

		char:GetAttributeChangedSignal("RightWeapon"):Connect(refreshWeaponStats)
		refreshWeaponStats()

		char:SetAttribute("IsFrozen", false)

		C.hum.StateChanged:Connect(function(oldState, newState)
			if not C.root then return end

			if newState == Enum.HumanoidStateType.Landed then
				lastLandTime = tick()
				jumpDebounce = false
				hasJumped = false
				wallJumpCount = 0

			elseif newState == Enum.HumanoidStateType.Jumping then
				if jumpDebounce then return end
				jumpDebounce = true

				if tick() - lastLandTime <= config.BhopWindow then
					currentSpeedBoost = math.clamp(currentSpeedBoost + config.BhopAcceleration, 0, config.MaxBhopBoost)
				else
					currentSpeedBoost = 0
				end

				if states.isSliding then
					endSlide()
					local lookDir = C.root.CFrame.LookVector
					C.root.AssemblyLinearVelocity = Vector3.new(
						lookDir.X * config.SlideJumpForwardBoost,
						config.SlideJumpUpwardBoost,
						lookDir.Z * config.SlideJumpForwardBoost
					)
					currentSpeedBoost = math.clamp(currentSpeedBoost + config.SlideJumpBoost, 0, config.MaxBhopBoost)
				end
			end
		end)

		RunService:BindToRenderStep("MovementPhysicsLoop", Enum.RenderPriority.Camera.Value + 1, onRenderStep)
	end

	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then setupCharacter(player.Character) end

	player.CharacterRemoving:Connect(function()
		RunService:UnbindFromRenderStep("MovementPhysicsLoop")
		if slideConnection then
			slideConnection:Disconnect()
			slideConnection = nil
		end
		C.char, C.hum, C.root, C.anim = nil, nil, nil, nil
	end)
end

return MovementController
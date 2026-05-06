local MovementConfig = {
	WalkSpeed = 18,
	SprintSpeed = 38,

	-- Acceleration & Deceleration
	AccelerationTime = 0.15,
	DecelerationTime = 0.2,

	-- Slide Physics
	SlidePower = 120,
	SlideDuration = 1.0,
	SlideMomentumDecay = 0.85,

	-- Jump & Bhop Physics
	CoyoteTime = 0.1,
	SlideJumpForwardBoost = 90,
	SlideJumpUpwardBoost = 40,

	BhopWindow = 0.2,
	BhopAcceleration = 5,
	MaxBhopBoost = 50,
	AirControlMultiplier = 0.4,

	-- Wall Run Physics
	WallRunBaseSpeed = 35,
	WallRunRayDistance = 2.5,
	WallJumpUpwardBoost = 50,
	WallJumpOutwardBoost = 80,

	-- Visuals
	CameraDip = Vector3.new(0, -1.5, 0),
	BaseFOV = 70,
	MaxFOV = 110,
	FOVSpeedCap = 100,
	WallRunCameraTilt = -15,
	HeadBobMultiplier = 1.0,
}

return MovementConfig

local MovementConfig = {
	WalkSpeed = 18, 
	SprintSpeed = 38,

	-- Slide Physics
	SlidePower = 120, 
	SlideDuration = 1.0, 

	-- Jump & Bhop Physics
	SlideJumpForwardBoost = 90, 
	SlideJumpUpwardBoost = 40,  

	BhopWindow = 0.2, 
	BhopAcceleration = 5, 
	MaxBhopBoost = 50, 

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
	WallRunCameraTilt = -15 
}

return MovementConfig
local MovementConfig = {
	-- 1. BASE MOVEMENT
	WalkSpeed = 16,     -- Standard baseline
	SprintSpeed = 32,   -- Bumped from 28. Noticeably faster for map traversal.

	-- Acceleration & Deceleration
	AccelerationTime = 0.15, 
	DecelerationTime = 0.15, 
	FrictionDecayRate = 50, 

	-- 2. SLIDE PHYSICS
	SlidePower = 75,      -- Bumped from 70. Gives a slightly harder initial kick.
	SlideDuration = 0.75, 
	SlideMomentumDecay = 0.85,

	-- 3. JUMP & BHOP PHYSICS
	CoyoteTime = 0.15,
	CoyoteJumpForce = 50,       
	SlideJumpForwardBoost = 65, -- Bumped from 60. Covers more ground instantly.
	SlideJumpUpwardBoost = 35,  
	SlideJumpBoost = 18,        -- Bumped from 15. More raw speed awarded for a perfect jump-slide.

	BhopWindow = 0.2,
	BhopAcceleration = 4, -- Bumped from 3. You hit top speed in fewer jumps.
	MaxBhopBoost = 26,    -- Bumped from 22. Top speed is now 32 (Sprint) + 26 (Bhop) = 58 WalkSpeed.
	AirControlMultiplier = 0.8, -- Bumped from 0.7. Gives you slightly better mid-air dodging!

	-- 4. WALL JUMP PHYSICS
	WallRayDistance = 2.5,      
	WallJumpUpwardBoost = 40,   
	WallJumpOutwardBoost = 55,  -- Bumped from 50. Makes kicking off the wall feel more explosive.
	WallJumpForwardBoost = 25,  -- Bumped from 20. Keeps your forward momentum strong after a bounce.

	-- 5. VISUALS & CAMERA
	CameraDip = Vector3.new(0, -1.2, 0),
	BaseFOV = 80,         
	MaxFOV = 110,         -- Bumped from 105 to visually match the new top speed.
	FOVSpeedCap = 65,     -- Bumped from 60.
	HeadBobMultiplier = 1.0,
}

return MovementConfig
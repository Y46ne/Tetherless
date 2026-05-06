-- Centralized UI constants: paths, timings, easing, viewmodel settings
local UIConstants = {
	-- HUD & Timing
	FadeDuration = 0.18,
	PickupToastDuration = 2.5,
	KillFeedDuration = 4.0,
	HUDRoot = "StarterGui:HUD",

	-- Viewmodel Settings
	ViewmodelSwayAmount = 0.05,
	ViewmodelSwaySpeed = 8,
	ViewmodelBobSpeedMultiplier = 0.08,
	ViewmodelBobIntensity = 0.05,
	ViewmodelBaseOffset = CFrame.new(0, -1.5, -0.5),
	ViewmodelGripOffset = CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), math.rad(90), math.rad(180)),
}

return UIConstants

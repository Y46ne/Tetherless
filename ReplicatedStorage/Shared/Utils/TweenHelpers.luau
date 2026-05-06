local TweenHelpers = {}
local TweenService = game:GetService("TweenService")

-- Simple wrapper to play a tween and return the Tween instance.
function TweenHelpers.play(instance, goals, duration, tweenInfo)
	local info = tweenInfo or TweenInfo.new(duration or 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tween = TweenService:Create(instance, info, goals)
	tween:Play()
	return tween
end

return TweenHelpers

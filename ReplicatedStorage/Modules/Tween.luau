local TweenService = game:GetService("TweenService")
local TweenManager = {}

local DEFAULT_DURATION = 0.2
local DEFAULT_STYLE = Enum.EasingStyle.Quad
local DEFAULT_DIRECTION = Enum.EasingDirection.Out

function TweenManager.play(object, goals, duration)
	local time = duration or DEFAULT_DURATION
	local info = TweenInfo.new(time, DEFAULT_STYLE, DEFAULT_DIRECTION)
	local tween = TweenService:Create(object, info, goals)
	tween:Play()
	return tween
end

return TweenManager
local TweenService = game:GetService("TweenService")
local TweenManager = {}

local DEFAULT_DURATION = 0.2
local DEFAULT_STYLE = Enum.EasingStyle.Quad
local DEFAULT_DIRECTION = Enum.EasingDirection.Out

function TweenManager.play(object, goals, duration, style, direction)
	local time = duration or DEFAULT_DURATION
	local tStyle = style or DEFAULT_STYLE
	local tDir = direction or DEFAULT_DIRECTION

	local info = TweenInfo.new(time, tStyle, tDir)
	local tween = TweenService:Create(object, info, goals)
	tween:Play()

	return tween
end

return TweenManager
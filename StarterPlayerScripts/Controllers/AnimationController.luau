local AnimationController = {}

-- We cache tracks here so we don't load the same animation twice
-- Format: cache[animator][animationId] = AnimationTrack
local trackCache = {}

-- Grabs a track if it exists, or creates and caches it if it doesn't
function AnimationController.getTrack(animator, animationId)
	if not trackCache[animator] then
		trackCache[animator] = {}
	end

	if not trackCache[animator][animationId] then
		local anim = Instance.new("Animation")
		anim.AnimationId = animationId
		trackCache[animator][animationId] = animator:LoadAnimation(anim)
	end

	return trackCache[animator][animationId]
end

-- Plays the animation and allows you to force a priority (like Action)
function AnimationController.play(animator, animationId, priority)
	local track = AnimationController.getTrack(animator, animationId)

	if priority then 
		track.Priority = priority 
	end

	track:Play()
	return track
end

-- Stops a specific animation on that animator
function AnimationController.stop(animator, animationId)
	if trackCache[animator] and trackCache[animator][animationId] then
		trackCache[animator][animationId]:Stop()
	end
end

return AnimationController
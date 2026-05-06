local MathUtils = {}

function MathUtils.clamp(val, min, max)
	if val < min then
		return min
	end
	if val > max then
		return max
	end
	return val
end

function MathUtils.lerp(a, b, t)
	return a + (b - a) * t
end

function MathUtils.safeUnit(v)
	if typeof(v) == "Vector3" and v.Magnitude > 0 then
		return v.Unit
	end
	return Vector3.new(0, 0, 0)
end

return MathUtils

local RaycastUtils = {}
local workspace = game:GetService("Workspace")

-- Performs a raycast given an origin and a displacement vector (origin + displacement).
-- `ignoreList` is an array of instances to exclude.
function RaycastUtils.Raycast(origin, displacement, ignoreList)
	local params = RaycastParams.new()
	params.FilterDescendantsInstances = ignoreList or {}
	params.FilterType = Enum.RaycastFilterType.Exclude
	return workspace:Raycast(origin, displacement, params)
end

return RaycastUtils

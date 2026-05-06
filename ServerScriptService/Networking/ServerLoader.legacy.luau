local serverScriptService = game:GetService("ServerScriptService")

local servicesFolder = serverScriptService:WaitForChild("Services")

-- 1. Require all services
for _, module in pairs(servicesFolder:GetChildren()) do
	if module:IsA("ModuleScript") then
		local service = require(module)

		-- 2. If the module has an "Init" function, run it!
		if type(service.Init) == "function" then
			service.Init()
		end
	end
end

print("SERVER: All Services successfully loaded!")
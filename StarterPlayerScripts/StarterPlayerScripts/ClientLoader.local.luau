local controllersFolder = script.Parent:WaitForChild("Controllers")

for _, module in pairs(controllersFolder:GetChildren()) do
	if module:IsA("ModuleScript") then
		local controller = require(module)

		if type(controller.Init) == "function" then
			controller.Init()
		end
	end
end

print("CLIENT: All Controllers successfully loaded!")
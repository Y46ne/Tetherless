local InputController = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local shared = ReplicatedStorage:WaitForChild("Shared")
local EventBus = require(shared:WaitForChild("EventBus"):WaitForChild("EventBus"))

-----------------------------
-- STATE --
-----------------------------
local isTossing = false

-----------------------------
-- EVENT SIGNALS --
-----------------------------
local InputEvents = {
	SprintToggle = EventBus.Get("Input:SprintToggle"),
	SlidePressed = EventBus.Get("Input:SlidePressed"),
	SlideReleased = EventBus.Get("Input:SlideReleased"),
	JumpPressed = EventBus.Get("Input:JumpPressed"),
	FireRight = EventBus.Get("Input:FireRight"),
	FireLeft = EventBus.Get("Input:FireLeft"),
	TossWeapon = EventBus.Get("Input:TossWeapon"),
}

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function InputController.GetEvents()
	return InputEvents
end

function InputController.Init()
	print("InputController: Initializing...")

	UserInputService.InputBegan:Connect(function(input, gp)
		if gp then
			return
		end

		if input.KeyCode == Enum.KeyCode.LeftShift then
			InputEvents.SprintToggle:Fire()
		elseif input.KeyCode == Enum.KeyCode.C then
			InputEvents.SlidePressed:Fire()
		elseif input.KeyCode == Enum.KeyCode.Space then
			InputEvents.JumpPressed:Fire()
		elseif input.KeyCode == Enum.KeyCode.F then
			if not isTossing then
				isTossing = true
				InputEvents.TossWeapon:Fire()
				task.wait(0.2)
				isTossing = false
			end
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
			InputEvents.FireRight:Fire()
		elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
			InputEvents.FireLeft:Fire()
		end
	end)

	UserInputService.InputEnded:Connect(function(input, gp)
		if gp then
			return
		end
		if input.KeyCode == Enum.KeyCode.C then
			InputEvents.SlideReleased:Fire()
		end
	end)
end

return InputController

local ViewmodelController = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local workspace = game:GetService("Workspace")
local player = game.Players.LocalPlayer

local shared = ReplicatedStorage:WaitForChild("Shared")
local configs = shared:WaitForChild("Configs")
local UIConstants = require(configs:WaitForChild("UIConstants"))

local assetsFolder = ReplicatedStorage:WaitForChild("Assets")
local weaponsFolder = assetsFolder:WaitForChild("Weapons")
local viewModelsFolder = assetsFolder:WaitForChild("ViewModels")
local currentTemplate = viewModelsFolder:WaitForChild("CurrentViewModel")
local otherTemplate = viewModelsFolder:WaitForChild("OtherViewModel")

local SWAY_AMOUNT = 0.05
local SWAY_SPEED = 8
local BASE_OFFSET = UIConstants.ViewmodelBaseOffset or CFrame.new(0, -1.5, -0.5)
local GRIP_OFFSET = UIConstants.ViewmodelGripOffset
	or (CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), math.rad(90), math.rad(180)))

local currentViewmodel = nil
local otherViewmodel = nil
local equippedGunModel = nil
local equippedLeftGunModel = nil
local currentSway = CFrame.new()
local activeViewmodel = nil -- Tracks which viewmodel is currently active

-- STATE TRACKERS
local currentRightName = nil
local currentLeftName = nil

local function updateArmVisibility(showRight, showLeft)
	if not currentViewmodel then
		return
	end

	for _, part in pairs(currentViewmodel:GetDescendants()) do
		local isWeapon = false
		if equippedGunModel and (part == equippedGunModel or part:IsDescendantOf(equippedGunModel)) then
			isWeapon = true
		end
		if equippedLeftGunModel and (part == equippedLeftGunModel or part:IsDescendantOf(equippedLeftGunModel)) then
			isWeapon = true
		end

		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" and not isWeapon then
			if string.find(part.Name, "Right") then
				part.Transparency = showRight and 0 or 1
				part.LocalTransparencyModifier = 0
			elseif string.find(part.Name, "Left") then
				part.Transparency = showLeft and 0 or 1
				part.LocalTransparencyModifier = 0
			end
		end
	end
end

local function syncViewmodelArms(playerCharacter, viewmodel)
	if not playerCharacter or not viewmodel then
		return
	end
	for _, child in pairs(viewmodel:GetChildren()) do
		if child:IsA("Shirt") or child:IsA("ShirtGraphic") or child:IsA("BodyColors") or child:IsA("CharacterMesh") then
			child:Destroy()
		end
	end
	for _, child in pairs(playerCharacter:GetChildren()) do
		if child:IsA("BodyColors") or child:IsA("Shirt") or child:IsA("ShirtGraphic") or child:IsA("CharacterMesh") then
			child:Clone().Parent = viewmodel
		end
	end
end

local function setupViewmodel(character)
	if currentViewmodel then
		currentViewmodel:Destroy()
		currentViewmodel = nil
	end
	if otherViewmodel then
		otherViewmodel:Destroy()
		otherViewmodel = nil
	end

	equippedGunModel = nil
	equippedLeftGunModel = nil
	currentRightName = nil
	currentLeftName = nil
	activeViewmodel = nil

	-- Clone both viewmodels
	currentViewmodel = currentTemplate:Clone()
	currentViewmodel.Parent = workspace.CurrentCamera

	otherViewmodel = otherTemplate:Clone()
	otherViewmodel.Parent = workspace.CurrentCamera

	if character then
		syncViewmodelArms(character, currentViewmodel)
		syncViewmodelArms(character, otherViewmodel)
		ViewmodelController.UpdateViewmodels(character)
	end
end

local function onRenderStep(dt)
	if not activeViewmodel or not activeViewmodel.PrimaryPart then
		return
	end

	activeViewmodel.Parent = workspace.CurrentCamera
	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then
		return
	end

	local mouseDelta = UserInputService:GetMouseDelta()
	local deltaX = math.clamp(mouseDelta.X, -15, 15) * SWAY_AMOUNT
	local deltaY = math.clamp(mouseDelta.Y, -15, 15) * SWAY_AMOUNT
	currentSway = currentSway:Lerp(CFrame.Angles(math.rad(deltaY), math.rad(deltaX), 0), SWAY_SPEED * dt)

	activeViewmodel:PivotTo(workspace.CurrentCamera.CFrame * BASE_OFFSET * currentSway)

	for _, part in pairs(activeViewmodel:GetDescendants()) do
		if part:IsA("BasePart") then
			part.LocalTransparencyModifier = 0
		end
	end
end

function ViewmodelController.UpdateViewmodels(character)
	if not character then
		return
	end

	if not currentViewmodel or not otherViewmodel then
		return
	end

	local currentWeapon = character:GetAttribute("CurrentViewModelWeapon")
	local otherWeapon = character:GetAttribute("OtherViewModelWeapon")
	local showLeftArm = character:GetAttribute("ShowLeftArm") or false

	-- Determine which viewmodel should be active
	-- If showLeftArm is true, we're dual wielding one-handed weapons - use CurrentViewModel
	if showLeftArm then
		activeViewmodel = currentViewmodel
		currentViewmodel.Parent = workspace.CurrentCamera
		otherViewmodel.Parent = nil
	-- If otherWeapon is set and showLeftArm is false, it's a two-handed weapon - use OtherViewModel
	elseif otherWeapon and otherWeapon ~= "None" then
		activeViewmodel = otherViewmodel
		currentViewmodel.Parent = nil
		otherViewmodel.Parent = workspace.CurrentCamera
	-- If currentWeapon is set, it's a single one-handed weapon - use CurrentViewModel
	elseif currentWeapon and currentWeapon ~= "None" then
		activeViewmodel = currentViewmodel
		currentViewmodel.Parent = workspace.CurrentCamera
		otherViewmodel.Parent = nil
	-- No weapons equipped - hide both viewmodels
	else
		activeViewmodel = nil
		currentViewmodel.Parent = nil
		otherViewmodel.Parent = nil
		return
	end

	-- Update the active viewmodel's weapons
	if activeViewmodel == otherViewmodel then
		-- OtherViewModel with two-handed weapon
		if otherWeapon ~= currentRightName then
			if equippedGunModel then
				equippedGunModel:Destroy()
				equippedGunModel = nil
			end

			if otherWeapon and otherWeapon ~= "None" then
				local weaponTemplate = weaponsFolder:FindFirstChild(otherWeapon)
				if weaponTemplate then
					equippedGunModel = weaponTemplate:Clone()
					equippedGunModel.Parent = activeViewmodel
					local rightArm = activeViewmodel:FindFirstChild("Right Arm")
						or activeViewmodel:FindFirstChild("RightHand")

					if rightArm and equippedGunModel.PrimaryPart then
						equippedGunModel:PivotTo(rightArm.CFrame * GRIP_OFFSET)
						local weld = Instance.new("WeldConstraint")
						weld.Part0, weld.Part1, weld.Parent =
							rightArm, equippedGunModel.PrimaryPart, equippedGunModel.PrimaryPart
					end
				end
			end
			currentRightName = otherWeapon
		end

		-- Hide left arm and left weapon for two-handed
		if equippedLeftGunModel then
			equippedLeftGunModel:Destroy()
			equippedLeftGunModel = nil
		end
		currentLeftName = nil
		-- Show both arms for two-handed weapons
		updateArmVisibility(true, true)
	else
		-- CurrentViewModel with single or dual one-handed weapons
		if currentWeapon ~= currentRightName then
			if equippedGunModel then
				equippedGunModel:Destroy()
				equippedGunModel = nil
			end

			if currentWeapon and currentWeapon ~= "None" then
				local weaponTemplate = weaponsFolder:FindFirstChild(currentWeapon)
				if weaponTemplate then
					equippedGunModel = weaponTemplate:Clone()
					equippedGunModel.Parent = activeViewmodel
					local rightArm = activeViewmodel:FindFirstChild("Right Arm")
						or activeViewmodel:FindFirstChild("RightHand")

					if rightArm and equippedGunModel.PrimaryPart then
						equippedGunModel:PivotTo(rightArm.CFrame * GRIP_OFFSET)
						local weld = Instance.new("WeldConstraint")
						weld.Part0, weld.Part1, weld.Parent =
							rightArm, equippedGunModel.PrimaryPart, equippedGunModel.PrimaryPart
					end
				end
			end
			currentRightName = currentWeapon
		end

		if otherWeapon ~= currentLeftName then
			if equippedLeftGunModel then
				equippedLeftGunModel:Destroy()
				equippedLeftGunModel = nil
			end

			if otherWeapon and otherWeapon ~= "None" then
				local weaponTemplate = weaponsFolder:FindFirstChild(otherWeapon)
				if weaponTemplate then
					equippedLeftGunModel = weaponTemplate:Clone()
					equippedLeftGunModel.Parent = activeViewmodel
					local leftArm = activeViewmodel:FindFirstChild("Left Arm")
						or activeViewmodel:FindFirstChild("LeftHand")

					if leftArm and equippedLeftGunModel.PrimaryPart then
						equippedLeftGunModel:PivotTo(leftArm.CFrame * GRIP_OFFSET)
						local weld = Instance.new("WeldConstraint")
						weld.Part0, weld.Part1, weld.Parent =
							leftArm, equippedLeftGunModel.PrimaryPart, equippedLeftGunModel.PrimaryPart
					end
				end
			end
			currentLeftName = otherWeapon
		end

		-- Show/hide left arm based on whether we're dual wielding
		-- Right arm always shown, left arm only shown if showLeftArm is true
		updateArmVisibility(true, showLeftArm)
	end

	-- Ensure physics settings are correct
	for _, part in pairs(activeViewmodel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide, part.Massless = false, true
		end
	end
end

function ViewmodelController.PlayShootEffect(hand)
	local gunModel = (hand == "Left") and equippedLeftGunModel or equippedGunModel
	if gunModel then
		local muzzle = gunModel:FindFirstChild("Muzzle", true)
		if muzzle then
			local flash = muzzle:FindFirstChild("Flash")
			if flash and flash:IsA("ParticleEmitter") then
				flash:Emit(3)
			end
			return muzzle.CFrame.Position
		end
		return gunModel.PrimaryPart and gunModel.PrimaryPart.Position or nil
	end
	return nil
end

function ViewmodelController.Init()
	player.CharacterAdded:Connect(function(char)
		task.wait(0.1)
		setupViewmodel(char)

		-- Watch for viewmodel attribute changes
		char:GetAttributeChangedSignal("CurrentViewModelWeapon"):Connect(function()
			ViewmodelController.UpdateViewmodels(char)
		end)
		char:GetAttributeChangedSignal("OtherViewModelWeapon"):Connect(function()
			ViewmodelController.UpdateViewmodels(char)
		end)
		char:GetAttributeChangedSignal("ShowLeftArm"):Connect(function()
			ViewmodelController.UpdateViewmodels(char)
		end)
	end)

	-- Weapon replication to other players is handled by CharacterRenderService via WeldConstraints.
	-- No need to send viewmodel CFrame to server anymore.
	RunService.RenderStepped:Connect(function(dt)
		onRenderStep(dt)
	end)
end

return ViewmodelController

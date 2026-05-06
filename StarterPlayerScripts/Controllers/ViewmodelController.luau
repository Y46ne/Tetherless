local ViewmodelController = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
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
local viewmodelTemplate = assetsFolder:WaitForChild("Viewmodel")

-----------------------------
-- SETTINGS & STATE --
-----------------------------
local function numberOrDefault(value, defaultValue)
	if type(value) == "number" then
		return value
	end
	return defaultValue
end

local SWAY_AMOUNT = numberOrDefault(UIConstants.ViewmodelSwayAmount, 0.05)
local SWAY_SPEED = numberOrDefault(UIConstants.ViewmodelSwaySpeed, 8)
local BOB_SPEED_MULTIPLIER = numberOrDefault(UIConstants.ViewmodelBobSpeedMultiplier, 0.08)
local BOB_INTENSITY = numberOrDefault(UIConstants.ViewmodelBobIntensity, 0.05)
local BASE_OFFSET = UIConstants.ViewmodelBaseOffset or CFrame.new(0, -1.5, -0.5)
local GRIP_OFFSET = UIConstants.ViewmodelGripOffset
	or (CFrame.new(0, -1, 0) * CFrame.Angles(math.rad(90), math.rad(90), math.rad(180)))

local currentViewmodel = nil
local equippedGunModel = nil
local equippedLeftGunModel = nil

local currentSway = CFrame.new()
local currentBob = CFrame.new()
local bobTime = 0

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function updateArmVisibility(showRight, showLeft)
	if not currentViewmodel then
		return
	end

	for _, part in pairs(currentViewmodel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			local isWeaponPart = false
			if equippedGunModel and (part == equippedGunModel or part:IsDescendantOf(equippedGunModel)) then
				isWeaponPart = true
			end
			if equippedLeftGunModel and (part == equippedLeftGunModel or part:IsDescendantOf(equippedLeftGunModel)) then
				isWeaponPart = true
			end

			if not isWeaponPart then
				if string.find(part.Name, "Right") then
					local AmmoCountRight = part:WaitForChild("SurfaceGui"):WaitForChild("Ammo")
					part.Transparency = showRight and 0 or 1
					AmmoCountRight.Visible = showRight and true or false
				elseif string.find(part.Name, "Left") then
					local AmmoCountLeft = part:WaitForChild("SurfaceGui"):WaitForChild("Ammo")
					part.Transparency = showLeft and 0 or 1
					AmmoCountLeft.Visible = showLeft and true or false
				end
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

	equippedGunModel = nil
	equippedLeftGunModel = nil

	currentViewmodel = viewmodelTemplate:Clone()
	currentViewmodel.Parent = workspace.CurrentCamera

	if character then
		syncViewmodelArms(character, currentViewmodel)
	end

	updateArmVisibility(false, false)

	if character then
		local weaponName = character:GetAttribute("EquippedWeapon")
		local isDual = character:GetAttribute("IsDualWielding")
		local singleHand = character:GetAttribute("SingleWieldHand")

		if weaponName then
			ViewmodelController.EquipWeapon(weaponName, isDual, singleHand)
		end
	end
end

local function onRenderStep(deltaTime)
	if type(deltaTime) ~= "number" then
		deltaTime = 1 / 60
	end

	local step = deltaTime
	local swayAmount = SWAY_AMOUNT or 0.05
	local swaySpeed = SWAY_SPEED or 8
	local bobSpeedMultiplier = BOB_SPEED_MULTIPLIER or 0.08
	local bobIntensity = BOB_INTENSITY or 0.05

	if currentViewmodel and currentViewmodel.PrimaryPart then
		if currentViewmodel.Parent ~= workspace.CurrentCamera then
			currentViewmodel.Parent = workspace.CurrentCamera
		end

		local char = player.Character
		if not char or not char:FindFirstChild("HumanoidRootPart") or not char:FindFirstChild("Humanoid") then
			return
		end

		local rootPart = char.HumanoidRootPart
		local camera = workspace.CurrentCamera

		local mouseDelta = UserInputService:GetMouseDelta()
		local mouseX = math.max(-15, math.min(15, mouseDelta.X))
		local mouseY = math.max(-15, math.min(15, mouseDelta.Y))
		local deltaX = mouseX * swayAmount
		local deltaY = mouseY * swayAmount

		local targetSway = CFrame.Angles(math.rad(deltaY), math.rad(deltaX), 0)
		currentSway = currentSway:Lerp(targetSway, swaySpeed * step)

		local velocity = rootPart.AssemblyLinearVelocity
		local flatSpeed = Vector3.new(velocity.X, 0, velocity.Z).Magnitude

		if flatSpeed > 1 and char.Humanoid.FloorMaterial ~= Enum.Material.Air then
			bobTime = bobTime + (flatSpeed * step * bobSpeedMultiplier)
			local bobX = math.sin(bobTime) * bobIntensity
			local bobY = math.cos(bobTime * 2) * bobIntensity

			local targetBob = CFrame.new(bobX, bobY, 0)
			currentBob = currentBob:Lerp(targetBob, 10 * step)
		else
			currentBob = currentBob:Lerp(CFrame.new(), 5 * step)
		end

		local baseOffset = BASE_OFFSET

		currentViewmodel:PivotTo(camera.CFrame * baseOffset * currentBob * currentSway)
	end
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
function ViewmodelController.EquipWeapon(weaponName, isDual, singleWieldHand)
	if not currentViewmodel or not currentViewmodel.Parent then
		setupViewmodel(player.Character)
	end

	if equippedGunModel then
		equippedGunModel:Destroy()
		equippedGunModel = nil
	end
	if equippedLeftGunModel then
		equippedLeftGunModel:Destroy()
		equippedLeftGunModel = nil
	end

	if weaponName == "None" or weaponName == nil then
		updateArmVisibility(false, false)
		return
	end

	singleWieldHand = singleWieldHand or "Right"

	local gunTemplate = weaponsFolder:FindFirstChild(weaponName)
	if not gunTemplate then
		return
	end

	-- 1. EQUIP RIGHT HAND
	if isDual or singleWieldHand == "Right" then
		equippedGunModel = gunTemplate:Clone()
		equippedGunModel.Parent = currentViewmodel
		local rightArm = currentViewmodel:FindFirstChild("Right Arm") or currentViewmodel:FindFirstChild("RightHand")

		if rightArm and equippedGunModel.PrimaryPart then
			equippedGunModel:PivotTo(rightArm.CFrame * GRIP_OFFSET)

			local weld = Instance.new("WeldConstraint")
			weld.Part0 = rightArm
			weld.Part1 = equippedGunModel.PrimaryPart
			weld.Parent = equippedGunModel.PrimaryPart
		end
	end

	-- 2. EQUIP LEFT HAND
	if isDual or singleWieldHand == "Left" then
		equippedLeftGunModel = gunTemplate:Clone()
		equippedLeftGunModel.Parent = currentViewmodel
		local leftArm = currentViewmodel:FindFirstChild("Left Arm") or currentViewmodel:FindFirstChild("LeftHand")

		if leftArm and equippedLeftGunModel.PrimaryPart then
			equippedLeftGunModel:PivotTo(leftArm.CFrame * GRIP_OFFSET)

			local weld2 = Instance.new("WeldConstraint")
			weld2.Part0 = leftArm
			weld2.Part1 = equippedLeftGunModel.PrimaryPart
			weld2.Parent = equippedLeftGunModel.PrimaryPart
		end
	end

	-- Strip physics
	for _, part in pairs(currentViewmodel:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.CanCollide = false
			part.Massless = true
		end
	end

	-- 3. UPDATE ARM VISIBILITY
	local showRight = isDual or singleWieldHand == "Right"
	local showLeft = isDual or singleWieldHand == "Left"
	updateArmVisibility(showRight, showLeft)
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
		else
			warn("ViewmodelController: Muzzle not found on " .. gunModel.Name)
		end
	end
	return nil
end

function ViewmodelController.Init()
	print("ViewmodelController: Initializing...")

	if player.Character then
		setupViewmodel(player.Character)
	end

	player.CharacterAdded:Connect(function(char)
		-- THE RACE CONDITION FIX
		task.wait(0.1)
		setupViewmodel(char)
	end)

	RunService.RenderStepped:Connect(onRenderStep)
end

return ViewmodelController

local ProximityMine = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local RaycastUtils = require(shared.Utils:WaitForChild("RaycastUtils"))

local function getTrashCanFolder()
	local trashCan = workspace:FindFirstChild("TrashCan")
	if not trashCan then
		trashCan = Instance.new("Folder")
		trashCan.Name = "TrashCan"
		trashCan.Parent = workspace
	end

	return trashCan
end

ProximityMine.Stats = {
	DisplayName = "Sticky Mine",
	FireRate = 0.5,
	Magazine = 3,
	Category = "Utility",
	DualWieldable = true,
	HasTracer = false,
	Traits = { "One-Handed", "Throwable", "Placeable", "Explosive", "Special" },
	MineBlastRadius = 20,
	MineDamage = 80,
	MineKnockback = 150,
}

local function applyKnockback(origin, targetRoot, targetHum, force)
	if not targetRoot or not targetHum then return end

	-- CRITICAL: Change humanoid state to prevent ground friction
	targetHum:ChangeState(Enum.HumanoidStateType.Freefall)
	targetHum:ChangeState(Enum.HumanoidStateType.Jumping)

	local pushDirection = (targetRoot.Position - origin)
	if pushDirection.Magnitude < 0.1 then
		pushDirection = Vector3.new(0, 1, 0)
	end

	local impulse = (pushDirection.Unit + Vector3.new(0, 0.3, 0)).Unit * force * targetRoot.AssemblyMass
	targetRoot:ApplyImpulse(impulse)

	-- Also apply velocity for extra push
	local velocityPush = (pushDirection.Unit + Vector3.new(0, 0.3, 0)).Unit * force
	targetRoot.AssemblyLinearVelocity = targetRoot.AssemblyLinearVelocity + velocityPush
end

function ProximityMine.FireClient(_player, _hand, camera, _mouseHit)
	return { Origin = camera.CFrame.Position, Direction = camera.CFrame.LookVector }
end

function ProximityMine.FireServer(attacker, payload, onHitCallback)
	local rayResult = RaycastUtils.Raycast(payload.Origin, payload.Direction * 100, { attacker.Character })

	if rayResult then
		-- Safely check if we hit a player
		local hitModel = rayResult.Instance:FindFirstAncestorOfClass("Model")
		local hitHumanoid = hitModel and hitModel:FindFirstChild("Humanoid")

		-- Only deploy if we hit the map (NOT a humanoid)
		if not hitHumanoid then
			-- Create the physical mine
			local mine = Instance.new("Part")
			mine.Size = Vector3.new(1, 0.5, 1)
			mine.Color = Color3.fromRGB(255, 50, 50)
			mine.Material = Enum.Material.Neon
			mine.Anchored = true
			mine.CanCollide = false
			mine:SetAttribute("IsPlacedMine", true)

			-- Stick it to the surface using the raycast Normal
			mine.CFrame = CFrame.lookAt(rayResult.Position, rayResult.Position + rayResult.Normal)
				* CFrame.Angles(math.rad(90), 0, 0)
			mine.Parent = getTrashCanFolder()

			local isDetonated = false
			local triggerRadius = 8 -- Reduced trigger area

			-- Proximity Loop
			task.spawn(function()
				while mine.Parent and not isDetonated do
					task.wait(0.1)
					local overlapParams = OverlapParams.new()
					overlapParams.FilterDescendantsInstances = { mine }
					overlapParams.FilterType = Enum.RaycastFilterType.Exclude

					local partsInRadius = workspace:GetPartBoundsInRadius(mine.Position, triggerRadius, overlapParams)

					for _, part in ipairs(partsInRadius) do
						local model = part:FindFirstAncestorOfClass("Model")
						if model and model:FindFirstChild("Humanoid") then
							isDetonated = true

							local humanoid = model:FindFirstChild("Humanoid")
							local targetRoot = model:FindFirstChild("HumanoidRootPart")

							if humanoid and humanoid.Health > 0 and targetRoot then
								-- Deal damage
								humanoid:TakeDamage(ProximityMine.Stats.MineDamage)
								onHitCallback({ Instance = targetRoot, Position = mine.Position }, ProximityMine.Stats.MineDamage, false)

								-- Apply knockback using our custom system (MUCH more reliable)
								applyKnockback(mine.Position, targetRoot, humanoid, ProximityMine.Stats.MineKnockback)
							end

							mine:Destroy()
							break
						end
					end
				end
			end)

			-- Auto-destroy mine after 30 seconds to prevent lag
			game.Debris:AddItem(mine, 30)
		end
	end
end

return ProximityMine

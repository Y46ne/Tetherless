local CombatService = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local weaponsFolder = sharedFolder:WaitForChild("Weapons")

local DamageLogService = require(script.Parent.DamageLogService)

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local shootEvent = remoteEvents:WaitForChild("Shoot")
local hitmarkerEvent
local damageFeedbackEvent

function CombatService.Init()
	hitmarkerEvent = remoteEvents:FindFirstChild("Hitmarker") or Instance.new("RemoteEvent", remoteEvents)
	hitmarkerEvent.Name = "Hitmarker"

	damageFeedbackEvent = remoteEvents:FindFirstChild("DamageFeedback") or Instance.new("RemoteEvent", remoteEvents)
	damageFeedbackEvent.Name = "DamageFeedback"

	shootEvent.OnServerEvent:Connect(function(player, weaponName, payload, hand)
		local character = player.Character
		if not character or not character:FindFirstChild("Humanoid") then return end

		-- Check the specific hand string sent by the client
		if character:GetAttribute(hand .. "Weapon") ~= weaponName then return end

		local moduleNode = weaponsFolder:FindFirstChild(weaponName)
		if moduleNode then
			local weaponModule = require(moduleNode)

			if weaponModule.FireServer then
				weaponModule.FireServer(player, payload, function(rayResult, finalDamage, isHeadshot)
					local hitPart = rayResult.Instance
					local model = hitPart:FindFirstAncestorOfClass("Model")
					if not model then return end

					if model:GetAttribute("IsDroppedWeapon") then
						-- Trickshot logic or destroy
						model:Destroy()
						return
					end

					local humanoid = model:FindFirstChild("Humanoid")
					if humanoid and humanoid.Health > 0 then
						humanoid:TakeDamage(finalDamage)
						local victimPlayer = Players:GetPlayerFromCharacter(model)
						if victimPlayer then
							DamageLogService.LogDamage(victimPlayer, player.Name, weaponName, finalDamage, isHeadshot)
							damageFeedbackEvent:FireClient(victimPlayer, finalDamage, player.Name, isHeadshot)
						end
						hitmarkerEvent:FireClient(player, isHeadshot)
					end
				end)
			end
		end
	end)
end

return CombatService
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
local bulletTracerEvent

-- Effect manager to safely apply and restore per-character glow effects
local activeEffects = setmetatable({}, { __mode = "k" }) -- weak keys (character)

local function ensureEffectEntry(character)
	local entry = activeEffects[character]
	if not entry then
		entry = { orig = {}, hitCount = 0, frozen = false }
		-- capture originals lazily when first needed
		activeEffects[character] = entry
	end
	return entry
end

local function captureOriginalsIfNeeded(character, entry)
	if next(entry.orig) then
		return
	end
	for _, part in pairs(character:GetDescendants()) do
		if part:IsA("BasePart") then
			entry.orig[part] = { Color = part.Color, Material = part.Material, Transparency = part.Transparency }
		end
	end
end

local function restoreOriginals(character)
	local entry = activeEffects[character]
	if not entry then
		return
	end
	for part, data in pairs(entry.orig) do
		if part and part.Parent then
			part.Material = data.Material
			part.Color = data.Color
			part.Transparency = data.Transparency
		end
	end
	entry.orig = {}
	entry.hitCount = 0
	entry.frozen = false
	activeEffects[character] = nil
end

local function applyHitGlow(character)
	if not character or not character.Parent then
		return
	end
	local entry = ensureEffectEntry(character)
	captureOriginalsIfNeeded(character, entry)

	entry.hitCount = entry.hitCount + 1
	-- Apply red glow
	for part, _ in pairs(entry.orig) do
		if part and part.Parent then
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(255, 0, 0)
			part.Transparency = 0.3
		end
	end

	-- After duration, decrement and maybe restore
	task.delay(0.15, function()
		if not character or not character.Parent then
			return
		end
		local e = activeEffects[character]
		if not e then
			return
		end
		e.hitCount = math.max(0, e.hitCount - 1)
		if e.hitCount == 0 and not e.frozen then
			restoreOriginals(character)
		end
	end)
end

local function applyFrozenGlow(character)
	if not character or not character.Parent then
		return
	end
	local entry = ensureEffectEntry(character)
	captureOriginalsIfNeeded(character, entry)

	entry.frozen = true
	-- Apply blue glow
	for part, _ in pairs(entry.orig) do
		if part and part.Parent then
			part.Material = Enum.Material.Neon
			part.Color = Color3.fromRGB(0, 150, 255)
			part.Transparency = 0.2
		end
	end
end

local function clearFrozenGlow(character)
	if not character then
		return
	end
	local entry = activeEffects[character]
	if not entry then
		return
	end
	entry.frozen = false
	if entry.hitCount == 0 then
		restoreOriginals(character)
	end
end

function CombatService.Init()
	hitmarkerEvent = remoteEvents:FindFirstChild("Hitmarker") or Instance.new("RemoteEvent", remoteEvents)
	hitmarkerEvent.Name = "Hitmarker"

	damageFeedbackEvent = remoteEvents:FindFirstChild("DamageFeedback") or Instance.new("RemoteEvent", remoteEvents)
	damageFeedbackEvent.Name = "DamageFeedback"

	bulletTracerEvent = remoteEvents:FindFirstChild("BulletTracer") or Instance.new("RemoteEvent", remoteEvents)
	bulletTracerEvent.Name = "BulletTracer"

	shootEvent.OnServerEvent:Connect(function(player, weaponName, payload, hand)
		local character = player.Character
		if not character or not character:FindFirstChild("Humanoid") then
			return
		end

		-- Check the specific hand string sent by the client
		if character:GetAttribute(hand .. "Weapon") ~= weaponName then
			return
		end

		local moduleNode = weaponsFolder:FindFirstChild(weaponName)
		if moduleNode then
			local weaponModule = require(moduleNode)

			if weaponModule.FireServer then
				local muzzlePos = payload.Origin

				weaponModule.FireServer(player, payload, function(rayResult, finalDamage, isHeadshot)
					-- Send tracer to all clients
					if rayResult and rayResult.Position then
						bulletTracerEvent:FireAllClients(muzzlePos, rayResult.Position, player.Name)
					end

					local hitPart = rayResult.Instance
					local model = hitPart:FindFirstAncestorOfClass("Model")
					if not model then
						return
					end

					if model:GetAttribute("IsDroppedWeapon") then
						-- Trickshot logic or destroy
						model:Destroy()
						return
					end

					local humanoid = model:FindFirstChild("Humanoid")
					if humanoid and humanoid.Health > 0 then
						humanoid:TakeDamage(finalDamage)
						-- Apply red glow effect when hit
						task.spawn(function()
							applyHitGlow(model)
						end)
						-- Apply frozen glow if being hit by taser
						if model:GetAttribute("IsFrozen") then
							task.spawn(function()
								applyFrozenGlow(model)
							end)
						end
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

	-- Listen for IsFrozen attribute changes to apply blue glow
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			character:GetAttributeChangedSignal("IsFrozen"):Connect(function()
				if character:GetAttribute("IsFrozen") then
					task.spawn(function()
						applyFrozenGlow(character)
					end)
				else
					task.spawn(function()
						clearFrozenGlow(character)
					end)
				end
			end)
		end)
	end)

	-- Handle existing players
	for _, player in pairs(Players:GetPlayers()) do
		if player.Character then
			player.Character:GetAttributeChangedSignal("IsFrozen"):Connect(function()
				if player.Character:GetAttribute("IsFrozen") then
					task.spawn(function()
						applyFrozenGlow(player.Character)
					end)
				else
					task.spawn(function()
						clearFrozenGlow(player.Character)
					end)
				end
			end)
		end
	end
end

return CombatService

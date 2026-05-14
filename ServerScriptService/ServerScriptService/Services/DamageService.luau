-- DamageService (formerly CombatService)
-- Validates incoming Shoot events from clients and applies damage server-side.
-- Also manages visual feedback: hit glow (red edge outline) and freeze glow (blue edge outline).
-- Uses Highlight instances instead of material swaps so the character's appearance is never mutated.

local CombatService = {}

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local weaponsFolder = sharedFolder:WaitForChild("Weapons")
local DamageLogService = require(script.Parent.DamageLogService)

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local shootEvent = remoteEvents:WaitForChild("Shoot")
local hitmarkerEvent
local damageFeedbackEvent
local bulletTracerEvent
local weaponFiredEvent

-- Briefly flashes a red outline around a character when they take damage.
-- Uses Highlight so the character's material/color is never changed.
-- Multiple overlapping hits each get their own Highlight (they stack fine).
local function applyHitGlow(character)
	if not character or not character.Parent then
		return
	end

	local highlight = Instance.new("Highlight")
	highlight.Adornee = character
	highlight.FillColor = Color3.fromRGB(255, 50, 50)
	highlight.FillTransparency = 0.85   -- very faint fill so only the edge reads
	highlight.OutlineColor = Color3.fromRGB(255, 30, 30)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop  -- visible even through obstacles for clarity
	highlight.Parent = character

	Debris:AddItem(highlight, 0.15)
end

-- Adds a persistent blue edge outline while the player is frozen by a Taser.
-- Only one frozen highlight per character; duplicate calls are ignored.
local function applyFrozenGlow(character)
	if not character or not character.Parent then
		return
	end
	if character:FindFirstChild("FrozenHighlight") then
		return  -- already applied; Taser hit again while still frozen
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "FrozenHighlight"
	highlight.Adornee = character
	highlight.FillColor = Color3.fromRGB(0, 180, 255)
	highlight.FillTransparency = 0.6    -- visible fill so the freeze looks substantial
	highlight.OutlineColor = Color3.fromRGB(130, 220, 255)
	highlight.OutlineTransparency = 0
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded  -- respects geometry (more grounded feel)
	highlight.Parent = character
end

-- Removes the frozen highlight when IsFrozen clears.
local function clearFrozenGlow(character)
	if not character then
		return
	end
	local highlight = character:FindFirstChild("FrozenHighlight")
	if highlight then
		highlight:Destroy()
	end
end

-- Hooks up the IsFrozen attribute listener for one character so freeze glow
-- tracks the Taser state automatically without needing to be called on every hit.
local function watchFreezeAttribute(character)
	character:GetAttributeChangedSignal("IsFrozen"):Connect(function()
		if character:GetAttribute("IsFrozen") then
			applyFrozenGlow(character)
		else
			clearFrozenGlow(character)
		end
	end)
end

function CombatService.Init()
	if not remoteEvents:FindFirstChild("Hitmarker") then
		local e = Instance.new("RemoteEvent")
		e.Name = "Hitmarker"
		e.Parent = remoteEvents
	end
	hitmarkerEvent = remoteEvents:WaitForChild("Hitmarker")

	if not remoteEvents:FindFirstChild("DamageFeedback") then
		local e = Instance.new("RemoteEvent")
		e.Name = "DamageFeedback"
		e.Parent = remoteEvents
	end
	damageFeedbackEvent = remoteEvents:WaitForChild("DamageFeedback")

	if not remoteEvents:FindFirstChild("BulletTracer") then
		local e = Instance.new("RemoteEvent")
		e.Name = "BulletTracer"
		e.Parent = remoteEvents
	end
	bulletTracerEvent = remoteEvents:WaitForChild("BulletTracer")

	if not remoteEvents:FindFirstChild("WeaponFired") then
		local e = Instance.new("RemoteEvent")
		e.Name = "WeaponFired"
		e.Parent = remoteEvents
	end
	weaponFiredEvent = remoteEvents:WaitForChild("WeaponFired")

	shootEvent.OnServerEvent:Connect(function(player, weaponName, payload, hand)
		local character = player.Character
		if not character or not character:FindFirstChild("Humanoid") then
			return
		end

		-- Confirm the client actually has this weapon in this hand before trusting the payload.
		-- Prevents a client from firing any weapon at any time.
		if character:GetAttribute(hand .. "Weapon") ~= weaponName then
			return
		end

		local moduleNode = weaponsFolder:FindFirstChild(weaponName)
		if not moduleNode then
			return
		end

		local weaponModule = require(moduleNode)
		if not weaponModule.FireServer then
			return
		end

		-- Tell all clients a valid shot was fired so they can play the 3D sound.
		-- SoundController on the shooter's client ignores this (already played locally).
		weaponFiredEvent:FireAllClients(player.Name, weaponName)

		local muzzlePos = payload.Origin
		weaponModule.FireServer(player, payload, function(rayResult, finalDamage, isHeadshot)
			-- Broadcast tracer to all clients; the shooter already drew their own client-side tracer,
			-- so the client filters out its own name to avoid a duplicate.
			if rayResult and rayResult.Position then
				bulletTracerEvent:FireAllClients(muzzlePos, rayResult.Position, player.Name)
			end

			local hitPart = rayResult.Instance
			local model = hitPart:FindFirstAncestorOfClass("Model")
			if not model then
				return
			end

			-- Shooting a dropped weapon destroys it (trickshot mechanic).
			if model:GetAttribute("IsDroppedWeapon") then
				model:Destroy()
				return
			end

			local humanoid = model:FindFirstChild("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid:TakeDamage(finalDamage)
				applyHitGlow(model)

				local victimPlayer = Players:GetPlayerFromCharacter(model)
				if victimPlayer then
					DamageLogService.LogDamage(victimPlayer, player.Name, weaponName, finalDamage, isHeadshot)
					damageFeedbackEvent:FireClient(victimPlayer, finalDamage, player.Name, isHeadshot)
				end
				hitmarkerEvent:FireClient(player, isHeadshot)
			end
		end)
	end)

	-- Watch freeze state for all players present now and in the future.
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(watchFreezeAttribute)
	end)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			watchFreezeAttribute(player.Character)
		end
	end
end

return CombatService

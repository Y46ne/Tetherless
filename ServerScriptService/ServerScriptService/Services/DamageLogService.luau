local DamageLogService = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")

local KillFeedService = require(script.Parent.KillFeedService)

-- We need a new RemoteEvent to send the Death Recap to the client
local deathRecapEvent = remoteEvents:FindFirstChild("DeathRecap")
if not deathRecapEvent then
	deathRecapEvent = Instance.new("RemoteEvent")
	deathRecapEvent.Name = "DeathRecap"
	deathRecapEvent.Parent = remoteEvents
end

-----------------------------
-- STATE VARIABLES --
-----------------------------
-- This table holds the active history for every player in the server
-- Format: activeLogs[PlayerName] = { {Hitter="Name", Weapon="Gun", Damage=20, Headshot=true}, ... }
local activeLogs = {}

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

-- Call this from your WeaponService whenever a bullet hits!
function DamageLogService.LogDamage(victimPlayer, hitterName, weaponName, damageAmount, isHeadshot)
	if not victimPlayer then return end

	local victimName = victimPlayer.Name

	-- Create a log table for them if they don't have one
	if not activeLogs[victimName] then
		activeLogs[victimName] = {}
	end

	-- Insert the specific hit data
	table.insert(activeLogs[victimName], {
		Hitter = hitterName,
		Weapon = weaponName,
		Damage = math.floor(damageAmount),
		Headshot = isHeadshot,
		Time = tick()
	})

	-- Optional: Prevent the log from getting infinitely long if someone is just slowly taking 1 damage forever
	if #activeLogs[victimName] > 15 then
		table.remove(activeLogs[victimName], 1)
	end
end

function DamageLogService.Init()
	print("DamageLogService: Initializing...")

	-- 1. TRACK WHEN PLAYERS JOIN
	Players.PlayerAdded:Connect(function(player)

		player.CharacterAdded:Connect(function(char)
			-- WIPE THE LOG ON SPAWN
			activeLogs[player.Name] = {}

			local hum = char:WaitForChild("Humanoid")

			hum.Died:Connect(function()
				local finalLog = activeLogs[player.Name] or {}

				-- FIRE DEATH RECAP (For the victim's screen)
				deathRecapEvent:FireClient(player, finalLog)

				-- DETERMINE KILLER FOR FEED
				if #finalLog > 0 then
					local lastHit = finalLog[#finalLog]
					local isTrickshot = string.find(lastHit.Weapon, "TRICKSHOT") ~= nil

					KillFeedService.OnPlayerKilled(
						player.Name, 
						lastHit.Hitter, 
						lastHit.Weapon, 
						isTrickshot, 
						lastHit.Headshot
					)
				else
					KillFeedService.OnPlayerKilled(player.Name, "The Void", "Environment", false, false)
				end
			end)
		end)
	end)

	-- 2. TRACK WHEN PLAYERS LEAVE (Fixed!)
	-- We connect this to the Service, not the individual player object.
	Players.PlayerRemoving:Connect(function(player)
		if activeLogs[player.Name] then
			activeLogs[player.Name] = nil
			print("DamageLogService: Cleaned up logs for " .. player.Name)
		end
	end)
end

return DamageLogService
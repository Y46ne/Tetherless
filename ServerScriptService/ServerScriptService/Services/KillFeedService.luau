local KillFeedService = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
local killFeedEvent = remoteEvents:WaitForChild("KillFeed")
local MatchManager = require(script.Parent.MatchManager)

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------

-- This is called by DamageLogService when a player actually dies
function KillFeedService.OnPlayerKilled(victimName, killerName, weaponName, isTrickshot, isHeadshot)
	-- 1. BROADCAST TO UI
	killFeedEvent:FireAllClients(victimName, killerName, weaponName, isTrickshot, isHeadshot)

	-- 2. TELL MATCH MANAGER SOMEONE DIED
	MatchManager.OnPlayerDied(victimName)

	-- Debug log
	print(string.format("KILLFEED: %s killed %s", killerName, victimName))
end

function KillFeedService.Init()
	print("KillFeedService: Initializing...")
end

return KillFeedService
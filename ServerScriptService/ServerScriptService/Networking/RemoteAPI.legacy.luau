-----------------------------
-- SERVICES --
-----------------------------
local replicatedStorage = game:GetService('ReplicatedStorage')

-----------------------------
-- VARIABLES --
-----------------------------
local eventsTable = {
	'Shoot',
	'DropWeapon',
	'PickupDroppedWeapon',
	'PickupOffhand',
	'SyncAmmo',
	'Hitmarker',
	'KillFeed',
	'DamageFeedback',
	'MatchStatus'
}

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function createRemoteEvents()
	-- Create RemoteEvents Folder
	local remoteEventsFolder = replicatedStorage:FindFirstChild('RemoteEvents') or Instance.new('Folder')
	remoteEventsFolder.Name = 'RemoteEvents'
	remoteEventsFolder.Parent = replicatedStorage

	for _, eventName in pairs(eventsTable) do
		if not remoteEventsFolder:FindFirstChild(eventName) then
			local remoteEvent = Instance.new('RemoteEvent')
			remoteEvent.Name = eventName
			remoteEvent.Parent = remoteEventsFolder
		end
	end

	local sharedFolder = replicatedStorage:FindFirstChild('Shared') or Instance.new('Folder')
	sharedFolder.Name = 'Shared'
	sharedFolder.Parent = replicatedStorage

	if not sharedFolder:FindFirstChild("UpdateHUD") then
		local bindable = Instance.new("BindableEvent")
		bindable.Name = "UpdateHUD"
		bindable.Parent = sharedFolder
	end
end

-----------------------------
-- PUBLIC FUNCTIONS --
-----------------------------
local ServerNetwork = {}

createRemoteEvents()

function ServerNetwork.BroadcastMatchStatus(statusText, timerValue)
	local matchStatusEvent = replicatedStorage:FindFirstChild('RemoteEvents'):FindFirstChild('MatchStatus')
	if matchStatusEvent then
		matchStatusEvent:FireAllClients(statusText, timerValue)
	end
end

return ServerNetwork
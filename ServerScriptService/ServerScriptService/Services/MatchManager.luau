local MatchManager = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local ServerNetwork = require(script.Parent.Parent:WaitForChild("Networking"):WaitForChild("ServerNetwork"))
local SpawnerService = require(script.Parent:WaitForChild("WeaponSpawnerService"))
local assetsFolder = ReplicatedStorage:WaitForChild("Assets")

-- RemoteEvents (ensure exists)
local remoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
if not remoteEvents then
	remoteEvents = Instance.new("Folder")
	remoteEvents.Name = "RemoteEvents"
	remoteEvents.Parent = ReplicatedStorage
end
local spectateEvent = remoteEvents:FindFirstChild("SpectatePlayer")
if not spectateEvent then
	spectateEvent = Instance.new("RemoteEvent")
	spectateEvent.Name = "SpectatePlayer"
	spectateEvent.Parent = remoteEvents
end
local stopSpectateEvent = remoteEvents:FindFirstChild("StopSpectating")
if not stopSpectateEvent then
	stopSpectateEvent = Instance.new("RemoteEvent")
	stopSpectateEvent.Name = "StopSpectating"
	stopSpectateEvent.Parent = remoteEvents
end

-----------------------------
-- SETTINGS --
-----------------------------
local MIN_PLAYERS = 1
local MAX_PLAYERS = 4
local PRE_ROUND_TIME = 3
local ROUND_TIME_LIMIT = 120

-- THE NEW HIERARCHY
local ROUNDS_TO_WIN_MAP = 4
local MAPS_TO_WIN_GAME = 3

-----------------------------
-- STATE VARIABLES --
-----------------------------
MatchManager.States = {
	WAITING = "WAITING",
	GAME_START = "GAME_START",
	MAP_START = "MAP_START",
	PRE_ROUND = "PRE_ROUND",
	IN_PROGRESS = "IN_PROGRESS",
	ROUND_END = "ROUND_END",
	MAP_END = "MAP_END",
	GAME_END = "GAME_END",
}

local currentMatchState = MatchManager.States.WAITING
local roundScores = {}
local alivePlayers = {}
local currentMapModel = nil
local lastRoundWinner = nil
local overallGameWinner = nil

-- Trackers for the UI
local currentMapCount = 0
local currentRoundCount = 0
local currentRoundTimer = 0
local currentMapMusic = nil

local function getSfxFolder(folderName)
	local sfxRoot = assetsFolder:FindFirstChild("Sfx")
	if not sfxRoot then
		return nil
	end

	return sfxRoot:FindFirstChild(folderName)
end

local function stopMapMusic()
	if currentMapMusic then
		currentMapMusic:Stop()
		currentMapMusic:Destroy()
		currentMapMusic = nil
	end
end

local function playRandomMapMusic()
	stopMapMusic()

	local musicFolder = getSfxFolder("backgroundMusic")
	if not musicFolder then
		warn("MATCH MANAGER: Assets/Sfx/backgroundMusic folder is missing")
		return
	end

	local candidates = {}
	for _, child in ipairs(musicFolder:GetChildren()) do
		if child:IsA("Sound") then
			table.insert(candidates, child)
		end
	end

	if #candidates == 0 then
		warn("MATCH MANAGER: No Sound objects found in Assets/Sfx/backgroundMusic")
		return
	end

	local picked = candidates[math.random(1, #candidates)]
	local sound = picked:Clone()
	sound.Name = "CurrentMapMusic"
	sound.Looped = true
	sound.Parent = SoundService
	sound:Play()

	currentMapMusic = sound
end

local function playRoundStartCountdownSfx()
	local roundsFolder = getSfxFolder("Rounds")
	if not roundsFolder then
		warn("MATCH MANAGER: Assets/Sfx/Rounds folder is missing")
		return PRE_ROUND_TIME
	end

	local template = roundsFolder:FindFirstChild("3-2-1-go")
	if not template or not template:IsA("Sound") then
		warn("MATCH MANAGER: Sound '3-2-1-go' missing in Assets/Sfx/Rounds")
		return PRE_ROUND_TIME
	end

	local countdownSound = template:Clone()
	countdownSound.Name = "RoundCountdown"
	countdownSound.Looped = false
	countdownSound.Parent = SoundService

	local duration = countdownSound.TimeLength
	if duration <= 0 then
		local loaded = pcall(function()
			countdownSound.Loaded:Wait()
		end)
		if loaded then
			duration = countdownSound.TimeLength
		end
	end

	countdownSound:Play()
	Debris:AddItem(countdownSound, math.max(duration, PRE_ROUND_TIME) + 1)

	if duration > 0 then
		return duration
	end

	return PRE_ROUND_TIME
end

-----------------------------
-- MAP MANAGEMENT --
-----------------------------
local function loadRandomMap()
	if currentMapModel then
		currentMapModel:Destroy()
		currentMapModel = nil
	end

	local mapsFolder = ServerStorage:FindFirstChild("Maps")
	if mapsFolder then
		local availableMaps = mapsFolder:GetChildren()
		if #availableMaps > 0 then
			local pickedMap = availableMaps[math.random(1, #availableMaps)]
			currentMapModel = pickedMap:Clone()
			currentMapModel.Name = "CurrentActiveMap"
			currentMapModel.Parent = workspace

			SpawnerService.SetupMapSpawners(currentMapModel)
			return true
		end
	end

	warn("MATCH MANAGER: No maps found in ServerStorage.Maps!")
	return false
end

-----------------------------
-- SCORE MANAGEMENT --
-----------------------------
local function resetGameScores()
	for _, player in pairs(Players:GetPlayers()) do
		player:SetAttribute("Wins", 0)
		player:SetAttribute("RoundWins", 0)
	end
end

local function resetRoundScores()
	roundScores = {}
	for _, player in pairs(Players:GetPlayers()) do
		roundScores[player.Name] = 0
		player:SetAttribute("RoundWins", 0)
	end
end

-----------------------------
-- PLAYER MANAGEMENT --
-----------------------------
local function broadcastStatus(statusText, timerValue)
	ServerNetwork.BroadcastMatchStatus(statusText, timerValue)
	print("[MATCH] " .. statusText)
end

local function clearRoundGroundItems()
	local trashCan = Workspace:FindFirstChild("TrashCan")
	if not trashCan then
		return
	end

	for _, item in ipairs(trashCan:GetChildren()) do
		item:Destroy()
	end
end

local function freezePlayers(player, shouldFreeze)
	local char = player.Character
	if char then
		char:SetAttribute("IsFrozen", shouldFreeze)
		local root = char:FindFirstChild("HumanoidRootPart")
		if root then
			root.Anchored = shouldFreeze
		end
	end
end

local function setupRound()
	alivePlayers = {}

	local spawnFolder = currentMapModel
		and (currentMapModel:FindFirstChild("Spawns") or currentMapModel:FindFirstChild("TempSpawns"))
	local points = spawnFolder and spawnFolder:GetChildren() or {}

	for i, player in pairs(Players:GetPlayers()) do
		-- WRAPPED IN task.spawn so nobody holds up the loading line!
		task.spawn(function()
			-- Force loading only here (auto-load is disabled elsewhere)
			player:LoadCharacterAsync()
			local char = player.Character or player.CharacterAdded:Wait()

			-- Tell client to stop spectating (they now have a character)
			if stopSpectateEvent and stopSpectateEvent.FireClient then
				pcall(function()
					stopSpectateEvent:FireClient(player)
				end)
			end

			local forceField = char:FindFirstChildOfClass("ForceField")
			if forceField then
				forceField:Destroy()
			end

			local targetPoint = points[i] or points[1]
			if targetPoint then
				char:PivotTo(targetPoint.CFrame + Vector3.new(0, 5, 0))
				freezePlayers(player, true)
			end

			alivePlayers[player.Name] = true
		end)
	end
end

local function removePlayerCharacterByName(playerName)
	local p = Players:FindFirstChild(playerName)
	if p and p.Character then
		-- destroy the character model to prevent accidental respawn (CharacterAutoLoads is disabled)
		p.Character:Destroy()
	end
end

-----------------------------
-- KILLFEED EVENT --
-----------------------------
function MatchManager.OnPlayerDied(deadPlayerName)
	if currentMatchState ~= MatchManager.States.IN_PROGRESS then
		return
	end

	alivePlayers[deadPlayerName] = nil

	-- Remove the dead player's character so they remain as a spectator until next round
	removePlayerCharacterByName(deadPlayerName)

	-- Notify the dead player to spectate someone still alive
	local deadPlayerObj = Players:FindFirstChild(deadPlayerName)
	if deadPlayerObj then
		local targetName = nil
		for name, alive in pairs(alivePlayers) do
			if alive then
				targetName = name
				break
			end
		end
		if spectateEvent and spectateEvent.FireClient then
			spectateEvent:FireClient(deadPlayerObj, targetName)
		end
	end

	local aliveCount = 0
	local lastAliveName = nil

	for name, isAlive in pairs(alivePlayers) do
		if isAlive then
			aliveCount = aliveCount + 1
			lastAliveName = name
		end
	end

	if aliveCount <= 1 then
		if lastAliveName then
			lastRoundWinner = lastAliveName
			roundScores[lastAliveName] = (roundScores[lastAliveName] or 0) + 1

			local winnerPlayer = Players:FindFirstChild(lastAliveName)
			if winnerPlayer then
				winnerPlayer:SetAttribute("RoundWins", roundScores[lastAliveName])
			end

			if roundScores[lastAliveName] >= ROUNDS_TO_WIN_MAP then
				currentMatchState = MatchManager.States.MAP_END
			else
				broadcastStatus(
					lastAliveName .. " WINS ROUND! (" .. roundScores[lastAliveName] .. "/" .. ROUNDS_TO_WIN_MAP .. ")",
					0
				)
				currentMatchState = MatchManager.States.ROUND_END
			end
		else
			broadcastStatus("ROUND DRAW!", 0)
			currentMatchState = MatchManager.States.ROUND_END
		end
	end
end

-----------------------------
-- THE MAIN STATE MACHINE --
-----------------------------
function MatchManager.StartLoop()
	task.spawn(function()
		while true do
			local playerCount = #Players:GetPlayers()

			if currentMatchState == MatchManager.States.WAITING then
				if playerCount >= MIN_PLAYERS and playerCount <= MAX_PLAYERS then
					currentMatchState = MatchManager.States.GAME_START
				else
					if playerCount < MIN_PLAYERS then
						broadcastStatus("WAITING FOR PLAYERS...", 0)
					else
						broadcastStatus("MATCH FULL! MAX 4 PLAYERS.", 0)
					end
				end
			elseif currentMatchState == MatchManager.States.GAME_START then
				broadcastStatus("INITIALIZING MATCH...", 3)
				task.wait(3)
				resetGameScores()
				currentMapCount = 0
				currentMatchState = MatchManager.States.MAP_START
			elseif currentMatchState == MatchManager.States.MAP_START then
				broadcastStatus("LOADING NEXT MAP...", 3)
				if loadRandomMap() then
					playRandomMapMusic()
				end
				resetRoundScores()
				currentMapCount = currentMapCount + 1
				currentRoundCount = 0
				task.wait(3)
				currentMatchState = MatchManager.States.PRE_ROUND
			elseif currentMatchState == MatchManager.States.PRE_ROUND then
				clearRoundGroundItems()
				SpawnerService.ResetMapSpawners(currentMapModel)
				setupRound()
				currentRoundCount = currentRoundCount + 1
				currentRoundTimer = ROUND_TIME_LIMIT
				local countdownDuration = playRoundStartCountdownSfx()
				local countdownStep = math.max(0.2, countdownDuration / PRE_ROUND_TIME)

				for i = PRE_ROUND_TIME, 1, -1 do
					broadcastStatus("PREPARING...", i)
					task.wait(countdownStep)
				end
				for _, p in pairs(Players:GetPlayers()) do
					freezePlayers(p, false)
				end
				currentMatchState = MatchManager.States.IN_PROGRESS
			elseif currentMatchState == MatchManager.States.IN_PROGRESS then
				if currentRoundTimer > 0 then
					currentRoundTimer = currentRoundTimer - 1
					broadcastStatus(
						string.format("MAP %d - ROUND %d", currentMapCount, currentRoundCount),
						currentRoundTimer
					)
					task.wait(1)
				else
					broadcastStatus("TIME UP! ROUND DRAW!", 0)
					task.wait(2)
					currentMatchState = MatchManager.States.ROUND_END
				end
			elseif currentMatchState == MatchManager.States.ROUND_END then
				task.wait(4)
				currentMatchState = MatchManager.States.PRE_ROUND
			elseif currentMatchState == MatchManager.States.MAP_END then
				broadcastStatus(lastRoundWinner .. " WINS THE MAP!", 5)

				local winnerPlayer = Players:FindFirstChild(lastRoundWinner)
				if winnerPlayer then
					local currentMapWins = winnerPlayer:GetAttribute("Wins") or 0
					winnerPlayer:SetAttribute("Wins", currentMapWins + 1)

					if (currentMapWins + 1) >= MAPS_TO_WIN_GAME then
						overallGameWinner = lastRoundWinner
						currentMatchState = MatchManager.States.GAME_END
					else
						task.wait(5)
						currentMatchState = MatchManager.States.MAP_START
					end
				end
			elseif currentMatchState == MatchManager.States.GAME_END then
				broadcastStatus("CHAMPION: " .. overallGameWinner .. "!", 8)
				task.wait(8)
				stopMapMusic()

				if currentMapModel then
					currentMapModel:Destroy()
					currentMapModel = nil
				end
				for _, p in pairs(Players:GetPlayers()) do
					task.spawn(function()
						p:LoadCharacterAsync()
					end)
				end

				currentMatchState = MatchManager.States.WAITING
			end

			task.wait(0.1)
		end
	end)
end

function MatchManager.Init()
	print("MatchManager: Initializing...")

	-- Disable Roblox's automatic respawn globally; rounds are the only time we load characters.
	Players.CharacterAutoLoads = false

	Players.PlayerAdded:Connect(function(player)
		-- If a character exists on join, remove it so player spectates until round start
		if player.Character then
			player.Character:Destroy()
		end
	end)

	-- Ensure existing players follow the same rule
	for _, p in pairs(Players:GetPlayers()) do
		if p.Character then
			p.Character:Destroy()
		end
	end

	MatchManager.StartLoop()
end

return MatchManager

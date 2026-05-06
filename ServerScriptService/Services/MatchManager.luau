local MatchManager = {}

-----------------------------
-- SERVICES & REFERENCES --
-----------------------------
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local sharedFolder = ReplicatedStorage:WaitForChild("Shared")
local updateHUD = sharedFolder:WaitForChild("UpdateHUD")

-----------------------------
-- SETTINGS --
-----------------------------
local MIN_PLAYERS = 1 -- Set to 1 if you are testing by yourself!
local PRE_ROUND_TIME = 3
local ROUND_MAX_DURATION = 120 -- 2 minute rounds
local ROUNDS_TO_WIN_MATCH = 4

-----------------------------
-- STATE VARIABLES --
-----------------------------
MatchManager.States = {
	WAITING = "WAITING",
	INTRO = "INTRO",
	PRE_ROUND = "PRE_ROUND",
	IN_PROGRESS = "IN_PROGRESS",
	ROUND_END = "ROUND_END",
	MATCH_END = "MATCH_END"
}

local currentMatchState = MatchManager.States.WAITING
local matchScores = {} -- Tracks how many ROUNDS a player has won
local alivePlayers = {} -- Tracks who is currently alive in the round

-----------------------------
-- PRIVATE FUNCTIONS --
-----------------------------
local function broadcastStatus(statusText, timerValue)
	updateHUD:Fire(statusText, timerValue)
	print("[MATCH] " .. statusText)
end

local function resetMatchData()
	matchScores = {}
	for _, player in pairs(Players:GetPlayers()) do
		matchScores[player.Name] = 0
	end
end

local function setupRound()
	alivePlayers = {}
	local spawnPoints = workspace:FindFirstChild("TempSpawns")
	local points = spawnPoints and spawnPoints:GetChildren() or {}

	for i, player in pairs(Players:GetPlayers()) do
		-- 1. Give them a perfectly clean body (Heals them, removes weapons, removes ragdoll)
		player:LoadCharacterAsync()
		
		

		-- Wait a tiny fraction of a second for the body to load in
		local char = player.Character or player.CharacterAdded:Wait()
		local root = char:WaitForChild("HumanoidRootPart")
		
		local forceField = char:FindFirstChildOfClass("ForceField")
		if forceField then
			forceField:Destroy()
		end

		-- 2. Teleport & Freeze
		local targetPoint = points[i] or points[1]
		if targetPoint then
			char:PivotTo(targetPoint.CFrame + Vector3.new(0, 5, 0))
			char:SetAttribute("IsFrozen", true)
			root.Anchored = true
		end

		-- 3. Mark them as alive for this round
		alivePlayers[player.Name] = true
	end
end

local function unfreezePlayers()
	for _, player in pairs(Players:GetPlayers()) do
		local char = player.Character
		if char then
			char:SetAttribute("IsFrozen", false)
			local root = char:FindFirstChild("HumanoidRootPart")
			if root then root.Anchored = false end
		end
	end
end

-----------------------------
-- PUBLIC FUNCTIONS (CALLED BY KILLFEED) --
-----------------------------
function MatchManager.OnPlayerDied(deadPlayerName)
	if currentMatchState ~= MatchManager.States.IN_PROGRESS then return end

	-- Remove them from the living
	alivePlayers[deadPlayerName] = nil

	-- Count who is left
	local aliveCount = 0
	local lastAliveName = nil

	for name, isAlive in pairs(alivePlayers) do
		if isAlive then
			aliveCount = aliveCount + 1
			lastAliveName = name
		end
	end

	-- If only one person is left, they win the round!
	if aliveCount <= 1 then
		if lastAliveName then
			matchScores[lastAliveName] = (matchScores[lastAliveName] or 0) + 1
			broadcastStatus(lastAliveName .. " WINS THE ROUND!", 0)

			-- Did they win the whole game?
			if matchScores[lastAliveName] >= ROUNDS_TO_WIN_MATCH then
				currentMatchState = MatchManager.States.MATCH_END
			else
				currentMatchState = MatchManager.States.ROUND_END
			end
		else
			-- Tie / mutual destruction
			broadcastStatus("ROUND DRAW!", 0)
			currentMatchState = MatchManager.States.ROUND_END
		end
	end
end

-----------------------------
-- THE MAIN LOOP --
-----------------------------
function MatchManager.StartLoop()
	task.spawn(function()
		while true do
			local playerCount = #Players:GetPlayers()

			if currentMatchState == MatchManager.States.WAITING then
				if playerCount >= MIN_PLAYERS then
					currentMatchState = MatchManager.States.INTRO
				else
					broadcastStatus("WAITING FOR PLAYERS...", 0)
				end

			elseif currentMatchState == MatchManager.States.INTRO then
				broadcastStatus("INITIALIZING SIMULATION...", 5)
				task.wait(5) -- Your future VR Cutscene
				resetMatchData()
				currentMatchState = MatchManager.States.PRE_ROUND

			elseif currentMatchState == MatchManager.States.PRE_ROUND then
				setupRound()
				for i = PRE_ROUND_TIME, 1, -1 do
					broadcastStatus("PREPARING...", i)
					task.wait(1)
				end
				unfreezePlayers()
				currentMatchState = MatchManager.States.IN_PROGRESS

			elseif currentMatchState == MatchManager.States.IN_PROGRESS then
				-- We just wait here until the KillFeed tells us only 1 player is left
				task.wait(1) 

			elseif currentMatchState == MatchManager.States.ROUND_END then
				-- Pause so players can watch the ragdoll/spectate before the reset
				task.wait(4)
				currentMatchState = MatchManager.States.PRE_ROUND -- Loop back to the next round!

			elseif currentMatchState == MatchManager.States.MATCH_END then
				broadcastStatus("MATCH COMPLETE!", 5)
				task.wait(5)
				currentMatchState = MatchManager.States.WAITING -- Send them back to the lobby
			end

			task.wait(0.1)
		end
	end)
end

function MatchManager.Init()
	print("MatchManager: Initializing...")
	MatchManager.StartLoop()
end

return MatchManager
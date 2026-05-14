-- SoundController
-- Plays weapon fire sounds for both the local player and remote players.
--
-- LOCAL  : WeaponController calls SoundController.PlayFire(weaponName) on every shot.
--          Sound plays from the camera — no 3D falloff, always full volume.
--
-- REMOTE : DamageService broadcasts "WeaponFired" to all clients.
--          If the shooter is not us, we play a 3D sound from their character.
--          If the shooter IS us, we ignore it (local sound already played above).
--
-- All sound IDs live in ReplicatedStorage/Shared/Configs/WeaponSounds.luau.
-- To add a sound, paste the asset ID there — nothing else needs to change.

local SoundController = {}

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local shared = ReplicatedStorage:WaitForChild("Shared")
local WeaponSounds = require(shared:WaitForChild("Configs"):WaitForChild("WeaponSounds"))

-- Cache of Sound objects so we don't create a new one on every shot
local localSoundCache = {} -- [weaponName] = Sound (parented to camera)

-- Returns (or lazily creates) the local Sound for a weapon.
-- Parented to the camera so it plays as a flat 2D sound with no distance falloff.
local function getLocalSound(weaponName)
	if localSoundCache[weaponName] then
		return localSoundCache[weaponName]
	end

	local data = WeaponSounds[weaponName]
	if not data or not data.Fire or data.Fire == "rbxassetid://0" then
		return nil  -- ID not set yet, silently skip
	end

	local sound = Instance.new("Sound")
	sound.Name = "WeaponFire_" .. weaponName
	sound.SoundId = data.Fire
	sound.Volume = 1
	sound.PlaybackSpeed = data.Pitch or 1.0
	sound.RollOffMaxDistance = 0
	sound.Parent = camera

	localSoundCache[weaponName] = sound
	return sound
end

-- Plays the fire sound for the local player's weapon.
-- Called directly by WeaponController on every shot.
function SoundController.PlayFire(weaponName)
	local sound = getLocalSound(weaponName)
	if sound then
		-- Stop then Play so rapid fire doesn't queue up; each shot restarts the sound
		sound:Stop()
		sound:Play()
	end
end

-- Plays a 3D fire sound anchored to a remote player's HumanoidRootPart.
-- The sound follows the character automatically because it's parented to it.
local function playRemoteFire(shooterName, weaponName)
	local data = WeaponSounds[weaponName]
	if not data or not data.Fire or data.Fire == "rbxassetid://0" then
		return
	end

	-- Find the shooter's character
	local shooter = Players:FindFirstChild(shooterName)
	local char = shooter and shooter.Character
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if not root then return end

	-- Reuse a cached Sound on this root if one exists, otherwise create it
	local soundName = "RemoteFire_" .. weaponName
	local existing = root:FindFirstChild(soundName)
	if not existing then
		existing = Instance.new("Sound")
		existing.Name = soundName
		existing.SoundId = data.Fire
		existing.Volume = 0.85
		existing.PlaybackSpeed = data.Pitch or 1.0
		existing.RollOffMaxDistance = 120
		existing.RollOffMinDistance = 5
		existing.Parent = root
	end

	existing:Stop()
	existing:Play()
end

function SoundController.Init()
	-- Listen for remote weapon fire events broadcast by DamageService
	local remoteEvents = ReplicatedStorage:WaitForChild("RemoteEvents")
	local weaponFiredEvent = remoteEvents:WaitForChild("WeaponFired")

	weaponFiredEvent.OnClientEvent:Connect(function(shooterName, weaponName)
		-- Skip if this is our own shot — we already played the local sound
		if shooterName == player.Name then return end
		playRemoteFire(shooterName, weaponName)
	end)
end

return SoundController

-- DEPRECATED: This file proxies to the new centralized Configs/AnimationIDs for backward compatibility.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local shared = ReplicatedStorage:WaitForChild("Shared")
local configs = shared:WaitForChild("Configs")
return require(configs:WaitForChild("AnimationIDs"))

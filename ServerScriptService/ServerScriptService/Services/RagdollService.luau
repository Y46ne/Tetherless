local RagdollService = {}

function RagdollService.Init()
	print("RagdollService: Initializing...")

	game.Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(char)
			local humanoid = char:WaitForChild("Humanoid")

			-- 1. PREVENT THE LEGO SHATTER
			humanoid.BreakJointsOnDeath = false

			humanoid.Died:Connect(function()
				-- 2. BUILD THE RAGDOLL
				for _, descendant in ipairs(char:GetDescendants()) do
					if descendant:IsA("Motor6D") and descendant.Name ~= "RootJoint" then
						local part0 = descendant.Part0
						local part1 = descendant.Part1

						if part0 and part1 then
							-- Create the floppy joint
							local socket = Instance.new("BallSocketConstraint")
							local a0 = Instance.new("Attachment")
							local a1 = Instance.new("Attachment")

							a0.Parent = part0
							a1.Parent = part1
							socket.Parent = descendant.Parent

							socket.Attachment0 = a0
							socket.Attachment1 = a1

							a0.CFrame = descendant.C0
							a1.CFrame = descendant.C1

							-- Add limits so their arms don't spin like helicopters (too much)
							socket.LimitsEnabled = true
							socket.TwistLimitsEnabled = true

							-- Break the rigid motor
							descendant:Destroy()
						end
					end
				end

				-- 3. THE GOOFY LAUNCH
				-- We apply a random, massive physics impulse to send them flying when they die
				local hrp = char:FindFirstChild("HumanoidRootPart")
				if hrp then
					local randomX = math.random(-2000, 2000)
					local upwardForce = math.random(1500, 3500) -- Shoots them upward
					local randomZ = math.random(-2000, 2000)

					hrp:ApplyImpulse(Vector3.new(randomX, upwardForce, randomZ))
				end
			end)
		end)
	end)
end

return RagdollService
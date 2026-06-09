local LowUI = require(game.ReplicatedStorage.LowUI)

local Window = LowUI.new({
	Title   = "Low-UI",
	Keybind = Enum.KeyCode.RightShift,
})

-- ── Tab: Main ─────────────────────────────────
local Main = Window:AddTab({ Name = "Main" })

Main:AddSection("Combat")

Main:AddButton({
	Name = "Kill Aura",
	Desc = "Attack players in range",
	Callback = function()
		Window:Notify({ Title = "Kill Aura", Desc = "Activated!", Duration = 2 })
	end,
})

Main:AddButton({
	Name = "Teleport to Player",
	Desc = "Teleports to nearest player",
	Callback = function()
		print("Teleport!")
	end,
})

local speedToggle = Main:AddToggle({
	Name    = "Speed Boost",
	Desc    = "Doubles walk speed",
	Default = false,
	Callback = function(v)
		local h = game.Players.LocalPlayer.Character and
			game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
		if h then h.WalkSpeed = v and 32 or 16 end
	end,
})

Main:AddSection("Movement")

local walkSlider = Main:AddSlider({
	Name    = "Walk Speed",
	Min     = 8, Max = 100, Default = 16, Step = 2,
	Callback = function(v)
		local h = game.Players.LocalPlayer.Character and
			game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
		if h then h.WalkSpeed = v end
	end,
})

local jumpSlider = Main:AddSlider({
	Name    = "Jump Power",
	Min     = 50, Max = 400, Default = 50, Step = 10,
	Callback = function(v)
		local h = game.Players.LocalPlayer.Character and
			game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
		if h then h.JumpPower = v end
	end,
})

-- ── Tab: Visual ───────────────────────────────
local Visual = Window:AddTab({ Name = "Visual" })

Visual:AddSection("ESP")

Visual:AddToggle({ Name = "Player ESP",  Default = false, Callback = function(v) print("ESP:", v) end })
Visual:AddToggle({ Name = "Box ESP",     Default = false, Callback = function(v) print("Box:", v) end })
Visual:AddToggle({ Name = "Name Tags",   Default = false, Callback = function(v) print("Names:", v) end })

Visual:AddSection("Chams")

Visual:AddDropdown({
	Name    = "Chams Color",
	Options = { "White", "Red", "Blue", "Green", "Yellow", "Cyan" },
	Default = "White",
	Callback = function(v) print("Color:", v) end,
})

Visual:AddSlider({
	Name = "ESP Distance", Min = 50, Max = 1000, Default = 500, Step = 50,
	Suffix = "m",
	Callback = function(v) print("Distance:", v) end,
})

Visual:AddSection("Info")

local pingVal = Visual:AddValue({ Name = "Ping",  Value = "—", Suffix = " ms" })
local fpsVal  = Visual:AddValue({ Name = "FPS",   Value = "—" })
local posVal  = Visual:AddValue({ Name = "Position", Value = "—" })

-- ── Tab: Misc ─────────────────────────────────
local Misc = Window:AddTab({ Name = "Misc" })

Misc:AddSection("Game")

Misc:AddButton({
	Name = "Rejoin",
	Desc = "Reconnect to the server",
	Callback = function()
		game:GetService("TeleportService"):Teleport(game.PlaceId)
	end,
})

Misc:AddButton({
	Name = "Copy Username",
	Callback = function()
		if setclipboard then
			setclipboard(game.Players.LocalPlayer.Name)
			Window:Notify({ Title = "Copied", Desc = game.Players.LocalPlayer.Name, Duration = 2 })
		end
	end,
})

Misc:AddSection("Misc Toggles")

Misc:AddToggle({ Name = "Anti-AFK",    Default = false, Callback = function(v) print("Anti-AFK:", v) end })
Misc:AddToggle({ Name = "No Clip",     Default = false, Callback = function(v) print("Noclip:", v)  end })
Misc:AddToggle({ Name = "Infinite Jump", Default = false,
	Callback = function(v)
		if v then
			game:GetService("UserInputService").JumpRequest:Connect(function()
				local h = game.Players.LocalPlayer.Character and
					game.Players.LocalPlayer.Character:FindFirstChild("Humanoid")
				if h then h:ChangeState(Enum.HumanoidStateType.Jumping) end
			end)
		end
	end,
})

-- ── Live stats loop ───────────────────────────
local frames, last = 0, tick()
game:GetService("RunService").RenderStepped:Connect(function()
	frames += 1
	local now = tick()
	if now - last >= 1 then
		fpsVal:Set(frames)
		local ok, ping = pcall(function()
			return math.floor(game.Players.LocalPlayer:GetNetworkPing() * 1000)
		end)
		if ok then pingVal:Set(ping) end

		local char = game.Players.LocalPlayer.Character
		if char and char:FindFirstChild("HumanoidRootPart") then
			local p = char.HumanoidRootPart.Position
			posVal:Set(string.format("%d, %d, %d", p.X, p.Y, p.Z))
		end

		frames, last = 0, now
	end
end)

-- ── Welcome ───────────────────────────────────
task.delay(0.5, function()
	Window:Notify({
		Title    = "Low-UI v2.0",
		Desc     = "Press RightShift to toggle",
		Duration = 4,
	})
end)

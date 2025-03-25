-- Linoria Setup
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

local Window = Library:CreateWindow({
    Title = "Blue Lock: Rivals",
    Footer = "Blue Lock: Rivals V1.5",
    Icon = 1234567890,
    AutoShow = true,
    ShowCustomCursor = true,
    Size = UDim2.new(0, 915, 0, 467),
    Position = UDim2.new(0.5, -457.5, 0.5, -233.5),
})

local Tabs = {
    Main = Window:AddTab("Welcome", "user"),
    AutoDribble = Window:AddTab("Auto Dribble", "volleyball"),
    AutoSpin = Window:AddTab("Auto Spin", "coins"),
    Misc = Window:AddTab("Misc", "settings"),

}

local Options = Library.Options
local Toggles = Library.Toggles

--------------------------------------------------
-- 👋 Welcome Tab
--------------------------------------------------

local playerName = game.Players.LocalPlayer.DisplayName
Tabs.Main:AddLeftGroupbox("Info"):AddLabel("Welcome, " .. playerName .. "!\nThis is the main hub for Blue Lock: Rivals.", true)

--------------------------------------------------
-- 🕹️ AUTO DRIBBLE TAB
--------------------------------------------------


local DribbleGroup = Tabs.AutoDribble:AddLeftGroupbox("Auto Dribble")

DribbleGroup:AddToggle("AutoDribbleToggle", {
	Text = "Enable Auto Dribble",
	Default = false,
	Tooltip = "Automatically performs dribbles when someone tries to slide",
})

-- Auto Dribble Logic
Toggles.AutoDribbleToggle:OnChanged(function(enabled)
	getgenv().AutoDribbleSettings = {
		Enabled = enabled,
		range = 30 -- pode ajustar aqui se quiser
	}

	if enabled then
		Library:Notify("🕹️ Auto Dribble Enabled!", 4)

		local ReplicatedStorage = game:GetService("ReplicatedStorage")
		local Players = game:GetService("Players")
		local RunService = game:GetService("RunService")

		local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
		local function GetCharacter()
			local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
			return char, char:WaitForChild("HumanoidRootPart"), char:WaitForChild("Humanoid")
		end

		local Character, HRP, Humanoid = GetCharacter()
		LocalPlayer.CharacterAdded:Connect(function()
			Character, HRP, Humanoid = GetCharacter()
		end)

		local DribbleEvent = ReplicatedStorage.Packages.Knit.Services.BallService.RE.Dribble
		local Animations = require(ReplicatedStorage.Assets.Animations)

		local function LoadDribbleAnimation(style)
			if Animations.Dribbles[style] then
				local anim = Instance.new("Animation")
				anim.AnimationId = Animations.Dribbles[style]
				return Humanoid:LoadAnimation(anim)
			end
		end

		local function IsSliding(plr)
			if plr ~= LocalPlayer and plr.Character then
				local char = plr.Character
				local slideValue = char:FindFirstChild("Values") and char.Values:FindFirstChild("Sliding")
				local hum = char:FindFirstChildOfClass("Humanoid")
				return (slideValue and slideValue.Value) or (hum and hum.MoveDirection.Magnitude > 0 and hum.WalkSpeed == 0)
			end
		end

		local function IsEnemy(plr)
			return LocalPlayer.Team and plr.Team and LocalPlayer.Team ~= plr.Team
		end

		local function PerformDribble(distance)
			if getgenv().AutoDribbleSettings.Enabled and Character:FindFirstChild("Values") and Character.Values.HasBall.Value then
				DribbleEvent:FireServer()
				local style = LocalPlayer:FindFirstChild("PlayerStats") and LocalPlayer.PlayerStats:FindFirstChild("Style") and LocalPlayer.PlayerStats.Style.Value
				local anim = LoadDribbleAnimation(style)
				if anim then
					anim:Play()
					anim:AdjustSpeed(math.clamp(1 + (10 - distance) / 10, 1, 2))
				end
				local ball = workspace:FindFirstChild("Football")
				if ball then
					ball.AssemblyLinearVelocity = Vector3.new()
					ball.CFrame = HRP.CFrame * CFrame.new(0, -2.5, 0)
				end
			end
		end

		-- Conecta o loop no Heartbeat
		getgenv().AutoDribbleConnection = RunService.Heartbeat:Connect(function()
			if getgenv().AutoDribbleSettings.Enabled and Character and HRP then
				for _, plr in pairs(Players:GetPlayers()) do
					if IsEnemy(plr) and IsSliding(plr) then
						local theirHRP = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
						if theirHRP then
							local dist = (theirHRP.Position - HRP.Position).Magnitude
							if dist <= getgenv().AutoDribbleSettings.range then
								PerformDribble(dist)
								break
							end
						end
					end
				end
			end
		end)

	else
		if getgenv().AutoDribbleConnection then
			getgenv().AutoDribbleConnection:Disconnect()
			getgenv().AutoDribbleConnection = nil
		end
		Library:Notify("⏹️ Auto Dribble Disabled!", 4)
	end
end)



--------------------------------------------------
-- 🌀 AUTO SPIN TAB
--------------------------------------------------

local AutoGroup = Tabs.AutoSpin:AddLeftGroupbox("Auto Spin")

-- Dropdown com estilos
local styleList = {}
local abilitiesFolder = game:GetService("ReplicatedStorage")
	:WaitForChild("Controllers")
	:WaitForChild("AbilityController")
	:WaitForChild("Abilities")

for _, style in ipairs(abilitiesFolder:GetChildren()) do
	table.insert(styleList, style.Name)
end

AutoGroup:AddDropdown("StyleDropdown", {
	Values = styleList,
	Default = 1,
	Multi = false,
	Text = "Select Target Style",
	Tooltip = "Spins until you get this style",
})

AutoGroup:AddToggle("LuckySpinToggle", {
	Text = "Use Lucky Spin?",
	Default = false,
	Tooltip = "Enable Lucky Spin instead of the normal one",
})

AutoGroup:AddToggle("AutoSpinToggle", {
	Text = "Enable Auto Spin",
	Default = false,
	Tooltip = "Will spin until you get the selected style",
})

Toggles.AutoSpinToggle:OnChanged(function(enabled)
	if not Options.StyleDropdown or not Options.StyleDropdown.Value then
		Library:Notify("⚠️ Please select a target style first.", 5)
		Toggles.AutoSpinToggle:SetValue(false)
		return
	end

	local targetStyle = Options.StyleDropdown.Value
	local player = game:GetService("Players").LocalPlayer
	local styleValue = player:WaitForChild("PlayerStats"):WaitForChild("Style")

	local spinFunction = game:GetService("ReplicatedStorage")
		:WaitForChild("Packages"):WaitForChild("Knit")
		:WaitForChild("Services"):WaitForChild("StyleService")
		:WaitForChild("RE"):WaitForChild("Spin")

	if enabled then
		Library:Notify("🎰 Auto Spin started for: " .. targetStyle, 5)

		local styleConnection
		styleConnection = styleValue:GetPropertyChangedSignal("Value"):Connect(function()
			if styleValue.Value == targetStyle then
				Library:Notify("✅ Got target style: " .. targetStyle, 6)
				Toggles.AutoSpinToggle:SetValue(false)
				if styleConnection then styleConnection:Disconnect() end
			end
		end)

		task.spawn(function()
			while Toggles.AutoSpinToggle and Toggles.AutoSpinToggle.Value do
				pcall(function()
					local useLucky = Toggles.LuckySpinToggle and Toggles.LuckySpinToggle.Value
					spinFunction:FireServer(useLucky)
				end)
				task.wait(0.3)
			end
		end)
	else
		Library:Notify("⏹️ Auto Spin stopped.", 4)
	end
end)

--------------------------------------------------
-- ⚙️ MISC TAB
--------------------------------------------------

local MenuGroup = Tabs.Misc:AddLeftGroupbox("Menu")
local CooldownGroup = Tabs.Misc:AddRightGroupbox("Cooldown")

CooldownGroup:AddButton("No Ability Cooldown", function()
	local AbilityController = require(game:GetService("ReplicatedStorage"):WaitForChild("Controllers"):WaitForChild("AbilityController"))

	if not getgenv().OriginalCooldownHooked then
		getgenv().OriginalCooldownHooked = hookfunction(AbilityController.AbilityCooldown, function(self)
			return
		end)

		Library:Notify("✅ No Ability Cooldown Enabled.\nRejoin the game to disable it.", 6)
	else
		Library:Notify("⚠️ No Ability Cooldown is already active.", 4)
	end
end)

MenuGroup:AddLabel("Menu bind")
	:AddKeyPicker("MenuKeybind", {
		Default = "RightShift",
		NoUI = true,
		Text = "Menu keybind"
	})

MenuGroup:AddButton("Unload Script", function()
	Library:Unload()
end)

Library.ToggleKeybind = Options.MenuKeybind

-- Theme/Config

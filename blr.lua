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

Toggles.AutoDribbleToggle:OnChanged(function(enabled)
    getgenv().AutoDribbleSettings = {
        Enabled = enabled,
        range = 30
    }

    if enabled then
        Library:Notify("🕹️ Auto Dribble Enabled!", 4)

        local R = game:GetService("ReplicatedStorage")
        local P = game:GetService("Players")
        local U = game:GetService("RunService")

        local L = P.LocalPlayer or P.PlayerAdded:Wait()
        local function i()
            local c = L.Character or L.CharacterAdded:Wait()
            return c, c:WaitForChild("HumanoidRootPart"), c:WaitForChild("Humanoid")
        end

        local C, H, M = i()
        L.CharacterAdded:Connect(function()
            C, H, M = i()
        end)

        local B = R.Packages.Knit.Services.BallService.RE.Dribble
        local A = require(R.Assets.Animations)

        local G = function(s)
            if A.Dribbles[s] then
                local a = Instance.new("Animation")
                a.AnimationId = A.Dribbles[s]
                return M:LoadAnimation(a)
            end
        end

        local T = function(p)
            if p ~= L and p.Character then
                local c = p.Character
                local v = c:FindFirstChild("Values") and c.Values:FindFirstChild("Sliding")
                local h = c:FindFirstChildOfClass("Humanoid")
                return (v and v.Value) or (h and h.MoveDirection.Magnitude > 0 and h.WalkSpeed == 0)
            end
        end

        local O = function(p)
            return L.Team and p.Team and L.Team ~= p.Team
        end

        local D = function(d)
            if getgenv().AutoDribbleSettings.Enabled and C:FindFirstChild("Values") and C.Values.HasBall.Value then
                B:FireServer()
                local s = L:FindFirstChild("PlayerStats") and L.PlayerStats:FindFirstChild("Style") and L.PlayerStats.Style.Value
                local t = G(s)
                if t then
                    t:Play()
                    t:AdjustSpeed(math.clamp(1 + (10 - d) / 10, 1, 2))
                end
                local f = workspace:FindFirstChild("Football")
                if f then
                    f.AssemblyLinearVelocity = Vector3.new()
                    f.CFrame = H.CFrame * CFrame.new(0, -2.5, 0)
                end
            end
        end

        getgenv().AutoDribbleConnection = U.Heartbeat:Connect(function()
            if getgenv().AutoDribbleSettings.Enabled and C and H then
                for _, p in pairs(P:GetPlayers()) do
                    if O(p) and T(p) then
                        local r = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                        if r then
                            local d = (r.Position - H.Position).Magnitude
                            if d < getgenv().AutoDribbleSettings.range then
                                D(d)
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

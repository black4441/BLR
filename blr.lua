-- Linoria Setup
local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/"
local Library = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

-- Window
local Window = Library:CreateWindow({
    Title = "Blue Lock: Rivals",
    Footer = "Blue Lock: Rivals V1.0",
    Icon = 1234567890,
    AutoShow = true,
    ShowCustomCursor = true,
    Size = UDim2.new(0, 915, 0, 467),
    Position = UDim2.new(0.5, -457.5, 0.5, -233.5),
})

-- Tabs
local Tabs = {
    Main = Window:AddTab("Welcome", "user"),
    AutoSpin = Window:AddTab("Auto Spin", "coins"),
    Misc = Window:AddTab("Misc", "settings"),
}

local playerName = game.Players.LocalPlayer.DisplayName
Tabs.Main:AddLeftGroupbox("Info"):AddLabel("Welcome, " .. playerName .. "!\nThis is the main hub for Blue Lock: Rivals.", true)
--------------------------------------------------
-- 🌀 AUTO SPIN TAB
--------------------------------------------------

local AutoGroup = Tabs.AutoSpin:AddLeftGroupbox("Auto Spin")

-- Coleta de estilos via pastas
local styleList = {}
local abilitiesFolder = game:GetService("ReplicatedStorage")
    :WaitForChild("Controllers")
    :WaitForChild("AbilityController")
    :WaitForChild("Abilities")

for _, style in ipairs(abilitiesFolder:GetChildren()) do
    table.insert(styleList, style.Name)
end

-- Dropdown de estilos
AutoGroup:AddDropdown("StyleDropdown", {
    Values = styleList,
    Default = 1,
    Multi = false,
    Text = "Select Target Style",
    Tooltip = "Spins until you get this style",
    Callback = function(value)
        print("🎯 Target style selected:", value)
    end
})

-- Toggle Auto Spin
AutoGroup:AddToggle("AutoSpinToggle", {
    Text = "Enable Auto Spin",
    Default = false,
    Tooltip = "Will spin until you get the selected style",
    Callback = function(enabled)
        local Options = Library.Options
        if not Options.StyleDropdown or not Options.StyleDropdown.Value then
            Library:Notify("⚠️ Please select a target style first.", 5)
            Options.AutoSpinToggle:SetValue(false)
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
                print("[🔁] Rolled style:", styleValue.Value)

                if styleValue.Value == targetStyle then
                    Library:Notify("✅ Got target style: " .. targetStyle, 6)
                    Options.AutoSpinToggle:SetValue(false)
                    if styleConnection then styleConnection:Disconnect() end
                end
            end)

            task.spawn(function()
                while Options.AutoSpinToggle.Value do
                    pcall(function()
                        spinFunction:FireServer()
                    end)
                    task.wait(0.3)
                end
            end)
        else
            Library:Notify("⏹️ Auto Spin stopped.", 4)
        end
    end
})

--------------------------------------------------
-- 🛠️ MISC TAB (THEME / CONFIG)
--------------------------------------------------


local Options = Library.Options
local MenuGroup = Tabs.Misc:AddLeftGroupbox("Menu")
MenuGroup:AddLabel("Menu bind")
    :AddKeyPicker("MenuKeybind", {
        Default = "RightShift",
        NoUI = true,
        Text = "Menu keybind"
    })

MenuGroup:AddButton("Unload", function()
    Library:Unload()
end)
Library.ToggleKeybind = Options.MenuKeybind
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({ "MenuKeybind" })

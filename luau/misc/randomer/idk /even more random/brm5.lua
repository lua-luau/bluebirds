--[[
    Male Model Highlighter - Powered by Fluent
    Press INSERT to open/close the menu
    Default: Enabled (ON)
]]

repeat task.wait() until game:IsLoaded()

local Fluent = loadstring(game:HttpGet("https://github.com/acsu123/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/acsu123/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/acsu123/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "Male Highlighter",
    SubTitle = "by YourName",
    TabWidth = 160,
    Size = UDim2.fromOffset(480, 360),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.Insert
})

-- Services
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Settings (will be saved automatically)
local Options = Fluent.Options

-- Main Tab
local MainTab = Window:AddTab({ Title = "Main", Icon = "user" })

MainTab:AddParagraph({
    Title = "Male Model Highlighter",
    Content = "Automatically highlights all models named 'Male' in Workspace.\nDefault: Enabled | Press Insert to toggle menu."
})

local Toggle = MainTab:AddToggle("HighlightToggle", {
    Title = "Enable Highlighter",
    Default = true,
    Callback = function() end
})

local ColorPicker = MainTab:AddColorpicker("HighlightColor", {
    Title = "Fill Color",
    Default = Color3.fromRGB(0, 255, 200),
    Callback = function() end
})

local OutlineColorPicker = MainTab:AddColorpicker("OutlineColor", {
    Title = "Outline Color",
    Default = Color3.fromRGB(255, 255, 255),
    Callback = function() end
})

local TransparencySlider = MainTab:AddSlider("Transparency", {
    Title = "Fill Transparency",
    Min = 0,
    Max = 100,
    Default = 75,
    Rounding = 1,
    Callback = function() end
})

-- Highlight Management
local function ApplyHighlights()
    if not Toggle.Value then
        -- Remove all Male highlights when disabled
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Highlight") and obj.Adornee and obj.Adornee.Name == "Male" then
                obj:Destroy()
            end
        end
        return
    end

    for _, model in ipairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model.Name == "Male" and model.PrimaryPart then
            local highlight = model:FindFirstChildOfClass("Highlight")
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Adornee = model
                highlight.Parent = model
            end

            highlight.FillColor = ColorPicker.Value
            highlight.OutlineColor = OutlineColorPicker.Value
            highlight.FillTransparency = TransparencySlider.Value / 100
            highlight.OutlineTransparency = 0
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        end
    end
end

-- Real-time update on every change
Toggle:OnChanged(function() ApplyHighlights() end)
ColorPicker:OnChanged(function() ApplyHighlights() end)
OutlineColorPicker:OnChanged(function() ApplyHighlights() end)
TransparencySlider:OnChanged(function() ApplyHighlights() end)

-- Efficient loop
RunService.Heartbeat:Connect(ApplyHighlights)

-- Auto-save settings
SaveManager:SetLibrary(Fluent)
SaveManager:IgnoreThemeSettings()
SaveManager:SetFolder("FluentConfig/MaleHighlighter")
InterfaceManager:SetLibrary(Fluent)
InterfaceManager:SetFolder("FluentConfig")

SaveManager:BuildConfigSection(MainTab)
InterfaceManager:BuildInterfaceSection(MainTab)

Window:SelectTab(1)

Fluent:Notify({
    Title = "Male Highlighter",
    Content = "Loaded successfully! Press Insert to open menu.",
    Duration = 5
})

-- Initial apply
ApplyHighlights()
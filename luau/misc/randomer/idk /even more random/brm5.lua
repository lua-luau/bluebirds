--[[
    Male Model Highlighter - Kavo UI Edition (Solara Compatible)
    Press RightShift to open/close menu
    Default: Enabled (ON)
]]

-- Load Kavo UI Library (most popular & easy for Solara)
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("Male Highlighter", "DarkTheme")

-- Services
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- Settings (defaults)
local Settings = {
    Enabled = true,
    FillColor = Color3.fromRGB(0, 255, 200),
    OutlineColor = Color3.fromRGB(255, 255, 255),
    FillTransparency = 0.75
}

-- Main Tab
local MainTab = Window:NewTab("Main")
local MainSection = MainTab:NewSection("Male Model Highlighter")

MainSection:NewParagraph("Automatically highlights all 'Male' models in Workspace. | Default: ON")

-- Toggle
MainSection:NewToggle("EnableToggle", "Enable Highlighter", function(state)
    Settings.Enabled = state
    if not state then
        -- Clean up highlights when disabled
        for _, obj in pairs(Workspace:GetDescendants()) do
            if obj:IsA("Highlight") and obj.Adornee and obj.Adornee.Name == "Male" then
                obj:Destroy()
            end
        end
    end
end)
local Toggle = MainSection:GetToggle("EnableToggle")
Toggle:Toggle(true)  -- Default ON

-- Color Picker (Fill)
MainSection:NewColorPicker("FillColor", "Fill Color", Color3.fromRGB(0, 255, 200), function(color)
    Settings.FillColor = color
end)

-- Color Picker (Outline)
MainSection:NewColorPicker("OutlineColor", "Outline Color", Color3.fromRGB(255, 255, 255), function(color)
    Settings.OutlineColor = color
end)

-- Transparency Slider
MainSection:NewSlider("TransSlider", "Fill Transparency", 75, 0, function(s)
    Settings.FillTransparency = s / 100
end)

-- Highlight Function
local function ApplyHighlights()
    if not Settings.Enabled then return end

    for _, model in pairs(Workspace:GetChildren()) do
        if model:IsA("Model") and model.Name == "Male" and model.PrimaryPart then
            local highlight = model:FindFirstChildOfClass("Highlight")
            if not highlight then
                highlight = Instance.new("Highlight")
                highlight.Adornee = model
                highlight.Parent = model
                highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            end

            highlight.FillColor = Settings.FillColor
            highlight.OutlineColor = Settings.OutlineColor
            highlight.FillTransparency = Settings.FillTransparency
            highlight.OutlineTransparency = 0
        end
    end
end

-- Real-time updates
spawn(function()
    while true do
        ApplyHighlights()
        wait(0.5)  -- Efficient tick rate (non-blocking)
    end
end)

-- Initial apply
ApplyHighlights()

-- Notification (Kavo built-in)
Library:Notify("Male Highlighter loaded! Press RightShift for menu.", 5)

print("Kavo Male Highlighter ready for Solara! ✨")
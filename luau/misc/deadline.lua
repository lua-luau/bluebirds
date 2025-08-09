--// SETTINGS
local ESP_COLOR = Color3.fromRGB(0, 255, 255)
local CHARACTERS_FOLDER_NAME = "characters"

--// SERVICES
local Players     = game:GetService("Players")
local Workspace   = game:GetService("Workspace")

--// VARIABLES
local LocalPlayer = Players.LocalPlayer
local Characters  = Workspace:WaitForChild(CHARACTERS_FOLDER_NAME)

--// STATE
local ActiveHighlights = {}

--// FUNCTIONS
local function createHighlight(character)
    if not character or character.Name == LocalPlayer.Name or ActiveHighlights[character] then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = ESP_COLOR
    highlight.FillTransparency = 0.5
    highlight.OutlineColor = ESP_COLOR
    highlight.OutlineTransparency = 0
    highlight.Adornee = character
    highlight.Parent = character

    ActiveHighlights[character] = highlight
end

local function removeHighlight(character)
    local highlight = ActiveHighlights[character]
    if highlight then
        highlight:Destroy()
        ActiveHighlights[character] = nil
    end
end

--// APPLY TO EXISTING CHARACTERS
for _, character in ipairs(Characters:GetChildren()) do
    if character.Name ~= LocalPlayer.Name then
        createHighlight(character)
    end
end

--// CHARACTER ADDED / REMOVED
Characters.ChildAdded:Connect(function(child)
    task.wait(0.1) -- wait for model parts to load
    createHighlight(child)
end)

Characters.ChildRemoved:Connect(function(child)
    removeHighlight(child)
end)

--// CLEANUP ON PLAYER EXIT
LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then
        for char in pairs(ActiveHighlights) do
            removeHighlight(char)
        end
    end
end)
--// SETTINGS
local ESP_COLOR = Color3.fromRGB(0, 255, 255)
local CHARACTERS_FOLDER_NAME = "characters"

--// SERVICES
local Players   = game:GetService("Players")
local Workspace = game:GetService("Workspace")

--// VARIABLES
local LocalPlayer = Players.LocalPlayer
local Characters  = Workspace:WaitForChild(CHARACTERS_FOLDER_NAME)

--// STATE
local ActiveHighlights = {}

--// FUNCTIONS
local function createHighlight(character)
    if not character 
        or not character:IsA("Model") 
        or character.Name == LocalPlayer.Name 
        or ActiveHighlights[character] 
    then
        return
    end

    -- Wait for at least one BasePart so the Highlight can attach
    local basePart = character:FindFirstChildWhichIsA("BasePart")
    if not basePart then
        basePart = character:WaitForChildWhichIsA("BasePart", 3) -- timeout to avoid infinite wait
    end
    if not basePart then
        return -- model never had a part
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
    createHighlight(character)
end

--// CHARACTER ADDED / REMOVED
Characters.ChildAdded:Connect(function(child)
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

-- Optional: cleanup if Characters folder is destroyed
Characters.AncestryChanged:Connect(function(_, parent)
    if not parent then
        for char in pairs(ActiveHighlights) do
            removeHighlight(char)
        end
    end
end)
-- PERFECT Highlight ESP for your game (Workspace.Characters > Model)
-- Only highlights real players, ignores dummies and terrain
-- Works instantly, no lag, always on top

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local CharactersFolder = Workspace:WaitForChild("Characters")
local highlights = {}

local function isRealPlayerCharacter(model)
    if not (model and model:IsA("Model") and model.Parent == CharactersFolder) then
        return false
    end
    if model.Name == "Character_C" then return false end -- skip dummy/test character
    if model:FindFirstChild("Humanoid") and model:FindFirstChild("Capsule") then
        return true
    end
    return false
end

local function addHighlight(character)
    if highlights[character] then return end

    -- Skip your own character (in case it ends up as a "Model" too)
    if character == LocalPlayer.Character then return end

    local highlight = Instance.new("Highlight")
    highlight.Adornee = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)         -- Enemy red fill
    highlight.OutlineColor = Color3.fromRGB(255, 255, 0)   -- Bright yellow outline (very visible)
    highlight.FillTransparency = 0.4
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Enabled = true
    highlight.Parent = character -- parent to character so it dies with it

    highlights[character] = highlight
end

local function removeHighlight(character)
    if highlights[character] then
        highlights[character]:Destroy()
        highlights[character] = nil
    end
end

-- Initial scan
for _, obj in ipairs(CharactersFolder:GetChildren()) do
    if isRealPlayerCharacter(obj) then
        addHighlight(obj)
    end
end

-- Live updates (players joining, respawning, dying)
CharactersFolder.ChildAdded:Connect(function(child)
    if isRealPlayerCharacter(child) then
        task.wait(0.2) -- small delay so parts load
        addHighlight(child)
    end
end)

CharactersFolder.ChildRemoved:Connect(function(child)
    removeHighlight(child)
end)

print("Custom Highlight ESP Loaded - Only real players in Characters folder are highlighted!")
-- Grok's Simple Universal Corner Box ESP (Feb 2026)
-- Toggle: Insert key (default) or change to your pref
-- Super lightweight, Drawing API only, players only
-- Copy-paste into executor (Solara/Delta/Wave/etc.)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer
local ESP_ENABLED = true  -- Start on
local TEAM_CHECK = false  -- Set true to ignore teammates
local CORNER_SIZE = 12    -- Pixel size of corner lines
local LINE_THICK = 2      -- Thickness
local BOX_COLOR = Color3.fromRGB(255, 0, 0)  -- Red, change as needed
local TRANSPARENCY = 1    -- Full opaque

local espObjects = {}  -- Store per player

local function WorldToScreen(pos)
    local screen, onScreen = Camera:WorldToScreenPoint(pos)
    return Vector2.new(screen.X, screen.Y), onScreen
end

local function addCorner(from, to)
    return {
        top_left = {from = from, to = Vector2.new(from.X + CORNER_SIZE, from.Y)},
        top_right = {from = to, to = Vector2.new(to.X - CORNER_SIZE, to.Y)},
        bot_left = {from = from, to = Vector2.new(from.X, from.Y + CORNER_SIZE)},
        bot_right = {from = to, to = Vector2.new(to.X, to.Y - CORNER_SIZE)}
    }
end

local function createEsp(player)
    if player == LocalPlayer then return end
    espObjects[player] = {
        lines = {}
    }
end

local function removeEsp(player)
    if espObjects[player] then
        for _, lineData in pairs(espObjects[player].lines) do
            lineData.Visible = false
            lineData:Remove()
        end
        espObjects[player] = nil
    end
end

local function updateEsp()
    if not ESP_ENABLED then
        for player, _ in pairs(espObjects) do
            removeEsp(player)
        end
        return
    end

    for player, esp in pairs(espObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character:FindFirstChild("Humanoid") and player.Character.Humanoid.Health > 0 then
            if TEAM_CHECK and player.Team == LocalPlayer.Team then
                for _, lineData in pairs(esp.lines) do
                    lineData.Visible = false
                end
            else
                local rootPart = player.Character.HumanoidRootPart
                local head = player.Character:FindFirstChild("Head")
                if head then
                    local topPos, topOnScreen = WorldToScreen(head.Position + Vector3.new(0, 0.5, 0))
                    local botPos, botOnScreen = WorldToScreen(rootPart.Position - Vector3.new(0, 3, 0))

                    if topOnScreen and botOnScreen then
                        local corners = addCorner(botPos, topPos)

                        local lines = esp.lines
                        local lineIndex = 1

                        for _, corner in pairs(corners) do
                            local line = lines[lineIndex]
                            if not line then
                                line = Drawing.new("Line")
                                line.Color = BOX_COLOR
                                line.Thickness = LINE_THICK
                                line.Transparency = TRANSPARENCY
                                lines[lineIndex] = line
                            end
                            line.From = corner.from
                            line.To = corner.to
                            line.Visible = true
                            lineIndex += 1
                        end
                    else
                        for _, lineData in pairs(esp.lines) do
                            lineData.Visible = false
                        end
                    end
                else
                    for _, lineData in pairs(esp.lines) do
                        lineData.Visible = false
                    end
                end
            end
        else
            removeEsp(player)
        end
    end
end

-- Init players
for _, player in pairs(Players:GetPlayers()) do
    createEsp(player)
end

Players.PlayerAdded:Connect(createEsp)
Players.PlayerRemoving:Connect(removeEsp)

-- Toggle on Insert key (change Enum.KeyCode.Insert to your key)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.Insert then
        ESP_ENABLED = not ESP_ENABLED
    end
end)

-- Main loop
RunService.RenderStepped:Connect(updateEsp)

print("Grok Corner ESP loaded! Toggle: Insert | Customize vars above.")
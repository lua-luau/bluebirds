-- Grok's Clean 2D Box ESP (2026 edition)
-- Keys: INS = toggle ESP    END = toggle team check    DEL = toggle team colors
--       PGUP = wider boxes   PGDN = thinner boxes

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local UserInput   = game:GetService("UserInputService")
local Workspace   = game:GetService("Workspace")

local Camera      = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings
local ESP = {
    Enabled     = true,
    TeamCheck   = true,           -- hide teammates by default
    TeamColors  = true,
    BaseColor   = Color3.fromRGB(255, 80, 80),
    Thickness   = 1.4,
    Transparency = 0.9,
    MaxDistance = 1200,           -- studs after which boxes fully fade
    WidthRatio  = 0.58,           -- 0.45–0.85 range feels natural
    Filled      = false
}

local boxes = {}   -- player → Drawing Square

local function IsValidTarget(player)
    if not player or player == LocalPlayer then return false end
    local char = player.Character
    if not char then return false end

    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    local root     = char:FindFirstChild("HumanoidRootPart")
    local head     = char:FindFirstChild("Head")

    if not (humanoid and root and head) then return false end
    if humanoid.Health <= 0 or humanoid.Health == math.huge then return false end

    if ESP.TeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then
        return false
    end

    return true
end

local function CreateBox(player)
    if player == LocalPlayer or boxes[player] then return end

    local sq = Drawing.new("Square")
    sq.Thickness   = ESP.Thickness
    sq.Transparency = ESP.Transparency
    sq.Filled      = ESP.Filled
    sq.Visible     = false
    sq.Color       = ESP.BaseColor

    boxes[player] = sq
end

local function UpdateBox(player, box)
    local char = player.Character
    if not char or not IsValidTarget(player) or not ESP.Enabled then
        box.Visible = false
        return
    end

    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not (head and root) then
        box.Visible = false
        return
    end

    -- Slightly dynamic offsets (better than hardcoded 1.4 / 3.8)
    local topPos    = head.Position + Vector3.new(0, head.Size.Y * 0.55 + 0.4, 0)
    local bottomPos = root.Position - Vector3.new(0, root.Size.Y * 0.55 + 2.2, 0)

    local top,  topVisible = Camera:WorldToViewportPoint(topPos)
    local bot, botVisible  = Camera:WorldToViewportPoint(bottomPos)

    if not (topVisible and botVisible) then
        box.Visible = false
        return
    end

    local height = math.abs(bot.Y - top.Y)
    if height < 8 then   -- too small / too far → hide
        box.Visible = false
        return
    end

    local width = height * ESP.WidthRatio

    -- Center point
    local centerX = (top.X + bot.X) * 0.5
    local centerY = (top.Y + bot.Y) * 0.5

    -- Distance fade
    local dist = (root.Position - Camera.CFrame.Position).Magnitude
    local alpha = math.clamp(1 - (dist / ESP.MaxDistance), 0.15, ESP.Transparency)

    box.Size        = Vector2.new(width, height)
    box.Position    = Vector2.new(centerX - width * 0.5, centerY - height * 0.5)
    box.Transparency = alpha

    -- Color
    if ESP.TeamColors and player.Team and player.Team.TeamColor then
        box.Color = player.Team.TeamColor.Color
    else
        box.Color = ESP.BaseColor
    end

    box.Visible = true
end

-- Input handling
UserInput.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    local key = input.KeyCode

    if key == Enum.KeyCode.Insert then
        ESP.Enabled = not ESP.Enabled
        print("ESP " .. (ESP.Enabled and "ON" or "OFF"))

    elseif key == Enum.KeyCode.End then
        ESP.TeamCheck = not ESP.TeamCheck
        print("Team check: " .. (ESP.TeamCheck and "ON" or "OFF"))

    elseif key == Enum.KeyCode.Delete then
        ESP.TeamColors = not ESP.TeamColors
        print("Team colors: " .. (ESP.TeamColors and "ON" or "OFF"))

    elseif key == Enum.KeyCode.PageUp then
        ESP.WidthRatio = math.clamp(ESP.WidthRatio + 0.025, 0.45, 0.85)
        print("Box width ratio: " .. string.format("%.2f", ESP.WidthRatio))

    elseif key == Enum.KeyCode.PageDown then
        ESP.WidthRatio = math.clamp(ESP.WidthRatio - 0.025, 0.45, 0.85)
        print("Box width ratio: " .. string.format("%.2f", ESP.WidthRatio))
    end
end)

-- Initialize existing players
for _, plr in ipairs(Players:GetPlayers()) do
    CreateBox(plr)
    -- Handle respawn
    plr.CharacterAdded:Connect(function()
        task.wait(0.3)  -- small delay for character to fully load
        CreateBox(plr)
    end)
end

-- New players
Players.PlayerAdded:Connect(function(plr)
    CreateBox(plr)
    plr.CharacterAdded:Connect(function()
        task.wait(0.3)
        CreateBox(plr)
    end)
end)

-- Cleanup
Players.PlayerRemoving:Connect(function(plr)
    if boxes[plr] then
        boxes[plr]:Remove()
        boxes[plr] = nil
    end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    for player, box in pairs(boxes) do
        if box then
            UpdateBox(player, box)
        end
    end
end)

print("Grok's 2D Box ESP loaded | INS = toggle | END = teamcheck | DEL = teamcolors | PGUP/PGDN = size")
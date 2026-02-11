-- Grok's Clean Universal 2D Box ESP (Full Rectangle Box - Redone from Scratch)
-- Features: Toggleable (Insert key), Players only, Team check optional
-- Uses single Drawing Square per player for full box
-- Fixed sizing with better head/feet extension + aspect ratio
-- Hides properly when offscreen / dead / invalid

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Config (customize here)
local ESP_ENABLED = true
local TEAM_CHECK = false          -- true to hide teammates
local BOX_COLOR = Color3.fromRGB(255, 0, 0)  -- Red
local BOX_THICKNESS = 1.5
local BOX_TRANSPARENCY = 1
local BOX_FILLED = false          -- true for filled box (semi-transparent if wanted)
local BOX_FILL_TRANSPARENCY = 0.7 -- only if FILLED=true

local espObjects = {}  -- player -> {box = Drawing Square}

local function createBoxForPlayer(player)
    if player == LocalPlayer or espObjects[player] then return end
    
    local box = Drawing.new("Square")
    box.Visible = false
    box.Color = BOX_COLOR
    box.Thickness = BOX_THICKNESS
    box.Transparency = BOX_TRANSPARENCY
    box.Filled = BOX_FILLED
    
    if BOX_FILLED then
        box.Transparency = BOX_FILL_TRANSPARENCY  -- softer fill
    end
    
    espObjects[player] = {box = box}
end

local function destroyBoxForPlayer(player)
    if espObjects[player] then
        espObjects[player].box:Remove()
        espObjects[player] = nil
    end
end

local function isPlayerValid(player)
    if not player or not player.Character then return false end
    
    local char = player.Character
    local humanoid = char:FindFirstChildWhichIsA("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    local head = char:FindFirstChild("Head")
    
    if not humanoid or humanoid.Health <= 0 or not root or not head then
        return false
    end
    
    if TEAM_CHECK and player.Team == LocalPlayer.Team then
        return false
    end
    
    return true
end

local function updateAllBoxes()
    if not ESP_ENABLED then
        for _, obj in pairs(espObjects) do
            obj.box.Visible = false
        end
        return
    end

    for player, obj in pairs(espObjects) do
        if isPlayerValid(player) then
            local char = player.Character
            local head = char.Head
            local root = char.HumanoidRootPart
            
            -- Extend bounds slightly for better visual fit
            local topPos = head.Position + Vector3.new(0, 1.2, 0)    -- above head
            local bottomPos = root.Position - Vector3.new(0, 3.8, 0) -- below feet
            
            local topScreen, topOnScreen = Camera:WorldToViewportPoint(topPos)
            local botScreen, botOnScreen = Camera:WorldToViewportPoint(bottomPos)
            
            if topOnScreen and botOnScreen then
                local height = math.abs(botScreen.Y - topScreen.Y)
                local width = height * 0.6  -- universal aspect \~0.6 for Roblox rigs (tweak 0.55-0.65 if needed)
                
                local centerX = (topScreen.X + botScreen.X) / 2
                local centerY = (topScreen.Y + botScreen.Y) / 2
                
                obj.box.Size = Vector2.new(width, height)
                obj.box.Position = Vector2.new(centerX - width / 2, centerY - height / 2)
                obj.box.Visible = true
            else
                obj.box.Visible = false
            end
        else
            obj.box.Visible = false
        end
    end
end

-- Initialize for existing players
for _, player in ipairs(Players:GetPlayers()) do
    createBoxForPlayer(player)
end

-- Handle new players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        createBoxForPlayer(player)
    end)
end)

-- Cleanup removed players
Players.PlayerRemoving:Connect(destroyBoxForPlayer)

-- Toggle with Insert (change KeyCode if you want)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        ESP_ENABLED = not ESP_ENABLED
        print("ESP Toggled: " .. (ESP_ENABLED and "ON" or "OFF"))
    end
end)

-- Main update loop (RenderStepped for smooth visuals)
RunService.RenderStepped:Connect(updateAllBoxes)

-- Optional cleanup on close
game:BindToClose(function()
    for player, _ in pairs(espObjects) do
        destroyBoxForPlayer(player)
    end
end)

print("Grok Universal 2D Box ESP loaded | Toggle: INSERT | Customize at top of script")
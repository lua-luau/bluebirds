-- Grok's Simple Universal 2D Box ESP (Full Box - Feb 2026 fix)
-- Toggle: Insert key
-- Uses Drawing.new("Square") for clean full box around players
-- Players only, team check optional, auto-hide offscreen/dead

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local ESP_ENABLED = true          -- Starts enabled
local TEAM_CHECK = false          -- true = hide teammates
local BOX_THICKNESS = 1.5
local BOX_COLOR = Color3.fromRGB(255, 0, 0)  -- Red
local BOX_TRANSPARENCY = 1       -- 1 = fully visible
local FILL_BOX = false            -- true = filled semi-transparent box

local espTable = {}  -- player -> {box = Drawing Square}

local function isValidTarget(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    if TEAM_CHECK and player.Team == LocalPlayer.Team then return false end
    return true
end

local function createESP(player)
    if espTable[player] then return end
    
    local box = Drawing.new("Square")
    box.Thickness = BOX_THICKNESS
    box.Color = BOX_COLOR
    box.Transparency = BOX_TRANSPARENCY
    box.Filled = FILL_BOX
    box.Visible = false
    
    espTable[player] = {box = box}
end

local function removeESP(player)
    if espTable[player] then
        espTable[player].box:Remove()
        espTable[player] = nil
    end
end

local function updateESP()
    if not ESP_ENABLED then
        for _, data in pairs(espTable) do
            data.box.Visible = false
        end
        return
    end

    for player, data in pairs(espTable) do
        local char = player.Character
        if isValidTarget(player) and char and char:FindFirstChild("HumanoidRootPart") and char:FindFirstChild("Head") then
            local root = char.HumanoidRootPart
            local head = char.Head
            
            -- Get 3D positions for top/bottom (extended a bit for better fit)
            local top = head.Position + Vector3.new(0, 1, 0)     -- above head
            local bottom = root.Position - Vector3.new(0, 3.5, 0) -- below feet approx
            
            local topScreen, topVisible = Camera:WorldToViewportPoint(top)
            local botScreen, botVisible = Camera:WorldToViewportPoint(bottom)
            
            if topVisible and botVisible then
                local sizeY = math.abs(topScreen.Y - botScreen.Y)
                local sizeX = sizeY * 0.55  -- aspect ratio \~0.55 for humanoids (tweak if needed)
                
                local centerX = (topScreen.X + botScreen.X) / 2
                local centerY = (topScreen.Y + botScreen.Y) / 2
                
                data.box.Size = Vector2.new(sizeX, sizeY)
                data.box.Position = Vector2.new(centerX - sizeX/2, centerY - sizeY/2)
                data.box.Visible = true
            else
                data.box.Visible = false
            end
        else
            data.box.Visible = false
        end
    end
end

-- Setup existing & new players
for _, plr in ipairs(Players:GetPlayers()) do
    createESP(plr)
end

Players.PlayerAdded:Connect(createESP)
Players.PlayerRemoving:Connect(removeESP)

-- Toggle with Insert key (change to any Enum.KeyCode you want)
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.Insert then
        ESP_ENABLED = not ESP_ENABLED
        print("ESP Toggled: " .. (ESP_ENABLED and "ON" or "OFF"))
    end
end)

-- Render loop
RunService.RenderStepped:Connect(updateESP)

-- Cleanup on script end (optional but good)
game:BindToClose(function()
    for player, _ in pairs(espTable) do
        removeESP(player)
    end
end)

print("Grok Full 2D Box ESP loaded! Toggle with INSERT key. Customize at top.")
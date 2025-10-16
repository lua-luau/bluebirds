--// Hitbox Expander + Utility UI (Rayfield)

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

--// Global Config
getgenv().Config = {
    HitboxSize = 15,
    HitboxTransparency = 0.9,
    HitboxStatus = false,
    TeamCheck = false,
    SanityCheck = false,

    WalkSpeed = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid.WalkSpeed or 16,
    JumpPower = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid.JumpPower or 50,

    TPSpeed = 3,
    TPWalk = false,

    LoopWalkSpeed = false,
    LoopJumpPower = false,
    Noclip = false,
    InfiniteJump = false,

    -- ESP Settings
    ESPEnabled = false,
    ShowName = true,
    ShowDistance = true,
    ShowHealthBar = true,
    ShowHealthText = true,
    ESPColor = Color3.fromRGB(255, 255, 255),
    HealthBarColor = Color3.fromRGB(0, 255, 0),
    TextSize = 16,
    XOffset = 0,
    YOffset = 0,
    DepthPerception = true,
    MaxDistance = 1000,
}

--// ESP Storage
local ESPObjects = {}

--// Rayfield UI Library
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Hitbox Expander",
    LoadingTitle = "Hitbox Expander",
    LoadingSubtitle = "by Script",
    ConfigurationSaving = {
        Enabled = false,
        FolderName = nil,
        FileName = "HitboxConfig"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
    KeySettings = {
        Title = "Untitled",
        Subtitle = "Key System",
        Note = "No method of obtaining the key is provided",
        FileName = "Key",
        SaveKey = false,
        GrabKeyFromSite = false,
        Key = {"Hello"}
    }
})

--// Helper: Safe humanoid property loop
local function maintainProperty(property, valueGetter, conditionGetter)
    RunService.Heartbeat:Connect(function()
        if conditionGetter() then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum[property] = valueGetter()
            end
        end
    end)
end

--// Tabs
local HomeTab = Window:CreateTab("Home", 4483362458)
local PlayerTab = Window:CreateTab("Players", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)

--// Home Controls
local HitboxSection = HomeTab:CreateSection("Hitbox Settings")

HomeTab:CreateInput({
    Name = "Hitbox Size",
    PlaceholderText = "15",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        Config.HitboxSize = tonumber(v) or 15
    end,
})

HomeTab:CreateInput({
    Name = "Hitbox Transparency",
    PlaceholderText = "0.9",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        Config.HitboxTransparency = tonumber(v) or 0.9
    end,
})

HomeTab:CreateToggle({
    Name = "Enable Hitbox",
    CurrentValue = false,
    Flag = "HitboxToggle",
    Callback = function(s)
        Config.HitboxStatus = s
    end,
})

HomeTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Flag = "TeamCheck",
    Callback = function(s)
        Config.TeamCheck = s
    end,
})

HomeTab:CreateToggle({
    Name = "Sanity Check (Auto Remove on Death)",
    CurrentValue = false,
    Flag = "SanityCheck",
    Callback = function(s)
        Config.SanityCheck = s
    end,
})

--// Player Controls
local MovementSection = PlayerTab:CreateSection("Movement")

PlayerTab:CreateInput({
    Name = "WalkSpeed",
    PlaceholderText = "16",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        Config.WalkSpeed = tonumber(v) or Config.WalkSpeed
    end,
})

PlayerTab:CreateToggle({
    Name = "Loop WalkSpeed",
    CurrentValue = false,
    Flag = "LoopWalkSpeed",
    Callback = function(s)
        Config.LoopWalkSpeed = s
    end,
})

maintainProperty("WalkSpeed", function() return Config.WalkSpeed end, function() return Config.LoopWalkSpeed end)

PlayerTab:CreateInput({
    Name = "JumpPower",
    PlaceholderText = "50",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        Config.JumpPower = tonumber(v) or Config.JumpPower
    end,
})

PlayerTab:CreateToggle({
    Name = "Loop JumpPower",
    CurrentValue = false,
    Flag = "LoopJumpPower",
    Callback = function(s)
        Config.LoopJumpPower = s
    end,
})

maintainProperty("JumpPower", function() return Config.JumpPower end, function() return Config.LoopJumpPower end)

PlayerTab:CreateInput({
    Name = "TP Speed",
    PlaceholderText = "3",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        Config.TPSpeed = tonumber(v) or 3
    end,
})

PlayerTab:CreateToggle({
    Name = "TP Walk",
    CurrentValue = false,
    Flag = "TPWalk",
    Callback = function(s)
        Config.TPWalk = s
    end,
})

RunService.Heartbeat:Connect(function()
    if Config.TPWalk then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then
            char:TranslateBy(hum.MoveDirection * Config.TPSpeed)
        end
    end
end)

PlayerTab:CreateSlider({
    Name = "FOV",
    Range = {1, 120},
    Increment = 1,
    CurrentValue = workspace.CurrentCamera.FieldOfView,
    Flag = "FOVSlider",
    Callback = function(v)
        workspace.CurrentCamera.FieldOfView = v
    end,
})

local MiscSection = PlayerTab:CreateSection("Misc")

PlayerTab:CreateToggle({
    Name = "Noclip",
    CurrentValue = false,
    Flag = "Noclip",
    Callback = function(s)
        Config.Noclip = s
    end,
})

RunService.Stepped:Connect(function()
    if Config.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = false
                end
            end
        end
    end
end)

PlayerTab:CreateToggle({
    Name = "Infinite Jump",
    CurrentValue = false,
    Flag = "InfiniteJump",
    Callback = function(s)
        Config.InfiniteJump = s
    end,
})

UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then
            hum:ChangeState(Enum.HumanoidStateType.Jumping)
        end
    end
end)

PlayerTab:CreateButton({
    Name = "Rejoin",
    Callback = function()
        TeleportService:Teleport(game.PlaceId, LocalPlayer)
    end,
})

--// ESP Tab
local ESPMainSection = ESPTab:CreateSection("Main Settings")

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = false,
    Flag = "ESPToggle",
    Callback = function(s)
        Config.ESPEnabled = s
        if not s then
            for _, esp in pairs(ESPObjects) do
                if esp.NameText then esp.NameText:Remove() end
                if esp.DistanceText then esp.DistanceText:Remove() end
                if esp.HealthText then esp.HealthText:Remove() end
                if esp.HealthBarOutline then esp.HealthBarOutline:Remove() end
                if esp.HealthBarFill then esp.HealthBarFill:Remove() end
            end
            ESPObjects = {}
        end
    end,
})

ESPTab:CreateToggle({
    Name = "Show Name",
    CurrentValue = true,
    Flag = "ShowName",
    Callback = function(s)
        Config.ShowName = s
    end,
})

ESPTab:CreateToggle({
    Name = "Show Distance",
    CurrentValue = true,
    Flag = "ShowDistance",
    Callback = function(s)
        Config.ShowDistance = s
    end,
})

ESPTab:CreateToggle({
    Name = "Show Health Bar",
    CurrentValue = true,
    Flag = "ShowHealthBar",
    Callback = function(s)
        Config.ShowHealthBar = s
    end,
})

ESPTab:CreateToggle({
    Name = "Show Health Text",
    CurrentValue = true,
    Flag = "ShowHealthText",
    Callback = function(s)
        Config.ShowHealthText = s
    end,
})

ESPTab:CreateToggle({
    Name = "Depth Perception (Size Based on Distance)",
    CurrentValue = true,
    Flag = "DepthPerception",
    Callback = function(s)
        Config.DepthPerception = s
    end,
})

local CustomizationSection = ESPTab:CreateSection("Customization")

ESPTab:CreateSlider({
    Name = "Text Size",
    Range = {10, 30},
    Increment = 1,
    CurrentValue = 16,
    Flag = "TextSize",
    Callback = function(v)
        Config.TextSize = v
    end,
})

ESPTab:CreateSlider({
    Name = "X Offset",
    Range = {-100, 100},
    Increment = 1,
    CurrentValue = 0,
    Flag = "XOffset",
    Callback = function(v)
        Config.XOffset = v
    end,
})

ESPTab:CreateSlider({
    Name = "Y Offset",
    Range = {-100, 100},
    Increment = 1,
    CurrentValue = 0,
    Flag = "YOffset",
    Callback = function(v)
        Config.YOffset = v
    end,
})

ESPTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 5000},
    Increment = 100,
    CurrentValue = 1000,
    Flag = "MaxDistance",
    Callback = function(v)
        Config.MaxDistance = v
    end,
})

ESPTab:CreateColorPicker({
    Name = "Text Color",
    Color = Color3.fromRGB(255, 255, 255),
    Flag = "ESPColor",
    Callback = function(c)
        Config.ESPColor = c
    end
})

ESPTab:CreateColorPicker({
    Name = "Health Bar Color",
    Color = Color3.fromRGB(0, 255, 0),
    Flag = "HealthBarColor",
    Callback = function(c)
        Config.HealthBarColor = c
    end
})

--// ESP Functions
local function createESP(player)
    if ESPObjects[player] then return end
    
    local esp = {
        NameText = Drawing.new("Text"),
        DistanceText = Drawing.new("Text"),
        HealthText = Drawing.new("Text"),
        HealthBarOutline = Drawing.new("Square"),
        HealthBarFill = Drawing.new("Square")
    }
    
    -- Name Text
    esp.NameText.Center = true
    esp.NameText.Outline = true
    esp.NameText.Font = 2
    
    -- Distance Text
    esp.DistanceText.Center = true
    esp.DistanceText.Outline = true
    esp.DistanceText.Font = 2
    
    -- Health Text
    esp.HealthText.Center = true
    esp.HealthText.Outline = true
    esp.HealthText.Font = 2
    
    -- Health Bar Outline
    esp.HealthBarOutline.Thickness = 1
    esp.HealthBarOutline.Filled = false
    esp.HealthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    
    -- Health Bar Fill
    esp.HealthBarFill.Filled = true
    
    ESPObjects[player] = esp
end

local function removeESP(player)
    if ESPObjects[player] then
        local esp = ESPObjects[player]
        if esp.NameText then esp.NameText:Remove() end
        if esp.DistanceText then esp.DistanceText:Remove() end
        if esp.HealthText then esp.HealthText:Remove() end
        if esp.HealthBarOutline then esp.HealthBarOutline:Remove() end
        if esp.HealthBarFill then esp.HealthBarFill:Remove() end
        ESPObjects[player] = nil
    end
end

local function updateESP()
    if not Config.ESPEnabled then return end
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            if hrp and head and hum then
                -- Check distance
                local distance = (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") and 
                    (LocalPlayer.Character.HumanoidRootPart.Position - hrp.Position).Magnitude) or math.huge
                
                if distance <= Config.MaxDistance then
                    if not ESPObjects[player] then
                        createESP(player)
                    end
                    
                    local esp = ESPObjects[player]
                    local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    
                    if onScreen then
                        -- Calculate depth perception size
                        local sizeMult = 1
                        if Config.DepthPerception then
                            sizeMult = math.clamp(1000 / distance, 0.5, 2)
                        end
                        
                        local textSize = Config.TextSize * sizeMult
                        local baseX = headPos.X + Config.XOffset
                        local baseY = headPos.Y + Config.YOffset
                        
                        -- Update Name
                        if Config.ShowName and esp.NameText then
                            esp.NameText.Visible = true
                            esp.NameText.Text = player.Name
                            esp.NameText.Size = textSize
                            esp.NameText.Position = Vector2.new(baseX, baseY - 40 * sizeMult)
                            esp.NameText.Color = Config.ESPColor
                        else
                            esp.NameText.Visible = false
                        end
                        
                        -- Update Distance
                        if Config.ShowDistance and esp.DistanceText then
                            esp.DistanceText.Visible = true
                            esp.DistanceText.Text = string.format("[%d studs]", math.floor(distance))
                            esp.DistanceText.Size = textSize * 0.8
                            esp.DistanceText.Position = Vector2.new(baseX, baseY - 25 * sizeMult)
                            esp.DistanceText.Color = Config.ESPColor
                        else
                            esp.DistanceText.Visible = false
                        end
                        
                        -- Update Health Text
                        if Config.ShowHealthText and esp.HealthText then
                            esp.HealthText.Visible = true
                            esp.HealthText.Text = string.format("%d/%d HP", math.floor(hum.Health), math.floor(hum.MaxHealth))
                            esp.HealthText.Size = textSize * 0.8
                            esp.HealthText.Position = Vector2.new(baseX, baseY - 10 * sizeMult)
                            esp.HealthText.Color = Config.ESPColor
                        else
                            esp.HealthText.Visible = false
                        end
                        
                        -- Update Health Bar
                        if Config.ShowHealthBar and esp.HealthBarOutline and esp.HealthBarFill then
                            local barWidth = 50 * sizeMult
                            local barHeight = 6 * sizeMult
                            local barX = baseX - barWidth / 2
                            local barY = baseY + 5 * sizeMult
                            
                            esp.HealthBarOutline.Visible = true
                            esp.HealthBarOutline.Size = Vector2.new(barWidth, barHeight)
                            esp.HealthBarOutline.Position = Vector2.new(barX, barY)
                            
                            local healthPercent = hum.Health / hum.MaxHealth
                            esp.HealthBarFill.Visible = true
                            esp.HealthBarFill.Size = Vector2.new(barWidth * healthPercent - 2, barHeight - 2)
                            esp.HealthBarFill.Position = Vector2.new(barX + 1, barY + 1)
                            esp.HealthBarFill.Color = Config.HealthBarColor:Lerp(Color3.fromRGB(255, 0, 0), 1 - healthPercent)
                        else
                            esp.HealthBarOutline.Visible = false
                            esp.HealthBarFill.Visible = false
                        end
                    else
                        -- Hide if not on screen
                        esp.NameText.Visible = false
                        esp.DistanceText.Visible = false
                        esp.HealthText.Visible = false
                        esp.HealthBarOutline.Visible = false
                        esp.HealthBarFill.Visible = false
                    end
                else
                    removeESP(player)
                end
            else
                removeESP(player)
            end
        end
    end
end

Players.PlayerRemoving:Connect(removeESP)

--// Hitbox Logic
local function updateHitbox()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            
            if hrp then
                local isInVehicle = hum and hum.Sit
                local isEnemy = not Config.TeamCheck or plr.Team ~= LocalPlayer.Team
                local isAlive = not Config.SanityCheck or (hum and hum.Health > 0)
                
                if Config.HitboxStatus and isEnemy and isAlive and not isInVehicle then
                    hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    hrp.Transparency = Config.HitboxTransparency
                    hrp.BrickColor = BrickColor.new("Really black")
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function()
    updateHitbox()
    updateESP()
end)
--// Hitbox Expander + Utility UI (Rayfield)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().Config = {
    HitboxSize = 15, HitboxTransparency = 0.9, HitboxStatus = false, TeamCheck = false, SanityCheck = false,
    WalkSpeed = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid.WalkSpeed or 16,
    JumpPower = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid.JumpPower or 50,
    TPSpeed = 3, TPWalk = false, LoopWalkSpeed = false, LoopJumpPower = false, Noclip = false, InfiniteJump = false,
    ESPEnabled = false, ShowName = true, ShowDistance = true, ShowHealthText = true, HealthColorBased = true, UseTeamColor = false, ESPTeamCheck = false,
    DepthPerception = true, DepthMinSize = 0.4, DepthMaxSize = 1.5, DepthCloseRange = 100, DepthMediumRange = 500, DepthLongRange = 2000,
    ESPColor = Color3.fromRGB(255, 255, 255), TextSize = 16, XOffset = 0, YOffset = 0, MaxDistance = 5000,
}

local ESPObjects = {}
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name = "Hitbox Expander", LoadingTitle = "Hitbox Expander", LoadingSubtitle = "by Script", ConfigurationSaving = {Enabled = false}, Discord = {Enabled = false}, KeySystem = false})

local function maintainProperty(property, valueGetter, conditionGetter)
    RunService.Heartbeat:Connect(function()
        if conditionGetter() then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then hum[property] = valueGetter() end
        end
    end)
end

local HomeTab = Window:CreateTab("Home", 4483362458)
local PlayerTab = Window:CreateTab("Players", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)

HomeTab:CreateSection("Hitbox Settings")
HomeTab:CreateInput({Name = "Hitbox Size", PlaceholderText = "15", RemoveTextAfterFocusLost = false, Callback = function(v) Config.HitboxSize = tonumber(v) or 15 end})
HomeTab:CreateInput({Name = "Hitbox Transparency", PlaceholderText = "0.9", RemoveTextAfterFocusLost = false, Callback = function(v) Config.HitboxTransparency = tonumber(v) or 0.9 end})
HomeTab:CreateToggle({Name = "Enable Hitbox", CurrentValue = false, Callback = function(s) Config.HitboxStatus = s end})
HomeTab:CreateToggle({Name = "Team Check", CurrentValue = false, Callback = function(s) Config.TeamCheck = s end})
HomeTab:CreateToggle({Name = "Sanity Check (Auto Remove on Death)", CurrentValue = false, Callback = function(s) Config.SanityCheck = s end})

PlayerTab:CreateSection("Movement")
PlayerTab:CreateInput({Name = "WalkSpeed", PlaceholderText = "16", RemoveTextAfterFocusLost = false, Callback = function(v) Config.WalkSpeed = tonumber(v) or Config.WalkSpeed end})
PlayerTab:CreateToggle({Name = "Loop WalkSpeed", CurrentValue = false, Callback = function(s) Config.LoopWalkSpeed = s end})
maintainProperty("WalkSpeed", function() return Config.WalkSpeed end, function() return Config.LoopWalkSpeed end)

PlayerTab:CreateInput({Name = "JumpPower", PlaceholderText = "50", RemoveTextAfterFocusLost = false, Callback = function(v) Config.JumpPower = tonumber(v) or Config.JumpPower end})
PlayerTab:CreateToggle({Name = "Loop JumpPower", CurrentValue = false, Callback = function(s) Config.LoopJumpPower = s end})
maintainProperty("JumpPower", function() return Config.JumpPower end, function() return Config.LoopJumpPower end)

PlayerTab:CreateInput({Name = "TP Speed", PlaceholderText = "3", RemoveTextAfterFocusLost = false, Callback = function(v) Config.TPSpeed = tonumber(v) or 3 end})
PlayerTab:CreateToggle({Name = "TP Walk", CurrentValue = false, Callback = function(s) Config.TPWalk = s end})

RunService.Heartbeat:Connect(function()
    if Config.TPWalk then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then char:TranslateBy(hum.MoveDirection * Config.TPSpeed) end
    end
end)

PlayerTab:CreateSlider({Name = "FOV", Range = {1, 120}, Increment = 1, CurrentValue = workspace.CurrentCamera.FieldOfView, Callback = function(v) workspace.CurrentCamera.FieldOfView = v end})

PlayerTab:CreateSection("Misc")
PlayerTab:CreateToggle({Name = "Noclip", CurrentValue = false, Callback = function(s) Config.Noclip = s end})
RunService.Stepped:Connect(function()
    if Config.Noclip then
        local char = LocalPlayer.Character
        if char then for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") then part.CanCollide = false end end end
    end
end)

PlayerTab:CreateToggle({Name = "Infinite Jump", CurrentValue = false, Callback = function(s) Config.InfiniteJump = s end})
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

PlayerTab:CreateButton({Name = "Rejoin", Callback = function() TeleportService:Teleport(game.PlaceId, LocalPlayer) end})

ESPTab:CreateSection("Main Settings")
ESPTab:CreateToggle({Name = "Enable ESP", CurrentValue = false, Callback = function(s)
    Config.ESPEnabled = s
    if not s then
        for _, esp in pairs(ESPObjects) do
            if esp.NameText then esp.NameText:Remove() end
            if esp.DistanceText then esp.DistanceText:Remove() end
            if esp.HealthText then esp.HealthText:Remove() end
        end
        ESPObjects = {}
    end
end})

ESPTab:CreateToggle({Name = "Show Name", CurrentValue = true, Callback = function(s) Config.ShowName = s end})
ESPTab:CreateToggle({Name = "Show Distance", CurrentValue = true, Callback = function(s) Config.ShowDistance = s end})
ESPTab:CreateToggle({Name = "Show Health Text", CurrentValue = true, Callback = function(s) Config.ShowHealthText = s end})
ESPTab:CreateToggle({Name = "Health Color Based (Green to Red)", CurrentValue = true, Callback = function(s) Config.HealthColorBased = s end})
ESPTab:CreateToggle({Name = "Use Team Colors", CurrentValue = false, Callback = function(s) Config.UseTeamColor = s end})
ESPTab:CreateToggle({Name = "ESP Team Check (Hide Teammates)", CurrentValue = false, Callback = function(s) Config.ESPTeamCheck = s end})
ESPTab:CreateToggle({Name = "Depth Perception", CurrentValue = true, Callback = function(s) Config.DepthPerception = s end})

ESPTab:CreateSection("Depth Perception Settings")
ESPTab:CreateSlider({Name = "Min Size Multiplier (Far)", Range = {0.1, 1}, Increment = 0.05, CurrentValue = 0.4, Callback = function(v) Config.DepthMinSize = v end})
ESPTab:CreateSlider({Name = "Max Size Multiplier (Close)", Range = {1, 3}, Increment = 0.1, CurrentValue = 1.5, Callback = function(v) Config.DepthMaxSize = v end})
ESPTab:CreateInput({Name = "Close Range Distance (studs)", PlaceholderText = "100", RemoveTextAfterFocusLost = false, Callback = function(v) Config.DepthCloseRange = tonumber(v) or 100 end})
ESPTab:CreateInput({Name = "Medium Range Distance (studs)", PlaceholderText = "500", RemoveTextAfterFocusLost = false, Callback = function(v) Config.DepthMediumRange = tonumber(v) or 500 end})
ESPTab:CreateInput({Name = "Long Range Distance (studs)", PlaceholderText = "2000", RemoveTextAfterFocusLost = false, Callback = function(v) Config.DepthLongRange = tonumber(v) or 2000 end})

ESPTab:CreateSection("Customization")
ESPTab:CreateSlider({Name = "Text Size", Range = {10, 30}, Increment = 1, CurrentValue = 16, Callback = function(v) Config.TextSize = v end})
ESPTab:CreateSlider({Name = "X Offset", Range = {-100, 100}, Increment = 1, CurrentValue = 0, Callback = function(v) Config.XOffset = v end})
ESPTab:CreateSlider({Name = "Y Offset", Range = {-100, 100}, Increment = 1, CurrentValue = 0, Callback = function(v) Config.YOffset = v end})
ESPTab:CreateSlider({Name = "Max Distance", Range = {100, 10000}, Increment = 100, CurrentValue = 5000, Callback = function(v) Config.MaxDistance = v end})
ESPTab:CreateColorPicker({Name = "Text Color", Color = Color3.fromRGB(255, 255, 255), Callback = function(c) Config.ESPColor = c end})

local function createESP(player)
    if ESPObjects[player] then return end
    local esp = {NameText = Drawing.new("Text"), DistanceText = Drawing.new("Text"), HealthText = Drawing.new("Text")}
    esp.NameText.Center = true; esp.NameText.Outline = true; esp.NameText.Font = 2
    esp.DistanceText.Center = true; esp.DistanceText.Outline = true; esp.DistanceText.Font = 2
    esp.HealthText.Center = true; esp.HealthText.Outline = true; esp.HealthText.Font = 2
    ESPObjects[player] = esp
end

local function removeESP(player)
    if ESPObjects[player] then
        local esp = ESPObjects[player]
        if esp.NameText then esp.NameText:Remove() end
        if esp.DistanceText then esp.DistanceText:Remove() end
        if esp.HealthText then esp.HealthText:Remove() end
        ESPObjects[player] = nil
    end
end

local function getHealthColor(healthPercent)
    if healthPercent > 0.75 then return Color3.fromRGB(0, 255, 0)
    elseif healthPercent > 0.5 then return Color3.fromRGB(173, 255, 47)
    elseif healthPercent > 0.25 then return Color3.fromRGB(255, 255, 0)
    elseif healthPercent > 0.1 then return Color3.fromRGB(255, 165, 0)
    else return Color3.fromRGB(255, 0, 0) end
end

local function updateESP()
    if not Config.ESPEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESPObjects[player] then createESP(player) end
            local esp = ESPObjects[player]
            if not esp then continue end
            if not player.Character then esp.NameText.Visible = false; esp.DistanceText.Visible = false; esp.HealthText.Visible = false; continue end
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local head = char:FindFirstChild("Head")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not head or not hum then esp.NameText.Visible = false; esp.DistanceText.Visible = false; esp.HealthText.Visible = false; continue end
            if hum.Health <= 0 then esp.NameText.Visible = false; esp.DistanceText.Visible = false; esp.HealthText.Visible = false; continue end
            if Config.ESPTeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then esp.NameText.Visible = false; esp.DistanceText.Visible = false; esp.HealthText.Visible = false; continue end
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then esp.NameText.Visible = false; esp.DistanceText.Visible = false; esp.HealthText.Visible = false; continue end
            local distance = (myHRP.Position - hrp.Position).Magnitude
            if distance > Config.MaxDistance then esp.NameText.Visible = false; esp.DistanceText.Visible = false; esp.HealthText.Visible = false; continue end
            local headPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if not onScreen then esp.NameText.Visible = false; esp.DistanceText.Visible = false; esp.HealthText.Visible = false; continue end
            local textColor = Config.ESPColor
            if Config.UseTeamColor and player.Team then textColor = player.TeamColor.Color end
            local sizeMult = 1
            local spacing = 15
            if Config.DepthPerception then
                if distance < Config.DepthCloseRange then sizeMult = Config.DepthMaxSize; spacing = 20
                elseif distance < Config.DepthMediumRange then local progress = (distance - Config.DepthCloseRange) / (Config.DepthMediumRange - Config.DepthCloseRange); sizeMult = Config.DepthMaxSize - (progress * (Config.DepthMaxSize - 1)); spacing = 20 - (progress * 5)
                elseif distance < Config.DepthLongRange then sizeMult = 1; spacing = 15
                else local logScale = math.log(distance / Config.DepthLongRange) / math.log(5); sizeMult = math.max(Config.DepthMinSize, 1 - (logScale * (1 - Config.DepthMinSize))); spacing = math.max(8, 15 - (logScale * 7)) end
            end
            local textSize = Config.TextSize * sizeMult
            local baseX = headPos.X + Config.XOffset
            local baseY = headPos.Y + Config.YOffset
            if Config.ShowName and esp.NameText then esp.NameText.Visible = true; esp.NameText.Text = player.Name; esp.NameText.Size = textSize; esp.NameText.Position = Vector2.new(baseX, baseY - spacing * 2); esp.NameText.Color = textColor else esp.NameText.Visible = false end
            if Config.ShowDistance and esp.DistanceText then esp.DistanceText.Visible = true; esp.DistanceText.Text = string.format("[%d studs]", math.floor(distance)); esp.DistanceText.Size = textSize * 0.9; esp.DistanceText.Position = Vector2.new(baseX, baseY - spacing); esp.DistanceText.Color = textColor else esp.DistanceText.Visible = false end
            if Config.ShowHealthText and esp.HealthText then local healthPercent = hum.Health / hum.MaxHealth; local healthColor = textColor; if Config.HealthColorBased then healthColor = getHealthColor(healthPercent) end; esp.HealthText.Visible = true; esp.HealthText.Text = string.format("%d/%d HP", math.floor(hum.Health), math.floor(hum.MaxHealth)); esp.HealthText.Size = textSize * 0.9; esp.HealthText.Position = Vector2.new(baseX, baseY); esp.HealthText.Color = healthColor else esp.HealthText.Visible = false end
        end
    end
end

Players.PlayerRemoving:Connect(function(player) removeESP(player) end)
Players.PlayerAdded:Connect(function(player) if Config.ESPEnabled then createESP(player) end end)

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

RunService.RenderStepped:Connect(function() updateHitbox(); updateESP() end)
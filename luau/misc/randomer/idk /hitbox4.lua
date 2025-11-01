--// Optimized Hitbox Expander + ESP (Rayfield)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().Config = getgenv().Config or {
    HitboxSize = 15, HitboxTransparency = 0.9, HitboxStatus = false, TeamCheck = false, SanityCheck = false,
    ExpandHead = true, ExpandTorso = true, ExpandHRP = true, ExpandLeftArm = false, ExpandRightArm = false, ExpandLeftLeg = false, ExpandRightLeg = false,
    ESPEnabled = false, ESPTeamCheck = false, ESPUseTeamColor = true, ESPColor = Color3.fromRGB(255, 0, 0), ESPSize = 3, ESPMaxDistance = 5000,
}

getgenv().ESPObjects = getgenv().ESPObjects or {}
getgenv().OriginalSizes = getgenv().OriginalSizes or {}
getgenv().ExpandedParts = getgenv().ExpandedParts or {}
getgenv().DeathConnections = getgenv().DeathConnections or {}

getgenv().PartMapping = {
    Head = {"Head"},
    Torso = {"Torso", "UpperTorso", "LowerTorso"},
    HRP = {"HumanoidRootPart"},
    LeftArm = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    RightArm = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    LeftLeg = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    RightLeg = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({Name = "Hitbox Expander", LoadingTitle = "Hitbox Expander", LoadingSubtitle = "by Script", ConfigurationSaving = {Enabled = false}, Discord = {Enabled = false}, KeySystem = false})

local HomeTab = Window:CreateTab("Home", 4483362458)
local PartsTab = Window:CreateTab("Body Parts", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)

local function createInput(tab, name, configKey)
    tab:CreateInput({Name = name, PlaceholderText = tostring(getgenv().Config[configKey]), RemoveTextAfterFocusLost = false, Callback = function(v) getgenv().Config[configKey] = tonumber(v) or getgenv().Config[configKey] end})
end

local function createToggle(tab, name, configKey, callback)
    tab:CreateToggle({Name = name, CurrentValue = getgenv().Config[configKey], Callback = callback or function(s) getgenv().Config[configKey] = s end})
end

local function createSlider(tab, name, range, increment, configKey)
    tab:CreateSlider({Name = name, Range = range, Increment = increment, CurrentValue = getgenv().Config[configKey], Callback = function(v) getgenv().Config[configKey] = v end})
end

HomeTab:CreateSection("Hitbox Settings")
createInput(HomeTab, "Hitbox Size", "HitboxSize")
createInput(HomeTab, "Hitbox Transparency", "HitboxTransparency")
createToggle(HomeTab, "Enable Hitbox", "HitboxStatus", function(s)
    getgenv().Config.HitboxStatus = s
    if not s then
        for player, parts in pairs(getgenv().ExpandedParts) do
            if player.Character then
                restoreHitbox(player.Character)
            end
        end
        getgenv().ExpandedParts = {}
    end
end)
createToggle(HomeTab, "Team Check", "TeamCheck")
createToggle(HomeTab, "Sanity Check (Auto Remove on Death)", "SanityCheck")

PartsTab:CreateSection("Select Body Parts to Expand")
createToggle(PartsTab, "Head", "ExpandHead")
createToggle(PartsTab, "Torso (Upper/Lower)", "ExpandTorso")
createToggle(PartsTab, "HumanoidRootPart", "ExpandHRP")
createToggle(PartsTab, "Left Arm", "ExpandLeftArm")
createToggle(PartsTab, "Right Arm", "ExpandRightArm")
createToggle(PartsTab, "Left Leg", "ExpandLeftLeg")
createToggle(PartsTab, "Right Leg", "ExpandRightLeg")

ESPTab:CreateSection("ESP Settings")
createToggle(ESPTab, "Enable ESP", "ESPEnabled", function(s)
    getgenv().Config.ESPEnabled = s
    if not s then 
        for _, esp in pairs(getgenv().ESPObjects) do 
            if esp.Dot then esp.Dot:Remove() end 
        end
        getgenv().ESPObjects = {} 
    end
end)
createToggle(ESPTab, "ESP Team Check (Hide Teammates)", "ESPTeamCheck")
createToggle(ESPTab, "Use Team Colors", "ESPUseTeamColor")
createSlider(ESPTab, "Dot Size", {1, 10}, 0.5, "ESPSize")
createSlider(ESPTab, "Max Distance", {100, 10000}, 100, "ESPMaxDistance")
ESPTab:CreateColorPicker({Name = "Dot Color (if not using team colors)", Color = getgenv().Config.ESPColor, Callback = function(c) getgenv().Config.ESPColor = c end})

local function shouldExpandPart(partName)
    for key, parts in pairs(getgenv().PartMapping) do
        local configKey = "Expand" .. key
        if getgenv().Config[configKey] then
            for _, name in ipairs(parts) do
                if partName == name then return true end
            end
        end
    end
    return false
end

function restoreHitbox(character)
    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and getgenv().OriginalSizes[part] then
            part.Size = getgenv().OriginalSizes[part].Size
            part.Transparency = getgenv().OriginalSizes[part].Transparency
            part.BrickColor = getgenv().OriginalSizes[part].BrickColor
            part.Material = getgenv().OriginalSizes[part].Material
            part.CanCollide = getgenv().OriginalSizes[part].CanCollide
            getgenv().OriginalSizes[part] = nil
        end
    end
end

local function expandHitbox(character, player)
    if not getgenv().ExpandedParts[player] then
        getgenv().ExpandedParts[player] = {}
    end

    for _, part in pairs(character:GetChildren()) do
        if part:IsA("BasePart") and shouldExpandPart(part.Name) then
            if not getgenv().OriginalSizes[part] then
                getgenv().OriginalSizes[part] = {
                    Size = part.Size,
                    Transparency = part.Transparency,
                    BrickColor = part.BrickColor,
                    Material = part.Material,
                    CanCollide = part.CanCollide
                }
            end
            
            local targetSize = Vector3.new(getgenv().Config.HitboxSize, getgenv().Config.HitboxSize, getgenv().Config.HitboxSize)
            if part.Size ~= targetSize then
                part.Size = targetSize
                part.Transparency = getgenv().Config.HitboxTransparency
                part.BrickColor = BrickColor.new("Really black")
                part.Material = Enum.Material.Neon
                part.CanCollide = false
                getgenv().ExpandedParts[player][part] = true
            end
        end
    end
end

local function setupDeathConnection(player)
    if getgenv().DeathConnections[player] then
        getgenv().DeathConnections[player]:Disconnect()
    end
    
    local char = player.Character
    if not char then return end
    
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        getgenv().DeathConnections[player] = hum.Died:Connect(function()
            if getgenv().Config.SanityCheck then
                restoreHitbox(char)
                getgenv().ExpandedParts[player] = nil
            end
        end)
    end
end

local function handleCharacterAdded(player)
    player.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        if getgenv().Config.SanityCheck then
            setupDeathConnection(player)
        end
        if getgenv().Config.HitboxStatus then
            local isEnemy = not getgenv().Config.TeamCheck or player.Team ~= LocalPlayer.Team
            if isEnemy and player ~= LocalPlayer then
                expandHitbox(char, player)
            end
        end
    end)
end

local function createESP(player)
    if getgenv().ESPObjects[player] then return end
    local dot = Drawing.new("Circle")
    dot.Filled = true
    dot.Thickness = 1
    dot.NumSides = 12
    dot.Visible = false
    getgenv().ESPObjects[player] = {Dot = dot}
end

local function removeESP(player)
    local esp = getgenv().ESPObjects[player]
    if esp and esp.Dot then esp.Dot:Remove() end
    getgenv().ESPObjects[player] = nil
    
    if getgenv().DeathConnections[player] then
        getgenv().DeathConnections[player]:Disconnect()
        getgenv().DeathConnections[player] = nil
    end
    
    if player.Character then
        restoreHitbox(player.Character)
    end
    getgenv().ExpandedParts[player] = nil
end

local function updateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not getgenv().ESPObjects[player] then createESP(player) end
        local esp = getgenv().ESPObjects[player]
        if not esp or not esp.Dot then continue end
        
        local char = player.Character
        if not char then esp.Dot.Visible = false; continue end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum or hum.Health <= 0 then esp.Dot.Visible = false; continue end
        
        if getgenv().Config.ESPTeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then 
            esp.Dot.Visible = false
            continue 
        end
        
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then esp.Dot.Visible = false; continue end
        
        local distance = (myHRP.Position - hrp.Position).Magnitude
        if distance > getgenv().Config.ESPMaxDistance then esp.Dot.Visible = false; continue end
        
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then esp.Dot.Visible = false; continue end
        
        esp.Dot.Visible = true
        esp.Dot.Position = Vector2.new(pos.X, pos.Y)
        esp.Dot.Radius = getgenv().Config.ESPSize
        esp.Dot.Color = (getgenv().Config.ESPUseTeamColor and player.Team) and player.TeamColor.Color or getgenv().Config.ESPColor
    end
end

local function updateHitbox()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer or not plr.Character then continue end
        
        local char = plr.Character
        local hum = char:FindFirstChildOfClass("Humanoid")
        
        local isEnemy = not getgenv().Config.TeamCheck or plr.Team ~= LocalPlayer.Team
        local isAlive = not getgenv().Config.SanityCheck or (hum and hum.Health > 0)
        
        if isEnemy and isAlive then
            expandHitbox(char, plr)
        else
            if getgenv().ExpandedParts[plr] then
                restoreHitbox(char)
                getgenv().ExpandedParts[plr] = nil
            end
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer then
        handleCharacterAdded(player)
        if player.Character then
            if getgenv().Config.SanityCheck then
                setupDeathConnection(player)
            end
        end
    end
end

Players.PlayerAdded:Connect(function(player)
    handleCharacterAdded(player)
    if getgenv().Config.ESPEnabled then createESP(player) end
end)

Players.PlayerRemoving:Connect(removeESP)

RunService.Heartbeat:Connect(function()
    if getgenv().Config.HitboxStatus then 
        updateHitbox() 
    end
    if getgenv().Config.ESPEnabled then 
        updateESP() 
    end
end)
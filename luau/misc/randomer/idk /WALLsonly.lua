--// Enhanced ESP Script with NPC Support (Rayfield)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().Config = getgenv().Config or {
    -- Player ESP
    ESPEnabled = false, 
    ESPTeamCheck = false, 
    ESPUseTeamColor = true, 
    ESPColor = Color3.fromRGB(255, 0, 0), 
    ESPSize = 3, 
    ESPMaxDistance = 5000,
    ShowDistance = true,
    ShowName = true,
    ShowHealthBar = true,
    ShowBoxESP = false,
    BoxThickness = 2,
    ESPTransparency = 1,
    DistanceBasedTransparency = false,
    MinTransparency = 0.2,
    MaxTransparency = 1,
    
    -- NPC ESP
    NPCESPEnabled = false,
    NPCColor = Color3.fromRGB(255, 255, 0),
    NPCSize = 3,
    NPCMaxDistance = 5000,
    NPCShowDistance = true,
    NPCShowName = true,
    NPCShowHealthBar = true,
    NPCShowBoxESP = false,
    NPCTransparency = 1,
    NPCDistanceBasedTransparency = false,
    NPCMinTransparency = 0.2,
    NPCMaxTransparency = 1,
}

getgenv().ESPObjects = getgenv().ESPObjects or {}
getgenv().NPCESPObjects = getgenv().NPCESPObjects or {}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Enhanced ESP", 
    LoadingTitle = "Enhanced ESP Script", 
    LoadingSubtitle = "Player & NPC ESP", 
    ConfigurationSaving = {Enabled = false}, 
    Discord = {Enabled = false}, 
    KeySystem = false
})

local PlayerESPTab = Window:CreateTab("Player ESP", 4483362458)
local NPCESPTab = Window:CreateTab("NPC ESP", 4483362458)
local SettingsTab = Window:CreateTab("Settings", 4483362458)

local function createToggle(tab, name, configKey, callback)
    tab:CreateToggle({
        Name = name, 
        CurrentValue = getgenv().Config[configKey], 
        Callback = callback or function(s) getgenv().Config[configKey] = s end
    })
end

local function createSlider(tab, name, range, increment, configKey)
    tab:CreateSlider({
        Name = name, 
        Range = range, 
        Increment = increment, 
        CurrentValue = getgenv().Config[configKey], 
        Callback = function(v) getgenv().Config[configKey] = v end
    })
end

-- Player ESP Settings
PlayerESPTab:CreateSection("Main Settings")
createToggle(PlayerESPTab, "Enable Player ESP", "ESPEnabled", function(s)
    getgenv().Config.ESPEnabled = s
    if not s then 
        for _, esp in pairs(getgenv().ESPObjects) do 
            if esp.Dot then esp.Dot:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.HealthBar then esp.HealthBar:Remove() end
            if esp.HealthBarBG then esp.HealthBarBG:Remove() end
            if esp.Box then esp.Box:Remove() end
        end
        getgenv().ESPObjects = {} 
    end
end)
createToggle(PlayerESPTab, "Team Check (Hide Teammates)", "ESPTeamCheck")
createToggle(PlayerESPTab, "Use Team Colors", "ESPUseTeamColor")

PlayerESPTab:CreateSection("Display Options")
createToggle(PlayerESPTab, "Show Name", "ShowName")
createToggle(PlayerESPTab, "Show Distance", "ShowDistance")
createToggle(PlayerESPTab, "Show Health Bar", "ShowHealthBar")
createToggle(PlayerESPTab, "Show Box ESP", "ShowBoxESP")

PlayerESPTab:CreateSection("Customization")
createSlider(PlayerESPTab, "Dot Size", {1, 15}, 0.5, "ESPSize")
createSlider(PlayerESPTab, "Max Distance", {100, 10000}, 100, "ESPMaxDistance")
createSlider(PlayerESPTab, "Box Thickness", {1, 5}, 1, "BoxThickness")

PlayerESPTab:CreateSection("Transparency")
createSlider(PlayerESPTab, "ESP Transparency", {0, 1}, 0.05, "ESPTransparency")
createToggle(PlayerESPTab, "Distance Based Transparency", "DistanceBasedTransparency")
createSlider(PlayerESPTab, "Min Transparency (Far)", {0, 1}, 0.05, "MinTransparency")
createSlider(PlayerESPTab, "Max Transparency (Near)", {0, 1}, 0.05, "MaxTransparency")

PlayerESPTab:CreateSection("Colors")
PlayerESPTab:CreateColorPicker({
    Name = "ESP Color (if not using team colors)", 
    Color = getgenv().Config.ESPColor, 
    Callback = function(c) getgenv().Config.ESPColor = c end
})

-- NPC ESP Settings
NPCESPTab:CreateSection("Main Settings")
createToggle(NPCESPTab, "Enable NPC ESP", "NPCESPEnabled", function(s)
    getgenv().Config.NPCESPEnabled = s
    if not s then 
        for _, esp in pairs(getgenv().NPCESPObjects) do 
            if esp.Dot then esp.Dot:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.HealthBar then esp.HealthBar:Remove() end
            if esp.HealthBarBG then esp.HealthBarBG:Remove() end
            if esp.Box then esp.Box:Remove() end
        end
        getgenv().NPCESPObjects = {} 
    end
end)

NPCESPTab:CreateSection("Display Options")
createToggle(NPCESPTab, "Show NPC Name", "NPCShowName")
createToggle(NPCESPTab, "Show NPC Distance", "NPCShowDistance")
createToggle(NPCESPTab, "Show NPC Health Bar", "NPCShowHealthBar")
createToggle(NPCESPTab, "Show NPC Box ESP", "NPCShowBoxESP")

NPCESPTab:CreateSection("Customization")
createSlider(NPCESPTab, "NPC Dot Size", {1, 15}, 0.5, "NPCSize")
createSlider(NPCESPTab, "NPC Max Distance", {100, 10000}, 100, "NPCMaxDistance")

NPCESPTab:CreateSection("Transparency")
createSlider(NPCESPTab, "NPC Transparency", {0, 1}, 0.05, "NPCTransparency")
createToggle(NPCESPTab, "Distance Based Transparency", "NPCDistanceBasedTransparency")
createSlider(NPCESPTab, "Min Transparency (Far)", {0, 1}, 0.05, "NPCMinTransparency")
createSlider(NPCESPTab, "Max Transparency (Near)", {0, 1}, 0.05, "NPCMaxTransparency")

NPCESPTab:CreateSection("Colors")
NPCESPTab:CreateColorPicker({
    Name = "NPC ESP Color", 
    Color = getgenv().Config.NPCColor, 
    Callback = function(c) getgenv().Config.NPCColor = c end
})

-- Settings Tab
SettingsTab:CreateSection("Info")
SettingsTab:CreateParagraph({Title = "Script Info", Content = "Enhanced ESP with Player and NPC detection. Includes health bars, distance indicators, and box ESP."})

SettingsTab:CreateSection("Actions")
SettingsTab:CreateButton({
    Name = "Refresh ESP",
    Callback = function()
        -- Clear all ESP
        for _, esp in pairs(getgenv().ESPObjects) do 
            if esp.Dot then esp.Dot:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.HealthBar then esp.HealthBar:Remove() end
            if esp.HealthBarBG then esp.HealthBarBG:Remove() end
            if esp.Box then esp.Box:Remove() end
        end
        for _, esp in pairs(getgenv().NPCESPObjects) do 
            if esp.Dot then esp.Dot:Remove() end
            if esp.Name then esp.Name:Remove() end
            if esp.Distance then esp.Distance:Remove() end
            if esp.HealthBar then esp.HealthBar:Remove() end
            if esp.HealthBarBG then esp.HealthBarBG:Remove() end
            if esp.Box then esp.Box:Remove() end
        end
        getgenv().ESPObjects = {}
        getgenv().NPCESPObjects = {}
    end
})

local function createESP(player)
    if getgenv().ESPObjects[player] then return end
    
    local dot = Drawing.new("Circle")
    dot.Filled = true
    dot.Thickness = 1
    dot.NumSides = 16
    dot.Visible = false
    
    local name = Drawing.new("Text")
    name.Center = true
    name.Outline = true
    name.Size = 14
    name.Visible = false
    
    local distance = Drawing.new("Text")
    distance.Center = true
    distance.Outline = true
    distance.Size = 12
    distance.Visible = false
    
    local healthBar = Drawing.new("Line")
    healthBar.Thickness = 3
    healthBar.Visible = false
    
    local healthBarBG = Drawing.new("Line")
    healthBarBG.Thickness = 3
    healthBarBG.Color = Color3.fromRGB(0, 0, 0)
    healthBarBG.Visible = false
    
    local box = Drawing.new("Square")
    box.Thickness = getgenv().Config.BoxThickness
    box.Filled = false
    box.Visible = false
    
    getgenv().ESPObjects[player] = {
        Dot = dot, 
        Name = name, 
        Distance = distance,
        HealthBar = healthBar,
        HealthBarBG = healthBarBG,
        Box = box
    }
end

local function createNPCESP(model)
    if getgenv().NPCESPObjects[model] then return end
    
    local dot = Drawing.new("Circle")
    dot.Filled = true
    dot.Thickness = 1
    dot.NumSides = 16
    dot.Visible = false
    
    local name = Drawing.new("Text")
    name.Center = true
    name.Outline = true
    name.Size = 14
    name.Visible = false
    
    local distance = Drawing.new("Text")
    distance.Center = true
    distance.Outline = true
    distance.Size = 12
    distance.Visible = false
    
    local healthBar = Drawing.new("Line")
    healthBar.Thickness = 3
    healthBar.Visible = false
    
    local healthBarBG = Drawing.new("Line")
    healthBarBG.Thickness = 3
    healthBarBG.Color = Color3.fromRGB(0, 0, 0)
    healthBarBG.Visible = false
    
    local box = Drawing.new("Square")
    box.Thickness = getgenv().Config.BoxThickness
    box.Filled = false
    box.Visible = false
    
    getgenv().NPCESPObjects[model] = {
        Dot = dot, 
        Name = name, 
        Distance = distance,
        HealthBar = healthBar,
        HealthBarBG = healthBarBG,
        Box = box
    }
end

local function removeESP(player)
    local esp = getgenv().ESPObjects[player]
    if esp then
        if esp.Dot then esp.Dot:Remove() end
        if esp.Name then esp.Name:Remove() end
        if esp.Distance then esp.Distance:Remove() end
        if esp.HealthBar then esp.HealthBar:Remove() end
        if esp.HealthBarBG then esp.HealthBarBG:Remove() end
        if esp.Box then esp.Box:Remove() end
    end
    getgenv().ESPObjects[player] = nil
end

local function removeNPCESP(model)
    local esp = getgenv().NPCESPObjects[model]
    if esp then
        if esp.Dot then esp.Dot:Remove() end
        if esp.Name then esp.Name:Remove() end
        if esp.Distance then esp.Distance:Remove() end
        if esp.HealthBar then esp.HealthBar:Remove() end
        if esp.HealthBarBG then esp.HealthBarBG:Remove() end
        if esp.Box then esp.Box:Remove() end
    end
    getgenv().NPCESPObjects[model] = nil
end

local function getHealth(humanoid)
    if not humanoid then return 0, 100 end
    return humanoid.Health, humanoid.MaxHealth
end

local function calculateTransparency(distance, maxDistance, minTrans, maxTrans)
    -- Calculate transparency based on distance (closer = more opaque)
    local normalizedDist = math.clamp(distance / maxDistance, 0, 1)
    return minTrans + (maxTrans - minTrans) * (1 - normalizedDist)
end

local function updatePlayerESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then continue end
        if not getgenv().ESPObjects[player] then createESP(player) end
        local esp = getgenv().ESPObjects[player]
        if not esp or not esp.Dot then continue end
        
        local char = player.Character
        if not char then 
            esp.Dot.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
            esp.Box.Visible = false
            continue 
        end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        local head = char:FindFirstChild("Head")
        
        if not hrp or not hum or hum.Health <= 0 then 
            esp.Dot.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
            esp.Box.Visible = false
            continue 
        end
        
        if getgenv().Config.ESPTeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then 
            esp.Dot.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
            esp.Box.Visible = false
            continue 
        end
        
        local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if not myHRP then 
            esp.Dot.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
            esp.Box.Visible = false
            continue 
        end
        
        local dist = (myHRP.Position - hrp.Position).Magnitude
        if dist > getgenv().Config.ESPMaxDistance then 
            esp.Dot.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
            esp.Box.Visible = false
            continue 
        end
        
        local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
        if not onScreen then 
            esp.Dot.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
            esp.Box.Visible = false
            continue 
        end
        
        local color = (getgenv().Config.ESPUseTeamColor and player.Team) and player.TeamColor.Color or getgenv().Config.ESPColor
        
        -- Calculate transparency
        local transparency = getgenv().Config.ESPTransparency
        if getgenv().Config.DistanceBasedTransparency then
            transparency = calculateTransparency(
                dist, 
                getgenv().Config.ESPMaxDistance,
                getgenv().Config.MinTransparency,
                getgenv().Config.MaxTransparency
            )
        end
        
        -- Dot
        esp.Dot.Visible = true
        esp.Dot.Position = Vector2.new(pos.X, pos.Y)
        esp.Dot.Radius = getgenv().Config.ESPSize
        esp.Dot.Color = color
        esp.Dot.Transparency = transparency
        
        -- Name
        if getgenv().Config.ShowName and head then
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
            esp.Name.Visible = true
            esp.Name.Position = Vector2.new(headPos.X, headPos.Y)
            esp.Name.Text = player.Name
            esp.Name.Color = color
            esp.Name.Transparency = transparency
        else
            esp.Name.Visible = false
        end
        
        -- Distance
        if getgenv().Config.ShowDistance then
            esp.Distance.Visible = true
            esp.Distance.Position = Vector2.new(pos.X, pos.Y + 20)
            esp.Distance.Text = string.format("[%d studs]", math.floor(dist))
            esp.Distance.Color = color
            esp.Distance.Transparency = transparency
        else
            esp.Distance.Visible = false
        end
        
        -- Health Bar
        if getgenv().Config.ShowHealthBar then
            local health, maxHealth = getHealth(hum)
            local healthPercent = health / maxHealth
            
            local barLength = 40
            local barStart = Vector2.new(pos.X - barLength/2, pos.Y + 35)
            local barEnd = Vector2.new(pos.X + barLength/2, pos.Y + 35)
            
            esp.HealthBarBG.Visible = true
            esp.HealthBarBG.From = barStart
            esp.HealthBarBG.To = barEnd
            esp.HealthBarBG.Transparency = transparency
            
            esp.HealthBar.Visible = true
            esp.HealthBar.From = barStart
            esp.HealthBar.To = Vector2.new(barStart.X + barLength * healthPercent, barStart.Y)
            esp.HealthBar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
            esp.HealthBar.Transparency = transparency
        else
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
        end
        
        -- Box ESP
        if getgenv().Config.ShowBoxESP and head then
            local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
            local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
            
            local height = math.abs(headPos.Y - legPos.Y)
            local width = height / 2
            
            esp.Box.Visible = true
            esp.Box.Size = Vector2.new(width, height)
            esp.Box.Position = Vector2.new(pos.X - width/2, headPos.Y)
            esp.Box.Color = color
            esp.Box.Thickness = getgenv().Config.BoxThickness
            esp.Box.Transparency = transparency
        else
            esp.Box.Visible = false
        end
    end
end

local function isNPC(model)
    if not model:IsA("Model") then return false end
    if Players:GetPlayerFromCharacter(model) then return false end
    
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
    
    return humanoid ~= nil and hrp ~= nil
end

local function updateNPCESP()
    local processedNPCs = {}
    
    for _, model in ipairs(workspace:GetDescendants()) do
        if isNPC(model) then
            processedNPCs[model] = true
            
            if not getgenv().NPCESPObjects[model] then 
                createNPCESP(model) 
            end
            
            local esp = getgenv().NPCESPObjects[model]
            if not esp or not esp.Dot then continue end
            
            local hrp = model:FindFirstChild("HumanoidRootPart") or model:FindFirstChild("Torso")
            local hum = model:FindFirstChildOfClass("Humanoid")
            local head = model:FindFirstChild("Head")
            
            if not hrp or not hum or hum.Health <= 0 then 
                esp.Dot.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthBarBG.Visible = false
                esp.Box.Visible = false
                continue 
            end
            
            local myHRP = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if not myHRP then 
                esp.Dot.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthBarBG.Visible = false
                esp.Box.Visible = false
                continue 
            end
            
            local dist = (myHRP.Position - hrp.Position).Magnitude
            if dist > getgenv().Config.NPCMaxDistance then 
                esp.Dot.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthBarBG.Visible = false
                esp.Box.Visible = false
                continue 
            end
            
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if not onScreen then 
                esp.Dot.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
                esp.HealthBar.Visible = false
                esp.HealthBarBG.Visible = false
                esp.Box.Visible = false
                continue 
            end
            
            local color = getgenv().Config.NPCColor
            
-- Calculate transparency
            local transparency = getgenv().Config.NPCTransparency
            if getgenv().Config.NPCDistanceBasedTransparency then
                transparency = calculateTransparency(
                    dist, 
                    getgenv().Config.NPCMaxDistance,
                    getgenv().Config.NPCMinTransparency,
                    getgenv().Config.NPCMaxTransparency
                )
            end
            
            -- Dot
            esp.Dot.Visible = true
            esp.Dot.Position = Vector2.new(pos.X, pos.Y)
            esp.Dot.Radius = getgenv().Config.NPCSize
            esp.Dot.Color = color
            esp.Dot.Transparency = transparency
            
            -- Name
            if getgenv().Config.NPCShowName and head then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 1, 0))
                esp.Name.Visible = true
                esp.Name.Position = Vector2.new(headPos.X, headPos.Y)
                esp.Name.Text = model.Name
                esp.Name.Color = color
                esp.Name.Transparency = transparency
            else
                esp.Name.Visible = false
            end
            
            -- Distance
            if getgenv().Config.NPCShowDistance then
                esp.Distance.Visible = true
                esp.Distance.Position = Vector2.new(pos.X, pos.Y + 20)
                esp.Distance.Text = string.format("[%d studs]", math.floor(dist))
                esp.Distance.Color = color
                esp.Distance.Transparency = transparency
            else
                esp.Distance.Visible = false
            end
            
            -- Health Bar
            if getgenv().Config.NPCShowHealthBar then
                local health, maxHealth = getHealth(hum)
                local healthPercent = health / maxHealth
                
                local barLength = 40
                local barStart = Vector2.new(pos.X - barLength/2, pos.Y + 35)
                local barEnd = Vector2.new(pos.X + barLength/2, pos.Y + 35)
                
                esp.HealthBarBG.Visible = true
                esp.HealthBarBG.From = barStart
                esp.HealthBarBG.To = barEnd
                esp.HealthBarBG.Transparency = transparency
                
                esp.HealthBar.Visible = true
                esp.HealthBar.From = barStart
                esp.HealthBar.To = Vector2.new(barStart.X + barLength * healthPercent, barStart.Y)
                esp.HealthBar.Color = Color3.new(1 - healthPercent, healthPercent, 0)
                esp.HealthBar.Transparency = transparency
            else
                esp.HealthBar.Visible = false
                esp.HealthBarBG.Visible = false
            end
            
            -- Box ESP
            if getgenv().Config.NPCShowBoxESP and head then
                local headPos = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                local legPos = Camera:WorldToViewportPoint(hrp.Position - Vector3.new(0, 3, 0))
                
                local height = math.abs(headPos.Y - legPos.Y)
                local width = height / 2
                
                esp.Box.Visible = true
                esp.Box.Size = Vector2.new(width, height)
                esp.Box.Position = Vector2.new(pos.X - width/2, headPos.Y)
                esp.Box.Color = color
                esp.Box.Thickness = getgenv().Config.BoxThickness
                esp.Box.Transparency = transparency
            else
                esp.Box.Visible = false
            end
        end
    end
    
    -- Clean up removed NPCs
    for model, esp in pairs(getgenv().NPCESPObjects) do
        if not processedNPCs[model] or not model.Parent then
            removeNPCESP(model)
        end
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    if player ~= LocalPlayer and getgenv().Config.ESPEnabled then 
        createESP(player) 
    end
end

Players.PlayerAdded:Connect(function(player)
    if getgenv().Config.ESPEnabled then createESP(player) end
end)

Players.PlayerRemoving:Connect(removeESP)

RunService.Heartbeat:Connect(function()
    if getgenv().Config.ESPEnabled then 
        updatePlayerESP() 
    end
    if getgenv().Config.NPCESPEnabled then 
        updateNPCESP() 
    end
end)
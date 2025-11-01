--// Hitbox Expander + ESP (Rayfield)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

getgenv().Config = getgenv().Config or {
    HitboxSize = 15,
    HitboxTransparency = 0.9,
    HitboxStatus = false,
    TeamCheck = false,
    SanityCheck = false,
    ExpandHead = true,
    ExpandTorso = true,
    ExpandLeftArm = false,
    ExpandRightArm = false,
    ExpandLeftLeg = false,
    ExpandRightLeg = false,
    ESPEnabled = false,
    ESPTeamCheck = false,
    ESPUseTeamColor = true,
    ESPColor = Color3.fromRGB(255, 0, 0),
    ESPSize = 3,
    ESPMaxDistance = 5000,
}

getgenv().ESPObjects = getgenv().ESPObjects or {}

local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Window = Rayfield:CreateWindow({
    Name = "Hitbox Expander",
    LoadingTitle = "Hitbox Expander",
    LoadingSubtitle = "by Script",
    ConfigurationSaving = {Enabled = false},
    Discord = {Enabled = false},
    KeySystem = false
})

local HomeTab = Window:CreateTab("Home", 4483362458)
local PartsTab = Window:CreateTab("Body Parts", 4483362458)
local ESPTab = Window:CreateTab("ESP", 4483362458)

HomeTab:CreateSection("Hitbox Settings")

HomeTab:CreateInput({
    Name = "Hitbox Size",
    PlaceholderText = tostring(getgenv().Config.HitboxSize),
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        getgenv().Config.HitboxSize = tonumber(v) or 15
    end
})

HomeTab:CreateInput({
    Name = "Hitbox Transparency",
    PlaceholderText = tostring(getgenv().Config.HitboxTransparency),
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        getgenv().Config.HitboxTransparency = tonumber(v) or 0.9
    end
})

HomeTab:CreateToggle({
    Name = "Enable Hitbox",
    CurrentValue = getgenv().Config.HitboxStatus,
    Callback = function(s)
        getgenv().Config.HitboxStatus = s
    end
})

HomeTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = getgenv().Config.TeamCheck,
    Callback = function(s)
        getgenv().Config.TeamCheck = s
    end
})

HomeTab:CreateToggle({
    Name = "Sanity Check (Auto Remove on Death)",
    CurrentValue = getgenv().Config.SanityCheck,
    Callback = function(s)
        getgenv().Config.SanityCheck = s
    end
})

PartsTab:CreateSection("Select Body Parts to Expand")

PartsTab:CreateToggle({
    Name = "Head",
    CurrentValue = getgenv().Config.ExpandHead,
    Callback = function(s)
        getgenv().Config.ExpandHead = s
    end
})

PartsTab:CreateToggle({
    Name = "Torso / HumanoidRootPart",
    CurrentValue = getgenv().Config.ExpandTorso,
    Callback = function(s)
        getgenv().Config.ExpandTorso = s
    end
})

PartsTab:CreateToggle({
    Name = "Left Arm",
    CurrentValue = getgenv().Config.ExpandLeftArm,
    Callback = function(s)
        getgenv().Config.ExpandLeftArm = s
    end
})

PartsTab:CreateToggle({
    Name = "Right Arm",
    CurrentValue = getgenv().Config.ExpandRightArm,
    Callback = function(s)
        getgenv().Config.ExpandRightArm = s
    end
})

PartsTab:CreateToggle({
    Name = "Left Leg",
    CurrentValue = getgenv().Config.ExpandLeftLeg,
    Callback = function(s)
        getgenv().Config.ExpandLeftLeg = s
    end
})

PartsTab:CreateToggle({
    Name = "Right Leg",
    CurrentValue = getgenv().Config.ExpandRightLeg,
    Callback = function(s)
        getgenv().Config.ExpandRightLeg = s
    end
})

ESPTab:CreateSection("ESP Settings")

ESPTab:CreateToggle({
    Name = "Enable ESP",
    CurrentValue = getgenv().Config.ESPEnabled,
    Callback = function(s)
        getgenv().Config.ESPEnabled = s
        if not s then
            for _, esp in pairs(getgenv().ESPObjects) do
                if esp.Dot then esp.Dot:Remove() end
            end
            getgenv().ESPObjects = {}
        end
    end
})

ESPTab:CreateToggle({
    Name = "ESP Team Check (Hide Teammates)",
    CurrentValue = getgenv().Config.ESPTeamCheck,
    Callback = function(s)
        getgenv().Config.ESPTeamCheck = s
    end
})

ESPTab:CreateToggle({
    Name = "Use Team Colors",
    CurrentValue = getgenv().Config.ESPUseTeamColor,
    Callback = function(s)
        getgenv().Config.ESPUseTeamColor = s
    end
})

ESPTab:CreateSlider({
    Name = "Dot Size",
    Range = {1, 10},
    Increment = 0.5,
    CurrentValue = getgenv().Config.ESPSize,
    Callback = function(v)
        getgenv().Config.ESPSize = v
    end
})

ESPTab:CreateSlider({
    Name = "Max Distance",
    Range = {100, 10000},
    Increment = 100,
    CurrentValue = getgenv().Config.ESPMaxDistance,
    Callback = function(v)
        getgenv().Config.ESPMaxDistance = v
    end
})

ESPTab:CreateColorPicker({
    Name = "Dot Color (if not using team colors)",
    Color = getgenv().Config.ESPColor,
    Callback = function(c)
        getgenv().Config.ESPColor = c
    end
})

getgenv().partMapping = {
    Head = {"Head"},
    Torso = {"Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    LeftArm = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    RightArm = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    LeftLeg = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    RightLeg = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
}

local function shouldExpandPart(partName)
    if getgenv().Config.ExpandHead then
        for _, name in ipairs(getgenv().partMapping.Head) do
            if partName == name then return true end
        end
    end
    if getgenv().Config.ExpandTorso then
        for _, name in ipairs(getgenv().partMapping.Torso) do
            if partName == name then return true end
        end
    end
    if getgenv().Config.ExpandLeftArm then
        for _, name in ipairs(getgenv().partMapping.LeftArm) do
            if partName == name then return true end
        end
    end
    if getgenv().Config.ExpandRightArm then
        for _, name in ipairs(getgenv().partMapping.RightArm) do
            if partName == name then return true end
        end
    end
    if getgenv().Config.ExpandLeftLeg then
        for _, name in ipairs(getgenv().partMapping.LeftLeg) do
            if partName == name then return true end
        end
    end
    if getgenv().Config.ExpandRightLeg then
        for _, name in ipairs(getgenv().partMapping.RightLeg) do
            if partName == name then return true end
        end
    end
    return false
end

local function createESP(player)
    if getgenv().ESPObjects[player] then return end
    local esp = {Dot = Drawing.new("Circle")}
    esp.Dot.Filled = true
    esp.Dot.Thickness = 1
    esp.Dot.NumSides = 12
    getgenv().ESPObjects[player] = esp
end

local function removeESP(player)
    if getgenv().ESPObjects[player] then
        local esp = getgenv().ESPObjects[player]
        if esp.Dot then esp.Dot:Remove() end
        getgenv().ESPObjects[player] = nil
    end
end

local function updateESP()
    if not getgenv().Config.ESPEnabled then return end
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not getgenv().ESPObjects[player] then createESP(player) end
            local esp = getgenv().ESPObjects[player]
            if not esp then continue end
            if not player.Character then esp.Dot.Visible = false; continue end
            local char = player.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if not hrp or not hum then esp.Dot.Visible = false; continue end
            if hum.Health <= 0 then esp.Dot.Visible = false; continue end
            if getgenv().Config.ESPTeamCheck and player.Team and LocalPlayer.Team and player.Team == LocalPlayer.Team then esp.Dot.Visible = false; continue end
            local myChar = LocalPlayer.Character
            local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if not myHRP then esp.Dot.Visible = false; continue end
            local distance = (myHRP.Position - hrp.Position).Magnitude
            if distance > getgenv().Config.ESPMaxDistance then esp.Dot.Visible = false; continue end
            local pos, onScreen = Camera:WorldToViewportPoint(hrp.Position)
            if not onScreen then esp.Dot.Visible = false; continue end
            esp.Dot.Visible = true
            esp.Dot.Position = Vector2.new(pos.X, pos.Y)
            esp.Dot.Radius = getgenv().Config.ESPSize
            if getgenv().Config.ESPUseTeamColor and player.Team then
                esp.Dot.Color = player.TeamColor.Color
            else
                esp.Dot.Color = getgenv().Config.ESPColor
            end
        end
    end
end

Players.PlayerRemoving:Connect(function(player) removeESP(player) end)
Players.PlayerAdded:Connect(function(player) if getgenv().Config.ESPEnabled then createESP(player) end end)

local function updateHitbox()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            local isEnemy = not getgenv().Config.TeamCheck or plr.Team ~= LocalPlayer.Team
            local isAlive = not getgenv().Config.SanityCheck or (hum and hum.Health > 0)
            if getgenv().Config.HitboxStatus and isEnemy and isAlive then
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") and shouldExpandPart(part.Name) then
                        part.Size = Vector3.new(getgenv().Config.HitboxSize, getgenv().Config.HitboxSize, getgenv().Config.HitboxSize)
                        part.Transparency = getgenv().Config.HitboxTransparency
                        part.BrickColor = BrickColor.new("Really black")
                        part.Material = Enum.Material.Neon
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(function() updateHitbox(); updateESP() end)
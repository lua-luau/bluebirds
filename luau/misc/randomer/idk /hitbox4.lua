--// Simple Hitbox Expander (Rayfield)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

getgenv().Config = {
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
}

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

HomeTab:CreateSection("Hitbox Settings")

HomeTab:CreateInput({
    Name = "Hitbox Size",
    PlaceholderText = "15",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        Config.HitboxSize = tonumber(v) or 15
    end
})

HomeTab:CreateInput({
    Name = "Hitbox Transparency",
    PlaceholderText = "0.9",
    RemoveTextAfterFocusLost = false,
    Callback = function(v)
        Config.HitboxTransparency = tonumber(v) or 0.9
    end
})

HomeTab:CreateToggle({
    Name = "Enable Hitbox",
    CurrentValue = false,
    Callback = function(s)
        Config.HitboxStatus = s
    end
})

HomeTab:CreateToggle({
    Name = "Team Check",
    CurrentValue = false,
    Callback = function(s)
        Config.TeamCheck = s
    end
})

HomeTab:CreateToggle({
    Name = "Sanity Check (Auto Remove on Death)",
    CurrentValue = false,
    Callback = function(s)
        Config.SanityCheck = s
    end
})

PartsTab:CreateSection("Select Body Parts to Expand")

PartsTab:CreateToggle({
    Name = "Head",
    CurrentValue = true,
    Callback = function(s)
        Config.ExpandHead = s
    end
})

PartsTab:CreateToggle({
    Name = "Torso / HumanoidRootPart",
    CurrentValue = true,
    Callback = function(s)
        Config.ExpandTorso = s
    end
})

PartsTab:CreateToggle({
    Name = "Left Arm",
    CurrentValue = false,
    Callback = function(s)
        Config.ExpandLeftArm = s
    end
})

PartsTab:CreateToggle({
    Name = "Right Arm",
    CurrentValue = false,
    Callback = function(s)
        Config.ExpandRightArm = s
    end
})

PartsTab:CreateToggle({
    Name = "Left Leg",
    CurrentValue = false,
    Callback = function(s)
        Config.ExpandLeftLeg = s
    end
})

PartsTab:CreateToggle({
    Name = "Right Leg",
    CurrentValue = false,
    Callback = function(s)
        Config.ExpandRightLeg = s
    end
})

local partMapping = {
    Head = {"Head"},
    Torso = {"Torso", "HumanoidRootPart", "UpperTorso", "LowerTorso"},
    LeftArm = {"Left Arm", "LeftUpperArm", "LeftLowerArm", "LeftHand"},
    RightArm = {"Right Arm", "RightUpperArm", "RightLowerArm", "RightHand"},
    LeftLeg = {"Left Leg", "LeftUpperLeg", "LeftLowerLeg", "LeftFoot"},
    RightLeg = {"Right Leg", "RightUpperLeg", "RightLowerLeg", "RightFoot"}
}

local function shouldExpandPart(partName)
    if Config.ExpandHead then
        for _, name in ipairs(partMapping.Head) do
            if partName == name then return true end
        end
    end
    if Config.ExpandTorso then
        for _, name in ipairs(partMapping.Torso) do
            if partName == name then return true end
        end
    end
    if Config.ExpandLeftArm then
        for _, name in ipairs(partMapping.LeftArm) do
            if partName == name then return true end
        end
    end
    if Config.ExpandRightArm then
        for _, name in ipairs(partMapping.RightArm) do
            if partName == name then return true end
        end
    end
    if Config.ExpandLeftLeg then
        for _, name in ipairs(partMapping.LeftLeg) do
            if partName == name then return true end
        end
    end
    if Config.ExpandRightLeg then
        for _, name in ipairs(partMapping.RightLeg) do
            if partName == name then return true end
        end
    end
    return false
end

local function updateHitbox()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            local isEnemy = not Config.TeamCheck or plr.Team ~= LocalPlayer.Team
            local isAlive = not Config.SanityCheck or (hum and hum.Health > 0)
            
            if Config.HitboxStatus and isEnemy and isAlive then
                for _, part in pairs(char:GetChildren()) do
                    if part:IsA("BasePart") and shouldExpandPart(part.Name) then
                        part.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                        part.Transparency = Config.HitboxTransparency
                        part.BrickColor = BrickColor.new("Really black")
                        part.Material = Enum.Material.Neon
                        part.CanCollide = false
                    end
                end
            end
        end
    end
end

RunService.RenderStepped:Connect(updateHitbox)
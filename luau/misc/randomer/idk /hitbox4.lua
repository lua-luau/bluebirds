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
    ExpandAllParts = true,
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
    Name = "Expand All Body Parts",
    CurrentValue = true,
    Callback = function(s)
        Config.ExpandAllParts = s
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

local function updateHitbox()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local char = plr.Character
            local hum = char:FindFirstChildOfClass("Humanoid")
            
            local isEnemy = not Config.TeamCheck or plr.Team ~= LocalPlayer.Team
            local isAlive = not Config.SanityCheck or (hum and hum.Health > 0)
            
            if Config.HitboxStatus and isEnemy and isAlive then
                if Config.ExpandAllParts then
                    -- Expand all body parts
                    for _, part in pairs(char:GetChildren()) do
                        if part:IsA("BasePart") then
                            part.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                            part.Transparency = Config.HitboxTransparency
                            part.BrickColor = BrickColor.new("Really black")
                            part.Material = Enum.Material.Neon
                            part.CanCollide = false
                        end
                    end
                else
                    -- Only expand HumanoidRootPart
                    local hrp = char:FindFirstChild("HumanoidRootPart")
                    if hrp then
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
end

RunService.RenderStepped:Connect(updateHitbox)
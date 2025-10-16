--// Hitbox Expander + Utility UI (Rayfield)

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local LocalPlayer = Players.LocalPlayer

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
}

--// Store original hitbox data to prevent vehicle freezing
local OriginalHitboxData = {}

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
        if not s then
            -- Restore original hitboxes when disabled
            for plr, data in pairs(OriginalHitboxData) do
                if plr.Character then
                    local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        hrp.Size = data.Size
                        hrp.Transparency = data.Transparency
                        hrp.BrickColor = data.BrickColor
                        hrp.Material = data.Material
                        hrp.CanCollide = data.CanCollide
                    end
                end
            end
        end
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

--// Hitbox Logic (Fixed to prevent vehicle freezing)
local function updateHitbox()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            
            if hrp then
                -- Store original data if not already stored
                if not OriginalHitboxData[plr] then
                    OriginalHitboxData[plr] = {
                        Size = hrp.Size,
                        Transparency = hrp.Transparency,
                        BrickColor = hrp.BrickColor,
                        Material = hrp.Material,
                        CanCollide = hrp.CanCollide
                    }
                end
                
                -- Check if player is in a vehicle (humanoid sit state)
                local isInVehicle = hum and hum.Sit
                
                local isEnemy = not Config.TeamCheck or plr.Team ~= LocalPlayer.Team
                local isAlive = not Config.SanityCheck or (hum and hum.Health > 0)
                
                -- Only modify hitbox if NOT in vehicle and conditions are met
                if Config.HitboxStatus and isEnemy and isAlive and not isInVehicle then
                    hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    hrp.Transparency = Config.HitboxTransparency
                    hrp.BrickColor = BrickColor.new("Really black")
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                    hrp.Massless = true -- Prevent physics issues
                else
                    -- Restore original properties
                    local orig = OriginalHitboxData[plr]
                    if orig then
                        hrp.Size = orig.Size
                        hrp.Transparency = orig.Transparency
                        hrp.BrickColor = orig.BrickColor
                        hrp.Material = orig.Material
                        hrp.CanCollide = orig.CanCollide
                    end
                end
            end
        end
    end
end

-- Clean up stored data when player leaves
Players.PlayerRemoving:Connect(function(plr)
    OriginalHitboxData[plr] = nil
end)

RunService.RenderStepped:Connect(updateHitbox)
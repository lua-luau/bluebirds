--// LocalScript - Skeleton ESP (R6 + R15 support)
--// Requires Drawing API (not usable in vanilla Roblox Studio)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Configuration
local Settings = {
    Enabled = true,                    -- toggle ESP on/off
    Hotkey = Enum.KeyCode.L,           -- toggle key
    Color = Color3.fromRGB(0, 255, 0), -- default skeleton color
    Thickness = 1.5,                   -- line thickness
    TeamCheck = true,                  -- only show enemies
    DeathCheck = true,                 -- hide skeleton if humanoid dead
    Transparency = 1,                  -- line transparency
}

--// Connections for R6 rigs
local R6Connections = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"},
}

--// Connections for R15 rigs
local R15Connections = {
    {"Head", "UpperTorso"},
    {"UpperTorso", "LowerTorso"},
    {"LowerTorso", "LeftUpperLeg"},
    {"LeftUpperLeg", "LeftLowerLeg"},
    {"LeftLowerLeg", "LeftFoot"},
    {"LowerTorso", "RightUpperLeg"},
    {"RightUpperLeg", "RightLowerLeg"},
    {"RightLowerLeg", "RightFoot"},
    {"UpperTorso", "LeftUpperArm"},
    {"LeftUpperArm", "LeftLowerArm"},
    {"LeftLowerArm", "LeftHand"},
    {"UpperTorso", "RightUpperArm"},
    {"RightUpperArm", "RightLowerArm"},
    {"RightLowerArm", "RightHand"},
}

--// Skeleton storage
local Skeletons = {}

--// Drawing line constructor
local function NewLine()
    local line = Drawing.new("Line")
    line.Color = Settings.Color
    line.Thickness = Settings.Thickness
    line.Transparency = Settings.Transparency
    line.Visible = false
    return line
end

--// Detect rig type
local function GetRigType(Character)
    if Character:FindFirstChild("UpperTorso") then
        return "R15"
    elseif Character:FindFirstChild("Torso") then
        return "R6"
    end
end

--// Create skeleton for a player
local function CreateSkeleton(Player, Character)
    local rigType = GetRigType(Character)
    if not rigType then return end

    local connections = (rigType == "R6") and R6Connections or R15Connections
    local lines = {}

    for _ = 1, #connections do
        table.insert(lines, NewLine())
    end

    Skeletons[Player] = {
        Character = Character,
        Lines = lines,
        Connections = connections,
    }
end

--// Cleanup skeleton
local function RemoveSkeleton(Player)
    local skeleton = Skeletons[Player]
    if skeleton then
        for _, line in ipairs(skeleton.Lines) do
            line:Remove()
        end
        Skeletons[Player] = nil
    end
end

--// Setup player connections
local function SetupPlayer(Player)
    if Player == LocalPlayer then return end

    Player.CharacterAdded:Connect(function(Character)
        task.wait(1) -- allow time to load
        CreateSkeleton(Player, Character)
    end)

    Player.CharacterRemoving:Connect(function()
        RemoveSkeleton(Player)
    end)
end

--// Initialize existing players
for _, plr in ipairs(Players:GetPlayers()) do
    SetupPlayer(plr)
    if plr ~= LocalPlayer and plr.Character then
        CreateSkeleton(plr, plr.Character)
    end
end

--// New players
Players.PlayerAdded:Connect(SetupPlayer)
Players.PlayerRemoving:Connect(RemoveSkeleton)

--// Hotkey toggle
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.Hotkey then
        Settings.Enabled = not Settings.Enabled
        -- Hide all lines immediately when turning off
        if not Settings.Enabled then
            for _, data in pairs(Skeletons) do
                for _, line in ipairs(data.Lines) do
                    line.Visible = false
                end
            end
        end
        print("Skeleton ESP:", Settings.Enabled and "Enabled" or "Disabled")
    end
end)

--// Update loop
RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then return end

    for Player, data in pairs(Skeletons) do
        local Character = data.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

        local valid = Character and Character.Parent
        if valid and Settings.DeathCheck then
            valid = Humanoid and Humanoid.Health > 0
        end
        if valid and Settings.TeamCheck then
            valid = Player.Team ~= LocalPlayer.Team
        end

        if valid then
            for i, conn in ipairs(data.Connections) do
                local part1 = Character:FindFirstChild(conn[1])
                local part2 = Character:FindFirstChild(conn[2])
                local line = data.Lines[i]

                if part1 and part2 then
                    local pos1, vis1 = Camera:WorldToViewportPoint(part1.Position)
                    local pos2, vis2 = Camera:WorldToViewportPoint(part2.Position)

                    if vis1 and vis2 then
                        line.From = Vector2.new(pos1.X, pos1.Y)
                        line.To = Vector2.new(pos2.X, pos2.Y)
                        line.Visible = true
                    else
                        line.Visible = false
                    end
                else
                    line.Visible = false
                end
            end
        else
            for _, line in ipairs(data.Lines) do
                line.Visible = false
            end
        end
    end
end)
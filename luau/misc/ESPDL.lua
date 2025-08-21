--// LocalScript - ESP (Skeleton + Box, R6 + R15 support)
--// Requires Drawing API (not usable in vanilla Roblox Studio)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

--// Configuration
local Settings = {
    Enabled = true,                         -- toggle ESP on/off
    HotkeyToggle = Enum.KeyCode.L,          -- toggle ESP enable/disable
    HotkeySwitch = Enum.KeyCode.RightBracket, -- switch ESP mode (] key)
    ESPMode = "Skeleton",                   -- "Skeleton" or "Box"
    Color = Color3.fromRGB(0, 255, 0),      -- default ESP color
    Thickness = 1.5,                        -- skeleton line thickness
    TeamCheck = true,                       -- only show enemies
    DeathCheck = true,                      -- hide dead players
    Transparency = 1,                       -- line/box transparency
}

--// Skeleton connections
local R6Connections = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"},
}
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
local ESPObjects = {}

--// Drawing constructors
local function NewLine()
    local line = Drawing.new("Line")
    line.Color = Settings.Color
    line.Thickness = Settings.Thickness
    line.Transparency = Settings.Transparency
    line.Visible = false
    return line
end
local function NewBox()
    local box = Drawing.new("Square")
    box.Color = Settings.Color
    box.Thickness = 1
    box.Transparency = Settings.Transparency
    box.Filled = false
    box.Visible = false
    return box
end

--// Detect rig type
local function GetRigType(Character)
    if Character:FindFirstChild("UpperTorso") then
        return "R15"
    elseif Character:FindFirstChild("Torso") then
        return "R6"
    end
end

--// Create ESP for a player
local function CreateESP(Player, Character)
    local rigType = GetRigType(Character)
    if not rigType then return end

    local connections = (rigType == "R6") and R6Connections or R15Connections
    local lines = {}
    for _ = 1, #connections do
        table.insert(lines, NewLine())
    end

    local box = NewBox()

    ESPObjects[Player] = {
        Character = Character,
        Lines = lines,
        Connections = connections,
        Box = box,
    }
end

--// Cleanup ESP
local function RemoveESP(Player)
    local esp = ESPObjects[Player]
    if esp then
        for _, line in ipairs(esp.Lines) do line:Remove() end
        esp.Box:Remove()
        ESPObjects[Player] = nil
    end
end

--// Setup player connections
local function SetupPlayer(Player)
    if Player == LocalPlayer then return end

    Player.CharacterAdded:Connect(function(Character)
        task.wait(1) -- allow time to load
        CreateESP(Player, Character)
    end)
    Player.CharacterRemoving:Connect(function()
        RemoveESP(Player)
    end)
end

--// Initialize existing players
for _, plr in ipairs(Players:GetPlayers()) do
    SetupPlayer(plr)
    if plr ~= LocalPlayer and plr.Character then
        CreateESP(plr, plr.Character)
    end
end
Players.PlayerAdded:Connect(SetupPlayer)
Players.PlayerRemoving:Connect(RemoveESP)

--// Hotkeys
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Settings.HotkeyToggle then
        Settings.Enabled = not Settings.Enabled
        for _, data in pairs(ESPObjects) do
            for _, line in ipairs(data.Lines) do line.Visible = false end
            data.Box.Visible = false
        end
        print("ESP:", Settings.Enabled and "Enabled" or "Disabled")
    elseif input.KeyCode == Settings.HotkeySwitch then
        Settings.ESPMode = (Settings.ESPMode == "Skeleton") and "Box" or "Skeleton"
        for _, data in pairs(ESPObjects) do
            for _, line in ipairs(data.Lines) do line.Visible = false end
            data.Box.Visible = false
        end
        print("ESP Mode:", Settings.ESPMode)
    end
end)

--// Update loop
RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then return end

    for Player, data in pairs(ESPObjects) do
        local Character = data.Character
        local Humanoid = Character and Character:FindFirstChildOfClass("Humanoid")

        local valid = Character and Character.Parent
        if valid and Settings.DeathCheck then
            valid = Humanoid and Humanoid.Health > 0
        end
        if valid and Settings.TeamCheck then
            valid = Player.Team ~= LocalPlayer.Team
        end

        if not valid then
            for _, line in ipairs(data.Lines) do line.Visible = false end
            data.Box.Visible = false
            continue
        end

        if Settings.ESPMode == "Skeleton" then
            data.Box.Visible = false
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
        elseif Settings.ESPMode == "Box" then
            for _, line in ipairs(data.Lines) do line.Visible = false end
            local box = data.Box
            local hrp = Character:FindFirstChild("HumanoidRootPart")
            local head = Character:FindFirstChild("Head")
            if hrp and head then
                local hrpPos, hrpVis = Camera:WorldToViewportPoint(hrp.Position)
                local headPos, headVis = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 0.5, 0))
                if hrpVis and headVis then
                    local height = (headPos.Y - hrpPos.Y)
                    local width = height / 2
                    box.Position = Vector2.new(hrpPos.X - width/2, hrpPos.Y - height/2)
                    box.Size = Vector2.new(width, height)
                    box.Visible = true
                else
                    box.Visible = false
                end
            else
                box.Visible = false
            end
        end
    end
end)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- Settings
getgenv().Enabled = getgenv().Enabled or true
getgenv().Rainbow = getgenv().Rainbow or false
getgenv().TeamCheck = getgenv().TeamCheck or true

local skeletons = {}
local linePool = {}

-- Line pool functions
local function getLine()
    for i, line in ipairs(linePool) do
        table.remove(linePool, i)
        return line
    end
    local newLine = Drawing.new("Line")
    newLine.Color = Color3.new(1,0,0)
    newLine.Thickness = 2
    newLine.Transparency = 1
    newLine.Visible = false
    return newLine
end

local function returnLines(lines)
    for _, d in ipairs(lines) do
        d.line.Visible = false
        table.insert(linePool, d.line)
    end
end

-- Create a R6-style skeleton (even if character is R15)
local function createSkeleton(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end

    local Head = char:FindFirstChild("Head")
    local Torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("Torso")
    local LeftArm = char:FindFirstChild("LeftUpperArm") or char:FindFirstChild("Left Arm")
    local RightArm = char:FindFirstChild("RightUpperArm") or char:FindFirstChild("Right Arm")
    local LeftLeg = char:FindFirstChild("LeftUpperLeg") or char:FindFirstChild("Left Leg")
    local RightLeg = char:FindFirstChild("RightUpperLeg") or char:FindFirstChild("Right Leg")

    if not (Head and Torso and LeftArm and RightArm and LeftLeg and RightLeg) then return end

    local parts = {
        {Head, Torso},
        {Torso, LeftArm},
        {Torso, RightArm},
        {Torso, LeftLeg},
        {Torso, RightLeg},
    }

    local lines = {}
    for _, pair in ipairs(parts) do
        local line = getLine()
        table.insert(lines, {line = line, p1 = pair[1], p2 = pair[2]})
    end

    skeletons[player] = lines

    -- Remove skeleton on death
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if humanoid then
        humanoid.Died:Connect(function()
            returnLines(lines)
            skeletons[player] = nil
        end)
    end
end

-- Update skeleton every frame
local function updateSkeleton(player)
    local lines = skeletons[player]
    if not lines then return end
    local char = player.Character
    if not char then
        returnLines(lines)
        skeletons[player] = nil
        return
    end

    -- Toggle off
    if not getgenv().Enabled then
        for _, d in ipairs(lines) do d.line.Visible = false end
        return
    end

    -- Team check
    if getgenv().TeamCheck and player.Team == LocalPlayer.Team then
        for _, d in ipairs(lines) do d.line.Visible = false end
        return
    end

    local color = Color3.new(1,0,0)
    if getgenv().Rainbow then
        local hue = (tick()%5)/5
        color = Color3.fromHSV(hue,1,1)
    end

    for _, d in ipairs(lines) do
        local p1, p2 = d.p1, d.p2
        if p1 and p2 and p1.Parent and p2.Parent then
            local pos1 = Camera:WorldToViewportPoint(p1.Position)
            local pos2 = Camera:WorldToViewportPoint(p2.Position)
            if pos1.Z > 0 and pos2.Z > 0 then
                d.line.From = Vector2.new(pos1.X,pos1.Y)
                d.line.To = Vector2.new(pos2.X,pos2.Y)
                d.line.Color = color
                d.line.Visible = true
            else
                d.line.Visible = false
            end
        else
            d.line.Visible = false
        end
    end
end

-- Player handling
local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function()
        repeat task.wait() until player.Character and player.Character:FindFirstChild("Head")
        task.wait(0.1)
        createSkeleton(player)
    end)
    if player.Character then createSkeleton(player) end
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    local lines = skeletons[player]
    if lines then
        returnLines(lines)
        skeletons[player] = nil
    end
end)

-- Keybinds
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.L then
        getgenv().Enabled = not getgenv().Enabled
    elseif input.KeyCode == Enum.KeyCode.LeftBracket then
        getgenv().Rainbow = not getgenv().Rainbow
    elseif input.KeyCode == Enum.KeyCode.RightBracket then
        getgenv().TeamCheck = not getgenv().TeamCheck
        print("TeamCheck:", getgenv().TeamCheck)
    end
end)

-- Render loop
RunService.RenderStepped:Connect(function()
    for player, _ in pairs(skeletons) do
        updateSkeleton(player)
    end
end)
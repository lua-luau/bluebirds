local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

getgenv().TeamCheck = getgenv().TeamCheck or true
getgenv().Enabled = getgenv().Enabled or true
getgenv().Rainbow = getgenv().Rainbow or false

local skeletons = {}
local linePool = {} -- line reuse pool

-- R6-style connections (simplified for R15 too)
local connectionsTemplate = {
    {"Head", "Torso"},
    {"Torso", "Left Arm"},
    {"Torso", "Right Arm"},
    {"Torso", "Left Leg"},
    {"Torso", "Right Leg"},
}

-- Line pool helper
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

local function returnLines(drawings)
    for _, d in ipairs(drawings) do
        d.line.Visible = false
        table.insert(linePool, d.line)
    end
end

local function createSkeleton(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char then return end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local rigType = humanoid.RigType
    local drawings = {}
    local connections = {}

    for _, conn in ipairs(connectionsTemplate) do
        local part1, part2 = nil, nil
        if rigType == Enum.HumanoidRigType.R6 then
            part1 = char:FindFirstChild(conn[1])
            part2 = char:FindFirstChild(conn[2])
        else -- R15 -> R6 approximation
            local mapping = {
                Head = char:FindFirstChild("Head"),
                Torso = char:FindFirstChild("UpperTorso") or char:FindFirstChild("LowerTorso"),
                ["Left Arm"] = char:FindFirstChild("LeftUpperArm"),
                ["Right Arm"] = char:FindFirstChild("RightUpperArm"),
                ["Left Leg"] = char:FindFirstChild("LeftUpperLeg"),
                ["Right Leg"] = char:FindFirstChild("RightUpperLeg"),
            }
            part1 = mapping[conn[1]]
            part2 = mapping[conn[2]]
        end

        if part1 and part2 then
            local line = getLine()
            table.insert(drawings, {line = line, part1 = part1, part2 = part2})
            table.insert(connections, {part1, part2})
        end
    end

    skeletons[player] = {drawings = drawings, connections = connections}

    humanoid.Died:Connect(function()
        returnLines(drawings)
        skeletons[player] = nil
    end)
end

local function updateSkeleton(player)
    local data = skeletons[player]
    if not data then return end
    local char = player.Character
    if not char then return end

    if not getgenv().Enabled then
        for _, d in ipairs(data.drawings) do
            d.line.Visible = false
        end
        return
    end

    if getgenv().TeamCheck and player.Team == LocalPlayer.Team then
        for _, d in ipairs(data.drawings) do
            d.line.Visible = false
        end
        return
    end

    local color = Color3.new(1, 0, 0)
    if getgenv().Rainbow then
        local hue = (tick() % 5) / 5
        color = Color3.fromHSV(hue, 1, 1)
    end

    for _, d in ipairs(data.drawings) do
        local p1, p2 = d.part1, d.part2
        if p1 and p2 and p1.Parent and p2.Parent then
            local pos1, onScreen1 = Camera:WorldToViewportPoint(p1.Position)
            local pos2, onScreen2 = Camera:WorldToViewportPoint(p2.Position)
            if onScreen1 and onScreen2 then
                d.line.From = Vector2.new(pos1.X, pos1.Y)
                d.line.To = Vector2.new(pos2.X, pos2.Y)
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

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function()
        repeat task.wait() until player.Character and player.Character:FindFirstChildOfClass("Humanoid")
        task.wait(0.1)
        createSkeleton(player)
    end)
    if player.Character then
        createSkeleton(player)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    onPlayerAdded(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(function(player)
    local data = skeletons[player]
    if data then
        returnLines(data.drawings)
        skeletons[player] = nil
    end
end)

UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.L then
        getgenv().Enabled = not getgenv().Enabled
    elseif input.KeyCode == Enum.KeyCode.LeftBracket then
        getgenv().Rainbow = not getgenv().Rainbow
    end
end)

RunService.RenderStepped:Connect(function()
    for player, _ in pairs(skeletons) do
        updateSkeleton(player)
    end
end)
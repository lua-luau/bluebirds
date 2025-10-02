local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

getgenv().TeamCheck = getgenv().TeamCheck or true
getgenv().Enabled = getgenv().Enabled or true
getgenv().Rainbow = getgenv().Rainbow or false

local skeletons = {}

local function createSkeleton(player)
    if player == LocalPlayer then return end
    local char = player.Character
    if not char or not char:FindFirstChild("Torso") then return end
    
    local drawings = {}
    local connections = {
        {char.Head, char.Torso}, -- Neck
        {char.Torso, char["Left Arm"]}, -- Left Shoulder
        {char.Torso, char["Right Arm"]}, -- Right Shoulder
        {char.Torso, char["Left Leg"]}, -- Left Hip
        {char.Torso, char["Right Leg"]}, -- Right Hip
    }
    
    for _, conn in ipairs(connections) do
        local part1, part2 = conn[1], conn[2]
        if part1 and part2 then
            local line = Drawing.new("Line")
            line.Color = Color3.new(1, 0, 0) -- Red
            line.Thickness = 2
            line.Transparency = 1
            table.insert(drawings, line)
        end
    end
    
    skeletons[player] = {drawings = drawings, connections = connections}
end

local function updateSkeleton(player)
    local data = skeletons[player]
    if not data then return end
    
    local char = player.Character
    if not char or not char.Parent then
        for _, line in ipairs(data.drawings) do
            line:Remove()
        end
        skeletons[player] = nil
        return
    end
    
    if not getgenv().Enabled then
        for _, line in ipairs(data.drawings) do
            line.Visible = false
        end
        return
    end
    
    -- Team check
    if getgenv().TeamCheck and player.Team == LocalPlayer.Team then
        for _, line in ipairs(data.drawings) do
            line.Visible = false
        end
        return
    end
    
    -- Set color
    if getgenv().Rainbow then
        local hue = (tick() % 3) / 3
        local color = Color3.fromHSV(hue, 1, 1)
        for _, line in ipairs(data.drawings) do
            line.Color = color
        end
    else
        for _, line in ipairs(data.drawings) do
            line.Color = Color3.new(1, 0, 0)
        end
    end
    
    for i, line in ipairs(data.drawings) do
        local part1, part2 = data.connections[i][1], data.connections[i][2]
        if part1 and part2 and part1.Parent and part2.Parent then
            local pos1, onScreen1 = Camera:WorldToViewportPoint(part1.Position)
            local pos2, onScreen2 = Camera:WorldToViewportPoint(part2.Position)
            if onScreen1 and onScreen2 then
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
end

local function removeSkeleton(player)
    local data = skeletons[player]
    if data then
        for _, line in ipairs(data.drawings) do
            line:Remove()
        end
        skeletons[player] = nil
    end
end

local function onPlayerAdded(player)
    player.CharacterAdded:Connect(function()
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
Players.PlayerRemoving:Connect(removeSkeleton)

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
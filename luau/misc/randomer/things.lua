local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local skeletons = {}

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

    local lines = {}
    local parts = {
        {Head, Torso},
        {Torso, LeftArm},
        {Torso, RightArm},
        {Torso, LeftLeg},
        {Torso, RightLeg}
    }

    for _, pair in ipairs(parts) do
        local line = Drawing.new("Line")
        line.Color = Color3.new(1,0,0)
        line.Thickness = 2
        line.Transparency = 1
        line.Visible = true
        table.insert(lines, {line = line, p1 = pair[1], p2 = pair[2]})
    end

    skeletons[player] = lines
end

RunService.RenderStepped:Connect(function()
    for player, lines in pairs(skeletons) do
        for _, data in ipairs(lines) do
            local pos1 = Camera:WorldToViewportPoint(data.p1.Position)
            local pos2 = Camera:WorldToViewportPoint(data.p2.Position)
            if pos1.Z > 0 and pos2.Z > 0 then
                data.line.From = Vector2.new(pos1.X,pos1.Y)
                data.line.To = Vector2.new(pos2.X,pos2.Y)
                data.line.Visible = true
            else
                data.line.Visible = false
            end
        end
    end
end)

Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        repeat task.wait() until player.Character and player.Character:FindFirstChild("Head")
        createSkeleton(player)
    end)
end)

for _, player in ipairs(Players:GetPlayers()) do
    if player.Character then
        createSkeleton(player)
    end
end
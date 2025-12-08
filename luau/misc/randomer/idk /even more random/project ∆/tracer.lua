-- Project Delta - Pure Visual Tracer (Solara only)
-- Nothing else, no highlights, no FOV circle, no bullet touch

local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

local Tracers = {}

local function CreateTracer(toPos)
    local line = Drawing.new("Line")
    line.Thickness = 1.7
    line.Color = Color3.fromRGB(255, 100, 255)
    line.Transparency = 1
    line.From = Vector2.new(Mouse.X, Mouse.Y + 36)  -- mouse position
    line.To = toPos
    line.Visible = true

    table.insert(Tracers, line)

    spawn(function()
        for i = 1, 0, -0.07 do
            task.wait()
            line.Transparency = i
        end
        line:Remove()
    end)
end

RunService.RenderStepped:Connect(function()
    if not UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then return end

    local closest = nil
    local bestDist = 300

    -- Players
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr == LocalPlayer then continue end
        local char = plr.Character
        if not char or not char:FindFirstChild("Head") then continue end
        local head = char.Head
        local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
        if onScreen then
            local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
            if dist < bestDist then
                bestDist = dist
                closest = Vector2.new(pos.X, pos.Y)
            end
        end
    end

    -- AiZones (bots)
    if workspace:FindFirstChild("AiZones") then
        for _, zone in workspace.AiZones:GetChildren() do
            for _, bot in zone:GetChildren() do
                local head = bot:FindFirstChild("Head")
                if head then
                    local pos, onScreen = Camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local dist = (Vector2.new(pos.X, pos.Y) - Vector2.new(Mouse.X, Mouse.Y)).Magnitude
                        if dist < bestDist then
                            bestDist = dist
                            closest = Vector2.new(pos.X, pos.Y)
                        end
                    end
                end
            end
        end
    end

    if closest then
        CreateTracer(closest)
    end
end)

-- cleanup
spawn(function()
    while task.wait(3) do
        for i = #Tracers, 1, -1 do
            local t = Tracers[i]
            if not t.Visible then table.remove(Tracers, i) end
        end
    end
end)

print("Pure tracer loaded - Project Delta / Solara")
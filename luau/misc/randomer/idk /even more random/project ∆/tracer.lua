-- Project Delta - True 3D Directional Tracer (NO SNAP, just where you're looking)
-- Fires a gorgeous glowing tracer in your exact aim direction - Solara / All Executors

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera

local LocalPlayer = Players.LocalPlayer

local TracerFolder = Instance.new("Folder")
TracerFolder.Name = "DeltaTrueTracers"
TracerFolder.Parent = Workspace

local function CreateDirectionalTracer()
    local startPos = Camera.CFrame.Position
    local direction = Camera.CFrame.LookVector
    local endPos = startPos + direction * 500  -- long enough to go across any map

    -- Two invisible parts for attachments
    local part0 = Instance.new("Part")
    local part1 = Instance.new("Part")
    part0.Transparency = 1
    part1.Transparency = 1
    part0.Size = Vector3.new(0.1, 0.1, 0.1)
    part1.Size = Vector3.new(0.1, 0.1, 0.1)
    part0.Anchored = true
    part1.Anchored = true
    part0.CanCollide = false
    part1.CanCollide = false
    part0.CFrame = CFrame.new(startPos)
    part1.CFrame = CFrame.new(endPos)
    part0.Parent = TracerFolder
    part1.Parent = TracerFolder

    -- Main Beam (glowing purple-pink)
    local beam = Instance.new("Beam")
    beam.Color = ColorSequence.new(Color3.fromRGB(255, 80, 255))
    beam.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
    beam.Width0 = 1.4
    beam.Width1 = 0.1
    beam.LightEmission = 1
    beam.Brightness = 8
    beam.FaceCamera = true

    local att0 = Instance.new("Attachment", part0)
    local att1 = Instance.new("Attachment", part1)
    beam.Attachment0 = att0
    beam.Attachment1 = att1
    beam.Parent = part0

    -- Extra thick glowing trail
    local trail = Instance.new("Trail")
    trail.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 255)),
        ColorSequenceKeypoint.new(0.8, Color3.fromRGB(200, 0, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 0, 200))
    }
    trail.Transparency = NumberSequence.new(0.05, 1)
    trail.WidthScale = NumberSequence.new(2.5, 0)
    trail.Lifetime = 0.4
    trail.LightEmission = 1
    trail.Attachment0 = att0
    trail.Attachment1 = att1
    trail.Parent = part0

    -- Animation: tracer flies forward with slight arc
    local time = 0
    local duration = 0.35
    local gravity = Vector3.new(0, -18, 0)

    local conn
    conn = RunService.Heartbeat:Connect(function(dt)
        time += dt
        local t = math.min(time / duration, 1)
        local ease = 1 - (1 - t)^2

        local offset = gravity * (t ^ 2) * 12
        local currentEnd = startPos + direction * (150 + ease * 400) + offset

        part1.CFrame = CFrame.new(currentEnd)

        if t >= 1 then
            conn:Disconnect()
            task.delay(0.15, function()
                part0:Destroy()
                part1:Destroy()
            end)
        end
    end)
end

-- Fire tracer only when holding left click
RunService.RenderStepped:Connect(function()
    if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
        CreateDirectionalTracer()
        task.wait(0.06)  -- controls fire rate of tracers (lower = more tracers)
    end
end)

print("Project Delta - True Directional 3D Tracer Loaded (No Snap - Just Pure Style)")
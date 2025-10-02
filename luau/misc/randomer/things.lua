-- Lightweight Skeleton ESP (R6 only)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

getgenv().ESPSettings = {
    Enabled = true,
    Rainbow = false,
    TeamCheck = true,
    LineThickness = 1.5,
    LineColor = Color3.fromRGB(255,255,255)
}

local settings = getgenv().ESPSettings
local skeletons = {}

-- Always use R6 skeleton (lighter)
local bonesR6 = {
    {"Head","Torso"},
    {"Torso","Right Arm"},{"Torso","Left Arm"},
    {"Torso","Right Leg"},{"Torso","Left Leg"}
}

local function rainbow()
    local t = tick()*2
    return Color3.fromRGB(
        math.sin(t)*127+128,
        math.sin(t+2)*127+128,
        math.sin(t+4)*127+128
    )
end

local function newSkeleton(char)
    local lines = {}
    for _,bone in ipairs(bonesR6) do
        local l = Drawing.new("Line")
        l.Visible = false
        l.Thickness = settings.LineThickness
        l.Color = settings.LineColor
        lines[#lines+1] = {a=bone[1],b=bone[2],line=l}
    end
    return {char=char,lines=lines}
end

local function updateSkeleton(player, skel)
    if settings.TeamCheck and LocalPlayer.Team and player.Team==LocalPlayer.Team then
        for _,d in ipairs(skel.lines) do d.line.Visible=false end
        return
    end
    local hum = skel.char:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health<=0 then
        for _,d in ipairs(skel.lines) do d.line.Visible=false end
        return
    end
    local color = settings.Rainbow and rainbow() or settings.LineColor
    for _,d in ipairs(skel.lines) do
        local p1 = skel.char:FindFirstChild(d.a)
        local p2 = skel.char:FindFirstChild(d.b)
        local line = d.line
        line.Color = color
        if p1 and p2 then
            local pos1,v1 = Camera:WorldToViewportPoint(p1.Position)
            local pos2,v2 = Camera:WorldToViewportPoint(p2.Position)
            if v1 and v2 and settings.Enabled then
                line.From = Vector2.new(pos1.X,pos1.Y)
                line.To   = Vector2.new(pos2.X,pos2.Y)
                line.Visible = true
            else line.Visible=false end
        else line.Visible=false end
    end
end

-- Player handling
local function setup(p)
    if p==LocalPlayer then return end
    local function attach(c) skeletons[p]=newSkeleton(c) end
    p.CharacterAdded:Connect(attach)
    if p.Character then attach(p.Character) end
end

for _,p in ipairs(Players:GetPlayers()) do setup(p) end
Players.PlayerAdded:Connect(setup)
Players.PlayerRemoving:Connect(function(p)
    if skeletons[p] then
        for _,d in ipairs(skeletons[p].lines) do d.line:Remove() end
        skeletons[p]=nil
    end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    for pl,skel in pairs(skeletons) do
        if skel.char then updateSkeleton(pl,skel) end
    end
end)
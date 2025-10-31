--[[ 
    Simple ESP Example (Boxes + Tracers + TeamCheck)
    Author: ChatGPT (educational example)
    Date: 2025
    Dependencies: Drawing API
--]]

--// Settings
local Settings = {
    Enabled = true,
    Boxes = true,
    Tracers = true,
    TeamColors = true,
    TeamCheck = true, -- only show enemies if true
    Thickness = 2,
    TracerAttach = "bottom", -- "center" or "bottom"
    Hotkeys = {
        ToggleESP = Enum.KeyCode.E,
        ToggleBoxes = Enum.KeyCode.B,
        ToggleTracers = Enum.KeyCode.T,
        ToggleTeamCheck = Enum.KeyCode.C
    }
}

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local Tracked = {} -- [character] = {box=Quad, tracer=Line, conn={...}}

--// Helper functions
local function Draw(class, props)
    local obj = Drawing.new(class)
    for i,v in pairs(props or {}) do
        obj[i] = v
    end
    return obj
end

local function GetTeamColor(plr)
    if Settings.TeamColors and plr.Team then
        return plr.Team.TeamColor.Color
    end
    return Color3.fromRGB(255, 170, 0)
end

local function OnSameTeam(plr)
    if not Settings.TeamCheck then return false end
    if not LocalPlayer.Team or not plr.Team then return false end
    return plr.Team == LocalPlayer.Team
end

local function RemoveChar(char)
    local esp = Tracked[char]
    if not esp then return end
    for _,v in pairs(esp.conn or {}) do
        if v.Disconnect then v:Disconnect() end
    end
    for _,obj in pairs(esp) do
        if typeof(obj) == "table" and obj.Visible ~= nil then
            pcall(function() obj.Visible = false; obj:Remove() end)
        end
    end
    Tracked[char] = nil
end

local function AddChar(char, plr)
    if plr == LocalPlayer then return end
    if Tracked[char] then return end
    local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end

    local esp = {
        box = Draw("Quad", {Thickness = Settings.Thickness, Filled = false, Visible = false}),
        tracer = Draw("Line", {Thickness = Settings.Thickness, Visible = false}),
        conn = {}
    }

    -- cleanup
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        table.insert(esp.conn, hum.Died:Connect(function() RemoveChar(char) end))
    end
    table.insert(esp.conn, char.AncestryChanged:Connect(function(_, parent)
        if not parent then RemoveChar(char) end
    end))

    Tracked[char] = esp
end

for _,plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer and plr.Character then
        AddChar(plr.Character, plr)
    end
    plr.CharacterAdded:Connect(function(c) AddChar(c, plr) end)
end
Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c) AddChar(c, p) end)
end)
Players.PlayerRemoving:Connect(function(p)
    if p.Character then RemoveChar(p.Character) end
end)

--// Hotkeys
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Settings.Hotkeys.ToggleESP then
        Settings.Enabled = not Settings.Enabled
        print("ESP Enabled:", Settings.Enabled)
    elseif input.KeyCode == Settings.Hotkeys.ToggleBoxes then
        Settings.Boxes = not Settings.Boxes
        print("Boxes:", Settings.Boxes)
    elseif input.KeyCode == Settings.Hotkeys.ToggleTracers then
        Settings.Tracers = not Settings.Tracers
        print("Tracers:", Settings.Tracers)
    elseif input.KeyCode == Settings.Hotkeys.ToggleTeamCheck then
        Settings.TeamCheck = not Settings.TeamCheck
        print("TeamCheck:", Settings.TeamCheck)
    end
end)

--// Render Loop
RunService.RenderStepped:Connect(function()
    if not Settings.Enabled then
        for _,esp in pairs(Tracked) do
            esp.box.Visible = false
            esp.tracer.Visible = false
        end
        return
    end

    local screenCenter = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y)
    local attachY = (Settings.TracerAttach == "center") and Camera.ViewportSize.Y/2 or (Camera.ViewportSize.Y - 40)

    for char, esp in pairs(Tracked) do
        local plr = Players:GetPlayerFromCharacter(char)
        local root = char:FindFirstChild("HumanoidRootPart")
        local head = char:FindFirstChild("Head")

        if not plr or not root then
            RemoveChar(char)
            continue
        end

        if OnSameTeam(plr) then
            esp.box.Visible = false
            esp.tracer.Visible = false
            continue
        end

        local color = GetTeamColor(plr)
        local rootPos, rootVis = Camera:WorldToViewportPoint(root.Position)
        local headPos, headVis = Camera:WorldToViewportPoint(head and head.Position or (root.Position + Vector3.new(0,3,0)))

        if rootVis or headVis then
            local boxHeight = math.abs(headPos.Y - rootPos.Y)
            local boxWidth = boxHeight / 2
            local top = Vector2.new(headPos.X, headPos.Y)
            local bottom = Vector2.new(rootPos.X, rootPos.Y)

            if Settings.Boxes then
                esp.box.Visible = true
                esp.box.PointA = Vector2.new(top.X - boxWidth/2, top.Y)
                esp.box.PointB = Vector2.new(top.X + boxWidth/2, top.Y)
                esp.box.PointC = Vector2.new(bottom.X + boxWidth/2, bottom.Y)
                esp.box.PointD = Vector2.new(bottom.X - boxWidth/2, bottom.Y)
                esp.box.Color = color
            else
                esp.box.Visible = false
            end

            if Settings.Tracers then
                esp.tracer.Visible = true
                esp.tracer.From = Vector2.new(Camera.ViewportSize.X/2, attachY)
                esp.tracer.To = Vector2.new(rootPos.X, rootPos.Y)
                esp.tracer.Color = color
            else
                esp.tracer.Visible = false
            end
        else
            esp.box.Visible = false
            esp.tracer.Visible = false
        end
    end
end)
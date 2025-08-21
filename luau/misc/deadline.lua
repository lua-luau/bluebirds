-- Kavo UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()

-- Window / Tabs / Sections
local Window   = Library.CreateLib("Skeleton ESP", "DarkTheme")
local TabVis   = Window:NewTab("Visuals")
local SecESP   = TabVis:NewSection("Skeleton ESP")
local SecAdv   = TabVis:NewSection("Advanced")

-- Services
local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace  = game:GetService("Workspace")
local Camera     = Workspace.CurrentCamera

-- Vars
local LocalPlayer = Players.LocalPlayer
local CHARACTERS_FOLDER_NAME = "characters"

-- Config (editable via UI)
local ESP_ENABLED   = false
local ESP_COLOR     = Color3.fromRGB(0, 255, 255)
local ESP_THICKNESS = 1

-- Skeleton definition
local SkeletonParts = {
    head          = true,
    torso         = true,
    right_arm_vis = true,
    left_arm_vis  = true,
    right_leg_vis = true,
    left_leg_vis  = true,
}

local ConnectionsMap = {
    {"head", "torso"},
    {"torso", "right_arm_vis"},
    {"torso", "left_arm_vis"},
    {"torso", "right_leg_vis"},
    {"torso", "left_leg_vis"},
}

-- State
local Characters = nil
local SkeletonDrawings = {}
local RSConn, ChildAddedConn, ChildRemovedConn, AncestryConn

-- Helpers
local function getCharactersFolder()
    local f = Workspace:FindFirstChild(CHARACTERS_FOLDER_NAME)
    if not f then
        f = Workspace:WaitForChild(CHARACTERS_FOLDER_NAME, 5)
    end
    return f
end

local function disconnectFolderSignals()
    if ChildAddedConn then ChildAddedConn:Disconnect() ChildAddedConn = nil end
    if ChildRemovedConn then ChildRemovedConn:Disconnect() ChildRemovedConn = nil end
end

local function bindFolder()
    disconnectFolderSignals()
    Characters = getCharactersFolder()
    if Characters then
        ChildAddedConn = Characters.ChildAdded:Connect(function(child)
            if ESP_ENABLED then
                task.wait(0.1)
                if child and child.Parent == Characters then
                    -- ensure we create ESP for new chars
                    if child.Name ~= LocalPlayer.Name and not SkeletonDrawings[child.Name] then
                        -- create after tiny delay to allow parts to appear
                        task.spawn(function()
                            task.wait(0.05)
                            -- create happens during update loop as well, but we proactively create here
                            local lines = {}
                            for _ = 1, #ConnectionsMap do
                                local line = Drawing.new("Line")
                                line.Color = ESP_COLOR
                                line.Thickness = ESP_THICKNESS
                                line.Transparency = 1
                                line.Visible = false
                                lines[#lines+1] = line
                            end
                            SkeletonDrawings[child.Name] = lines
                        end)
                    end
                end
            end
        end)
        ChildRemovedConn = Characters.ChildRemoved:Connect(function(child)
            local lines = SkeletonDrawings[child.Name]
            if lines then
                for _, line in ipairs(lines) do
                    line:Remove()
                end
                SkeletonDrawings[child.Name] = nil
            end
        end)
    end
end

local function removeAllESP()
    for name, lines in pairs(SkeletonDrawings) do
        if lines then
            for _, line in ipairs(lines) do
                line:Remove()
            end
        end
        SkeletonDrawings[name] = nil
    end
end

local function ensureESPFor(character)
    if not character or character.Name == LocalPlayer.Name or SkeletonDrawings[character.Name] then
        return
    end
    local lines = {}
    for _ = 1, #ConnectionsMap do
        local line = Drawing.new("Line")
        line.Color = ESP_COLOR
        line.Thickness = ESP_THICKNESS
        line.Transparency = 1
        line.Visible = false
        lines[#lines+1] = line
    end
    SkeletonDrawings[character.Name] = lines
end

local function updateESPFor(character)
    local lines = SkeletonDrawings[character.Name]
    if not lines then return end

    -- collect 2D positions
    local positions = {}
    for partName in pairs(SkeletonParts) do
        local part = character:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            local sp, onScreen = Camera:WorldToViewportPoint(part.Position)
            if onScreen then
                positions[partName] = Vector2.new(sp.X, sp.Y)
            end
        end
    end

    -- draw lines
    for i, conn in ipairs(ConnectionsMap) do
        local fromPos = positions[conn[1]]
        local toPos   = positions[conn[2]]
        local line    = lines[i]

        if ESP_ENABLED and fromPos and toPos then
            line.From = fromPos
            line.To   = toPos
            line.Color = ESP_COLOR
            line.Thickness = ESP_THICKNESS
            line.Visible = true
        else
            line.Visible = false
        end
    end
end

local function refreshAllLineStyles()
    for _, lines in pairs(SkeletonDrawings) do
        for _, line in ipairs(lines) do
            line.Color = ESP_COLOR
            line.Thickness = ESP_THICKNESS
        end
    end
end

local function enableESP()
    ESP_ENABLED = true
    if not Characters or not Characters.Parent then
        bindFolder()
    end
    if Characters then
        for _, character in ipairs(Characters:GetChildren()) do
            if character.Name ~= LocalPlayer.Name then
                ensureESPFor(character)
            end
        end
    end
end

local function disableESP()
    ESP_ENABLED = false
    -- hide, but keep connections alive so user can re-enable quickly
    for _, lines in pairs(SkeletonDrawings) do
        for _, line in ipairs(lines) do
            line.Visible = false
        end
    end
end

-- One render loop (cheap early-outs)
RSConn = RunService.RenderStepped:Connect(function()
    if not ESP_ENABLED then return end
    if not Characters or not Characters.Parent then
        bindFolder()
        if not Characters then return end
    end

    for _, character in ipairs(Characters:GetChildren()) do
        if character.Name ~= LocalPlayer.Name then
            if not SkeletonDrawings[character.Name] then
                ensureESPFor(character)
            end
            updateESPFor(character)
        end
    end
end)

-- Clean up on exit
AncestryConn = LocalPlayer.AncestryChanged:Connect(function(_, parent)
    if not parent then
        disableESP()
        removeAllESP()
        disconnectFolderSignals()
        if RSConn then RSConn:Disconnect() RSConn = nil end
        if AncestryConn then AncestryConn:Disconnect() AncestryConn = nil end
    end
end)

-- UI Controls (per Kavo docs)
SecESP:NewToggle("Enable ESP", "Draw stick-figure on other characters", function(state)
    if state then enableESP() else disableESP() end
end)

SecESP:NewColorPicker("ESP Color", "Line color", ESP_COLOR, function(color3)
    ESP_COLOR = color3
    refreshAllLineStyles()
end)

SecESP:NewSlider("Line Thickness", "ESP line thickness", 5, 1, function(v)
    ESP_THICKNESS = math.clamp(tonumber(v) or 1, 1, 5)
    refreshAllLineStyles()
end)

SecAdv:NewTextBox("Characters Folder", "Workspace folder that holds character models", function(txt)
    local newName = tostring(txt)
    if #newName > 0 and newName ~= CHARACTERS_FOLDER_NAME then
        CHARACTERS_FOLDER_NAME = newName
        bindFolder()
        -- rebuild drawings against new folder
        removeAllESP()
        if ESP_ENABLED and Characters then
            for _, c in ipairs(Characters:GetChildren()) do
                if c.Name ~= LocalPlayer.Name then
                    ensureESPFor(c)
                end
            end
        end
    end
end)

SecAdv:NewKeybind("Toggle UI", "Show/Hide this menu", Enum.KeyCode.RightShift, function()
    Library:ToggleUI()
end)
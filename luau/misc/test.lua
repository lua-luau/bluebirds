local SkeletonParts = {      
    head          = true,      
    torso         = true,      
    right_arm_vis = true,      
    left_arm_vis  = true,      
    right_leg_vis = true,      
    left_leg_vis  = true,      
}      

local Connections = {      
    {"head",         "torso"},      
    {"torso",        "right_arm_vis"},      
    {"torso",        "left_arm_vis"},      
    {"torso",        "right_leg_vis"},      
    {"torso",        "left_leg_vis"},      
}      

local ESP_COLOR = Color3.fromRGB(0, 255, 255)      
local ESP_THICKNESS = 1      
local CHARACTERS_FOLDER_NAME = "characters"      

--// SERVICES      
local Players     = game:GetService("Players")      
local RunService  = game:GetService("RunService")      
local Workspace   = game:GetService("Workspace")      
local UserInput   = game:GetService("UserInputService")      
local Camera      = Workspace.CurrentCamera      

--// VARIABLES      
local LocalPlayer = Players.LocalPlayer      
local Characters  = Workspace:WaitForChild(CHARACTERS_FOLDER_NAME)      

--// STATE      
local SkeletonDrawings = {}      
local ESP_ENABLED = true
local USE_SKELETON = true
local RAINBOW_MODE = false
local rainbow_hue = 0

--// FUNCTIONS      
local function createLine()      
    local line = Drawing.new("Line")      
    line.Color = ESP_COLOR      
    line.Thickness = ESP_THICKNESS      
    line.Transparency = 1      
    line.Visible = true      
    return line      
end      

local function create3DBox()
    local boxLines = {}
    for i = 1, 12 do -- 12 edges in a box
        local line = Drawing.new("Line")
        line.Color = ESP_COLOR
        line.Thickness = ESP_THICKNESS
        line.Transparency = 1
        line.Visible = true
        table.insert(boxLines, line)
    end
    return boxLines
end

local function createESP(character)      
    if not character or character.Name == LocalPlayer.Name or SkeletonDrawings[character.Name] then      
        return      
    end      

    local drawings = {}

    if USE_SKELETON then
        for _ = 1, #Connections do      
            table.insert(drawings, createLine())      
        end
    else
        drawings = create3DBox()
    end

    SkeletonDrawings[character.Name] = drawings      
end      

local function removeESP(characterName)      
    local drawings = SkeletonDrawings[characterName]      
    if not drawings then return end      

    for _, obj in ipairs(drawings) do      
        obj:Remove()      
    end      
    SkeletonDrawings[characterName] = nil      
end      

local function updateESP(character)
    local drawings = SkeletonDrawings[character.Name]      
    if not drawings then return end      

    if USE_SKELETON then
        -- Skeleton ESP
        local positions = {}      
        for partName in pairs(SkeletonParts) do      
            local part = character:FindFirstChild(partName)      
            if part and part:IsA("BasePart") then      
                local screenPos, onScreen = Camera:WorldToViewportPoint(part.Position)      
                if onScreen then      
                    positions[partName] = Vector2.new(screenPos.X, screenPos.Y)      
                end      
            end      
        end      
        for i, conn in ipairs(Connections) do      
            local fromPos = positions[conn[1]]      
            local toPos   = positions[conn[2]]      
            local line    = drawings[i]      
            if fromPos and toPos then      
                line.From = fromPos      
                line.To   = toPos      
                line.Visible = ESP_ENABLED      
            else      
                line.Visible = false      
            end      
        end      
    else
        -- 3D Box ESP for custom rig
        local torso = character:FindFirstChild("torso")

        if torso then
            local cf = torso.CFrame
            local size = Vector3.new(4, 6, 2) -- adjust to fit your rig properly

            -- 8 corners of the box relative to torso
            local corners = {
                Vector3.new(-size.X/2, -size.Y/2, -size.Z/2),
                Vector3.new(-size.X/2, -size.Y/2,  size.Z/2),
                Vector3.new( size.X/2, -size.Y/2,  size.Z/2),
                Vector3.new( size.X/2, -size.Y/2, -size.Z/2),

                Vector3.new(-size.X/2,  size.Y/2, -size.Z/2),
                Vector3.new(-size.X/2,  size.Y/2,  size.Z/2),
                Vector3.new( size.X/2,  size.Y/2,  size.Z/2),
                Vector3.new( size.X/2,  size.Y/2, -size.Z/2),
            }

            local projected, visible = {}, true
            for i, corner in ipairs(corners) do
                local worldPos = (cf * corner)
                local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
                if not onScreen then
                    visible = false
                end
                projected[i] = Vector2.new(screenPos.X, screenPos.Y)
            end

            local edges = {
                {1,2},{2,3},{3,4},{4,1}, -- bottom
                {5,6},{6,7},{7,8},{8,5}, -- top
                {1,5},{2,6},{3,7},{4,8}, -- verticals
            }

            for i, edge in ipairs(edges) do
                local line = drawings[i]
                if visible and projected[edge[1]] and projected[edge[2]] then
                    line.From = projected[edge[1]]
                    line.To   = projected[edge[2]]
                    line.Visible = ESP_ENABLED
                else
                    line.Visible = false
                end
            end
        end
    end
end

--// RAINBOW COLOR
local function getRainbowColor()
    rainbow_hue = (rainbow_hue + 0.005) % 1
    return Color3.fromHSV(rainbow_hue, 1, 1)
end

--// RENDER LOOP      
RunService.RenderStepped:Connect(function()      
    if not ESP_ENABLED then
        for _, drawings in pairs(SkeletonDrawings) do
            for _, obj in ipairs(drawings) do
                obj.Visible = false
            end
        end
        return
    end

    local currentColor = RAINBOW_MODE and getRainbowColor() or ESP_COLOR

    for _, character in ipairs(Characters:GetChildren()) do      
        if character.Name ~= LocalPlayer.Name then      
            if not SkeletonDrawings[character.Name] then      
                createESP(character)      
            end      
            for _, obj in ipairs(SkeletonDrawings[character.Name]) do
                obj.Color = currentColor
            end
            updateESP(character)      
        end      
    end      
end)      

--// CHARACTER ADDED / REMOVED      
Characters.ChildAdded:Connect(function(child)      
    task.wait(0.1)      
    createESP(child)      
end)      

Characters.ChildRemoved:Connect(function(child)      
    removeESP(child.Name)      
end)      

--// CLEANUP ON PLAYER EXIT      
LocalPlayer.AncestryChanged:Connect(function(_, parent)      
    if not parent then      
        for charName in pairs(SkeletonDrawings) do      
            removeESP(charName)      
        end      
    end      
end)      

--// HOTKEYS
UserInput.InputBegan:Connect(function(input, gp)
    if gp then return end

    if input.KeyCode == Enum.KeyCode.L then
        ESP_ENABLED = not ESP_ENABLED

    elseif input.KeyCode == Enum.KeyCode.RightBracket then
        USE_SKELETON = not USE_SKELETON
        for charName in pairs(SkeletonDrawings) do
            removeESP(charName)
            local char = Characters:FindFirstChild(charName)
            if char then
                createESP(char)
            end
        end

    elseif input.KeyCode == Enum.KeyCode.LeftBracket then
        RAINBOW_MODE = not RAINBOW_MODE
    end
end)
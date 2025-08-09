 
  
--// SETTINGS  
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
local Camera      = Workspace.CurrentCamera  
  
--// VARIABLES  
local LocalPlayer = Players.LocalPlayer  
local Characters  = Workspace:WaitForChild(CHARACTERS_FOLDER_NAME)  
  
--// STATE  
local SkeletonDrawings = {}  
  
--// FUNCTIONS  
local function createLine()  
    local line = Drawing.new("Line")  
    line.Color = ESP_COLOR  
    line.Thickness = ESP_THICKNESS  
    line.Transparency = 1  
    line.Visible = true  
    return line  
end  
  
local function createESP(character)  
    if not character or character.Name == LocalPlayer.Name or SkeletonDrawings[character.Name] then  
        return  
    end  
  
    local lines = {}  
    for _ = 1, #Connections do  
        table.insert(lines, createLine())  
    end  
    SkeletonDrawings[character.Name] = lines  
end  
  
local function removeESP(characterName)  
    local lines = SkeletonDrawings[characterName]  
    if not lines then return end  
  
    for _, line in ipairs(lines) do  
        line:Remove()  
    end  
    SkeletonDrawings[characterName] = nil  
end  
  
local function updateESP(character)  
    local lines = SkeletonDrawings[character.Name]  
    if not lines then return end  
  
    -- Get 2D positions for all skeleton parts  
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
  
    -- Draw connections  
    for i, conn in ipairs(Connections) do  
        local fromPos = positions[conn[1]]  
        local toPos   = positions[conn[2]]  
        local line    = lines[i]  
  
        if fromPos and toPos then  
            line.From = fromPos  
            line.To   = toPos  
            line.Visible = true  
        else  
            line.Visible = false  
        end  
    end  
end  
  
--// RENDER LOOP  
RunService.RenderStepped:Connect(function()  
    for _, character in ipairs(Characters:GetChildren()) do  
        if character.Name ~= LocalPlayer.Name then  
            if not SkeletonDrawings[character.Name] then  
                createESP(character)  
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
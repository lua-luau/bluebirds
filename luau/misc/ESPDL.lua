--// SETTINGS  
local skeletonParts = {  
    head = true,  
    torso = true,  
    right_arm_vis = true,  
    left_arm_vis = true,  
    right_leg_vis = true,  
    left_leg_vis = true,  
}  
  
local connections = {  
    {"head", "torso"},  
    {"torso", "right_arm_vis"},  
    {"torso", "left_arm_vis"},  
    {"torso", "right_leg_vis"},  
    {"torso", "left_leg_vis"},  
}  
  
--// SERVICES  
local players = game:GetService("Players")  
local runservice = game:GetService("RunService")  
local workspace = game:GetService("Workspace")  
local camera = workspace.CurrentCamera  
  
--// VARIABLES  
local localPlayer = players.LocalPlayer  
local characters = workspace:WaitForChild("characters")  
  
--// Drawing Manager  
local skeletonDrawings = {}  
  
-- Create Line  
local function createLine()  
    local line = Drawing.new("Line")  
    line.Color = Color3.fromRGB(255, 255, 255)  
    line.Thickness = 2  
    line.Transparency = 1  
    line.Visible = true  
    return line  
end  
  
-- Create ESP for a Character  
local function createESP(character)  
    if not character or character.Name == localPlayer.Name then return end  
    if skeletonDrawings[character.Name] then return end  
  
    skeletonDrawings[character.Name] = {}  
    for _ = 1, #connections do  
        table.insert(skeletonDrawings[character.Name], createLine())  
    end  
end  
  
-- Remove ESP for a Character  
local function removeESP(characterName)  
    local drawings = skeletonDrawings[characterName]  
    if drawings then  
        for _, line in ipairs(drawings) do  
            if line then  
                line:Remove()  
            end  
        end  
        skeletonDrawings[characterName] = nil  
    end  
end  
  
-- Main Render Loop  
runservice.RenderStepped:Connect(function()  
    for _, character in ipairs(characters:GetChildren()) do  
        if character and character.Name ~= localPlayer.Name then  
            if not skeletonDrawings[character.Name] then  
                createESP(character)  
            end  
  
            local positions = {}  
  
            for partName, _ in pairs(skeletonParts) do  
                local part = character:FindFirstChild(partName)  
                if part and part:IsA("BasePart") then  
                    local screenPos, onScreen = camera:WorldToViewportPoint(part.Position)  
                    if onScreen then  
                        positions[partName] = Vector2.new(screenPos.X, screenPos.Y)  
                    end  
                end  
            end  
  
            for i, conn in ipairs(connections) do  
                local fromPos = positions[conn[1]]  
                local toPos = positions[conn[2]]  
                local line = skeletonDrawings[character.Name][i]  
  
                if fromPos and toPos then  
                    local fromPart = character:FindFirstChild(conn[1])  
                    local toPart = character:FindFirstChild(conn[2])  
  
                    if fromPart and toPart then  
                        local camPos = camera.CFrame.Position  
                        local dist1 = (camPos - fromPart.Position).Magnitude  
                        local dist2 = (camPos - toPart.Position).Magnitude  
                        local avgDist = (dist1 + dist2) / 2  
  
                        line.Thickness = math.clamp(100 / avgDist, 0.5, 2)  
                        line.Transparency = math.clamp(1 - ((avgDist - 20) / 130), 0.2, 1)  
  
                        line.From = fromPos  
                        line.To = toPos  
                        line.Visible = true  
                    else  
                        line.Visible = false  
                    end  
                else  
                    line.Visible = false  
                end  
            end  
        end  
    end  
end)  
  
--// Handle Character Added  
characters.ChildAdded:Connect(function(child)  
    task.wait(0.1)   
    createESP(child)  
end)  
  
--// Handle Character Removed  
characters.ChildRemoved:Connect(function(child)  
    removeESP(child.Name)  
end)  
  
--// Clear ESP When LocalPlayer Leaves  
localPlayer.AncestryChanged:Connect(function(_, parent)  
    if not parent then  
        for charName, _ in pairs(skeletonDrawings) do  
            removeESP(charName)  
        end  
    end  
end)
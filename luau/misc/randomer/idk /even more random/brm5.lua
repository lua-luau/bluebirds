local RunService=game:GetService("RunService")
local Workspace=game:GetService("Workspace")
local Camera=workspace.CurrentCamera
local Players=game:GetService("Players")
local UserInputService=game:GetService("UserInputService")

local ESP={}
local connection

local function clearESP()
    for _,box in pairs(ESP)do
        for i=1,4 do if box[i]then box[i]:Remove()end end
    end
    ESP={}
end

local function isEnemy(model)
    local player=Players:GetPlayerFromCharacter(model)
    if not player then return true end
    if not player.Team or not Players.LocalPlayer.Team then return true end
    return player.Team~=Players.LocalPlayer.Team
end

local function updateESP()
    clearESP()
    for _,model in pairs(Workspace:GetChildren())do
        if model.Name=="Male"and model:FindFirstChild("HumanoidRootPart")and model:FindFirstChild("Humanoid")and model.Humanoid.Health>0 and isEnemy(model)then
            local root=model.HumanoidRootPart
            local head=model:FindFirstChild("Head")or root
            local pos,onScreen=Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local topY=Camera:WorldToViewportPoint(head.Position+Vector3.new(0,3,0)).Y
                local botY=Camera:WorldToViewportPoint(root.Position-Vector3.new(0,4,0)).Y
                local height=math.abs(topY-botY)
                local width=height*0.6
                local x=pos.X-width/2
                local y=pos.Y-height/2
                local box={}
                for i=1,4 do
                    box[i]=Drawing.new("Line")
                    box[i].Thickness=2
                    box[i].Color=Color3.fromRGB(0,255,200)
                    box[i].Visible=true
                end
                box[1].From=Vector2.new(x,y);box[1].To=Vector2.new(x+width,y)
                box[2].From=Vector2.new(x+width,y);box[2].To=Vector2.new(x+width,y+height)
                box[3].From=Vector2.new(x+width,y+height);box[3].To=Vector2.new(x,y+height)
                box[4].From=Vector2.new(x,y+height);box[4].To=Vector2.new(x,y)
                table.insert(ESP,box)
            end
        end
    end
end

local function toggleESP()
    if connection then
        connection:Disconnect()
        connection=nil
        clearESP()
    else
        connection=RunService.RenderStepped:Connect(updateESP)
    end
end

UserInputService.InputBegan:Connect(function(input,gameProcessed)
    if gameProcessed then return end
    if input.KeyCode==Enum.KeyCode.RightBracket then toggleESP()end
end)

connection=RunService.RenderStepped:Connect(updateESP)
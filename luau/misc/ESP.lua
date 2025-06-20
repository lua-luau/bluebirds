local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

-- Setup or reuse ESP holder
local holder = CoreGui:FindFirstChild("ESPHolder") or Instance.new("Folder")
if not holder:IsDescendantOf(CoreGui) or holder.Name ~= "ESPHolder" then
    holder.Name = "ESPHolder"
    holder.Parent = CoreGui
end

-- Cleanup if disabled
if enabled == false then
    holder:Destroy()
    return
end

-- Remove local player's ESP if needed
if uselocalplayer == false and holder:FindFirstChild(Players.LocalPlayer.Name) then
    holder:FindFirstChild(Players.LocalPlayer.Name):Destroy()
end

-- Re-toggle to force refresh (library behavior)
if getgenv().enabled == true then 
    getgenv().enabled = false
    getgenv().enabled = true
end

-- Main ESP logic
RunService.Heartbeat:Connect(function()
    if not getgenv().enabled then return end

    for _, player in pairs(Players:GetPlayers()) do
        if not uselocalplayer and player == Players.LocalPlayer then
            continue
        end

        local character = player.Character
        if not character then continue end

        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")

        if not humanoid or not rootPart then continue end

        -- Skip dead players
        if humanoid.Health <= 0 then
            if holder:FindFirstChild(player.Name) then
                holder[player.Name]:Destroy()
            end
            continue
        end

        -- Skip fully invisible characters (RootPart transparency = 1 or character Transparency = 1)
        local isInvisible = rootPart.Transparency >= 1
        for _, part in pairs(character:GetChildren()) do
            if part:IsA("BasePart") and part.Transparency < 1 then
                isInvisible = false
                break
            end
        end
        if isInvisible then
            if holder:FindFirstChild(player.Name) then
                holder[player.Name]:Destroy()
            end
            continue
        end

        -- Check for valid rig type (R6 or R15)
        local rig = humanoid.RigType
        if rig ~= Enum.HumanoidRigType.R6 and rig ~= Enum.HumanoidRigType.R15 then
            if holder:FindFirstChild(player.Name) then
                holder[player.Name]:Destroy()
            end
            continue
        end

        -- Create or update Highlight
        local esp = holder:FindFirstChild(player.Name)
        if not esp then
            esp = Instance.new("Highlight")
            esp.Name = player.Name
            esp.Parent = holder
        end

        esp.Adornee = rootPart
        esp.FillColor = filluseteamcolor and player.TeamColor.Color or fillcolor
        esp.OutlineColor = outlineuseteamcolor and player.TeamColor.Color or outlinecolor
        esp.FillTransparency = filltrans
        esp.OutlineTransparency = outlinetrans
        esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    end

    -- Clean up ESPs for players who have left
    for _, highlight in pairs(holder:GetChildren()) do
        if not Players:FindFirstChild(highlight.Name) then
            highlight:Destroy()
        end
    end
end)
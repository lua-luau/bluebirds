--[[ Configuration (set externally using getgenv())
-- getgenv().enabled = true
-- getgenv().filluseteamcolor = true
-- getgenv().outlineuseteamcolor = true
-- getgenv().fillcolor = Color3.new(0, 0, 0)
-- getgenv().outlinecolor = Color3.new(1, 1, 1)
-- getgenv().filltrans = 0.5
-- getgenv().outlinetrans = 0.5
-- getgenv().uselocalplayer = false
]]

-- Helper to get a config value with fallback
local function get(var, fallback)
    return (getgenv()[var] ~= nil) and getgenv()[var] or fallback
end

-- Create or reset ESP holder
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")

local holder = CoreGui:FindFirstChild("ESPHolder")
if holder then
    holder:Destroy()
end

holder = Instance.new("Folder")
holder.Name = "ESPHolder"
holder.Parent = CoreGui

-- Clean up ESP on player removal
Players.PlayerRemoving:Connect(function(player)
    local esp = holder:FindFirstChild(player.Name)
    if esp then
        esp:Destroy()
    end
end)

-- Create ESP for a player
local function createESP(player)
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end
    if not get("uselocalplayer", false) and player == Players.LocalPlayer then return end

    local esp = holder:FindFirstChild(player.Name)
    if not esp then
        esp = Instance.new("Highlight")
        esp.Name = player.Name
        esp.Parent = holder
    end

    esp.Adornee = player.Character
    esp.FillColor = get("filluseteamcolor", true) and player.TeamColor.Color or get("fillcolor", Color3.new(0, 0, 0))
    esp.OutlineColor = get("outlineuseteamcolor", true) and player.TeamColor.Color or get("outlinecolor", Color3.new(1, 1, 1))
    esp.FillTransparency = get("filltrans", 0.5)
    esp.OutlineTransparency = get("outlinetrans", 0.5)
    esp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
end

-- Update ESPs every frame
game:GetService("RunService").Heartbeat:Connect(function()
    if not get("enabled", false) then return end
    for _, player in ipairs(Players:GetPlayers()) do
        createESP(player)
    end
end)

-- ESP on new players
Players.PlayerAdded:Connect(function(player)
    player.CharacterAdded:Connect(function()
        task.wait(1)
        if get("enabled", false) then
            createESP(player)
        end
    end)
end)
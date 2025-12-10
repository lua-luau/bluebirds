-- Executor script: Outline ONLY + TEAM COLORS + TOGGLE (RShift + P)
-- Press RightShift + P to toggle ON/OFF (starts ON)

local UIS = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local toggled = true  -- Starts ENABLED
local connection = nil

local function highlightAll()
    local chars = Workspace:FindFirstChild("Characters") or Workspace:FindFirstChild("characters")
    if not chars then return end
    
    local HighlightTemplate = Instance.new("Highlight")
    HighlightTemplate.FillTransparency = 1                    -- Outline ONLY
    HighlightTemplate.OutlineTransparency = 0                 -- Solid thin outline
    HighlightTemplate.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    HighlightTemplate.Enabled = true
    
    for _, model in pairs(chars:GetChildren()) do
        if model:IsA("Model") then
            local hum = model:FindFirstChildOfClass("Humanoid")
            local hl = model:FindFirstChildWhichIsA("Highlight")
            
            if hl then
                -- Update color if team changes
                if hum and hum.TeamColor then
                    hl.OutlineColor = hum.TeamColor.Color
                end
            else
                -- Create ONLY if has Humanoid (team check)
                if hum and hum.TeamColor then
                    local h = HighlightTemplate:Clone()
                    h.OutlineColor = hum.TeamColor.Color
                    h.Adornee = model
                    h.Parent = model
                end
            end
        end
    end
    HighlightTemplate:Destroy()  -- Clean template
end

-- TOGGLE KEYBIND: RightShift + P
UIS.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.P and UIS:IsKeyDown(Enum.KeyCode.RightShift) then
        toggled = not toggled
        print("Highlights TOGGLED:", toggled and "ON" or "OFF")
        if toggled then
            -- Restart loop if turned ON
            if connection then connection:Disconnect() end
            connection = nil
            spawn(function()
                while toggled do
                    pcall(highlightAll)
                    task.wait(1)
                end
            end)
        end
    end
end)

-- Start the loop (initially ON)
spawn(function()
    while toggled do
        pcall(highlightAll)
        task.wait(1)
    end
end)

print("Highlights ACTIVE! Press RightShift + P to toggle.")
--[[
    Transparent Highlight ESP for "Male" models
    (Executor Friendly)
    - Fill: 100% transparent
    - Outline: 75% transparent, 1px thick look
    - Toggle: RightShift + P
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local ESP_Enabled = false
local Highlights = {} -- To keep track and clean up

local function createHighlight(model)
    if model:FindFirstChildOfClass("Highlight") then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "CustomESP"
    highlight.Adornee = model
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 1          -- Completely transparent fill
    highlight.OutlineTransparency = 0.75    -- 75% transparent outline
    highlight.OutlineColor = Color3.fromRGB(0, 255, 200)  -- Cyan outline
    highlight.Parent = model

    table.insert(Highlights, highlight)
end

local function applyESP()
    for _, object in pairs(workspace:GetDescendants()) do
        if object:IsA("Model") and object.Name == "Male" and object:FindFirstChild("Head") then
            createHighlight(object)
        end
    end
end

local function clearESP()
    for _, hl in pairs(Highlights) do
        if hl and hl.Parent then
            hl:Destroy()
        end
    end
    Highlights = {}
end

local function toggleESP()
    ESP_Enabled = not ESP_Enabled
    
    if ESP_Enabled then
        print("ESP Enabled - Thin cyan outline on Male models")
        applyESP()
    else
        print("ESP Disabled")
        clearESP()
    end
end

-- Toggle with Right Shift + P
local rshiftDown = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.RightShift then
        rshiftDown = true
    elseif input.KeyCode == Enum.KeyCode.P and rshiftDown then
        toggleESP()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        rshiftDown = false
    end
end)

-- Optional: Re-apply on new Male models spawning
workspace.DescendantAdded:Connect(function(child)
    if ESP_Enabled and child:IsA("Model") and child.Name == "Male" and child:FindFirstChild("Head") then
        task.wait(0.5) -- Small delay to ensure model fully loads
        createHighlight(child)
    end
end)

print("Thin Outline ESP Loaded | Toggle: RightShift + P")
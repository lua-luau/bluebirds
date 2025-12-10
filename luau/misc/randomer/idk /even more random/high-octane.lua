-- Executor-only one-liner version (works instantly, no matter when Characters folder spawns)

local Highlight = Instance.new("Highlight")
Highlight.FillColor = Color3.new(0, 1, 1)           -- Cyan fill
Highlight.OutlineColor = Color3.new(1, 1, 0)     -- Bright yellow outline
Highlight.FillTransparency = 0.5
Highlight.OutlineTransparency = 0
Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

local function highlightAll()
    local chars = game.Workspace:FindFirstChild("Characters") or game.Workspace:FindFirstChild("characters")
    if not chars then return end
    
    for _, model in pairs(chars:GetChildren()) do
        if model:IsA("Model") and not model:FindFirstChildWhichIsA("Highlight") then
            local h = Highlight:Clone()
            h.Adornee = model
            h.Parent = model
        end
    end
end

-- Run every 1 second forever (executor keeps it alive)
while task.wait(1) do
    pcall(highlightAll)  -- pcall so it never crashes even if something breaks
end
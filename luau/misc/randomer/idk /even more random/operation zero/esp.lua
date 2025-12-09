-- LocalScript → StarterPlayer → StarterPlayerScripts
-- This WILL work 100% on your game with custom rigs in Workspace

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local OUTLINE_COLOR = Color3.fromRGB(0, 255, 255)  -- Cyan glow (change if you want)
local MY_COLOR      = Color3.fromRGB(255, 255, 0)  -- Yellow for your own dummy (optional)

local highlighted = {}  -- prevent duplicates

local function highlightModel(model)
	if not model or highlighted[model] then return end
	if not Players:FindFirstChild(model.Name) then return end  -- must be real player name

	local highlight = Instance.new("Highlight")
	highlight.Name = "ESP_Outline"
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.OutlineColor = (model.Name == Players.LocalPlayer.Name) and MY_COLOR or OUTLINE_COLOR
	
	highlight.Parent = model
	highlighted[model] = highlight
	
	print("Outlined custom rig:", model.Name)
end

-- Highlight existing ones
for _, obj in ipairs(Workspace:GetChildren()) do
	if obj:IsA("Model") and Players:FindFirstChild(obj.Name) then
		highlightModel(obj)
	end
end

-- Highlight new ones that appear later
Workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") then
		-- Wait a tiny bit in case the model is still loading
		task.wait(0.2)
		if child.Parent and Players:FindFirstChild(child.Name) then
			highlightModel(child)
		end
	end
end)

-- Clean up if model gets deleted
Workspace.ChildRemoved:Connect(function(child)
	if highlighted[child] then
		highlighted[child]:Destroy()
		highlighted[child] = nil
	end
end)

print("Custom rig ESP active - All player-named models in Workspace are now glowing!")
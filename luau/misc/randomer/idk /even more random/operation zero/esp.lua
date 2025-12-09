-- LocalScript → Put in StarterPlayer > StarterPlayerScripts

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local myName = localPlayer.Name

local OUTLINE_COLOR = Color3.fromRGB(0, 255, 255)       -- Cyan (or change to whatever you like)
local MY_OUTLINE_COLOR = Color3.fromRGB(255, 255, 0)    -- Yellow for your own dummy model (optional)
local OUTLINE_TRANSPARENCY = 0
local FILL_TRANSPARENCY = 1  -- completely invisible fill

local highlightedModels = {}  -- to avoid duplicating Highlights

local function addHighlight(model)
	if not model or highlightedModels[model] then return end
	
	local highlight = Instance.new("Highlight")
	highlight.Name = "CustomPlayerOutline"
	highlight.Adornee = model
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = FILL_TRANSPARENCY
	highlight.OutlineTransparency = OUTLINE_TRANSPARENCY
	
	-- Optional: make your own dummy model a different color
	if model.Name == myName then
		highlight.OutlineColor = MY_OUTLINE_COLOR
	else
		highlight.OutlineColor = OUTLINE_COLOR
	end
	
	highlight.Parent = model
	highlightedModels[model] = highlight
end

local function removeHighlight(model)
	if highlightedModels[model] then
		highlightedModels[model]:Destroy()
		highlightedModels[model] = nil
	end
end

local function scanAndHighlight()
	for _, obj in ipairs(Workspace:GetChildren()) do
		if obj:IsA("Model") and Players:FindFirstChild(obj.Name) then
			-- It's a custom dummy model named after a real player
			addHighlight(obj)
		end
	end
end

-- Initial scan (in case models are already there)
scanAndHighlight()

-- Continuously check for new dummy models (in case they spawn later)
Workspace.ChildAdded:Connect(function(child)
	if child:IsA("Model") and Players:FindFirstChild(child.Name) then
		-- Small delay to make sure the model is fully loaded
		task.wait(0.5)
		addHighlight(child)
	end
end)

Workspace.ChildRemoved:Connect(removeHighlight)

-- Clean up any broken references every few seconds
RunService.Heartbeat:Connect(function()
	for model, _ in pairs(highlightedModels) do
		if not model.Parent then
			removeHighlight(model)
		end
	end
end)

print("Custom player model outliner active! All dummy models named after players now have glowing outlines.")
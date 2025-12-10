-- LocalScript (place in StarterPlayerScripts or StarterGui)

local Highlight = Instance.new("Highlight")
Highlight.FillColor = Color3.fromRGB(0, 255, 255)      -- Cyan fill (you can change)
Highlight.OutlineColor = Color3.fromRGB(255, 255, 0)  -- Yellow outline (very visible)
Highlight.FillTransparency = 0.5                      -- Semi-transparent fill
Highlight.OutlineTransparency = 0                     -- Solid outline
Highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- Always visible through walls
Highlight.Enabled = true

local CharactersFolder = game:GetService("Workspace"):WaitForChild("Characters")

-- Function to highlight a model
local function addHighlight(model)
	if model:IsA("Model") and model:FindFirstChild("HumanoidRootPart") then
		-- Clone the Highlight and parent it to the model
		local highlightClone = Highlight:Clone()
		highlightClone.Adornee = model
		highlightClone.Parent = model
	end
end

-- Highlight existing characters
for _, model in ipairs(CharactersFolder:GetChildren()) do
	addHighlight(model)
end

-- Highlight any new characters that spawn later (very important in multiplayer)
CharactersFolder.ChildAdded:Connect(function(child)
	-- Small delay in case the model is still loading parts
	task.wait(0.5)
	addHighlight(child)
end)

-- Optional: Remove highlight when character is removed (clean up memory)
CharactersFolder.ChildRemoved:Connect(function(child)
	-- Destroy any Highlight instances inside the removed model
	for _, obj in ipairs(child:GetDescendants()) do
		if obj:IsA("Highlight") then
			obj:Destroy()
		end
	end
end)

print("Highlight script active on Workspace/Characters!")
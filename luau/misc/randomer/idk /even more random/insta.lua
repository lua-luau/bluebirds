-- Clean & performant version (2025 best practice)
local ProximityPromptService = game:GetService("ProximityPromptService")

local function enhancePrompt(prompt)
	prompt.HoldDuration = prompt.HoldDuration * 0.5
	prompt.MaxActivationDistance = prompt.MaxActivationDistance * 2
end

-- Apply to all current and future prompts
workspace:GetDescendants()
for _, prompt in ipairs(workspace:GetDescendants()) do
	if prompt:IsA("ProximityPrompt") then
		enhancePrompt(prompt)
	end
end

workspace.DescendantAdded:Connect(function(obj)
	if obj:IsA("ProximityPrompt") then
		task.defer(enhancePrompt, obj)
	end
end)
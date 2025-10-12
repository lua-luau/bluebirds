--// LocalScript (StarterPlayer > StarterPlayerScripts)

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local originalFOV = Camera.FieldOfView
local zoomedFOV = originalFOV - 60
local isZoomed = false

-- Toggle zoom when J is pressed
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.J then
		isZoomed = not isZoomed

		-- Update originalFOV when toggling back
		if not isZoomed then
			originalFOV = Camera.FieldOfView
			zoomedFOV = originalFOV - 60
		end
	end
end)

-- Bind to render step with high priority so it overrides other scripts
RunService:BindToRenderStep("EnforceFOV", Enum.RenderPriority.Last.Value + 1000, function()
	if isZoomed then
		Camera.FieldOfView = math.max(1, zoomedFOV)
	else
		Camera.FieldOfView = originalFOV
	end
end)
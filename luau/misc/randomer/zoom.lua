--// LocalScript (StarterPlayer > StarterPlayerScripts)

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local originalFOV = Camera.FieldOfView
local zoomedFOV = originalFOV - 60
local isZoomed = false

-- Keep FOV enforced every frame
RunService.RenderStepped:Connect(function()
	if isZoomed then
		Camera.FieldOfView = math.max(1, zoomedFOV)
	else
		Camera.FieldOfView = originalFOV
	end
end)

-- Toggle zoom on J press
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end

	if input.KeyCode == Enum.KeyCode.J then
		isZoomed = not isZoomed
	end
end)
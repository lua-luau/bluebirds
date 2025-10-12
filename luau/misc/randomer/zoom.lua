--// LocalScript (Place this in StarterPlayerScripts)

local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera

local originalFOV = Camera.FieldOfView
local zoomedFOV = originalFOV - 60  -- how much to reduce FOV
local isZoomed = false

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end  -- don't trigger if typing in chat etc.

	if input.KeyCode == Enum.KeyCode.J then
		if not isZoomed then
			Camera.FieldOfView = math.max(1, zoomedFOV) -- prevent negative FOV
			isZoomed = true
		else
			Camera.FieldOfView = originalFOV
			isZoomed = false
		end
	end
end)
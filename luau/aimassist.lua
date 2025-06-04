-- Prevent duplicate aimbot instance
if getgenv().Aimbot then
    return getgenv().Aimbot
end

local Aimbot = {}
getgenv().Aimbot = Aimbot

-- Settings
Aimbot.Settings = {  
	AimFOV = 35,  
	MinAssist = 0.05,  
	MaxAssist = 0.35,  
	PingFallback = 50,  
	EnableFOVSync = true,  
	ShowFOVCircle = true,  
	TeamCheck = false,  
	UseLineOfSight = true,  
	TargetPart = "Head",  
	MaxPredictionTime = 0.2,  
	LOSParts = {"Head", "HumanoidRootPart"},  
	ScoreWeights = { FOV = 0.6, Distance = 0.4 },  
	CustomCrosshair = Vector2.new(0.5, 0.5) -- normalized screen position
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

-- Remove any existing FOV circle
if getgenv().AimbotFOVCircle then
    getgenv().AimbotFOVCircle:Remove()
    getgenv().AimbotFOVCircle = nil
end

-- Create Drawing Circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 0.4
fovCircle.Visible = Aimbot.Settings.ShowFOVCircle
getgenv().AimbotFOVCircle = fovCircle

local cachedPlayers, lastPlayerCache = {}, 0
local function refreshPlayerCache()
	if tick() - lastPlayerCache > 0.25 then
		cachedPlayers = Players:GetPlayers()
		lastPlayerCache = tick()
	end
end

local function getPredictedPosition(part)
	local vel = part:IsA("BasePart") and part.Velocity or Vector3.zero
	local predictionTime = math.clamp(Aimbot.Settings.PingFallback / 1000, 0, Aimbot.Settings.MaxPredictionTime)
	return part.Position + (vel * predictionTime)
end

local function checkLineOfSight(char)
	for _, partName in ipairs(Aimbot.Settings.LOSParts) do
		local part = char:FindFirstChild(partName)
		if part then
			local dir = (part.Position - Camera.CFrame.Position)
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			rayParams.FilterDescendantsInstances = {player.Character, char}
			local result = workspace:Raycast(Camera.CFrame.Position, dir.Unit * dir.Magnitude, rayParams)
			if result and not result.Instance:IsDescendantOf(char) then
				return false
			end
		end
	end
	return true
end

local function getCustomCrosshair()
	local viewport = Camera.ViewportSize
	local scale = Aimbot.Settings.CustomCrosshair or Vector2.new(0.5, 0.5)
	return Vector2.new(viewport.X * scale.X, viewport.Y * scale.Y)
end

local function getClosestTarget()
	refreshPlayerCache()
	local best, bestScore = nil, -math.huge
	local camPos = Camera.CFrame.Position
	local screenPoint = getCustomCrosshair()
	local ray = Camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
	local aimOrigin = ray.Origin
	local aimDirection = ray.Direction.Unit

	for _, otherPlayer in ipairs(cachedPlayers) do
		if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild(Aimbot.Settings.TargetPart) then
			if not Aimbot.Settings.TeamCheck or otherPlayer.Team ~= player.Team then
				local part = otherPlayer.Character[Aimbot.Settings.TargetPart]
				local predictedPos = getPredictedPosition(part)
				local toTarget = (predictedPos - aimOrigin).Unit
				local angle = math.deg(math.acos(math.clamp(aimDirection:Dot(toTarget), -1, 1)))
				if angle <= Aimbot.Settings.AimFOV then
					local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
					if onScreen then
						local dist = (part.Position - camPos).Magnitude
						local losOK = not Aimbot.Settings.UseLineOfSight or checkLineOfSight(otherPlayer.Character)
						if losOK then
							local score =
								((1 - (angle / Aimbot.Settings.AimFOV)) * Aimbot.Settings.ScoreWeights.FOV) +
								((1 / dist) * Aimbot.Settings.ScoreWeights.Distance)

							if score > bestScore then
								bestScore = score
								best = {
									Part = part,
									PredictedPos = predictedPos,
									Angle = angle,
									Distance = dist,
									ScreenPos = screenPos
								}
							end
						end
					end
				end
			end
		end
	end

	return best
end

local function updateFOVCircle()
	if not Aimbot.Settings.ShowFOVCircle then
		fovCircle.Visible = false
		return
	end

	local camFOV = Camera.FieldOfView
	local screenHeight = Camera.ViewportSize.Y
	local scale = math.tan(math.rad(Aimbot.Settings.AimFOV / 2)) / math.tan(math.rad(camFOV / 2))
	fovCircle.Radius = (screenHeight / 2) * scale
	fovCircle.Position = getCustomCrosshair()
	fovCircle.Visible = true
end

-- Public Start Function
function Aimbot.Start()
	RunService.RenderStepped:Connect(function()
		if not player.Character or not Camera then return end

		updateFOVCircle()

		local targetData = getClosestTarget()
		if targetData then
			local screenPoint = getCustomCrosshair()
			local ray = Camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
			local aimOrigin = ray.Origin
			local aimDirection = (targetData.PredictedPos - aimOrigin).Unit

			local assistStrength = Aimbot.Settings.MinAssist +
				((1 - (targetData.Angle / Aimbot.Settings.AimFOV)) * (Aimbot.Settings.MaxAssist - Aimbot.Settings.MinAssist))

			local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + aimDirection)
			Camera.CFrame = Camera.CFrame:Lerp(newCFrame, assistStrength)
		end
	end)
end

return Aimbot

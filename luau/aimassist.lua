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
	CustomCrosshair = Vector2.new(0.5, 0.3) -- 50% horizontal, 30% vertical
}

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local player = Players.LocalPlayer

-- Cleanup previous visuals
if getgenv().AimbotFOVCircle then
	getgenv().AimbotFOVCircle:Remove()
end
if getgenv().AimbotDot then
	getgenv().AimbotDot:Remove()
end

-- Create FOV circle
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 0.4
fovCircle.Visible = Aimbot.Settings.ShowFOVCircle
getgenv().AimbotFOVCircle = fovCircle

-- Create custom crosshair dot
local dot = Drawing.new("Circle")
dot.Color = Color3.fromRGB(255, 255, 255)
dot.Filled = true
dot.Radius = 2
dot.Visible = true
getgenv().AimbotDot = dot

-- Player cache
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
	local circleCenter = fovCircle.Position
	local radius = fovCircle.Radius

	for _, otherPlayer in ipairs(cachedPlayers) do
		if otherPlayer ~= player and otherPlayer.Character and otherPlayer.Character:FindFirstChild(Aimbot.Settings.TargetPart) then
			if not Aimbot.Settings.TeamCheck or otherPlayer.Team ~= player.Team then
				local part = otherPlayer.Character[Aimbot.Settings.TargetPart]
				local predictedPos = getPredictedPosition(part)
				local screenPos, onScreen = Camera:WorldToViewportPoint(predictedPos)
				if onScreen then
					local screenDist = (Vector2.new(screenPos.X, screenPos.Y) - circleCenter).Magnitude
					if screenDist <= radius then
						local dist = (part.Position - camPos).Magnitude
						local losOK = not Aimbot.Settings.UseLineOfSight or checkLineOfSight(otherPlayer.Character)
						if losOK then
							local screenScore = (1 - (screenDist / radius))
							local score =
								(screenScore * Aimbot.Settings.ScoreWeights.FOV) +
								((1 / dist) * Aimbot.Settings.ScoreWeights.Distance)

							if score > bestScore then
								bestScore = score
								best = {
									Part = part,
									PredictedPos = predictedPos,
									ScreenDist = screenDist,
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

local function updateVisuals()
	if not Camera then return end

	local screenHeight = Camera.ViewportSize.Y
	local camFOV = Camera.FieldOfView
	local scale = math.tan(math.rad(Aimbot.Settings.AimFOV / 2)) / math.tan(math.rad(camFOV / 2))
	local radius = (screenHeight / 2) * scale

	local crosshairPos = getCustomCrosshair()
	fovCircle.Position = crosshairPos
	fovCircle.Radius = radius
	fovCircle.Visible = Aimbot.Settings.ShowFOVCircle

	dot.Position = crosshairPos
	dot.Visible = true
end

-- Main loop
function Aimbot.Start()
	RunService.RenderStepped:Connect(function()
		if not player.Character or not Camera then return end

		updateVisuals()

		local crosshairPos = getCustomCrosshair()
		local ray = Camera:ScreenPointToRay(crosshairPos.X, crosshairPos.Y)
		local crosshairOrigin = ray.Origin
		local crosshairDir = ray.Direction.Unit

		local targetData = getClosestTarget()
		if targetData then
			-- Actual direction to predicted target
			local toTarget = (targetData.PredictedPos - Camera.CFrame.Position).Unit

			-- Lerp between current crosshair direction and the target direction
			local assistStrength = Aimbot.Settings.MinAssist +
				((1 - (targetData.ScreenDist / fovCircle.Radius)) * (Aimbot.Settings.MaxAssist - Aimbot.Settings.MinAssist))

			local newDir = crosshairDir:Lerp(toTarget, assistStrength).Unit
			local newLook = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newDir)
			Camera.CFrame = newLook
		end
	end)
end

return Aimbot
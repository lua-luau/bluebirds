local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Aimbot = {}
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
	CustomCrosshair = Vector2.new(0.5, 0.5)
}

local localPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local connection = nil
local fovCircle = nil
local cachedPlayers = {}
local lastCacheTime = 0

-- Drawing setup
local function initFOVCircle()
	if fovCircle then fovCircle:Remove() end
	fovCircle = Drawing.new("Circle")
	fovCircle.Color = Color3.fromRGB(0, 255, 0)
	fovCircle.Thickness = 2
	fovCircle.Filled = false
	fovCircle.Transparency = 0.4
	fovCircle.Visible = Aimbot.Settings.ShowFOVCircle
end

local function updateFOVCircle()
	if not Aimbot.Settings.ShowFOVCircle or not fovCircle then
		if fovCircle then fovCircle.Visible = false end
		return
	end
	local screenSize = Camera.ViewportSize.Y
	local fov = Aimbot.Settings.AimFOV
	local scale = math.tan(math.rad(fov / 2)) / math.tan(math.rad(Camera.FieldOfView / 2))
	fovCircle.Radius = (screenSize / 2) * scale
	local viewScale = Aimbot.Settings.CustomCrosshair
	fovCircle.Position = Vector2.new(Camera.ViewportSize.X * viewScale.X, Camera.ViewportSize.Y * viewScale.Y)
	fovCircle.Visible = true
end

local function refreshPlayerCache()
	if tick() - lastCacheTime > 0.25 then
		cachedPlayers = Players:GetPlayers()
		lastCacheTime = tick()
	end
end

local function getPredictedPosition(part)
	local vel = part:IsA("BasePart") and part.Velocity or Vector3.zero
	local predictionTime = math.clamp(Aimbot.Settings.PingFallback / 1000, 0, Aimbot.Settings.MaxPredictionTime)
	return part.Position + (vel * predictionTime)
end

-- LOS: From enemy part TO local character
local function checkLineOfSight(enemyChar)
	if not localPlayer.Character or not localPlayer.Character:FindFirstChild("Head") then return false end
	local localHead = localPlayer.Character.Head.Position

	for _, partName in ipairs(Aimbot.Settings.LOSParts) do
		local part = enemyChar:FindFirstChild(partName)
		if part then
			local direction = (localHead - part.Position).Unit * (localHead - part.Position).Magnitude
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Blacklist
			params.FilterDescendantsInstances = {enemyChar, localPlayer.Character}
			local result = Workspace:Raycast(part.Position, direction, params)
			if result and not result.Instance:IsDescendantOf(localPlayer.Character) then
				return false
			end
		end
	end
	return true
end

local function getCrosshairPosition()
	local scale = Aimbot.Settings.CustomCrosshair
	return Vector2.new(Camera.ViewportSize.X * scale.X, Camera.ViewportSize.Y * scale.Y)
end

local function getClosestTarget()
	refreshPlayerCache()
	local best = nil
	local bestScore = -math.huge
	local screenPoint = getCrosshairPosition()
	local ray = Camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
	local origin = ray.Origin
	local aimDir = ray.Direction.Unit

	for _, otherPlayer in ipairs(cachedPlayers) do
		if otherPlayer ~= localPlayer and otherPlayer.Character and otherPlayer.Character:FindFirstChild(Aimbot.Settings.TargetPart) then
			if not Aimbot.Settings.TeamCheck or otherPlayer.Team ~= localPlayer.Team then
				local targetPart = otherPlayer.Character[Aimbot.Settings.TargetPart]
				local predicted = getPredictedPosition(targetPart)
				local toTarget = (predicted - origin).Unit
				local angle = math.deg(math.acos(math.clamp(aimDir:Dot(toTarget), -1, 1)))
				if angle <= Aimbot.Settings.AimFOV then
					local screenPos, onScreen = Camera:WorldToViewportPoint(predicted)
					if onScreen then
						local dist = (Camera.CFrame.Position - targetPart.Position).Magnitude
						local losCheck = not Aimbot.Settings.UseLineOfSight or checkLineOfSight(otherPlayer.Character)
						if losCheck then
							local score =
								((1 - (angle / Aimbot.Settings.AimFOV)) * Aimbot.Settings.ScoreWeights.FOV) +
								((1 / dist) * Aimbot.Settings.ScoreWeights.Distance)
							if score > bestScore then
								bestScore = score
								best = {
									PredictedPos = predicted,
									Angle = angle
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

function Aimbot.Start()
	if connection then return end
	initFOVCircle()
	connection = RunService.RenderStepped:Connect(function()
		if not Camera or not localPlayer.Character then return end
		updateFOVCircle()

		local target = getClosestTarget()
		if target then
			local screenPoint = getCrosshairPosition()
			local ray = Camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
			local origin = ray.Origin
			local assistDir = (target.PredictedPos - origin).Unit

			local strength = Aimbot.Settings.MinAssist +
				((1 - (target.Angle / Aimbot.Settings.AimFOV)) * (Aimbot.Settings.MaxAssist - Aimbot.Settings.MinAssist))

			local newCam = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + assistDir)
			Camera.CFrame = Camera.CFrame:Lerp(newCam, strength)
		end
	end)
end

function Aimbot.Stop()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	if fovCircle then
		fovCircle:Remove()
		fovCircle = nil
	end
end

return Aimbot
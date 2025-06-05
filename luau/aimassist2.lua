-- Prevent duplicate instance
if getgenv().Aimbot then
    return getgenv().Aimbot
end

local Aimbot = {}
getgenv().Aimbot = Aimbot

-- Settings
Aimbot.Settings = {
    AimFOV = 35,
    Smoothing = 0.15, -- new smoothing setting (0 = instant)
    MinHealth = 1, -- ignore characters below this health
    TeamCheck = false,
    UseLineOfSight = true,
    TreatTapAsCenter = true,
    ShowFOVCircle = true,
    TargetPart = "Head",
    MaxPredictionTime = 0.2,
    LOSParts = {"Head", "HumanoidRootPart"},
    ScoreWeights = { FOV = 0.6, Distance = 0.4 }
}

-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- FOV Circle (visual)
if getgenv().AimbotFOVCircle then
    getgenv().AimbotFOVCircle:Remove()
    getgenv().AimbotFOVCircle = nil
end

local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 0.4
fovCircle.Visible = Aimbot.Settings.ShowFOVCircle
getgenv().AimbotFOVCircle = fovCircle

-- Crosshair always center
local function getCustomCrosshair()
	local viewport = Camera.ViewportSize
	return Vector2.new(viewport.X * 0.5, viewport.Y * 0.5)
end

-- Touch Input (simulated as center)
if Aimbot.Settings.TreatTapAsCenter then
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if input.UserInputType == Enum.UserInputType.Touch and not gameProcessed then
			local tapPos = getCustomCrosshair()
			local ray = Camera:ScreenPointToRay(tapPos.X, tapPos.Y)
			-- Optional: Use ray for simulated shooting logic
		end
	end)
end

-- Player cache
local cachedPlayers, lastPlayerCache = {}, 0
local function refreshPlayerCache()
	if tick() - lastPlayerCache > 0.25 then
		cachedPlayers = Players:GetPlayers()
		lastPlayerCache = tick()
	end
end

-- Predict movement
local function getPredictedPosition(part)
	local vel = part:IsA("BasePart") and part.Velocity or Vector3.zero
	local predictionTime = math.clamp(0.05, 0, Aimbot.Settings.MaxPredictionTime)
	return part.Position + (vel * predictionTime)
end

-- Line of Sight: enemy can see *you*
local function checkLineOfSight(enemyChar)
	for _, partName in ipairs(Aimbot.Settings.LOSParts) do
		local part = enemyChar:FindFirstChild(partName)
		local myChar = LocalPlayer.Character
		if part and myChar and myChar:FindFirstChild("Head") then
			local rayParams = RaycastParams.new()
			rayParams.FilterType = Enum.RaycastFilterType.Blacklist
			rayParams.FilterDescendantsInstances = {enemyChar, myChar}

			local origin = part.Position
			local targetPos = myChar.Head.Position
			local dir = (targetPos - origin)

			local result = workspace:Raycast(origin, dir.Unit * dir.Magnitude, rayParams)
			if result and not result.Instance:IsDescendantOf(myChar) then
				return false
			end
		end
	end
	return true
end

-- Get best target
local function getClosestTarget()
	refreshPlayerCache()
	local best, bestScore = nil, -math.huge
	local camPos = Camera.CFrame.Position
	local screenPoint = getCustomCrosshair()
	local ray = Camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
	local aimOrigin = ray.Origin
	local aimDirection = ray.Direction.Unit

	for _, otherPlayer in ipairs(cachedPlayers) do
		if otherPlayer ~= LocalPlayer and otherPlayer.Character and otherPlayer.Character:FindFirstChild(Aimbot.Settings.TargetPart) then
			local humanoid = otherPlayer.Character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health >= Aimbot.Settings.MinHealth then
				if not Aimbot.Settings.TeamCheck or otherPlayer.Team ~= LocalPlayer.Team then
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
	end

	return best
end

-- Update FOV Visual
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

-- Start Aimbot
function Aimbot.Start()
	RunService.RenderStepped:Connect(function()
		if not LocalPlayer.Character or not Camera then return end

		updateFOVCircle()

		local targetData = getClosestTarget()
		if targetData then
			local screenPoint = getCustomCrosshair()
			local ray = Camera:ScreenPointToRay(screenPoint.X, screenPoint.Y)
			local aimOrigin = ray.Origin
			local aimDirection = (targetData.PredictedPos - aimOrigin).Unit

			local newCFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + aimDirection)
			Camera.CFrame = Camera.CFrame:Lerp(newCFrame, Aimbot.Settings.Smoothing)
		end
	end)
end

return Aimbot
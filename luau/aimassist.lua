local AimAssist = {}

-- ================== SERVICES ================== --
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local gravity = workspace.Gravity

-- ================== CONFIG ================== --
AimAssist.Settings = {
	AimFOV = 15,
	ViewDistance = 10,
	MinAssist = 0.02,
	MaxAssist = 0.15,
	PingFallback = 50,
	EnableFOVSync = true,
	ShowFOVCircle = true,
	TeamCheck = false,
	UseLineOfSight = false,
	TargetPart = "Head",
	MaxPredictionTime = 0.1
}

-- ================== STATE ================== --
local SmoothedVelocities = {}
local VelocitySmoothingFactor = 0.2

-- ================== FOV CIRCLE ================== --
local fovCircle = Drawing.new("Circle")
fovCircle.Color = Color3.fromRGB(0, 255, 0)
fovCircle.Thickness = 2
fovCircle.Filled = false
fovCircle.Transparency = 0.4
fovCircle.Visible = AimAssist.Settings.ShowFOVCircle

local function updateFOVCircleRadius()
	local angleRad = math.rad(AimAssist.Settings.AimFOV)
	local offset = math.tan(angleRad) * AimAssist.Settings.ViewDistance
	local centerWorld = Camera.CFrame.Position + Camera.CFrame.LookVector * AimAssist.Settings.ViewDistance
	local edgeWorld = centerWorld + Camera.CFrame.RightVector * offset

	local screenCenter = Camera:WorldToViewportPoint(centerWorld)
	local screenEdge = Camera:WorldToViewportPoint(edgeWorld)
	local radius = (Vector2.new(screenEdge.X, screenEdge.Y) - Vector2.new(screenCenter.X, screenCenter.Y)).Magnitude
	fovCircle.Radius = radius
end

-- ================== PREDICTION ================== --
local function getPing()
	local stats = LocalPlayer:FindFirstChild("PerformanceStats")
	local ping = stats and stats:FindFirstChild("Ping")
	return ping and ping.Value or AimAssist.Settings.PingFallback
end

local function getPredictedPosition(char, part, pingMs)
	if not (char and part) then return part.Position end

	local hrp = char:FindFirstChild("HumanoidRootPart")
	local velocity = hrp and hrp.Velocity or part.Velocity
	local userId = char:GetAttribute("UserId") or 0

	local prev = SmoothedVelocities[userId]
	if prev then
		velocity = prev:Lerp(velocity, VelocitySmoothingFactor)
	end
	SmoothedVelocities[userId] = velocity

	local t = math.clamp(pingMs / 1000, 0.01, AimAssist.Settings.MaxPredictionTime)
	local vertical = velocity.Y * t + 0.5 * -gravity * t * t

	return part.Position + Vector3.new(velocity.X * t, vertical, velocity.Z * t)
end

-- ================== TARGET FINDER ================== --
local function getClosestTarget()
	local best = nil
	local bestDist = math.huge
	local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
	local radius = fovCircle.Radius
	local ping = getPing()

	for _, otherPlayer in ipairs(Players:GetPlayers()) do
		if otherPlayer ~= LocalPlayer and otherPlayer.Character then
			if not AimAssist.Settings.TeamCheck or otherPlayer.Team ~= LocalPlayer.Team then
				local char = otherPlayer.Character
				local part = char:FindFirstChild(AimAssist.Settings.TargetPart)
				if part then
					local predicted = getPredictedPosition(char, part, ping)
					local screenPos, onScreen = Camera:WorldToViewportPoint(predicted)
					if onScreen then
						local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
						if dist < radius then
							local worldDist = (part.Position - Camera.CFrame.Position).Magnitude
							local visible = true

							if AimAssist.Settings.UseLineOfSight then
								local rayParams = RaycastParams.new()
								rayParams.FilterDescendantsInstances = {LocalPlayer.Character}
								rayParams.FilterType = Enum.RaycastFilterType.Blacklist

								local result = workspace:Raycast(Camera.CFrame.Position, (predicted - Camera.CFrame.Position).Unit * worldDist, rayParams)
								visible = result == nil
							end

							if visible and worldDist < bestDist then
								best = {
									Part = part,
									PredictedPos = predicted,
									ScreenDistance = dist,
									Fraction = dist / radius,
									WorldDistance = worldDist
								}
								bestDist = worldDist
							end
						end
					end
				end
			end
		end
	end

	return best
end

-- ================== MAIN LOOP ================== --
local connected = false

function AimAssist.Start()
	if connected then return end
	connected = true

	RunService.RenderStepped:Connect(function()
		local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
		fovCircle.Position = screenCenter

		if AimAssist.Settings.EnableFOVSync then
			updateFOVCircleRadius()
		end

		local target = getClosestTarget()
		if target then
			local assist = AimAssist.Settings.MinAssist + (1 - target.Fraction) * (AimAssist.Settings.MaxAssist - AimAssist.Settings.MinAssist)
			local direction = (target.PredictedPos - Camera.CFrame.Position).Unit
			local newLook = Camera.CFrame.LookVector:Lerp(direction, assist)
			Camera.CFrame = CFrame.new(Camera.CFrame.Position, Camera.CFrame.Position + newLook)
		end
	end)
end

return AimAssist
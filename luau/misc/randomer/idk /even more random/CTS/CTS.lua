--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

--// Rayfield UI
local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

--// Settings
local ToggleKey = Enum.KeyCode.F
local ScanInterval = 0.5
local MaxDistance = 1000
local ShowDistance = false
local ESPEnabled = true

local HullColor = Color3.fromRGB(204, 51, 230)
local TurretColor = Color3.fromRGB(51, 230, 102)

local FillTransparency = 0.5
local OutlineTransparency = 0.2
local EnableFill = true
local EnableOutline = true
local DepthMode = "AlwaysOnTop"

--// Storage
local ESPFolder = Instance.new("Folder")
ESPFolder.Name = "CTS_ESP"
ESPFolder.Parent = CoreGui

local ESPObjects = {}
local ScanTimer = 0

--// UI
local Window = Rayfield:CreateWindow({
	Name = "C.T.S",
	LoadingTitle = "Cursed Tank Simulator",
	LoadingSubtitle = "by Qwiix21",
	ConfigurationSaving = {Enabled = true, FolderName = "CTS", FileName = "config"},
	KeySystem = false,
})

Rayfield:Notify({
	Title = "C.T.S Loaded",
	Content = "Press F to toggle ESP",
	Duration = 4,
})

local MainTab = Window:CreateTab("Main")
local VisualTab = Window:CreateTab("Visual")
local SettingsTab = Window:CreateTab("Settings")

MainTab:CreateToggle({
	Name = "Enable ESP",
	CurrentValue = true,
	Callback = function(v)
		ESPEnabled = v
	end
})

MainTab:CreateToggle({
	Name = "Show Distance",
	CurrentValue = false,
	Callback = function(v)
		ShowDistance = v
	end
})

MainTab:CreateSlider({
	Name = "Max Distance",
	Range = {200, 5000},
	Increment = 50,
	Suffix = " studs",
	CurrentValue = 1000,
	Callback = function(v)
		MaxDistance = v
	end
})

VisualTab:CreateColorPicker({
	Name = "Hull Color",
	Color = HullColor,
	Callback = function(v)
		HullColor = v
	end
})

VisualTab:CreateColorPicker({
	Name = "Turret Color",
	Color = TurretColor,
	Callback = function(v)
		TurretColor = v
	end
})

VisualTab:CreateSlider({
	Name = "Fill Transparency",
	Range = {0,1},
	Increment = 0.01,
	CurrentValue = FillTransparency,
	Callback = function(v)
		FillTransparency = v
	end
})

VisualTab:CreateSlider({
	Name = "Outline Transparency",
	Range = {0,1},
	Increment = 0.01,
	CurrentValue = OutlineTransparency,
	Callback = function(v)
		OutlineTransparency = v
	end
})

--// Core Functions

local function GetDistance(model)
	return (model:GetPivot().Position - Camera.CFrame.Position).Magnitude
end

local function CreateESP(model, color, isHull)
	if ESPObjects[model] then return end

	local h = Instance.new("Highlight")
	h.Parent = ESPFolder
	h.Adornee = model
	h.FillColor = color
	h.OutlineColor = color
	h.FillTransparency = EnableFill and FillTransparency or 1
	h.OutlineTransparency = EnableOutline and OutlineTransparency or 1
	h.DepthMode = Enum.HighlightDepthMode[DepthMode]

	local gui, label
	if isHull then
		gui = Instance.new("BillboardGui")
		gui.Adornee = model
		gui.Size = UDim2.fromOffset(150, 30)
		gui.StudsOffset = Vector3.new(0,-3,0)
		gui.AlwaysOnTop = true
		gui.Parent = ESPFolder

		label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1,1)
		label.BackgroundTransparency = 1
		label.TextStrokeTransparency = 0
		label.Font = Enum.Font.SourceSansBold
		label.TextSize = 16
		label.TextColor3 = color
		label.Parent = gui
	end

	ESPObjects[model] = {
		Highlight = h,
		Label = label,
		Gui = gui,
		IsHull = isHull,
		Color = color
	}
end

local function ProcessVehicle(chassis)
	if not chassis:IsA("Actor") or not chassis.Name:match("^Chassis") then return end

	local hull = chassis:FindFirstChild("Hull")
	if hull then
		for _,m in ipairs(hull:GetChildren()) do
			if m:IsA("Model") then
				CreateESP(m, HullColor, true)
				break
			end
		end
	end

	local turret = chassis:FindFirstChild("Turret")
	if turret then
		for _,m in ipairs(turret:GetChildren()) do
			if m:IsA("Model") then
				CreateESP(m, TurretColor, false)
				break
			end
		end
	end
end

local function ScanVehicles()
	local folder = Workspace:FindFirstChild("Vehicles")
	if not folder then return end
	for _,c in ipairs(folder:GetChildren()) do
		ProcessVehicle(c)
	end
end

local function UpdateESP()
	for model,data in pairs(ESPObjects) do
		if not model:IsDescendantOf(Workspace) then
			if data.Highlight then data.Highlight:Destroy() end
			if data.Gui then data.Gui:Destroy() end
			ESPObjects[model] = nil
		else
			local dist = GetDistance(model)
			local visible = ESPEnabled and dist <= MaxDistance

			data.Highlight.Adornee = visible and model or nil

			if data.Gui then
				data.Gui.Enabled = visible and ShowDistance
				if data.Label then
					data.Label.Text = string.format("%dm", math.floor(dist/3))
				end
			end
		end
	end
end

--// Input
UserInputService.InputBegan:Connect(function(input,gp)
	if gp then return end
	if input.KeyCode == ToggleKey then
		ESPEnabled = not ESPEnabled
	end
end)

--// Loop
RunService.Heartbeat:Connect(function(dt)
	ScanTimer += dt
	if ScanTimer >= ScanInterval then
		ScanTimer = 0
		ScanVehicles()
	end
	UpdateESP()
end)

--// Cleanup
game:BindToClose(function()
	ESPFolder:Destroy()
	table.clear(ESPObjects)
end)
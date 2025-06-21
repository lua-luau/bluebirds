local Aimbot = loadstring(game:HttpGet("https://raw.githubusercontent.com/lua-luau/bluebirds/main/luau/aimassist.lua"))()
local aimbot = getgenv().Aimbot
aimbot.Settings.Enabled = true
aimbot.Settings.AimFOV = 45
aimbot.Settings.ShowFOVCircle = true
aimbot.Settings.TeamCheck = true
aimbot.Settings.HealthCheck = true
aimbot.Settings.UseLineOfSight = true
aimbot.Settings.AimSmoothing = 0.2
aimbot.Settings.TargetPart = "Head"
aimbot.Settings.LOSParts = {"Head", "HumanoidRootPart"}
aimbot.Settings.FOVCircleColor = Color3.fromRGB(0, 255, 0)

aimbot.Start()

--//aimbot.Stop()
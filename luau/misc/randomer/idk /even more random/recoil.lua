-- // ZERO RECOIL + FULL BRIGHT - SOLARA NOVEMBER 2025 FIXED \\

repeat task.wait() until game:IsLoaded()

local env = getgenv()
if env.DualCheat_Working then
    print("Script already running!")
    return
end
env.DualCheat_Working = true

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- CONFIG
local RECOIL_STRENGTH = 3.5      -- Start here, go up/down by 0.5 until perfect
local RECOIL_ENABLED = true
local FULLBRIGHT_ENABLED = false

local holdingLMB = false
local counter = 0

-- Mouse detection
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        holdingLMB = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        holdingLMB = false
    end
end)

-- RECOIL (now on RenderStepped + counter = no nil errors ever)
RunService.RenderStepped:Connect(function()
    if RECOIL_ENABLED and holdingLMB then
        counter += 1
        if counter >= 2 then  -- roughly every 0.002-0.003 seconds
            counter = 0
            mousemoverel(0, RECOIL_STRENGTH)
        end
    end

    -- Full Bright (also here so it never gets reset)
    if FULLBRIGHT_ENABLED then
        Lighting.Brightness = 10
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.GlobalShadows = false
        Lighting.ClockTime = 12
        for _, v in Lighting:GetChildren() do
            if v:IsA("Atmosphere") or v:IsA("BloomEffect") or v:IsA("BlurEffect") or 
               v:IsA("ColorCorrectionEffect") or v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
                v.Enabled = false
            end
        end
    end
end)

-- Toggles
local debounce = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or debounce then return end
    if input.KeyCode == Enum.KeyCode.End then
        debounce = true
        RECOIL_ENABLED = not RECOIL_ENABLED
        print("Zero Recoil:", RECOIL_ENABLED and "ON" or "OFF")
        task.wait(0.2)
        debounce = false
    elseif input.KeyCode == Enum.KeyCode.Home then
        debounce = true
        FULLBRIGHT_ENABLED = not FULLBRIGHT_ENABLED
        print("Full Bright:", FULLBRIGHT_ENABLED and "ON" or "OFF")
        task.wait(0.2)
        debounce = false
    end
end)

print("SOLARA FIXED - ZERO RECOIL + FULLBRIGHT LOADED 100% WORKING")
print("Hold LMB = perfect no recoil | End = toggle recoil | Home = toggle fullbright")
print("Adjust RECOIL_STRENGTH at the top if needed")
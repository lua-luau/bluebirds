-- // UNIVERSAL ZERO RECOIL + CLEAN FULLBRIGHT (Works EVERYWHERE 2025) \\

repeat task.wait() until game:IsLoaded()

local env = getgenv()

-- ==================== TUNABLE (Change & re-paste = instant update) ====================
env.PullDownPixels = 3.2      -- ← Main strength (2.5-5.0 for most games | 0 = off)
env.Randomness     = 0.6      -- ← 0 = perfectly stable laser | 0.5-1.0 = slight human feel
-- ====================================================================================

if env.UniversalCheat then
    env.PullDownPixels = env.NewPull or env.PullDownPixels
    env.Randomness     = env.NewRand or env.Randomness
    print("Universal updated → Strength:", env.PullDownPixels, "| Random:", env.Randomness)
    return
end

-- First-time load
env.NewPull = env.PullDownPixels
env.NewRand = env.Randomness
env.UniversalCheat = true

local UIS = game:GetService("UserInputService")
local RS  = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

local holding = false
local counter = 0

-- Save original lighting
local Original = {
    Brightness = Lighting.Brightness,
    GlobalShadows = Lighting.GlobalShadows,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart,
    ClockTime = Lighting.ClockTime,
}

local RECOIL_ON = true
local FB_ON = false

-- Mouse detection
UIS.InputBegan:Connect(function(i,gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        holding = true
    end
end)

UIS.InputEnded:Connect(function(i,gp)
    if gp then return end
    if i.UserInputType == Enum.UserInputType.MouseButton1 then
        holding = false
    end
end)

-- MAIN UNIVERSAL LOOP
RS.RenderStepped:Connect(function()
    counter += 1
    if RECOIL_ON and holding and counter >= 2 then
        counter = 0
        
        local strength = env.PullDownPixels
        if env.Randomness > 0 then
            strength = strength + math.random(-env.Randomness*10, env.Randomness*10)/10
        end
        
        mousemoverel(0, strength)  -- Universal downward pull
    end

    -- Clean FullBright toggle
    if FB_ON then
        Lighting.Brightness = 10
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.ClockTime = 12
        for _,v in pairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then v.Enabled = false end
        end
    else
        Lighting.Brightness = Original.Brightness
        Lighting.GlobalShadows = Original.GlobalShadows
        Lighting.FogEnd = Original.FogEnd
        Lighting.FogStart = Original.FogStart
        Lighting.ClockTime = Original.ClockTime
    end
end)

-- Toggles
local db = false
UIS.InputBegan:Connect(function(i,gp)
    if gp or db then return end
    db = true

    if i.KeyCode == Enum.KeyCode.End then
        RECOIL_ON = not RECOIL_ON
        print("Universal Recoil:", RECOIL_ON and "ON" or "OFF")

    elseif i.KeyCode == Enum.KeyCode.Home then
        FB_ON = not FB_ON
        print("FullBright:", FB_ON and "ON" or "OFF")
    end

    task.wait(0.2)
    db = false
end)

print("UNIVERSAL ZERO-RECOIL LOADED (Works in EVERY FPS)")
print("Hold LMB = Laser | End = Toggle Recoil | Home = Toggle FullBright")
print("Current Pull:", env.PullDownPixels, "| Random:", env.Randomness)
print("Change numbers at top → re-paste to update instantly")
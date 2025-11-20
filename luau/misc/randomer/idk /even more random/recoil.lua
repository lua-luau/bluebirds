-- // Zero Recoil + Full Bright - SOLARA PERFECT (Recoil FIXED) \\

repeat task.wait() until game:IsLoaded()

local env = getgenv()
if env.DualCheat_Instanced then
    print("Script already running | End = Recoil Toggle | Home = FullBright Toggle")
    return
end
env.DualCheat_Instanced = true

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- ==================== CONFIG ====================
local RECOIL_STRENGTH = 3.5      -- Pixels down per tick (tune: 2-5 most games)
local RECOIL_INTERVAL = 0.002    -- Super smooth pull rate
local RECOIL_ENABLED = true
local FULLBRIGHT_ENABLED = false
-- ================================================

local holdingLMB = false

-- FIXED Recoil (Solara: mousemoverel)
local function pullDown()
    if RECOIL_ENABLED and holdingLMB then
        mousemoverel(0, RECOIL_STRENGTH)
    end
end

-- Mouse Hold Detection
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        holdingLMB = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        holdingLMB = false
    end
end)

-- Full Bright (anti-reset loop)
local function forceFullBright()
    if not FULLBRIGHT_ENABLED then return end
    
    Lighting.Brightness = 10
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.GlobalShadows = false
    Lighting.ClockTime = 12

    for _, v in Lighting:GetChildren() do
        if v:IsA("BloomEffect") or v:IsA("BlurEffect") or v:IsA("ColorCorrectionEffect") or 
           v:IsA("DepthOfFieldEffect") or v:IsA("SunRaysEffect") then
            v.Enabled = false
        end
    end
end

-- Loops
RunService.Heartbeat:Connect(function()
    pullDown()
    task.wait(RECOIL_INTERVAL)
end)

RunService.RenderStepped:Connect(forceFullBright)

-- Toggle Keys (optimized debounce - only triggers on bind keys)
local canToggle = true
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed or not canToggle then return end
    
    if input.KeyCode == Enum.KeyCode.End then
        canToggle = false
        RECOIL_ENABLED = not RECOIL_ENABLED
        print("Zero Recoil:", RECOIL_ENABLED and "ON" or "OFF")
        task.spawn(function()
            task.wait(0.2)
            canToggle = true
        end)
        
    elseif input.KeyCode == Enum.KeyCode.Home then
        canToggle = false
        FULLBRIGHT_ENABLED = not FULLBRIGHT_ENABLED
        print("Full Bright:", FULLBRIGHT_ENABLED and "ON" or "OFF")
        task.spawn(function()
            task.wait(0.2)
            canToggle = true
        end)
    end
end)

print("✅ Solara FIXED - Recoil + FullBright LOADED")
print("Hold LMB = PERFECT zero recoil | End = Toggle recoil | Home = Toggle FullBright")
print("Tune RECOIL_STRENGTH if needed (higher = stronger pull down)")
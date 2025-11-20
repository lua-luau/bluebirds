-- // Zero Recoil + Full Bright (Dual Feature) - Non-Layering \\

repeat task.wait() until game:IsLoaded()

local env = getgenv()
if env.DualCheat_Instanced then
    print("Dual cheat already running | End = Recoil | Home = FullBright")
    return
end
env.DualCheat_Instanced = true

local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")

-- ==================== CONFIG ====================
local RECOIL_STRENGTH = 3.5      -- Tune per game
local RECOIL_INTERVAL = 0.002    -- Super smooth
local RECOIL_ENABLED = true

local FULLBRIGHT_ENABLED = false
-- ================================================

local holdingLMB = false

-- // Recoil Control
local function pullDown()
    if not RECOIL_ENABLED or not holdingLMB then return end
    mousemove_rel(0, RECOIL_STRENGTH)
end

UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        holdingLMB = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        holdingLMB = false
    end
end)

RunService.Heartbeat:Connect(function()
    if holdingLMB and RECOIL_ENABLED then
        pullDown()
        task.wait(RECOIL_INTERVAL)
    end
end)

-- // Full Bright (forces it every frame because games revert it)
local function applyFullBright()
    if not FULLBRIGHT_ENABLED then return end
    
    Lighting.Brightness = 1
    Lighting.ClockTime = 12
    Lighting.FogEnd = 100000
    Lighting.FogStart = 0
    Lighting.GlobalShadows = false
    Lighting.ShadowSoftness = 0
    
    for _, v in pairs(Lighting:GetChildren()) do
        if v:IsA("PostEffect") then
            if v.Name == "ColorCorrection" then
                v.Saturation = 0.5
                v.Contrast = 0.3
                v.Brightness = 0.1
            elseif v.Name ~= "Sky" then
                v.Enabled = false
            end
        end
    end
end

RunService.RenderStepped:Connect(applyFullBright)  -- Runs every frame to fight game resets

-- // Key Toggles (with debounce)
local debounce = false
UserInputService.InputBegan:Connect(function(input, gp  gp)
    if gp or debounce then return end
    debounce = true

    if input.KeyCode == Enum.KeyCode.End then
        RECOIL_ENABLED = not RECOIL_ENABLED
        print("🔫 Zero Recoil:", RECOIL_ENABLED and "§aON" or "§cOFF")

    elseif input.KeyCode == Enum.KeyCode.Home then
        FULLBRIGHT_ENABLED = not FULLBRIGHT_ENABLED
        print("☀ Full Bright:", FULLBRIGHT_ENABLED and "§aON" or "§cOFF")
        if FULLBRIGHT_ENABLED then
            Lighting.Brightness = 1
            Lighting.GlobalShadows = false
        end
    end

    task.wait(0.2)
    debounce = false
end)

print("✅ Dual cheat loaded!")
print("   Hold LMB  →  Zero vertical recoil")
print("   End key   →  Toggle recoil control")
print("   Home key  →  Toggle full bright (permanent)")
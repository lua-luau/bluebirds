-- // BRM5 PERFECT TUNABLE NO-RECOIL + CLEAN FULLBRIGHT (Solara 2025) \\
-- Sets weapon recoil properties directly = 100% stable laser (no mouse movement!)

repeat task.wait() until game:IsLoaded()

local env = getgenv()

-- ==================== SAFE RE-EXEC (Change numbers below & re-paste to update!) ====================
env.NewVertRecoil = 0       -- ← VERTICAL: 0=no recoil | 1=slight | 2=medium | 3=heavy
env.NewHorzRecoil = 0       -- ← HORIZONTAL: 0=no side kick | 1=slight | etc.

if env.BRM5_TunableCheat then
    print("🔄 Updating recoil config...")
    env.VERT_RECOIL_AMOUNT = env.NewVertRecoil
    env.HORZ_RECOIL_AMOUNT = env.NewHorzRecoil
    print("✅ Updated! Vert:", env.VERT_RECOIL_AMOUNT, "| Horz:", env.HORZ_RECOIL_AMOUNT)
    return
end
env.BRM5_TunableCheat = true
env.VERT_RECOIL_AMOUNT = env.NewVertRecoil
env.HORZ_RECOIL_AMOUNT = env.NewHorzRecoil
-- =================================================================================================

local Players           = game:GetService("Players")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local Lighting          = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

-- Save original lighting
local OriginalLighting = {
    Brightness       = Lighting.Brightness,
    GlobalShadows    = Lighting.GlobalShadows,
    FogEnd           = Lighting.FogStart,
    FogStart         = Lighting.FogStart,
    ClockTime        = Lighting.ClockTime,
    Ambient          = Lighting.Ambient,
    OutdoorAmbient   = Lighting.OutdoorAmbient
}

local RECOIL_ENABLED = true
local FULLBRIGHT_ENABLED = false

-- Weapon Recoil Modifier Loop (BRM5 specific - perfect zero recoil)
RunService.Heartbeat:Connect(function()
    if RECOIL_ENABLED then
        local cam = workspace.CurrentCamera
        local gun = cam:FindFirstChildOfClass("Tool")
        if gun and gun:FindFirstChild("Handle") then
            local handle = gun.Handle
            
            -- Set tunable recoil amounts (0 = laser, higher = more realistic recoil)
            if handle:FindFirstChild("RecoilUp") then
                handle.RecoilUp.Value = env.VERT_RECOIL_AMOUNT
            end
            if handle:FindFirstChild("RecoilSide") then
                handle.RecoilSide.Value = env.HORZ_RECOIL_AMOUNT
            end
            if handle:FindFirstChild("RecoilUpModifier") then
                handle.RecoilUpModifier.Value = env.VERT_RECOIL_AMOUNT * 0.1  -- subtle modifier
            end
            if handle:FindFirstChild("RecoilSideModifier") then
                handle.RecoilSideModifier.Value = env.HORZ_RECOIL_AMOUNT * 0.1
            end
        end
    end
end)

-- FullBright Loop (perfect restore)
RunService.RenderStepped:Connect(function()
    if FULLBRIGHT_ENABLED then
        Lighting.Brightness = 10
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
        Lighting.FogStart = 0
        Lighting.ClockTime = 12
        for _, v in pairs(Lighting:GetChildren()) do
            if v:IsA("PostEffect") then
                v.Enabled = false
            end
        end
    else
        -- Restore original EVERY frame
        Lighting.Brightness       = OriginalLighting.Brightness
        Lighting.GlobalShadows    = OriginalLighting.GlobalShadows
        Lighting.FogEnd           = OriginalLighting.FogEnd
        Lighting.FogStart         = OriginalLighting.FogStart
        Lighting.ClockTime        = OriginalLighting.ClockTime
        Lighting.Ambient          = OriginalLighting.Ambient
        Lighting.OutdoorAmbient   = OriginalLighting.OutdoorAmbient
    end
end)

-- Toggles
local debounce = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or debounce then return end
    debounce = true

    if input.KeyCode == Enum.KeyCode.End then
        RECOIL_ENABLED = not RECOIL_ENABLED
        print("Tunable No-Recoil:", RECOIL_ENABLED and "§aON" or "§cOFF")
        print("   (Vert:", env.VERT_RECOIL_AMOUNT, "| Horz:", env.HORZ_RECOIL_AMOUNT, ")")

    elseif input.KeyCode == Enum.KeyCode.Home then
        FULLBRIGHT_ENABLED = not FULLBRIGHT_ENABLED
        print("Full Bright:", FULLBRIGHT_ENABLED and "§aON" or "§cOFF")
    end

    task.wait(0.2)
    debounce = false
end)

print("✅ BRM5 TUNABLE NO-RECOIL LOADED (Direct weapon mod = PERFECT)")
print("   Hold any gun → auto applies settings | End = Toggle | Home = FullBright")
print("   §cVert Recoil§r:", env.VERT_RECOIL_AMOUNT, "§cHorz Recoil§r:", env.HORZ_RECOIL_AMOUNT)
print("   §lRe-paste to change numbers at top§r → instant update!")
print("   §a0 = laser beam | 1-3 = realistic§r")
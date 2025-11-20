-- // ULTIMATE BRM5 CHEAT: Zero Recoil + FullBright + Enemy ESP - SOLARA SAFE RE-EXEC \\

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local localplayer = Players.LocalPlayer

-- ==================== CONFIG (Re-Exec to UPDATE these!) ====================
local CONFIG = {
    RECOIL_STRENGTH = 4,        -- Pixels down (INTEGER for Solara - tune 3-6 for BRM5)
}
-- ===========================================================================

-- Safe Re-Execution Handler
if getgenv().BRM5_Cheat then
    print("🔄 Updating config... (Re-Exec detected)")
    getgenv().CONFIG.RECOIL_STRENGTH = CONFIG.RECOIL_STRENGTH
    -- Clear old ESP drawings
    if getgenv().ESP then
        for _, data in pairs(getgenv().ESP) do
            pcall(function()
                data.box:Remove()
                data.text:Remove()
            end)
        end
    end
    getgenv().ESP = {}
    print("✅ Config updated! New recoil strength:", getgenv().CONFIG.RECOIL_STRENGTH)
    return
end
getgenv().BRM5_Cheat = true
getgenv().CONFIG = CONFIG

-- Runtime Toggles
local RECOIL_ENABLED = true
local FULLBRIGHT_ENABLED = false
local ESP_ENABLED = false

local holdingLMB = false
local counter = 0
getgenv().ESP = {}

-- ==================== RECOIL + FULLBRIGHT + ESP ====================
RunService.RenderStepped:Connect(function()
    -- Recoil (Solara-safe counter throttle)
    if RECOIL_ENABLED and holdingLMB then
        counter += 1
        if counter >= 2 then  -- ~every 0.033s (smooth, no lag)
            counter = 0
            mousemoverel(0, getgenv().CONFIG.RECOIL_STRENGTH)
        end
    end

    -- Full Bright (fights resets)
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

    -- Enemy ESP Update
    if ESP_ENABLED then
        local cam = workspace.CurrentCamera
        local lpchar = localplayer.Character
        if not lpchar or not lpchar:FindFirstChild("HumanoidRootPart") then return end
        local lppos = lpchar.HumanoidRootPart.Position

        for model, data in pairs(getgenv().ESP) do
            if not model.Parent or not data.root or not data.root.Parent then
                pcall(function()
                    data.box:Remove()
                    data.text:Remove()
                end)
                getgenv().ESP[model] = nil
                continue
            end

            local rootpos = data.root.Position
            local dist = (lppos - rootpos).Magnitude
            if dist > 3000 then  -- Max range
                data.box.Visible = false
                data.text.Visible = false
                continue
            end

            local headpos = data.head.Position
            local screenroot, visible1 = cam:WorldToViewportPoint(rootpos)
            local screenhead, visible2 = cam:WorldToViewportPoint(headpos)

            if visible1 or visible2 then
                local headToRoot = screenroot.Y - screenhead.Y
                local size = math.clamp(math.abs(headToRoot) * 1.5, 8, 300)
                data.box.Size = Vector2.new(size * 0.6, size)
                data.box.Position = Vector2.new(screenroot.X - data.box.Size.X / 2, screenroot.Y - data.box.Size.Y / 2)
                data.box.Visible = true

                data.text.Text = data.name .. " [" .. math.floor(dist) .. "]"
                data.text.Position = Vector2.new(screenroot.X, screenroot.Y + data.box.Size.Y / 2 + 5)
                data.text.Visible = true
            else
                data.box.Visible = false
                data.text.Visible = false
            end
        end
    else
        -- Hide ESP when off
        for _, data in pairs(getgenv().ESP) do
            data.box.Visible = false
            data.text.Visible = false
        end
    end
end)

-- ==================== ENEMY ESP CREATOR ====================
local function createEnemyESP(model, plr)
    if getgenv().ESP[model] then return end

    -- Skip teammates
    if plr and plr.Team and localplayer.Team and plr.Team == localplayer.Team then return end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    local root = model:FindFirstChild("HumanoidRootPart")
    local head = model:FindFirstChild("Head")
    if not (humanoid and root and head) then return end

    local data = {}
    local box = Drawing.new("Square")
    box.Color = Color3.fromRGB(255, 0, 0)  -- Red for enemies
    box.Thickness = 3
    box.Filled = false
    box.Transparency = 0.9
    box.Visible = false

    local text = Drawing.new("Text")
    text.Font = 2
    text.Size = 18
    text.Center = true
    text.Outline = true
    text.Color = Color3.fromRGB(255, 255, 255)
    text.Visible = false

    data.box = box
    data.text = text
    data.root = root
    data.head = head
    data.name = humanoid.DisplayName ~= "" and humanoid.DisplayName or model.Name

    getgenv().ESP[model] = data
end

-- ==================== MOUSE HOLD ====================
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

-- ==================== TOGGLES (Debounced) ====================
local debounce = false
UserInputService.InputBegan:Connect(function(input, gp)
    if gp or debounce then return end
    debounce = true

    if input.KeyCode == Enum.KeyCode.End then
        RECOIL_ENABLED = not RECOIL_ENABLED
        print("🔫 Zero Recoil:", RECOIL_ENABLED and "§aON" or "§cOFF")
    elseif input.KeyCode == Enum.KeyCode.Home then
        FULLBRIGHT_ENABLED = not FULLBRIGHT_ENABLED
        print("☀️ Full Bright:", FULLBRIGHT_ENABLED and "§aON" or "§cOFF")
    elseif input.KeyCode == Enum.KeyCode.Delete then
        ESP_ENABLED = not ESP_ENABLED
        print("👁️ Enemy ESP (Players + NPCs):", ESP_ENABLED and "§aON" or "§cOFF")
    end

    task.spawn(function()
        task.wait(0.25)
        debounce = false
    end)
end)

-- ==================== DYNAMIC ESP SETUP ====================
-- Players
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= localplayer then
        if plr.Character then
            createEnemyESP(plr.Character, plr)
        end
        plr.CharacterAdded:Connect(function(char)
            task.wait(0.1)  -- Load time
            createEnemyESP(char, plr)
        end)
    end
end
Players.PlayerAdded:Connect(function(plr)
    plr.CharacterAdded:Connect(function(char)
        task.wait(0.1)
        createEnemyESP(char, plr)
    end)
end)

-- NPCs (AI_ models)
workspace.ChildAdded:Connect(function(child)
    task.wait()
    if child:IsA("Model") and child.Name:match("^AI_") and child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
        createEnemyESP(child, nil)
    end
end)

-- Scan existing NPCs
for _, child in ipairs(workspace:GetChildren()) do
    if child:IsA("Model") and child.Name:match("^AI_") and child:FindFirstChild("Humanoid") and child:FindFirstChild("HumanoidRootPart") then
        createEnemyESP(child, nil)
    end
end

print("✅ BRM5 ULTIMATE CHEAT LOADED (Re-Exec to change RECOIL_STRENGTH!)")
print("🔫 Hold LMB = Zero Recoil | §cEnd§r = Toggle Recoil")
print("☀️ §cHome§r = Toggle FullBright")
print("👁️ §cDelete§r = Toggle Enemy ESP (Red boxes + dist on enemies/NPCs)")
print("💡 Strength:", getgenv().CONFIG.RECOIL_STRENGTH, "| Re-Exec anytime to update!")
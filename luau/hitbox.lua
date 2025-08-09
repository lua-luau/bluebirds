--// Hitbox Expander + Utility UI (Refactored)

--// Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

--// Global Config
getgenv().Config = {
    HitboxSize = 15,
    HitboxTransparency = 0.9,
    HitboxStatus = false,
    TeamCheck = false,
    SanityCheck = false,

    WalkSpeed = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid.WalkSpeed or 16,
    JumpPower = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character.Humanoid.JumpPower or 50,

    TPSpeed = 3,
    TPWalk = false,

    LoopWalkSpeed = false,
    LoopJumpPower = false,
    Noclip = false,
    InfiniteJump = false,
}

--// UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vcsk/UI-Library/main/Source/MyUILib(Unamed).lua"))()
local Window = Library:Create("Hitbox Expander")

--// Toggle Button UI
local function createToggleButton()
    local gui = Instance.new("ScreenGui")
    gui.Parent = CoreGui

    local btn = Instance.new("TextButton")
    btn.Name = "Toggle"
    btn.Size = UDim2.new(0.065, 0, 0.088, 0)
    btn.Position = UDim2.new(0, 0, 0.45, 0)
    btn.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    btn.BackgroundTransparency = 0.66
    btn.Font = Enum.Font.SourceSans
    btn.Text = "Toggle"
    btn.TextScaled = true
    btn.TextColor3 = Color3.fromRGB(40, 40, 40)
    btn.Draggable = true
    btn.Parent = gui

    btn.MouseButton1Click:Connect(function()
        Library:ToggleUI()
    end)
end
createToggleButton()

--// Helper: Safe humanoid property loop
local function maintainProperty(property, valueGetter, conditionGetter)
    RunService.Heartbeat:Connect(function()
        if conditionGetter() then
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                hum[property] = valueGetter()
            end
        end
    end)
end

--// Tabs
local HomeTab = Window:Tab("Home", "rbxassetid://10888331510")
local PlayerTab = Window:Tab("Players", "rbxassetid://12296135476")
local VisualTab = Window:Tab("Visuals", "rbxassetid://12308581351")

--// Home Controls
HomeTab:TextBox("Hitbox Size", function(v) Config.HitboxSize = tonumber(v) or 15 end)
HomeTab:TextBox("Hitbox Transparency", function(v) Config.HitboxTransparency = tonumber(v) or 0.9 end)
HomeTab:Toggle("Enable Hitbox", function(s) Config.HitboxStatus = s end)
HomeTab:Toggle("Team Check", function(s) Config.TeamCheck = s end)
HomeTab:Toggle("Sanity Check (Auto Remove on Death)", function(s) Config.SanityCheck = s end)
HomeTab:Keybind("Toggle UI", Enum.KeyCode.F, Library.ToggleUI)

--// Player Controls
PlayerTab:TextBox("WalkSpeed", function(v) Config.WalkSpeed = tonumber(v) or Config.WalkSpeed end)
PlayerTab:Toggle("Loop WalkSpeed", function(s) Config.LoopWalkSpeed = s end)
maintainProperty("WalkSpeed", function() return Config.WalkSpeed end, function() return Config.LoopWalkSpeed end)

PlayerTab:TextBox("JumpPower", function(v) Config.JumpPower = tonumber(v) or Config.JumpPower end)
PlayerTab:Toggle("Loop JumpPower", function(s) Config.LoopJumpPower = s end)
maintainProperty("JumpPower", function() return Config.JumpPower end, function() return Config.LoopJumpPower end)

PlayerTab:TextBox("TP Speed", function(v) Config.TPSpeed = tonumber(v) or 3 end)
PlayerTab:Toggle("TP Walk", function(s)
    Config.TPWalk = s
end)

RunService.Heartbeat:Connect(function()
    if Config.TPWalk then
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChildOfClass("Humanoid")
        if hum and hum.MoveDirection.Magnitude > 0 then
            char:TranslateBy(hum.MoveDirection * Config.TPSpeed)
        end
    end
end)

PlayerTab:Slider("FOV", workspace.CurrentCamera.FieldOfView, 120, function(v)
    workspace.CurrentCamera.FieldOfView = v
end)

PlayerTab:Toggle("Noclip", function(s) Config.Noclip = s end)
RunService.Stepped:Connect(function()
    if Config.Noclip then
        local char = LocalPlayer.Character
        if char then
            for _, part in ipairs({char:FindFirstChild("Head"), char:FindFirstChild("Torso")}) do
                if part then part.CanCollide = false end
            end
        end
    end
end)

PlayerTab:Toggle("Infinite Jump", function(s) Config.InfiniteJump = s end)
UserInputService.JumpRequest:Connect(function()
    if Config.InfiniteJump then
        local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
    end
end)

PlayerTab:Button("Rejoin", function()
    TeleportService:Teleport(game.PlaceId, LocalPlayer)
end)

--// Visuals
VisualTab:Toggle("Character Highlight", function(state)
    getgenv().enabled = state
    getgenv().filluseteamcolor = true
    getgenv().outlineuseteamcolor = true
    getgenv().fillcolor = Color3.new(0, 0, 0)
    getgenv().outlinecolor = Color3.new(1, 1, 1)
    getgenv().filltrans = 0.5
    getgenv().outlinetrans = 0.3
    loadstring(game:HttpGet("https://raw.githubusercontent.com/lua-luau/bluebirds/refs/heads/main/luau/misc/ESP.lua"))()
end)

--// Hitbox Logic
local function updateHitbox()
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Character then
            local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            if hrp then
                local isEnemy = not Config.TeamCheck or plr.Team ~= LocalPlayer.Team
                local isAlive = not Config.SanityCheck or (hum and hum.Health > 0)
                if Config.HitboxStatus and isEnemy and isAlive then
                    hrp.Size = Vector3.new(Config.HitboxSize, Config.HitboxSize, Config.HitboxSize)
                    hrp.Transparency = Config.HitboxTransparency
                    hrp.BrickColor = BrickColor.new("Really black")
                    hrp.Material = Enum.Material.Neon
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.BrickColor = BrickColor.new("Medium stone grey")
                    hrp.Material = Enum.Material.Plastic
                end
                hrp.CanCollide = false
            end
        end
    end
end

RunService.RenderStepped:Connect(updateHitbox)
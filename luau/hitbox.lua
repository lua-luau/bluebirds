-- Hitbox Expander + Utility UI

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local CoreGui = game:GetService("CoreGui")

-- Globals
getgenv().HitboxSize = 15
getgenv().HitboxTransparency = 0.9
getgenv().HitboxStatus = false
getgenv().TeamCheck = false
getgenv().SanityCheck = false
getgenv().Walkspeed = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character:FindFirstChildOfClass("Humanoid").WalkSpeed or 16
getgenv().Jumppower = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") and LocalPlayer.Character:FindFirstChildOfClass("Humanoid").JumpPower or 50
getgenv().TPSpeed = 3
getgenv().TPWalk = false

-- Load UI Library
local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Vcsk/UI-Library/main/Source/MyUILib(Unamed).lua"))()
local Window = Library:Create("Hitbox Expander")

-- Toggle Button UI
local ToggleGui = Instance.new("ScreenGui", CoreGui)
local Toggle = Instance.new("TextButton", ToggleGui)
Toggle.Name = "Toggle"
Toggle.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
Toggle.BackgroundTransparency = 0.66
Toggle.Position = UDim2.new(0, 0, 0.45, 0)
Toggle.Size = UDim2.new(0.065, 0, 0.088, 0)
Toggle.Font = Enum.Font.SourceSans
Toggle.Text = "Toggle"
Toggle.TextScaled = true
Toggle.TextColor3 = Color3.fromRGB(40, 40, 40)
Toggle.TextSize = 24
Toggle.TextXAlignment = Enum.TextXAlignment.Left
Toggle.Draggable = true
Toggle.MouseButton1Click:Connect(function()
    Library:ToggleUI()
end)

-- Tabs
local HomeTab = Window:Tab("Home", "rbxassetid://10888331510")
local PlayerTab = Window:Tab("Players", "rbxassetid://12296135476")
local VisualTab = Window:Tab("Visuals", "rbxassetid://12308581351")

-- Home
HomeTab:TextBox("Hitbox Size", function(value) getgenv().HitboxSize = tonumber(value) or 15 end)
HomeTab:TextBox("Hitbox Transparency", function(value) getgenv().HitboxTransparency = tonumber(value) or 0.9 end)
HomeTab:Toggle("Enable Hitbox", function(state) getgenv().HitboxStatus = state end)
HomeTab:Toggle("Team Check", function(state) getgenv().TeamCheck = state end)
HomeTab:Toggle("Sanity Check (Auto Remove on Death)", function(state) getgenv().SanityCheck = state end)
HomeTab:Keybind("Toggle UI", Enum.KeyCode.F, function() Library:ToggleUI() end)

-- Player
PlayerTab:TextBox("WalkSpeed", function(value)
    getgenv().Walkspeed = tonumber(value)
    pcall(function()
        LocalPlayer.Character.Humanoid.WalkSpeed = getgenv().Walkspeed
    end)
end)
PlayerTab:Toggle("Loop WalkSpeed", function(state)
    getgenv().loopW = state
    RunService.Heartbeat:Connect(function()
        if getgenv().loopW then
            pcall(function()
                LocalPlayer.Character.Humanoid.WalkSpeed = getgenv().Walkspeed
            end)
        end
    end)
end)
PlayerTab:TextBox("JumpPower", function(value)
    getgenv().Jumppower = tonumber(value)
    pcall(function()
        LocalPlayer.Character.Humanoid.JumpPower = getgenv().Jumppower
    end)
end)
PlayerTab:Toggle("Loop JumpPower", function(state)
    getgenv().loopJ = state
    RunService.Heartbeat:Connect(function()
        if getgenv().loopJ then
            pcall(function()
                LocalPlayer.Character.Humanoid.JumpPower = getgenv().Jumppower
            end)
        end
    end)
end)
PlayerTab:TextBox("TP Speed", function(value) getgenv().TPSpeed = tonumber(value) or 3 end)
PlayerTab:Toggle("TP Walk", function(s)
    getgenv().TPWalk = s
    spawn(function()
        while getgenv().TPWalk and task.wait() do
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum and hum.MoveDirection.Magnitude > 0 then
                char:TranslateBy(hum.MoveDirection * getgenv().TPSpeed)
            end
        end
    end)
end)
PlayerTab:Slider("FOV", workspace.CurrentCamera.FieldOfView, 120, function(v)
    workspace.CurrentCamera.FieldOfView = v
end)
PlayerTab:Toggle("Noclip", function(state)
    getgenv().Noclip = state
    RunService.Stepped:Connect(function()
        if getgenv().Noclip then
            local char = LocalPlayer.Character
            if char then
                for _, part in ipairs({char:FindFirstChild("Head"), char:FindFirstChild("Torso")}) do
                    if part then part.CanCollide = false end
                end
            end
        end
    end)
end)
PlayerTab:Toggle("Infinite Jump", function(state)
    getgenv().InfJ = state
    game:GetService("UserInputService").JumpRequest:Connect(function()
        if getgenv().InfJ then
            local hum = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end)
end)
PlayerTab:Button("Rejoin", function()
    game:GetService("TeleportService"):Teleport(game.PlaceId, LocalPlayer)
end)

-- Visuals
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

-- Hitbox logic loop
RunService.RenderStepped:Connect(function()
    for _, v in ipairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character then
            local char = v.Character
            local hrp = char:FindFirstChild("HumanoidRootPart")
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hrp then
                local isEnemy = not getgenv().TeamCheck or v.Team ~= LocalPlayer.Team
                local isAlive = not getgenv().SanityCheck or (hum and hum.Health > 0)
                if getgenv().HitboxStatus and isEnemy and isAlive then
                    hrp.Size = Vector3.new(getgenv().HitboxSize, getgenv().HitboxSize, getgenv().HitboxSize)
                    hrp.Transparency = getgenv().HitboxTransparency
                    hrp.BrickColor = BrickColor.new("Really black")
                    hrp.Material = Enum.Material.Neon
                    hrp.CanCollide = false
                else
                    hrp.Size = Vector3.new(2, 2, 1)
                    hrp.Transparency = 1
                    hrp.BrickColor = BrickColor.new("Medium stone grey")
                    hrp.Material = Enum.Material.Plastic
                    hrp.CanCollide = false
                end
            end
        end
    end
end)

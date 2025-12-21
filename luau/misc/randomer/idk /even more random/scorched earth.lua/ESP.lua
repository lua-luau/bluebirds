-- It doesn't turn on right away. It won't take long
local ESP = {
    Enabled = false,
    Boxes = true,
    BoxShift = CFrame.new(0, -1.5, 0),
    BoxSize = Vector3.new(4, 6, 0),
    Color = Color3.fromRGB(255, 170, 0),
    Thickness = 2,
    AttachShift = 1,
    
    Objects = setmetatable({}, {__mode="kv"}),
    Overrides = {}
}

local cam = workspace.CurrentCamera
local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local mouse = plr:GetMouse()

local V3new = Vector3.new
local WorldToViewportPoint = cam.WorldToViewportPoint

local function Draw(obj, props)
    local new = Drawing.new(obj)
    
    props = props or {}
    for i, v in pairs(props) do
        new[i] = v
    end
    return new
end

function ESP:GetColor(obj)
    local ov = self.Overrides.GetColor
    if ov then
        return ov(obj)
    end
    local p = self:GetPlrFromChar(obj)
    return p and self.Color
end

function ESP:GetPlrFromChar(char)
    local ov = self.Overrides.GetPlrFromChar
    if ov then
        return ov(char)
    end
    
    return plrs:GetPlayerFromCharacter(char)
end

function ESP:Toggle(bool)
    self.Enabled = bool
    if not bool then
        for i, v in pairs(self.Objects) do
            if v.Type == "Box" then
                if v.Temporary then
                    v:Remove()
                else
                    for i, v in pairs(v.Components) do
                        v.Visible = false
                    end
                end
            end
        end
    end
end

function ESP:GetBox(obj)
    return self.Objects[obj]
end

function ESP:AddObjectListener(parent, options)
    if not parent then
        return
    end

    local function NewListener(c)
        if type(options.Type) == "string" and c:IsA(options.Type) or options.Type == nil then
            if type(options.Name) == "string" and c.Name == options.Name or options.Name == nil then
                if not options.Validator or options.Validator(c) then
                    if c.Parent and workspace:IsAncestorOf(c) then
                        local box = ESP:Add(c, {
                            PrimaryPart = type(options.PrimaryPart) == "string" and c:WaitForChild(options.PrimaryPart) or type(options.PrimaryPart) == "function" and options.PrimaryPart(c),
                            Color = type(options.Color) == "function" and options.Color(c) or options.Color,
                            ColorDynamic = options.ColorDynamic,
                            IsEnabled = options.IsEnabled,
                            RenderInNil = options.RenderInNil
                        })
                        if options.OnAdded then
                            coroutine.wrap(options.OnAdded)(box)
                        end
                    else
                    end
                end
            end
        end
    end
    
    if options.Recursive then
        parent.DescendantAdded:Connect(NewListener)
        for i, v in pairs(parent:GetDescendants()) do
            NewListener(v)
        end
    else
        parent.ChildAdded:Connect(NewListener)
        for i, v in pairs(parent:GetChildren()) do
            NewListener(v)
        end
    end
end

local boxBase = {}
boxBase.__index = boxBase

function boxBase:Remove()
    ESP.Objects[self.Object] = nil
    for i, v in pairs(self.Components) do
        if v then
            v.Visible = false
            v:Remove()
            self.Components[i] = nil
        end
    end
end

function boxBase:Update()
    if not self.PrimaryPart then
        return self:Remove()
    end

    local allow = true

    if ESP.Overrides.UpdateAllow and not ESP.Overrides.UpdateAllow(self) then
        allow = false
    end
    if self.IsEnabled and (type(self.IsEnabled) == "string" and not ESP[self.IsEnabled] or type(self.IsEnabled) == "function" and not self:IsEnabled()) then
        allow = false
    end
    if not workspace:IsAncestorOf(self.PrimaryPart) and not self.RenderInNil then
        allow = false
    end

    if not allow then
        for i, v in pairs(self.Components) do
            if v then
                v.Visible = false
            end
        end
        return
    end

    local size = self.Size
    local cf = self.PrimaryPart.CFrame

    local locs = {
        TopLeft = WorldToViewportPoint(cam, (cf * ESP.BoxShift * CFrame.new(size.X / 2, size.Y / 2, 0)).Position),
        TopRight = WorldToViewportPoint(cam, (cf * ESP.BoxShift * CFrame.new(-size.X / 2, size.Y / 2, 0)).Position),
        BottomLeft = WorldToViewportPoint(cam, (cf * ESP.BoxShift * CFrame.new(size.X / 2, -size.Y / 2, 0)).Position),
        BottomRight = WorldToViewportPoint(cam, (cf * ESP.BoxShift * CFrame.new(-size.X / 2, -size.Y / 2, 0)).Position)
    }

    if self.Components.Quad then
        if locs.TopRight.Z > 0 and locs.TopLeft.Z > 0 and locs.BottomLeft.Z > 0 and locs.BottomRight.Z > 0 then
            self.Components.Quad.Visible = true
            self.Components.Quad.PointA = Vector2.new(locs.TopRight.X, locs.TopRight.Y)
            self.Components.Quad.PointB = Vector2.new(locs.TopLeft.X, locs.TopLeft.Y)
            self.Components.Quad.PointC = Vector2.new(locs.BottomLeft.X, locs.BottomLeft.Y)
            self.Components.Quad.PointD = Vector2.new(locs.BottomRight.X, locs.BottomRight.Y)
            self.Components.Quad.Color = self.Color or ESP.Color
        else
            self.Components.Quad.Visible = false
        end
        self.Components.Quad.Color = self.Color or ESP.Color
    end
end

function ESP:Add(obj, options)
    if not obj.Parent and not options.RenderInNil then
        return
    end

    local box = setmetatable({
        Type = "Box",
        Color = options.Color,
        Size = options.Size or self.BoxSize,
        Object = obj,
        Player = options.Player or plrs:GetPlayerFromCharacter(obj),
        PrimaryPart = options.PrimaryPart or obj.ClassName == "Model" and (obj.PrimaryPart or obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildWhichIsA("BasePart")) or obj:IsA("BasePart") and obj,
        Components = {},
        IsEnabled = options.IsEnabled,
        Temporary = options.Temporary,
        ColorDynamic = options.ColorDynamic,
        RenderInNil = options.RenderInNil
    }, boxBase)

    if not box.PrimaryPart then
        return
    end

    if self:GetBox(obj) then
        self:GetBox(obj):Remove()
    end

    box.Components["Quad"] = Draw("Quad", {
        Thickness = self.Thickness,
        Color = box.Color,
        Transparency = 1,
        Filled = false,
        Visible = self.Enabled and self.Boxes
    })

    self.Objects[obj] = box

    obj.AncestryChanged:Connect(function(_, parent)
        if parent == nil and ESP.AutoRemove ~= false then
            box:Remove()
        end
    end)
    obj:GetPropertyChangedSignal("Parent"):Connect(function()
        if obj.Parent == nil and ESP.AutoRemove ~= false then
            box:Remove()
        end
    end)

    local hum = obj:FindFirstChildOfClass("Humanoid")
    if hum then
        hum.Died:Connect(function()
            if ESP.AutoRemove ~= false then
                box:Remove()
            end
        end)
    end

    return box
end

local function CharAdded(char)
    local p = plrs:GetPlayerFromCharacter(char)
    if not char:FindFirstChild("HumanoidRootPart") then
        local ev
        ev = char.ChildAdded:Connect(function(c)
            if c.Name == "HumanoidRootPart" then
                ev:Disconnect()
                ESP:Add(char, {
                    Player = p,
                    PrimaryPart = c
                })
            end
        end)
    else
        ESP:Add(char, {
            Player = p,
            PrimaryPart = char.HumanoidRootPart
        })
    end
end

local function PlayerAdded(p)
    p.CharacterAdded:Connect(CharAdded)
    if p.Character then
        coroutine.wrap(CharAdded)(p.Character)
    end
end
plrs.PlayerAdded:Connect(PlayerAdded)
for i, v in pairs(plrs:GetPlayers()) do
    if v ~= plr then
        PlayerAdded(v)
    end
end

game:GetService("RunService").RenderStepped:Connect(function()
    cam = workspace.CurrentCamera
    for i, v in pairs(ESP.Objects) do
        if v.Update then
            local s, e = pcall(v.Update, v)
            if not s then
            end
        end
    end
end)

ESP:Toggle(true)
ESP.Boxes = true

local charBodies

for _, folder in pairs(workspace:GetChildren()) do
    if folder:IsA("Folder") then
        local humanoidFound = false
        for _, model in pairs(folder:GetChildren()) do
            if model:FindFirstChildOfClass("Humanoid") then
                humanoidFound = true
                break
            end
        end
        if humanoidFound then
            charBodies = folder
            break
        end
    end
end

ESP:AddObjectListener(charBodies, {
    Type = "Model",
    Color = Color3.fromRGB(255, 0, 4),
    PrimaryPart = function(obj)
        return obj:FindFirstChild("HumanoidRootPart") or obj:FindFirstChildOfClass("BasePart")
    end, 
    Validator = function(obj)
        task.wait(1)
        return true 
    end, 
    IsEnabled = "player"
}); ESP.player = true
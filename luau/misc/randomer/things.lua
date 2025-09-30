--// Skeleton ESP Script (R6 + R15 toggle) --// Requires Drawing API (exploit environment) --// Toggle between R15/R6 with ']' and toggle ESP on/off with '['

-- Settings local isR15 = true -- starts in R15 mode local toggleRigKey = Enum.KeyCode.RightBracket -- ']' toggles between R15/R6 local toggleESPKey = Enum.KeyCode.LeftBracket -- '[' toggles the ESP on/off local espEnabled = true -- ESP starts enabled

-- Services local Players = game:GetService("Players") local RunService = game:GetService("RunService") local UserInputService = game:GetService("UserInputService") local LocalPlayer = Players.LocalPlayer

-- Tables to store drawings local skeletons = {}

-- Utility: Create line local function newLine() local line = Drawing.new("Line") line.Visible = false line.Color = Color3.fromRGB(0, 255, 0) line.Thickness = 2 line.Transparency = 1 return line end

-- Skeleton connections (R6 / R15) local R6Parts = { {"Head", "Torso"}, {"Torso", "Left Arm"}, {"Torso", "Right Arm"}, {"Torso", "Left Leg"}, {"Torso", "Right Leg"}, }

local R15Parts = { {"Head", "UpperTorso"}, {"UpperTorso", "LowerTorso"}, {"UpperTorso", "LeftUpperArm"}, {"LeftUpperArm", "LeftLowerArm"}, {"LeftLowerArm", "LeftHand"}, {"UpperTorso", "RightUpperArm"}, {"RightUpperArm", "RightLowerArm"}, {"RightLowerArm", "RightHand"}, {"LowerTorso", "LeftUpperLeg"}, {"LeftUpperLeg", "LeftLowerLeg"}, {"LeftLowerLeg", "LeftFoot"}, {"LowerTorso", "RightUpperLeg"}, {"RightUpperLeg", "RightLowerLeg"}, {"RightLowerLeg", "RightFoot"}, }

-- Create skeleton for player local function createSkeleton(plr) if plr == LocalPlayer then return end removeSkeleton(plr) -- ensure no leftover skeletons[plr] = {} local conns = isR15 and R15Parts or R6Parts for _, _ in ipairs(conns) do table.insert(skeletons[plr], newLine()) end end

-- Remove skeleton function removeSkeleton(plr) if skeletons[plr] then for _, line in ipairs(skeletons[plr]) do pcall(function() line:Remove() end) end skeletons[plr] = nil end end

-- Set visibility for all lines immediately (used when toggling ESP) local function setAllVisibility(visible) for plr, lines in pairs(skeletons) do for _, line in ipairs(lines) do line.Visible = visible end end end

-- Toggle rigs and ESP via input UserInputService.InputBegan:Connect(function(input, gameProcessed) if gameProcessed then return end if input.KeyCode == toggleRigKey then isR15 = not isR15 -- rebuild skeletons for new rig type for plr in pairs(skeletons) do removeSkeleton(plr) createSkeleton(plr) end elseif input.KeyCode == toggleESPKey then espEnabled = not espEnabled if not espEnabled then -- hide all lines immediately setAllVisibility(false) end end end)

-- Player added Players.PlayerAdded:Connect(function(plr) plr.CharacterAdded:Connect(function() task.wait(1) -- allow parts to load createSkeleton(plr) end) end)

-- Player removing Players.PlayerRemoving:Connect(function(plr) removeSkeleton(plr) end)

-- Render loop RunService.RenderStepped:Connect(function() if not espEnabled then return end

for plr, lines in pairs(skeletons) do
    local char = plr.Character
    if char and char:FindFirstChild("HumanoidRootPart") then
        local conns = isR15 and R15Parts or R6Parts
        for i, pair in ipairs(conns) do
            local partA = char:FindFirstChild(pair[1])
            local partB = char:FindFirstChild(pair[2])
            if partA and partB then
                local screenA, visA = workspace.CurrentCamera:WorldToViewportPoint(partA.Position)
                local screenB, visB = workspace.CurrentCamera:WorldToViewportPoint(partB.Position)
                if visA and visB then
                    lines[i].From = Vector2.new(screenA.X, screenA.Y)
                    lines[i].To = Vector2.new(screenB.X, screenB.Y)
                    lines[i].Visible = true
                else
                    lines[i].Visible = false
                end
            else
                lines[i].Visible = false
            end
        end
    else
        for _, line in ipairs(lines) do
            line.Visible = false
        end
    end
end

end)

-- Init existing players for _, plr in ipairs(Players:GetPlayers()) do if plr ~= LocalPlayer then if plr.Character then task.spawn(function() task.wait(1) createSkeleton(plr) end) end end end


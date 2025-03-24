local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/xHeptc/Kavo-UI-Library/main/source.lua"))()
local Window = Library.CreateLib("SPACATHUB", "DarkTheme")

local Tab = Window:NewTab("AFTERMATH")
local Section = Tab:NewSection("AIMBOT")
Section:NewToggle("AIMBOT", "ToggleInfo", function(state)
    if state then

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Replicated = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local player = LocalPlayer

local CircleRadius = 200
local Gravity = 50
local BulletSpeed = 2200
local TargetPlayer = nil
local RightMouseButtonHeld = false

local DebugLineEnabled = true
local AimingEnabled = true -- Toggle for aiming

-- Create a new circle drawing
local Circle = Drawing.new("Circle")
Circle.Visible = true
Circle.Color = Color3.fromRGB(255, 0, 0)
Circle.Thickness = 2
Circle.NumSides = 50
Circle.Radius = CircleRadius
Circle.Filled = false
Circle.Transparency = 0.5

-- Create a single line for drawing
local DebugLine = Drawing.new("Line")
DebugLine.Color = Color3.fromRGB(0, 255, 0)
DebugLine.Thickness = 2
DebugLine.Transparency = 0.8
DebugLine.Visible = false

local PlayersList = {}

-- Function to update the bullet speed based on the player's held item
local function getHeldItem(player)
    local target = player:FindFirstChild("CurrentSelectedObject")
    if target and target.Value and target.Value.Value then
        return target.Value.Value.Name
    end
    return nil
end

-- Function to retrieve the BulletSpeed of the weapon
local function getBulletSpeed(player)
    local heldItemName = getHeldItem(player)
    local bulletSpeed = 2250

    if heldItemName then
        local gunData = Replicated:WaitForChild("GunData")
        local weapon = gunData:FindFirstChild(heldItemName)

        if weapon and weapon:FindFirstChild("Stats") and weapon.Stats:FindFirstChild("BulletSettings") then
            local bulletSpeedObj = weapon.Stats.BulletSettings:FindFirstChild("BulletSpeed")
            if bulletSpeedObj then
                bulletSpeed = bulletSpeedObj.Value
            end
        end
    end

    return bulletSpeed
end

local function updateCirclePosition()
    local screenSize = Camera.ViewportSize
    local centerPosition = Vector2.new(screenSize.X / 2, screenSize.Y / 2)
    Circle.Position = centerPosition
end

local function findNearestTargetToMouse()
    local nearestTarget = nil
    local shortestDistance = math.huge

    for _, player in pairs(Players:GetPlayers()) do
        if PlayersList[player.Name] and player ~= LocalPlayer and player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local screenPoint = Camera:WorldToViewportPoint(rootPart.Position)
            local mousePos = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local targetPos = Vector2.new(screenPoint.X, screenPoint.Y)
            local distance = (targetPos - mousePos).Magnitude

            if distance < CircleRadius and distance < shortestDistance then
                shortestDistance = distance
                nearestTarget = player
            end
        end
    end

    return nearestTarget
end

local function predictFuturePosition(targetPosition, targetVelocity, bulletSpeed, Gravity)
    local distance = (targetPosition - Camera.CFrame.Position).Magnitude
    local travelTime = distance / bulletSpeed
    local futurePosition = targetVelocity * travelTime * 1.054
    futurePosition = futurePosition + targetPosition
    local drop = Gravity * travelTime ^ 2 * 1.052
    futurePosition = futurePosition + Vector3.new(0, drop, 0)

    return futurePosition
end

local function aimAtTarget()
    if not TargetPlayer or not TargetPlayer.Character then return end

    local serverColliderHead = TargetPlayer.Character:FindFirstChild("ServerColliderHead")
    
    if serverColliderHead then
        local targetPosition = serverColliderHead.Position
        local targetVelocity = serverColliderHead.Velocity or Vector3.new(0, 0, 0)

        local futurePosition = predictFuturePosition(targetPosition, targetVelocity, BulletSpeed, Gravity)
        local screenPoint = Camera:WorldToViewportPoint(futurePosition)

        local mouseX = Camera.ViewportSize.X / 2
        local mouseY = Camera.ViewportSize.Y / 2

        local deltaX = screenPoint.X - mouseX
        local deltaY = screenPoint.Y - mouseY

        mousemoverel(deltaX, deltaY)
    end
end

local function updateDebugLine()
    if not DebugLineEnabled then
        DebugLine.Visible = false
        return
    end

    local nearestTarget = findNearestTargetToMouse()

    if nearestTarget and nearestTarget.Character then
        local serverColliderHead = nearestTarget.Character:FindFirstChild("ServerColliderHead")
        
        if serverColliderHead then
            local targetPosition = serverColliderHead.Position
            local targetVelocity = serverColliderHead.Velocity or Vector3.new(0, 0, 0)

            local futurePosition = predictFuturePosition(targetPosition, targetVelocity, BulletSpeed, Gravity)
            local screenPoint = Camera:WorldToViewportPoint(futurePosition)

            DebugLine.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            DebugLine.To = Vector2.new(screenPoint.X, screenPoint.Y)
            DebugLine.Visible = true
        else
            DebugLine.Visible = false
        end
    else
        DebugLine.Visible = false
    end
end

UserInputService.InputBegan:Connect(function(input, processed)
    if not processed then
        if input.KeyCode == Enum.KeyCode.F then
            AimingEnabled = not AimingEnabled -- Toggle the aiming
            print(AimingEnabled and "Aiming enabled" or "Aiming disabled")
        elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
            RightMouseButtonHeld = true
        elseif input.KeyCode == Enum.KeyCode.D then
            DebugLineEnabled = not DebugLineEnabled -- Toggle the debug line
        end
    end
end)

UserInputService.InputEnded:Connect(function(input, processed)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then
        RightMouseButtonHeld = false
    end
end)

Players.PlayerAdded:Connect(function(player)
    PlayersList[player.Name] = true
end)

Players.PlayerRemoving:Connect(function(player)
    PlayersList[player.Name] = nil
end)

for _, player in pairs(Players:GetPlayers()) do
    PlayersList[player.Name] = true
end

RunService.RenderStepped:Connect(function()
    updateCirclePosition()

    BulletSpeed = getBulletSpeed(player)

    updateDebugLine()

    if RightMouseButtonHeld and AimingEnabled then
        TargetPlayer = findNearestTargetToMouse()
        aimAtTarget()
    end
end)

while true do
    print(BulletSpeed)
    wait(10)
end
    else
        print("Press F to close")
    end
end)


local Section = Tab:NewSection("ESP")

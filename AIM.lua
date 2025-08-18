-- Services
local Camera = workspace.CurrentCamera
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

-- Configuration 
local Config = {
    Key = Enum.KeyCode.Q,
    Enabled = false, -- Disabled by default for safety
    TeamCheck = true,
    AimPart = "Head",
    Sensitivity = 0.1, -- Smoother default
    
    FOV = {
        Enabled = false, -- Disabled by default
        Sides = 64,
        Color = Color3.fromRGB(255, 255, 255),
        Transparency = 0.7,
        Radius = 80,
        Filled = false,
        Thickness = 1
    }
}

-- State management
local State = {
    Holding = false,
    FOVCircle = nil
}

-- Initialize FOV Circle
local function InitializeFOV()
    if not Config.FOV.Enabled then return end
    
    local circle = Drawing.new("Circle")
    circle.Visible = false
    circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    circle.Radius = Config.FOV.Radius
    circle.Filled = Config.FOV.Filled
    circle.Color = Config.FOV.Color
    circle.Transparency = Config.FOV.Transparency
    circle.NumSides = Config.FOV.Sides
    circle.Thickness = Config.FOV.Thickness
    
    State.FOVCircle = circle
    return circle
end

-- Check if a player is valid for targeting
local function IsValidTarget(player)
    if player == LocalPlayer then return false end
    if not player.Character then return false end
    
    local humanoid = player.Character:FindFirstChild("Humanoid")
    local rootPart = player.Character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return false end
    if humanoid.Health <= 0 then return false end
    
    if Config.TeamCheck and player.Team == LocalPlayer.Team then
        return false
    end
    
    return true
end

-- Find the closest player within FOV
local function GetClosestPlayer()
    if not Config.Enabled then return nil end
    
    local closestPlayer = nil
    local shortestDistance = Config.FOV.Radius
    local mousePos = UserInputService:GetMouseLocation()

    for _, player in ipairs(Players:GetPlayers()) do
        if IsValidTarget(player) then
            local rootPart = player.Character.HumanoidRootPart
            local screenPos, onScreen = Camera:WorldToScreenPoint(rootPart.Position)
            
            if onScreen then
                local distance = (mousePos - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                
                if distance < shortestDistance then
                    shortestDistance = distance
                    closestPlayer = player
                end
            end
        end
    end

    return closestPlayer
end

-- Handle aiming
local function HandleAiming()
    if not State.Holding or not Config.Enabled then return end
    
    local target = GetClosestPlayer()
    if not target or not target.Character then return end
    
    local aimPart = target.Character:FindFirstChild(Config.AimPart)
    if not aimPart then return end
    
    TweenService:Create(
        Camera,
        TweenInfo.new(Config.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
        {CFrame = CFrame.new(Camera.CFrame.Position, aimPart.Position)}
    ):Play()
end

-- Input handlers
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Config.Key then
        State.Holding = true
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Config.Key then
        State.Holding = false
    end
end)

-- Main loop
RunService.RenderStepped:Connect(function()
    -- Update FOV Circle
    if State.FOVCircle and Config.FOV.Enabled then
        State.FOVCircle.Position = UserInputService:GetMouseLocation()
        State.FOVCircle.Visible = Config.Enabled
    end
    
    HandleAiming()
end)

-- Initialize
InitializeFOV()
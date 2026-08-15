-- ==================================================
-- TÂM ẢO QUÂN CHỦ BẠO LỰC + AIMBOT (FIX LỖI MULTI-TOUCH & LOGIC NÚT NỔI)
-- CÓ THÊM TÍNH NĂNG KHOÁ CHẾT MỤC TIÊU (LOCK TARGET)
-- ==================================================
if not game:IsLoaded() then game.Loaded:Wait() end

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Cam = workspace.CurrentCamera

-- 1. HỆ THỐNG TÌM NƠI TRÚ ẨN AN TOÀN (CHỐNG ANTI-CHEAT)
local safeParent = LocalPlayer:WaitForChild("PlayerGui")
pcall(function() safeParent = (gethui and gethui()) or game:GetService("CoreGui") end)

if safeParent:FindFirstChild("TamAoQuanChuBaoLuc") then safeParent.TamAoQuanChuBaoLuc:Destroy() end
if getgenv()._Aimbot_FOV then pcall(function() getgenv()._Aimbot_FOV:Remove() end) end
if getgenv()._Aimbot_FocusCircle then pcall(function() getgenv()._Aimbot_FocusCircle:Remove() end) end
if getgenv()._Aimbot_RenderLoop then getgenv()._Aimbot_RenderLoop:Disconnect(); getgenv()._Aimbot_RenderLoop = nil end

-- ==========================================
-- 2. CẤU HÌNH & BIẾN TOÀN CỤC
-- ==========================================
local offsetX, offsetY = -6.4, 4.1 -- Tọa độ Tâm Ảo

local AimbotSettings = {
    CamAim = false,
    BodyAim = false,      
    MenuBodyAim = false,  
    AimToCrosshair = true,
    ShowAimFloat = true,
    FocusPart = "Head",       
    FovRadius = 200,
    ShowFov = true,
    FovColor = Color3.fromRGB(255, 204, 0),
    Smooth = 2,
    LockTarget = false, -- Biến trạng thái Khoá Mục Tiêu
    TeamCheck = false,
    WallCheck = true,
    DeadCheck = true,
    ShowFocus = true,
}

local lockedTarget = nil

local FOVring = Drawing.new("Circle")
FOVring.Visible = false 
FOVring.Thickness = 1.5
FOVring.Color = AimbotSettings.FovColor
FOVring.Filled = false
getgenv()._Aimbot_FOV = FOVring

local FocusCircle = Drawing.new("Circle")
FocusCircle.Visible = false
FocusCircle.Thickness = 1.5
FocusCircle.Color = AimbotSettings.FovColor
FocusCircle.Filled = true 
FocusCircle.Radius = 4    
getgenv()._Aimbot_FocusCircle = FocusCircle

local function getAimbotCenter()
    if AimbotSettings.AimToCrosshair then
        return Vector2.new((Cam.ViewportSize.X / 2) + offsetX, (Cam.ViewportSize.Y / 2) + offsetY)
    else return Cam.ViewportSize / 2 end
end

-- ==========================================
-- 3. LÕI AIMBOT (KHÔNG ĐÓN HƯỚNG & KHỬ MÉO CAMERA)
-- ==========================================
local function getAimbotTargetPart(character)
    if not character then return nil end
    return character:FindFirstChild(AimbotSettings.FocusPart) or character:FindFirstChild("Head") or character:FindFirstChild("HumanoidRootPart")
end

local function checkAimbotWall(targetPlayer, targetPart)
    if not AimbotSettings.WallCheck then return true end
    if not targetPart then return false end
    local castParams = RaycastParams.new()
    castParams.FilterType = Enum.RaycastFilterType.Exclude
    local ignoreList = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p.Character then table.insert(ignoreList, p.Character) end
    end
    castParams.FilterDescendantsInstances = ignoreList
    castParams.IgnoreWater = true
    
    local ray = workspace:Raycast(Cam.CFrame.Position, targetPart.Position - Cam.CFrame.Position, castParams)
    return ray == nil
end

local function isAimbotTargetValid(targetPlayer)
    if not targetPlayer or not targetPlayer.Parent then return false end
    local char = targetPlayer.Character
    if not char then return false end
    local targetPart = getAimbotTargetPart(char)
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not targetPart or not humanoid then return false end
    if AimbotSettings.DeadCheck and humanoid.Health <= 0 then return false end
    if AimbotSettings.TeamCheck and targetPlayer.Team == LocalPlayer.Team then return false end
    if not checkAimbotWall(targetPlayer, targetPart) then return false end
    return true
end

local function getBestAimbotTarget()
    local bestTarget, minFovDistance = nil, math.huge
    local viewportCenter = getAimbotCenter()
    
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and isAimbotTargetValid(p) then
            local targetPart = getAimbotTargetPart(p.Character)
            if targetPart then
                local screenPos, visible = Cam:WorldToViewportPoint(targetPart.Position)
                if visible and screenPos.Z > 0 then
                    local fovDistance = (Vector2.new(screenPos.X, screenPos.Y) - viewportCenter).Magnitude
                    if fovDistance <= AimbotSettings.FovRadius and fovDistance < minFovDistance then
                        minFovDistance = fovDistance; bestTarget = p
                    end
                end
            end
        end
    end
    return bestTarget
end

local function aim(targetPosition)
    local currentCF = Cam.CFrame
    local targetCF
    
    if AimbotSettings.AimToCrosshair then
        local screenPos, visible = Cam:WorldToViewportPoint(targetPosition)
        if not visible then return end
        
        local crosshairPos = getAimbotCenter()
        local deltaX = screenPos.X - crosshairPos.X
        local deltaY = screenPos.Y - crosshairPos.Y
        
        local fovY = math.rad(Cam.FieldOfView)
        local aspectRatio = Cam.ViewportSize.X / Cam.ViewportSize.Y
        local fovX = 2 * math.atan(math.tan(fovY / 2) * aspectRatio)
        
        local yaw = -(deltaX / Cam.ViewportSize.X) * fovX
        local pitch = -(deltaY / Cam.ViewportSize.Y) * fovY
        
        targetCF = currentCF * CFrame.Angles(pitch, yaw, 0)
    else
        targetCF = CFrame.lookAt(currentCF.Position, targetPosition)
    end
    
    local rx, ry, rz = targetCF:ToEulerAnglesYXZ()
    local unrolledCF = CFrame.new(currentCF.Position) * CFrame.fromEulerAnglesYXZ(rx, ry, 0)
    
    if AimbotSettings.Smooth == 1 then
        Cam.CFrame = unrolledCF
    else
        Cam.CFrame = currentCF:Lerp(unrolledCF, AimbotSettings.Smooth)
    end
end

-- Render Loop Aimbot
getgenv()._Aimbot_RenderLoop = RunService.RenderStepped:Connect(function()
    FOVring.Position = getAimbotCenter()
    FOVring.Radius = AimbotSettings.FovRadius
    FOVring.Visible = (AimbotSettings.CamAim or AimbotSettings.BodyAim) and AimbotSettings.ShowFov

    if AimbotSettings.CamAim or AimbotSettings.BodyAim then
        local holdCurrentTarget = false
        local centerPos = getAimbotCenter()
        
        if lockedTarget and isAimbotTargetValid(lockedTarget) then
            if AimbotSettings.LockTarget then holdCurrentTarget = true else
                local tPart = getAimbotTargetPart(lockedTarget.Character)
                if tPart then
                    local sPos, vis = Cam:WorldToViewportPoint(tPart.Position)
                    if vis and (Vector2.new(sPos.X, sPos.Y) - centerPos).Magnitude <= AimbotSettings.FovRadius then holdCurrentTarget = true end
                end
            end
        end

        if AimbotSettings.LockTarget then
            if not holdCurrentTarget then lockedTarget = getBestAimbotTarget() end
        else
            local potentialTarget = getBestAimbotTarget()
            if holdCurrentTarget and potentialTarget and potentialTarget ~= lockedTarget then
                local oldPart = getAimbotTargetPart(lockedTarget.Character)
                local newPart = getAimbotTargetPart(potentialTarget.Character)
                if oldPart and newPart then
                    local sOld, _ = Cam:WorldToViewportPoint(oldPart.Position)
                    local sNew, _ = Cam:WorldToViewportPoint(newPart.Position)
                    local dOld = (Vector2.new(sOld.X, sOld.Y) - centerPos).Magnitude
                    local dNew = (Vector2.new(sNew.X, sNew.Y) - centerPos).Magnitude
                    if dNew < (dOld - 25) then lockedTarget = potentialTarget end
                end
            elseif not holdCurrentTarget then lockedTarget = potentialTarget end
        end

        if lockedTarget and lockedTarget.Character then
            local targetPart = getAimbotTargetPart(lockedTarget.Character)
            if targetPart then
                if AimbotSettings.CamAim then
                    aim(targetPart.Position)
                    if AimbotSettings.ShowFocus then
                        local screenPos, visible = Cam:WorldToViewportPoint(targetPart.Position)
                        if visible then
                            FocusCircle.Position = Vector2.new(screenPos.X, screenPos.Y)
                            FocusCircle.Visible = true
                        else FocusCircle.Visible = false end
                    else FocusCircle.Visible = false end
                else FocusCircle.Visible = false end
                
                if AimbotSettings.BodyAim and LocalPlayer.Character then
                    local myRoot = LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                    if myRoot then
                        myRoot.CFrame = CFrame.lookAt(myRoot.Position, Vector3.new(targetPart.Position.X, myRoot.Position.Y, targetPart.Position.Z))
                    end
                end
            else FocusCircle.Visible = false end
        else FocusCircle.Visible = false end
    else
        lockedTarget = nil; FocusCircle.Visible = false
    end
end)

-- ==========================================
-- 4. TẠO GIAO DIỆN CHÍNH (NÚT NỔI & TÂM)
-- ==========================================
local Gui = Instance.new("ScreenGui", safeParent)
Gui.Name = "TamAoQuanChuBaoLuc"
Gui.IgnoreGuiInset = true
Gui.ResetOnSpawn = false 

local Crosshair = Instance.new("ImageLabel", Gui)
Crosshair.Name = "Crosshair"
Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
Crosshair.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
Crosshair.Size = UDim2.new(0, 15, 0, 15) 
Crosshair.BackgroundTransparency = 1
Crosshair.Image = "rbxassetid://119703340047941"
Crosshair.Visible = false
Crosshair.ZIndex = 999

-- Nút Toggle Menu
local ToggleBtn = Instance.new("TextButton", Gui)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50); ToggleBtn.Position = UDim2.new(0, 10, 0.5, -25)
ToggleBtn.Text = "TÂM"; ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 204, 0); ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14; ToggleBtn.Active = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleBtn).Color = Color3.fromRGB(255, 204, 0)

-- Nút Bật/Tắt Aim Nổi (Floating)
local MenuCamAimBtn = nil 
local ToggleAimFloatBtn = Instance.new("TextButton", Gui)
ToggleAimFloatBtn.Size = UDim2.new(0, 50, 0, 50); ToggleAimFloatBtn.Position = UDim2.new(0, 70, 0.5, -25)
ToggleAimFloatBtn.Text = "AIM\nOFF"; ToggleAimFloatBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleAimFloatBtn.TextColor3 = Color3.fromRGB(255, 255, 255); ToggleAimFloatBtn.Font = Enum.Font.GothamBold
ToggleAimFloatBtn.TextSize = 12; ToggleAimFloatBtn.Active = true; ToggleAimFloatBtn.Visible = false
Instance.new("UICorner", ToggleAimFloatBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleAimFloatBtn).Color = Color3.fromRGB(255, 204, 0)

-- Cập nhật giao diện khi bật công tắc Master
local function UpdateCamAimUI()
    if AimbotSettings.CamAim then
        ToggleAimFloatBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40); ToggleAimFloatBtn.Text = "AIM\nON"
        if MenuCamAimBtn then MenuCamAimBtn.Text = "🎯 Cam Aim: ON"; MenuCamAimBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 40) end
        
        if AimbotSettings.MenuBodyAim then
            AimbotSettings.BodyAim = true
        else
            AimbotSettings.BodyAim = false
        end
    else
        ToggleAimFloatBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); ToggleAimFloatBtn.Text = "AIM\nOFF"
        if MenuCamAimBtn then MenuCamAimBtn.Text = "🎯 Cam Aim: OFF"; MenuCamAimBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30) end
        AimbotSettings.BodyAim = false
    end
end

local Main = Instance.new("Frame", Gui)
-- Đã tăng chiều cao từ 360 lên 400 để chứa đủ nút Lock Target
Main.Size = UDim2.new(0, 240, 0, 400); Main.Position = UDim2.new(0.5, -120, 0.5, -200)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15); Main.Visible = false; Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main); MainStroke.Color = Color3.fromRGB(255, 204, 0); MainStroke.Thickness = 2

local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 32); Title.Text = "Tâm Ảo Quân Chủ Bạo Lực"
Title.TextColor3 = Color3.fromRGB(255, 204, 0); Title.Font = Enum.Font.GothamBold; Title.TextSize = 11
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25); Title.Active = true
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)
local TitleFix = Instance.new("Frame", Title); TitleFix.Size = UDim2.new(1, 0, 0, 5); TitleFix.Position = UDim2.new(0, 0, 1, -5)
TitleFix.BackgroundColor3 = Color3.fromRGB(25, 25, 25); TitleFix.BorderSizePixel = 0

local TabBar = Instance.new("Frame", Main)
TabBar.Size = UDim2.new(1, 0, 0, 30); TabBar.Position = UDim2.new(0, 0, 0, 32)
TabBar.BackgroundColor3 = Color3.fromRGB(20, 20, 20); TabBar.BorderSizePixel = 0

local BtnTabCrosshair = Instance.new("TextButton", TabBar)
BtnTabCrosshair.Size = UDim2.new(0.5, 0, 1, 0); BtnTabCrosshair.Position = UDim2.new(0, 0, 0, 0)
BtnTabCrosshair.Text = "🎯 TÂM ẢO"; BtnTabCrosshair.Font = Enum.Font.GothamBold; BtnTabCrosshair.TextSize = 11
BtnTabCrosshair.BackgroundColor3 = Color3.fromRGB(255, 204, 0); BtnTabCrosshair.TextColor3 = Color3.fromRGB(0, 0, 0)
BtnTabCrosshair.BorderSizePixel = 0

local BtnTabAimbot = Instance.new("TextButton", TabBar)
BtnTabAimbot.Size = UDim2.new(0.5, 0, 1, 0); BtnTabAimbot.Position = UDim2.new(0.5, 0, 0, 0)
BtnTabAimbot.Text = "⚡ AIMBOT"; BtnTabAimbot.Font = Enum.Font.GothamBold; BtnTabAimbot.TextSize = 11
BtnTabAimbot.BackgroundColor3 = Color3.fromRGB(30, 30, 30); BtnTabAimbot.TextColor3 = Color3.fromRGB(255, 255, 255)
BtnTabAimbot.BorderSizePixel = 0

local CrosshairContainer = Instance.new("Frame", Main)
CrosshairContainer.Size = UDim2.new(1, 0, 1, -62); CrosshairContainer.Position = UDim2.new(0, 0, 0, 62)
CrosshairContainer.BackgroundTransparency = 1; CrosshairContainer.Visible = true

local AimbotContainer = Instance.new("Frame", Main)
AimbotContainer.Size = UDim2.new(1, 0, 1, -62); AimbotContainer.Position = UDim2.new(0, 0, 0, 62)
AimbotContainer.BackgroundTransparency = 1; AimbotContainer.Visible = false

BtnTabCrosshair.Activated:Connect(function()
    CrosshairContainer.Visible = true; AimbotContainer.Visible = false
    BtnTabCrosshair.BackgroundColor3 = Color3.fromRGB(255, 204, 0); BtnTabCrosshair.TextColor3 = Color3.fromRGB(0, 0, 0)
    BtnTabAimbot.BackgroundColor3 = Color3.fromRGB(30, 30, 30); BtnTabAimbot.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

BtnTabAimbot.Activated:Connect(function()
    CrosshairContainer.Visible = false; AimbotContainer.Visible = true
    BtnTabAimbot.BackgroundColor3 = Color3.fromRGB(255, 204, 0); BtnTabAimbot.TextColor3 = Color3.fromRGB(0, 0, 0)
    BtnTabCrosshair.BackgroundColor3 = Color3.fromRGB(30, 30, 30); BtnTabCrosshair.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

-- ==========================================
-- 6. NỘI DUNG TAB 1: TÂM ẢO
-- ==========================================
local InputID = Instance.new("TextBox", CrosshairContainer)
InputID.Size = UDim2.new(0.85, 0, 0, 30); InputID.Position = UDim2.new(0.075, 0, 0, 10)
InputID.PlaceholderText = "Nhập ID Tâm..."; InputID.Text = ""
InputID.BackgroundColor3 = Color3.fromRGB(30, 30, 30); InputID.TextColor3 = Color3.new(1, 1, 1)
Instance.new("UICorner", InputID).CornerRadius = UDim.new(0, 6)

local ApplyBtn = Instance.new("TextButton", CrosshairContainer)
ApplyBtn.Size = UDim2.new(0.85, 0, 0, 30); ApplyBtn.Position = UDim2.new(0.075, 0, 0, 45)
ApplyBtn.Text = "Đổi ID Tâm"; ApplyBtn.BackgroundColor3 = Color3.fromRGB(255, 204, 0)
ApplyBtn.TextColor3 = Color3.fromRGB(0, 0, 0); ApplyBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 6)

local SizeHeader = Instance.new("TextLabel", CrosshairContainer)
SizeHeader.Size = UDim2.new(0.5, 0, 0, 22); SizeHeader.Position = UDim2.new(0.075, 0, 0, 83)
SizeHeader.Text = "Kích cỡ:"; SizeHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
SizeHeader.Font = Enum.Font.GothamSemibold; SizeHeader.TextXAlignment = Enum.TextXAlignment.Left
SizeHeader.BackgroundTransparency = 1

local SizeInput = Instance.new("TextBox", CrosshairContainer)
SizeInput.Size = UDim2.new(0.35, 0, 0, 22); SizeInput.Position = UDim2.new(0.575, 0, 0, 83)
SizeInput.Text = "15"; SizeInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SizeInput.TextColor3 = Color3.fromRGB(255, 204, 0); SizeInput.Font = Enum.Font.GothamBold
Instance.new("UICorner", SizeInput).CornerRadius = UDim.new(0, 4)

local SliderTrack = Instance.new("Frame", CrosshairContainer)
SliderTrack.Size = UDim2.new(0.85, 0, 0, 8); SliderTrack.Position = UDim2.new(0.075, 0, 0, 113)
SliderTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(1, 0)

local Knob = Instance.new("Frame", SliderTrack)
Knob.Size = UDim2.new(0, 18, 0, 18); Knob.Position = UDim2.new(0.036, -9, 0.5, -9) 
Knob.BackgroundColor3 = Color3.fromRGB(255, 204, 0)
Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

local function CreateAxisEditor(axisName, yPos)
    local Label = Instance.new("TextLabel", CrosshairContainer)
    Label.Size = UDim2.new(0, 20, 0, 28); Label.Position = UDim2.new(0.075, 0, 0, yPos)
    Label.Text = axisName .. ":"; Label.TextColor3 = Color3.fromRGB(255, 204, 0)
    Label.Font = Enum.Font.GothamBold; Label.BackgroundTransparency = 1

    local BtnMinus = Instance.new("TextButton", CrosshairContainer)
    BtnMinus.Size = UDim2.new(0, 30, 0, 28); BtnMinus.Position = UDim2.new(0.075, 25, 0, yPos)
    BtnMinus.Text = "-"; BtnMinus.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnMinus.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", BtnMinus).CornerRadius = UDim.new(0, 5)

    local InputBox = Instance.new("TextBox", CrosshairContainer)
    InputBox.Size = UDim2.new(0, 80, 0, 28); InputBox.Position = UDim2.new(0.075, 60, 0, yPos)
    InputBox.Text = "0"; InputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20); InputBox.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 5)

    local BtnPlus = Instance.new("TextButton", CrosshairContainer)
    BtnPlus.Size = UDim2.new(0, 30, 0, 28); BtnPlus.Position = UDim2.new(0.075, 145, 0, yPos)
    BtnPlus.Text = "+"; BtnPlus.BackgroundColor3 = Color3.fromRGB(40, 40, 40); BtnPlus.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", BtnPlus).CornerRadius = UDim.new(0, 5)

    return BtnMinus, BtnPlus, InputBox
end

local xMinus, xPlus, xInput = CreateAxisEditor("X", 133)
local yMinus, yPlus, yInput = CreateAxisEditor("Y", 168)

local ToggleCross = Instance.new("TextButton", CrosshairContainer)
ToggleCross.Size = UDim2.new(0.85, 0, 0, 32); ToggleCross.Position = UDim2.new(0.075, 0, 0, 208)
ToggleCross.Text = "Bật / Tắt Tâm Ảo"; ToggleCross.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleCross.TextColor3 = Color3.new(1, 1, 1); ToggleCross.Font = Enum.Font.GothamSemibold
Instance.new("UICorner", ToggleCross).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- 7. NỘI DUNG TAB 2: AIMBOT
-- ==========================================
local function createAimbotBtn(text, yPos, colorOn, colorOff, callback)
    local btn = Instance.new("TextButton", AimbotContainer)
    btn.Size = UDim2.new(0.85, 0, 0, 28); btn.Position = UDim2.new(0.075, 0, 0, yPos)
    btn.Text = text; btn.BackgroundColor3 = colorOff; btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 11
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    btn.Activated:Connect(function() callback(btn) end)
    return btn
end

local ColorON = Color3.fromRGB(40, 140, 40)
local ColorOFF = Color3.fromRGB(30, 30, 30)

MenuCamAimBtn = createAimbotBtn("🎯 Cam Aim: OFF", 10, ColorON, ColorOFF, function(btn)
    AimbotSettings.CamAim = not AimbotSettings.CamAim
    UpdateCamAimUI()
end)

createAimbotBtn("🧍 Body Aim: OFF", 45, ColorON, ColorOFF, function(btn)
    AimbotSettings.MenuBodyAim = not AimbotSettings.MenuBodyAim
    btn.Text = AimbotSettings.MenuBodyAim and "🧍 Body Aim: ON" or "🧍 Body Aim: OFF"
    btn.BackgroundColor3 = AimbotSettings.MenuBodyAim and ColorON or ColorOFF
    
    if AimbotSettings.CamAim and AimbotSettings.MenuBodyAim then
        AimbotSettings.BodyAim = true
    else
        AimbotSettings.BodyAim = false
    end
end)

createAimbotBtn("🎯 Mục tiêu: Đầu (Head)", 80, ColorON, ColorOFF, function(btn)
    if AimbotSettings.FocusPart == "Head" then
        AimbotSettings.FocusPart = "HumanoidRootPart"; btn.Text = "🎯 Mục tiêu: Thân (Body)"
    else
        AimbotSettings.FocusPart = "Head"; btn.Text = "🎯 Mục tiêu: Đầu (Head)"
    end
    btn.TextColor3 = Color3.fromRGB(255, 204, 0)
end).TextColor3 = Color3.fromRGB(255, 204, 0)

createAimbotBtn("⭕ Vòng FOV: HIỆN", 115, ColorON, ColorOFF, function(btn)
    AimbotSettings.ShowFov = not AimbotSettings.ShowFov
    btn.Text = AimbotSettings.ShowFov and "⭕ Vòng FOV: HIỆN" or "⭕ Vòng FOV: ẨN"
end)

local function createFovRadiusEditor(yPos)
    local container = Instance.new("Frame", AimbotContainer)
    container.Size = UDim2.new(0.85, 0, 0, 28)
    container.Position = UDim2.new(0.075, 0, 0, yPos)
    container.BackgroundTransparency = 1

    local Label = Instance.new("TextLabel", container)
    Label.Size = UDim2.new(0, 85, 1, 0)
    Label.Position = UDim2.new(0, 0, 0, 0)
    Label.Text = "📏 Cỡ FOV:"
    Label.TextColor3 = Color3.fromRGB(200, 200, 200)
    Label.Font = Enum.Font.GothamSemibold
    Label.TextSize = 11
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.BackgroundTransparency = 1

    local BtnMinus = Instance.new("TextButton", container)
    BtnMinus.Size = UDim2.new(0, 28, 1, 0)
    BtnMinus.Position = UDim2.new(0, 85, 0, 0)
    BtnMinus.Text = "-"
    BtnMinus.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BtnMinus.TextColor3 = Color3.new(1, 1, 1)
    BtnMinus.Font = Enum.Font.GothamBold
    Instance.new("UICorner", BtnMinus).CornerRadius = UDim.new(0, 5)

    local InputBox = Instance.new("TextBox", container)
    InputBox.Size = UDim2.new(0, 60, 1, 0)
    InputBox.Position = UDim2.new(0, 118, 0, 0)
    InputBox.Text = tostring(AimbotSettings.FovRadius)
    InputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    InputBox.TextColor3 = Color3.fromRGB(255, 204, 0)
    InputBox.Font = Enum.Font.GothamBold
    InputBox.TextSize = 11
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 5)

    local BtnPlus = Instance.new("TextButton", container)
    BtnPlus.Size = UDim2.new(0, 28, 1, 0)
    BtnPlus.Position = UDim2.new(0, 183, 0, 0)
    BtnPlus.Text = "+"
    BtnPlus.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BtnPlus.TextColor3 = Color3.new(1, 1, 1)
    BtnPlus.Font = Enum.Font.GothamBold
    Instance.new("UICorner", BtnPlus).CornerRadius = UDim.new(0, 5)

    local function updateFov(val)
        local num = math.clamp(math.round(val), 10, 800)
        AimbotSettings.FovRadius = num
        InputBox.Text = tostring(num)
    end

    BtnMinus.Activated:Connect(function() updateFov(AimbotSettings.FovRadius - 5) end)
    BtnPlus.Activated:Connect(function() updateFov(AimbotSettings.FovRadius + 5) end)
    InputBox.FocusLost:Connect(function()
        local num = tonumber(InputBox.Text)
        if num then updateFov(num) else InputBox.Text = tostring(AimbotSettings.FovRadius) end
    end)
end
createFovRadiusEditor(150)

createAimbotBtn("🧱 Check Tường: ON", 185, ColorON, ColorON, function(btn)
    AimbotSettings.WallCheck = not AimbotSettings.WallCheck
    btn.Text = AimbotSettings.WallCheck and "🧱 Check Tường: ON" or "🧱 Check Tường: OFF"
    btn.BackgroundColor3 = AimbotSettings.WallCheck and ColorON or ColorOFF
end)

createAimbotBtn("➕ Theo Tâm Ảo: OFF", 220, ColorON, ColorOFF, function(btn)
    AimbotSettings.AimToCrosshair = not AimbotSettings.AimToCrosshair
    btn.Text = AimbotSettings.AimToCrosshair and "➕ Theo Tâm Ảo: ON" or "➕ Theo Tâm Ảo: OFF"
    btn.BackgroundColor3 = AimbotSettings.AimToCrosshair and ColorON or ColorOFF
end)

createAimbotBtn("🖲️ Nút Aim Ngoài: OFF", 255, ColorON, ColorOFF, function(btn)
    AimbotSettings.ShowAimFloat = not AimbotSettings.ShowAimFloat
    ToggleAimFloatBtn.Visible = AimbotSettings.ShowAimFloat
    btn.Text = AimbotSettings.ShowAimFloat and "🖲️ Nút Aim Ngoài: ON" or "🖲️ Nút Aim Ngoài: OFF"
    btn.BackgroundColor3 = AimbotSettings.ShowAimFloat and ColorON or ColorOFF
end)

-- NÚT MỚI THÊM: KHOÁ CHẾT MỤC TIÊU (LOCK TARGET)
createAimbotBtn("🔒 Khoá Mục Tiêu: OFF", 290, ColorON, ColorOFF, function(btn)
    AimbotSettings.LockTarget = not AimbotSettings.LockTarget
    btn.Text = AimbotSettings.LockTarget and "🔒 Khoá Mục Tiêu: ON" or "🔒 Khoá Mục Tiêu: OFF"
    btn.BackgroundColor3 = AimbotSettings.LockTarget and ColorON or ColorOFF
end)

-- ==========================================
-- 8. KÉO THẢ VÀ FIX LỖI ĐA ĐIỂM (MULTI-TOUCH)
-- ==========================================
local function MakeDraggable(dragPart, movePart, onClickCallback)
    local isDown = false
    local isMoving = false
    local dragStartPos = nil
    local startUiPos = nil
    local dragThreshold = 5
    local dragInput = nil

    dragPart.InputBegan:Connect(function(input)
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not dragInput then
            dragInput = input
            isDown = true
            isMoving = false
            dragStartPos = input.Position
            startUiPos = movePart.Position
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and isDown then
            local delta = input.Position - dragStartPos
            if delta.Magnitude > dragThreshold then
                isMoving = true
                movePart.Position = UDim2.new(
                    startUiPos.X.Scale, startUiPos.X.Offset + delta.X, 
                    startUiPos.Y.Scale, startUiPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput and isDown then
            isDown = false
            dragInput = nil
            
            if not isMoving and onClickCallback then
                onClickCallback()
            end
            isMoving = false
        end
    end)
end

MakeDraggable(Title, Main, nil)
MakeDraggable(ToggleBtn, ToggleBtn, function() Main.Visible = not Main.Visible end)
MakeDraggable(ToggleAimFloatBtn, ToggleAimFloatBtn, function() 
    AimbotSettings.CamAim = not AimbotSettings.CamAim
    UpdateCamAimUI()
end)

local function UpdatePosition()
    Crosshair.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
    xInput.Text = string.format("%g", math.round(offsetX * 10) / 10)
    yInput.Text = string.format("%g", math.round(offsetY * 10) / 10)
end
UpdatePosition()

xMinus.Activated:Connect(function() offsetX = offsetX - 0.1; UpdatePosition() end)
xPlus.Activated:Connect(function() offsetX = offsetX + 0.1; UpdatePosition() end)
yMinus.Activated:Connect(function() offsetY = offsetY - 0.1; UpdatePosition() end)
yPlus.Activated:Connect(function() offsetY = offsetY + 0.1; UpdatePosition() end)
xInput.FocusLost:Connect(function() offsetX = tonumber(xInput.Text) or offsetX; UpdatePosition() end)
yInput.FocusLost:Connect(function() offsetY = tonumber(yInput.Text) or offsetY; UpdatePosition() end)

local minSize, maxSize, currentSize = 10, 150, 15
local function UpdateSize(newSize, updateSlider)
    currentSize = math.clamp(math.round(newSize), minSize, maxSize)
    Crosshair.Size = UDim2.new(0, currentSize, 0, currentSize)
    SizeInput.Text = tostring(currentSize)
    if updateSlider then Knob.Position = UDim2.new((currentSize - minSize)/(maxSize - minSize), -9, 0.5, -9) end
end

local sliderInput = nil
SliderTrack.InputBegan:Connect(function(input)
    if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not sliderInput then 
        sliderInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == sliderInput then
        local percent = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        Knob.Position = UDim2.new(percent, -9, 0.5, -9)
        UpdateSize(minSize + (percent * (maxSize - minSize)), false)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input == sliderInput then 
        sliderInput = nil
    end
end)

SizeInput.FocusLost:Connect(function() UpdateSize(tonumber(SizeInput.Text) or currentSize, true) end)
ApplyBtn.Activated:Connect(function() if InputID.Text ~= "" then Crosshair.Image = "rbxassetid://" .. InputID.Text end end)
ToggleCross.Activated:Connect(function() Crosshair.Visible = not Crosshair.Visible end)

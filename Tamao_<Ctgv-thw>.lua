-- ==================================================
-- BATMAN MINIMALIST HUB V10 - FIX LỖI RESET CÀI ĐẶT
-- ==================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local PlayerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

-- FIX: Nếu GUI đã tồn tại, dừng script ngay để không xóa cài đặt cũ
if PlayerGui:FindFirstChild("BatmanHub") then 
    return 
end

local Gui = Instance.new("ScreenGui", PlayerGui)
Gui.Name = "BatmanHub"
Gui.IgnoreGuiInset = true
Gui.ResetOnSpawn = false -- Giữ GUI tồn tại khi chết

-- ==========================================
-- 1. TÂM ẢO (KÍCH CỠ MẶC ĐỊNH 20)
-- ==========================================
local Crosshair = Instance.new("ImageLabel", Gui)
Crosshair.Name = "Crosshair"
Crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
local offsetX, offsetY = 0, 0
Crosshair.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
Crosshair.Size = UDim2.new(0, 20, 0, 20) 
Crosshair.BackgroundTransparency = 1
Crosshair.Image = "rbxassetid://119703340047941"
Crosshair.Visible = false
Crosshair.ZIndex = 999

-- ==========================================
-- 2. NÚT BAT (TÍCH HỢP KÉO THẢ THÔNG MINH)
-- ==========================================
local ToggleBtn = Instance.new("TextButton", Gui)
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 10, 0.5, -25)
ToggleBtn.Text = "BAT"
ToggleBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ToggleBtn.TextColor3 = Color3.fromRGB(255, 204, 0)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 14
ToggleBtn.Active = true
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleBtn).Color = Color3.fromRGB(255, 204, 0)

-- ==========================================
-- 3. GIAO DIỆN MENU CHÍNH
-- ==========================================
local Main = Instance.new("Frame", Gui)
Main.Size = UDim2.new(0, 230, 0, 360) 
Main.Position = UDim2.new(0.5, -115, 0.5, -180)
Main.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
Main.Visible = false
Main.Active = true
Instance.new("UICorner", Main).CornerRadius = UDim.new(0, 10)
local MainStroke = Instance.new("UIStroke", Main)
MainStroke.Color = Color3.fromRGB(255, 204, 0)
MainStroke.Thickness = 2

-- Tiêu đề (DÙNG ĐỂ KÉO MENU)
local Title = Instance.new("TextLabel", Main)
Title.Size = UDim2.new(1, 0, 0, 35)
Title.Text = "BATMAN HUB (Kéo ở đây)"
Title.TextColor3 = Color3.fromRGB(255, 204, 0)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 13
Title.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Title.Active = true
Instance.new("UICorner", Title).CornerRadius = UDim.new(0, 10)

local TitleFix = Instance.new("Frame", Title)
TitleFix.Size = UDim2.new(1, 0, 0, 5)
TitleFix.Position = UDim2.new(0, 0, 1, -5)
TitleFix.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
TitleFix.BorderSizePixel = 0

-- ID & KÍCH CỠ
local InputID = Instance.new("TextBox", Main)
InputID.Size = UDim2.new(0.85, 0, 0, 32)
InputID.Position = UDim2.new(0.075, 0, 0, 45)
InputID.PlaceholderText = "Nhập ID Tâm..."
InputID.Text = ""
InputID.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
InputID.TextColor3 = Color3.new(1, 1, 1)
InputID.Font = Enum.Font.Gotham
Instance.new("UICorner", InputID).CornerRadius = UDim.new(0, 6)

local ApplyBtn = Instance.new("TextButton", Main)
ApplyBtn.Size = UDim2.new(0.85, 0, 0, 32)
ApplyBtn.Position = UDim2.new(0.075, 0, 0, 85)
ApplyBtn.Text = "Đổi ID Tâm"
ApplyBtn.BackgroundColor3 = Color3.fromRGB(255, 204, 0)
ApplyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
ApplyBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", ApplyBtn).CornerRadius = UDim.new(0, 6)

local SizeHeader = Instance.new("TextLabel", Main)
SizeHeader.Size = UDim2.new(0.5, 0, 0, 25)
SizeHeader.Position = UDim2.new(0.075, 0, 0, 125)
SizeHeader.Text = "Kích cỡ:"
SizeHeader.TextColor3 = Color3.fromRGB(200, 200, 200)
SizeHeader.Font = Enum.Font.GothamSemibold
SizeHeader.TextXAlignment = Enum.TextXAlignment.Left
SizeHeader.BackgroundTransparency = 1

local SizeInput = Instance.new("TextBox", Main)
SizeInput.Size = UDim2.new(0.35, 0, 0, 25)
SizeInput.Position = UDim2.new(0.575, 0, 0, 125)
SizeInput.Text = "20"
SizeInput.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
SizeInput.TextColor3 = Color3.fromRGB(255, 204, 0)
SizeInput.Font = Enum.Font.GothamBold
Instance.new("UICorner", SizeInput).CornerRadius = UDim.new(0, 4)

local SliderTrack = Instance.new("Frame", Main)
SliderTrack.Size = UDim2.new(0.85, 0, 0, 8)
SliderTrack.Position = UDim2.new(0.075, 0, 0, 160)
SliderTrack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
Instance.new("UICorner", SliderTrack).CornerRadius = UDim.new(1, 0)

local Knob = Instance.new("Frame", SliderTrack)
Knob.Size = UDim2.new(0, 18, 0, 18)
Knob.Position = UDim2.new(0.071, -9, 0.5, -9) 
Knob.BackgroundColor3 = Color3.fromRGB(255, 204, 0)
Instance.new("UICorner", Knob).CornerRadius = UDim.new(1, 0)

-- ==========================================
-- 4. KHU VỰC TỌA ĐỘ (X / Y) CHỈNH 0.1
-- ==========================================
local function CreateAxisEditor(axisName, yPos)
    local Label = Instance.new("TextLabel", Main)
    Label.Size = UDim2.new(0, 20, 0, 30)
    Label.Position = UDim2.new(0.075, 0, 0, yPos)
    Label.Text = axisName .. ":"
    Label.TextColor3 = Color3.fromRGB(255, 204, 0)
    Label.Font = Enum.Font.GothamBold
    Label.BackgroundTransparency = 1

    local BtnMinus = Instance.new("TextButton", Main)
    BtnMinus.Size = UDim2.new(0, 30, 0, 30)
    BtnMinus.Position = UDim2.new(0.075, 25, 0, yPos)
    BtnMinus.Text = "-"
    BtnMinus.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BtnMinus.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", BtnMinus).CornerRadius = UDim.new(0, 5)

    local InputBox = Instance.new("TextBox", Main)
    InputBox.Size = UDim2.new(0, 75, 0, 30)
    InputBox.Position = UDim2.new(0.075, 60, 0, yPos)
    InputBox.Text = "0"
    InputBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    InputBox.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", InputBox).CornerRadius = UDim.new(0, 5)

    local BtnPlus = Instance.new("TextButton", Main)
    BtnPlus.Size = UDim2.new(0, 30, 0, 30)
    BtnPlus.Position = UDim2.new(0.075, 140, 0, yPos)
    BtnPlus.Text = "+"
    BtnPlus.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
    BtnPlus.TextColor3 = Color3.new(1, 1, 1)
    Instance.new("UICorner", BtnPlus).CornerRadius = UDim.new(0, 5)

    return BtnMinus, BtnPlus, InputBox
end

local xMinus, xPlus, xInput = CreateAxisEditor("X", 185)
local yMinus, yPlus, yInput = CreateAxisEditor("Y", 225)

local ToggleCross = Instance.new("TextButton", Main)
ToggleCross.Size = UDim2.new(0.85, 0, 0, 35)
ToggleCross.Position = UDim2.new(0.075, 0, 0, 275)
ToggleCross.Text = "Bật / Tắt Tâm"
ToggleCross.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleCross.TextColor3 = Color3.new(1, 1, 1)
ToggleCross.Font = Enum.Font.GothamSemibold
Instance.new("UICorner", ToggleCross).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- HỆ THỐNG DRAG (CHỐNG LOẠN CẢM ỨNG)
-- ==========================================
local function MakeDraggable(dragPart, movePart, isToggleBtn)
    local dragging, dragStart, startPos
    
    dragPart.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = movePart.Position
        end
    end)
    
    dragPart.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            if dragging then
                dragging = false
                if isToggleBtn then
                    local dist = (input.Position - dragStart).Magnitude
                    if dist < 5 then Main.Visible = not Main.Visible end
                end
            end
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            movePart.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

MakeDraggable(Title, Main, false)
MakeDraggable(ToggleBtn, ToggleBtn, true)

-- ==========================================
-- LOGIC KÍCH CỠ & TỌA ĐỘ
-- ==========================================
local function UpdatePosition()
    Crosshair.Position = UDim2.new(0.5, offsetX, 0.5, offsetY)
    xInput.Text = string.format("%g", math.round(offsetX * 10) / 10)
    yInput.Text = string.format("%g", math.round(offsetY * 10) / 10)
end

xMinus.Activated:Connect(function() offsetX = offsetX - 0.1; UpdatePosition() end)
xPlus.Activated:Connect(function() offsetX = offsetX + 0.1; UpdatePosition() end)
yMinus.Activated:Connect(function() offsetY = offsetY - 0.1; UpdatePosition() end)
yPlus.Activated:Connect(function() offsetY = offsetY + 0.1; UpdatePosition() end)

xInput.FocusLost:Connect(function()
    offsetX = tonumber(xInput.Text) or offsetX; UpdatePosition()
end)
yInput.FocusLost:Connect(function()
    offsetY = tonumber(yInput.Text) or offsetY; UpdatePosition()
end)

local minSize, maxSize, currentSize = 10, 150, 20
local function UpdateSize(newSize, updateSlider)
    currentSize = math.clamp(math.round(newSize), minSize, maxSize)
    Crosshair.Size = UDim2.new(0, currentSize, 0, currentSize)
    SizeInput.Text = tostring(currentSize)
    if updateSlider then
        Knob.Position = UDim2.new((currentSize - minSize)/(maxSize - minSize), -9, 0.5, -9)
    end
end

local isSliderDragging = false
SliderTrack.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isSliderDragging = true
    end
end)
UserInputService.InputChanged:Connect(function(input)
    if isSliderDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local percent = math.clamp((input.Position.X - SliderTrack.AbsolutePosition.X) / SliderTrack.AbsoluteSize.X, 0, 1)
        Knob.Position = UDim2.new(percent, -9, 0.5, -9)
        UpdateSize(minSize + (percent * (maxSize - minSize)), false)
    end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isSliderDragging = false
    end
end)

SizeInput.FocusLost:Connect(function() UpdateSize(tonumber(SizeInput.Text) or currentSize, true) end)

ApplyBtn.Activated:Connect(function()
    if InputID.Text ~= "" then Crosshair.Image = "rbxassetid://" .. InputID.Text end
end)
ToggleCross.Activated:Connect(function() Crosshair.Visible = not Crosshair.Visible end)

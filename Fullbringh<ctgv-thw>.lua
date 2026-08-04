-- ==========================================
-- MENU FULLBRIGHT TRONG ROBLOX ESC MENU
-- ==========================================

-- Dọn dẹp script cũ nếu đã chạy trước đó
if getgenv().FullBrightCleanup then
    pcall(getgenv().FullBrightCleanup)
end

local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")
local CoreGui = (gethui and pcall(gethui)) and gethui() or game:GetService("CoreGui")

local connections = {}
local isSettingLighting = false 

-- Khởi tạo biến toàn cục cho Độ Sáng
if getgenv().FullBrightEnabled == nil then getgenv().FullBrightEnabled = false end
if getgenv().CurrentBrightness == nil then getgenv().CurrentBrightness = 2.0 end -- Mặc định là 2

-- Lưu lại ánh sáng gốc của Map
local DefaultLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient
}

-- Hàm áp dụng FullBright
local function ApplyFullBright()
    if isSettingLighting then return end
    isSettingLighting = true

    Lighting.Brightness = getgenv().CurrentBrightness -- Sử dụng độ sáng tùy chỉnh
    Lighting.ClockTime = 12
    Lighting.FogEnd = 786543
    Lighting.GlobalShadows = false
    Lighting.Ambient = Color3.fromRGB(178, 178, 178)
    Lighting.OutdoorAmbient = Color3.fromRGB(178, 178, 178)

    isSettingLighting = false
end

-- Hàm khôi phục ánh sáng gốc
local function RestoreLighting()
    if isSettingLighting then return end
    isSettingLighting = true

    Lighting.Brightness = DefaultLighting.Brightness
    Lighting.ClockTime = DefaultLighting.ClockTime
    Lighting.FogEnd = DefaultLighting.FogEnd
    Lighting.GlobalShadows = DefaultLighting.GlobalShadows
    Lighting.Ambient = DefaultLighting.Ambient
    Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient

    isSettingLighting = false
end

-- Hàm cập nhật tổng quát
local function UpdateLighting()
    if getgenv().FullBrightEnabled then
        ApplyFullBright()
    else
        RestoreLighting()
    end
end

-- Theo dõi sự thay đổi ánh sáng của Game (Anti-Flicker)
local properties = {"Brightness", "ClockTime", "FogEnd", "GlobalShadows", "Ambient", "OutdoorAmbient"}
for _, prop in ipairs(properties) do
    local conn = Lighting:GetPropertyChangedSignal(prop):Connect(function()
        if isSettingLighting then return end 
        
        if getgenv().FullBrightEnabled then
            ApplyFullBright()
        else
            DefaultLighting[prop] = Lighting[prop]
        end
    end)
    table.insert(connections, conn)
end

-- ==========================================
-- TẠO GIAO DIỆN (UI) TRÊN TOPBAR
-- ==========================================

local UI = Instance.new("ScreenGui")
UI.Name = "FullbrightEscMenu"
UI.IgnoreGuiInset = true -- Hiển thị đè lên khu vực Topbar
UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UI.Parent = CoreGui

-- Khung chính (Vị trí ngay hình chữ nhật xanh bạn vẽ)
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 310, 0, 40)
MainFrame.Position = UDim2.new(0, 280, 0, 10) -- Nằm cạnh các nút của Roblox
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BackgroundTransparency = 0.1
MainFrame.Visible = GuiService.MenuIsOpen -- Tự động ẩn/hiện theo trạng thái Menu hiện tại
MainFrame.Parent = UI

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(80, 80, 80)

-- Sắp xếp Layout ngang
local Layout = Instance.new("UIListLayout")
Layout.FillDirection = Enum.FillDirection.Horizontal
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Center
Layout.Padding = UDim.new(0, 8)
Layout.Parent = MainFrame

-- Nút Bật/Tắt
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 120, 0, 28)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ToggleBtn.Text = getgenv().FullBrightEnabled and "FullBright [BẬT]" or "FullBright [TẮT]"
ToggleBtn.TextColor3 = getgenv().FullBrightEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(220, 220, 220)
ToggleBtn.Font = Enum.Font.GothamBold
ToggleBtn.TextSize = 12
ToggleBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBtn).CornerRadius = UDim.new(0, 6)

-- Nút Trừ (-)
local MinusBtn = Instance.new("TextButton")
MinusBtn.Size = UDim2.new(0, 30, 0, 28)
MinusBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MinusBtn.Text = "-"
MinusBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.TextSize = 16
MinusBtn.Parent = MainFrame
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 6)

-- TextBox Nhập/Hiển thị số
local BrightnessBox = Instance.new("TextBox")
BrightnessBox.Size = UDim2.new(0, 60, 0, 28)
BrightnessBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
BrightnessBox.Text = string.format("%.1f", getgenv().CurrentBrightness)
BrightnessBox.TextColor3 = Color3.fromRGB(255, 255, 255)
BrightnessBox.Font = Enum.Font.GothamBold
BrightnessBox.TextSize = 14
BrightnessBox.ClearTextOnFocus = false
BrightnessBox.Parent = MainFrame
Instance.new("UICorner", BrightnessBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", BrightnessBox).Color = Color3.fromRGB(100, 100, 100)

-- Nút Cộng (+)
local PlusBtn = Instance.new("TextButton")
PlusBtn.Size = UDim2.new(0, 30, 0, 28)
PlusBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PlusBtn.Text = "+"
PlusBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.TextSize = 16
PlusBtn.Parent = MainFrame
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 6)

-- ==========================================
-- KẾT NỐI CHỨC NĂNG (LOGIC)
-- ==========================================

-- Hàm xử lý đổi độ sáng
local function SetBrightnessValue(val)
    local newVal = math.clamp(val, 0, 50) -- Giới hạn từ 0 đến 50 tránh chói lóa
    getgenv().CurrentBrightness = newVal
    BrightnessBox.Text = string.format("%.1f", newVal)
    
    if getgenv().FullBrightEnabled then
        ApplyFullBright()
    end
end

-- Bật/Tắt Fullbright
ToggleBtn.MouseButton1Click:Connect(function()
    getgenv().FullBrightEnabled = not getgenv().FullBrightEnabled
    UpdateLighting()
    
    ToggleBtn.Text = getgenv().FullBrightEnabled and "FullBright [BẬT]" or "FullBright [TẮT]"
    ToggleBtn.TextColor3 = getgenv().FullBrightEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(220, 220, 220)
end)

-- Bấm Trừ
MinusBtn.MouseButton1Click:Connect(function()
    SetBrightnessValue(getgenv().CurrentBrightness - 0.5)
end)

-- Bấm Cộng
PlusBtn.MouseButton1Click:Connect(function()
    SetBrightnessValue(getgenv().CurrentBrightness + 0.5)
end)

-- Nhập TextBox thủ công
BrightnessBox.FocusLost:Connect(function()
    local num = tonumber(BrightnessBox.Text)
    if num then
        SetBrightnessValue(num)
    else
        BrightnessBox.Text = string.format("%.1f", getgenv().CurrentBrightness)
    end
end)

-- LOGIC ẨN/HIỆN THEO MENU ROBLOX CHÍNH (THAY THẾ CLICK LOGO)
local menuOpenConn = GuiService.MenuOpened:Connect(function()
    MainFrame.Visible = true
end)
local menuClosedConn = GuiService.MenuClosed:Connect(function()
    MainFrame.Visible = false
end)
table.insert(connections, menuOpenConn)
table.insert(connections, menuClosedConn)

-- ==========================================
-- HOÀN TẤT VÀ DỌN DẸP
-- ==========================================

getgenv().FullBrightCleanup = function()
    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    connections = {}
    if UI then UI:Destroy() end
    RestoreLighting()
end

-- Khởi động lần đầu
UpdateLighting()

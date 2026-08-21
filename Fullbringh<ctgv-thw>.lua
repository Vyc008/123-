-- ==========================================
-- MENU SOFT FULLBRIGHT & NO FOG (DỊU MẮT, GIỮ MÀU GỐC)
-- ==========================================

if getgenv().FullBrightCleanup then
    pcall(getgenv().FullBrightCleanup)
end

local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local connections = {}

-- Khởi tạo biến (Set độ sáng mặc định thấp xuống)
if getgenv().FullBrightEnabled == nil then getgenv().FullBrightEnabled = true end
if getgenv().CurrentBrightness == nil then getgenv().CurrentBrightness = 0 end -- 1.5 là đủ nhìn

local DefaultLighting = {
    Brightness = Lighting.Brightness,
    ClockTime = Lighting.ClockTime,
    FogStart = Lighting.FogStart,
    FogEnd = Lighting.FogEnd,
    GlobalShadows = Lighting.GlobalShadows,
    Ambient = Lighting.Ambient,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ExposureCompensation = Lighting.ExposureCompensation
}

local OriginalAtmospheres = {}
local CachedEffects = {}

local function CacheAtmosphereData()
    OriginalAtmospheres = {}
    CachedEffects = {}
    
    local function ScanForEffects(parentObj)
        for _, v in ipairs(parentObj:GetDescendants()) do
            if v:IsA("Atmosphere") or v:IsA("DepthOfFieldEffect") or v:IsA("BlurEffect") then
                table.insert(CachedEffects, v)
                
                if v:IsA("Atmosphere") then
                    OriginalAtmospheres[v] = {Density = v.Density, Haze = v.Haze, Glare = v.Glare}
                else
                    OriginalAtmospheres[v] = {Enabled = v.Enabled}
                end
            end
        end
    end
    
    ScanForEffects(Lighting)
    ScanForEffects(Workspace)
end
CacheAtmosphereData()

local function RestoreLighting()
    Lighting.Brightness = DefaultLighting.Brightness
    Lighting.ClockTime = DefaultLighting.ClockTime
    Lighting.GlobalShadows = DefaultLighting.GlobalShadows
    Lighting.Ambient = DefaultLighting.Ambient
    Lighting.OutdoorAmbient = DefaultLighting.OutdoorAmbient
    Lighting.ExposureCompensation = DefaultLighting.ExposureCompensation
end

local function RestoreFog()
    Lighting.FogStart = DefaultLighting.FogStart
    Lighting.FogEnd = DefaultLighting.FogEnd
    
    for v, data in pairs(OriginalAtmospheres) do
        if v and v.Parent then
            pcall(function()
                if v:IsA("Atmosphere") then
                    v.Density = data.Density; v.Haze = data.Haze; v.Glare = data.Glare
                elseif v:IsA("DepthOfFieldEffect") or v:IsA("BlurEffect") then
                    v.Enabled = data.Enabled
                end
            end)
        end
    end
end

local function ClearFogOnce()
    CacheAtmosphereData()
    Lighting.FogStart = 9e9
    Lighting.FogEnd = 9e9
    
    for _, v in ipairs(CachedEffects) do
        if v and v.Parent then
            pcall(function()
                if v:IsA("Atmosphere") then
                    v.Density = 0; v.Haze = 0; v.Glare = 0
                elseif v:IsA("DepthOfFieldEffect") or v:IsA("BlurEffect") then
                    v.Enabled = false
                end
            end)
        end
    end
end

-- ================= CỐT LÕI MỚI: SOFT BRIGHT =================
local renderConn = RunService.RenderStepped:Connect(function()
    if getgenv().FullBrightEnabled then
        Lighting.ClockTime = 12
        Lighting.GlobalShadows = false 
        
        -- Dùng ExposureCompensation để nâng sáng tự nhiên thay vì tẩy trắng môi trường
        Lighting.Brightness = getgenv().CurrentBrightness
        Lighting.ExposureCompensation = 0.8 
        
        -- Dùng xám nhạt thay vì trắng (255,255,255) để dịu mắt
        Lighting.Ambient = Color3.fromRGB(150, 150, 150)
        Lighting.OutdoorAmbient = Color3.fromRGB(120, 120, 120)
    end
end)
table.insert(connections, renderConn)

-- ================= TẠO GIAO DIỆN UI =================
local function GetSafeParent()
    if gethui then
        local success, result = pcall(gethui)
        if success and result then return result end
    end
    local success2, result2 = pcall(function() return game:GetService("CoreGui") end)
    if success2 and result2 then return result2 end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local UI = Instance.new("ScreenGui")
UI.Name = "SoftBrightMenu"
UI.IgnoreGuiInset = true 
UI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
UI.Parent = GetSafeParent()

local ToggleMenuBtn = Instance.new("TextButton")
ToggleMenuBtn.Size = UDim2.new(0, 85, 0, 30)
ToggleMenuBtn.Position = UDim2.new(0.5, -42, 0, 65)
ToggleMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ToggleMenuBtn.Text = "💡 FB Menu"
ToggleMenuBtn.TextColor3 = Color3.fromRGB(255, 220, 100)
ToggleMenuBtn.Font = Enum.Font.GothamBold
ToggleMenuBtn.TextSize = 12
ToggleMenuBtn.Active = true
ToggleMenuBtn.Draggable = true
ToggleMenuBtn.Parent = UI

Instance.new("UICorner", ToggleMenuBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", ToggleMenuBtn).Color = Color3.fromRGB(80, 80, 80)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 395, 0, 40)
MainFrame.Position = UDim2.new(0.5, -197, 0, 20) 
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BackgroundTransparency = 0.1
MainFrame.Visible = true 
MainFrame.Active = true 
MainFrame.Draggable = true 
MainFrame.Parent = UI

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Color3.fromRGB(80, 80, 80)

local Layout = Instance.new("UIListLayout")
Layout.FillDirection = Enum.FillDirection.Horizontal
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Center
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.Padding = UDim.new(0, 6)
Layout.Parent = MainFrame

local ToggleBrightBtn = Instance.new("TextButton")
ToggleBrightBtn.LayoutOrder = 1
ToggleBrightBtn.Size = UDim2.new(0, 110, 0, 28)
ToggleBrightBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
if getgenv().FullBrightEnabled then
    ToggleBrightBtn.Text = "SoftBright [BẬT]"
    ToggleBrightBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
else
    ToggleBrightBtn.Text = "SoftBright [TẮT]"
    ToggleBrightBtn.TextColor3 = Color3.fromRGB(220, 220, 220)
end
ToggleBrightBtn.Font = Enum.Font.GothamBold
ToggleBrightBtn.TextSize = 11
ToggleBrightBtn.Parent = MainFrame
Instance.new("UICorner", ToggleBrightBtn).CornerRadius = UDim.new(0, 6)

local MinusBtn = Instance.new("TextButton")
MinusBtn.LayoutOrder = 2
MinusBtn.Size = UDim2.new(0, 28, 0, 28)
MinusBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
MinusBtn.Text = "-"
MinusBtn.TextColor3 = Color3.fromRGB(255, 100, 100)
MinusBtn.Font = Enum.Font.GothamBold
MinusBtn.TextSize = 15
MinusBtn.Parent = MainFrame
Instance.new("UICorner", MinusBtn).CornerRadius = UDim.new(0, 6)

local BrightnessBox = Instance.new("TextBox")
BrightnessBox.LayoutOrder = 3
BrightnessBox.Size = UDim2.new(0, 48, 0, 28)
BrightnessBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
BrightnessBox.Text = string.format("%.1f", getgenv().CurrentBrightness)
BrightnessBox.TextColor3 = Color3.fromRGB(255, 255, 255)
BrightnessBox.Font = Enum.Font.GothamBold
BrightnessBox.TextSize = 13
BrightnessBox.ClearTextOnFocus = false
BrightnessBox.Parent = MainFrame
Instance.new("UICorner", BrightnessBox).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", BrightnessBox).Color = Color3.fromRGB(100, 100, 100)

local PlusBtn = Instance.new("TextButton")
PlusBtn.LayoutOrder = 4
PlusBtn.Size = UDim2.new(0, 28, 0, 28)
PlusBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
PlusBtn.Text = "+"
PlusBtn.TextColor3 = Color3.fromRGB(100, 255, 100)
PlusBtn.Font = Enum.Font.GothamBold
PlusBtn.TextSize = 15
PlusBtn.Parent = MainFrame
Instance.new("UICorner", PlusBtn).CornerRadius = UDim.new(0, 6)

local ClearFogBtn = Instance.new("TextButton")
ClearFogBtn.LayoutOrder = 5
ClearFogBtn.Size = UDim2.new(0, 100, 0, 28)
ClearFogBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
ClearFogBtn.Text = "Clear Fog"
ClearFogBtn.TextColor3 = Color3.fromRGB(255, 180, 50)
ClearFogBtn.Font = Enum.Font.GothamBold
ClearFogBtn.TextSize = 11
ClearFogBtn.Parent = MainFrame
Instance.new("UICorner", ClearFogBtn).CornerRadius = UDim.new(0, 6)

-- ================= SỰ KIỆN =================
local function SetBrightnessValue(val)
    local newVal = math.clamp(val, 0, 5) -- Giới hạn tối đa là 5 để tránh chói
    getgenv().CurrentBrightness = newVal
    BrightnessBox.Text = string.format("%.1f", newVal)
end

ToggleMenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    ToggleMenuBtn.TextColor3 = MainFrame.Visible and Color3.fromRGB(255, 220, 100) or Color3.fromRGB(150, 150, 150)
end)

ToggleBrightBtn.MouseButton1Click:Connect(function()
    getgenv().FullBrightEnabled = not getgenv().FullBrightEnabled
    if not getgenv().FullBrightEnabled then RestoreLighting() end
    
    ToggleBrightBtn.Text = getgenv().FullBrightEnabled and "SoftBright [BẬT]" or "SoftBright [TẮT]"
    ToggleBrightBtn.TextColor3 = getgenv().FullBrightEnabled and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(220, 220, 220)
end)

ClearFogBtn.MouseButton1Click:Connect(function()
    ClearFogOnce()
    ClearFogBtn.Text = "Đã Xoá Fog!"
    ClearFogBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
    task.delay(1.5, function()
        if ClearFogBtn and ClearFogBtn.Parent then
            ClearFogBtn.Text = "Clear Fog"
            ClearFogBtn.TextColor3 = Color3.fromRGB(255, 180, 50)
        end
    end)
end)

MinusBtn.MouseButton1Click:Connect(function() SetBrightnessValue(getgenv().CurrentBrightness - 0.5) end)
PlusBtn.MouseButton1Click:Connect(function() SetBrightnessValue(getgenv().CurrentBrightness + 0.5) end)

BrightnessBox.FocusLost:Connect(function()
    local num = tonumber(BrightnessBox.Text)
    if num then SetBrightnessValue(num) else BrightnessBox.Text = string.format("%.1f", getgenv().CurrentBrightness) end
end)

getgenv().FullBrightCleanup = function()
    for _, conn in ipairs(connections) do if conn.Connected then conn:Disconnect() end end
    connections = {}
    if UI then UI:Destroy() end
    RestoreLighting()
    RestoreFog()
end

print("✅ Menu SoftBright Loaded!")

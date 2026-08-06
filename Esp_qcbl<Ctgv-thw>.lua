-- ==========================================
-- 0. TỰ ĐỘNG DỌN DẸP SCRIPT CŨ (FIX CHẠY 2 LẦN)
-- ==========================================
if getgenv().GenEsp_Cleanup then
    pcall(getgenv().GenEsp_Cleanup)
end

getgenv().GenEsp_IsRunning = true

local connections = {}
local instancesToDestroy = {}

getgenv().GenEsp_Cleanup = function()
    getgenv().GenEsp_IsRunning = false
    for _, conn in ipairs(connections) do
        if conn and conn.Connected then
            conn:Disconnect()
        end
    end
    for _, inst in ipairs(instancesToDestroy) do
        if inst and inst.Destroy then
            pcall(function() inst:Destroy() end)
        end
    end
    connections = {}
    instancesToDestroy = {}
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = (gethui and pcall(gethui)) and gethui() or game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ==========================================
-- CẤU HÌNH TRẠNG THÁI MẶC ĐỊNH
-- ==========================================
local outlineEnabled = false
local distanceEnabled = false
local fullbrightEnabled = false
local currentTextSize = 10 

-- Cấu hình Movement
getgenv().Walkspeed = 18
getgenv().loopW = false
getgenv().TPSpeed = 0.01
getgenv().TPWalk = false

local defaultLighting = {
    Ambient = Lighting.Ambient,
    ColorShift_Top = Lighting.ColorShift_Top,
    ColorShift_Bottom = Lighting.ColorShift_Bottom,
    OutdoorAmbient = Lighting.OutdoorAmbient,
    ClockTime = Lighting.ClockTime,
    FogColor = Lighting.FogColor,
    FogEnd = Lighting.FogEnd,
    FogStart = Lighting.FogStart
}

-- ==========================================
-- 1. LOGIC QUẢN LÝ TẢI MAP & TÌM GENERATOR
-- ==========================================
local function GetValidGenerators()
    local validBodies = {}
    local addedBodies = {} 
    
    local function AddBodySafe(body)
        if body and body:IsA("BasePart") and not addedBodies[body] then
            table.insert(validBodies, body)
            addedBodies[body] = true
        end
    end

    local map = workspace:FindFirstChild("Map")
    if not map then return validBodies end

    pcall(function()
        local genFolder = map:FindFirstChild("Generator")
        if genFolder then
            local children = genFolder:GetChildren()
            for i = 7, 2, -1 do
                if children[i] then AddBodySafe(children[i]:FindFirstChild("GeneratorBody")) end
            end
            local specificGen = genFolder:FindFirstChild("Generator")
            if specificGen then AddBodySafe(specificGen:FindFirstChild("GeneratorBody")) end
        end
    end)

    local folderNames = {"Gens", "Generators", "newGenerators", "new Generators", "Generator"}
    for _, folderName in ipairs(folderNames) do
        local folder = map:FindFirstChild(folderName)
        if folder then
            for _, genChild in ipairs(folder:GetChildren()) do
                AddBodySafe(genChild:FindFirstChild("GeneratorBody"))
            end
        end
    end
    
    return validBodies
end

-- ==========================================
-- 2. LOGIC ESP (OUTLINE & DISTANCE)
-- ==========================================
local espFolder = nil
local espElements = {}

local function InitESPObjects()
    if espFolder then espFolder:Destroy() end
    espElements = {}
    
    espFolder = Instance.new("Folder")
    espFolder.Name = "GeneratorESP_System"
    espFolder.Parent = CoreGui
    table.insert(instancesToDestroy, espFolder)
    
    local targets = GetValidGenerators()
    
    for _, body in ipairs(targets) do
        local highlight = Instance.new("Highlight")
        highlight.Adornee = body
        highlight.FillTransparency = 0.8
        highlight.FillColor = Color3.fromRGB(255, 50, 50)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Enabled = outlineEnabled
        highlight.Parent = espFolder
        
        local billboard = Instance.new("BillboardGui")
        billboard.Adornee = body
        billboard.Size = UDim2.new(0, 200, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 4, 0)
        billboard.AlwaysOnTop = true
        billboard.Enabled = distanceEnabled
        billboard.Parent = espFolder
        
        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, 0, 1, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.TextScaled = false
        textLabel.TextSize = currentTextSize
        textLabel.Font = Enum.Font.GothamBold
        textLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
        textLabel.TextStrokeTransparency = 0.2
        textLabel.Parent = billboard
        
        table.insert(espElements, {
            Part = body,
            Highlight = highlight,
            Billboard = billboard,
            Label = textLabel
        })
    end
end

local function UpdateESPVisibility()
    local needsReinit = false
    if not espFolder or #espElements == 0 then
        needsReinit = true
    else
        for _, data in ipairs(espElements) do
            if not data.Part or not data.Part.Parent then
                needsReinit = true
                break
            end
        end
    end

    if needsReinit then InitESPObjects() end
    
    for _, data in ipairs(espElements) do
        if data.Highlight then data.Highlight.Enabled = outlineEnabled end
        if data.Billboard then data.Billboard.Enabled = distanceEnabled end
    end
end

local function UpdateTextSize(newSize)
    currentTextSize = newSize
    for _, data in ipairs(espElements) do
        if data.Label then data.Label.TextSize = currentTextSize end
    end
end

local function ClearFogOnce()
    Lighting.FogStart = 9e9
    Lighting.FogEnd = 9e9
    
    for _, v in ipairs(Lighting:GetChildren()) do
        pcall(function()
            if v:IsA("Atmosphere") then
                v:Destroy()
            elseif v:IsA("DepthOfFieldEffect") or v:IsA("BlurEffect") then
                v.Enabled = false
            end
        end)
    end

    for _, v in ipairs(Workspace:GetDescendants()) do
        pcall(function()
            if v:IsA("Atmosphere") then
                v:Destroy()
            elseif v:IsA("DepthOfFieldEffect") or v:IsA("BlurEffect") then
                v.Enabled = false
            end
        end)
    end
end

-- ==========================================
-- CORE LOGIC NGẦM (RENDERSTEPPED & HEARTBEAT)
-- ==========================================
local renderConn = RunService.RenderStepped:Connect(function()
    if fullbrightEnabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 14
    end

    if not distanceEnabled then return end
    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    
    for _, data in ipairs(espElements) do
        if data.Part and data.Part.Parent then
            local distance = (root.Position - data.Part.Position).Magnitude
            data.Label.Text = string.format("Generator\n[%.1f m]", distance)
        else
            data.Label.Text = "" 
        end
    end
end)
table.insert(connections, renderConn)

local moveConn = RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChild("Humanoid")
    
    if char and hum and hum.Parent then
        if getgenv().loopW then 
            local targetWS = tonumber(getgenv().Walkspeed) or 16
            if hum.WalkSpeed ~= targetWS then 
                hum.WalkSpeed = targetWS 
            end 
        end
        
        if getgenv().TPWalk and hum.MoveDirection.Magnitude > 0 then
            local speed = tonumber(getgenv().TPSpeed) or 0.1
            char:TranslateBy(hum.MoveDirection * speed)
        end
    end
end)
table.insert(connections, moveConn)

-- ==========================================
-- 3. GIAO DIỆN MENU (MINIMAL UI VỚI SCROLLINGFRAME)
-- ==========================================
local UI = Instance.new("ScreenGui")
UI.Name = "GenEspHub"
UI.ResetOnSpawn = false
UI.Parent = CoreGui
table.insert(instancesToDestroy, UI)

local Colors = {
    Bg = Color3.fromRGB(25, 25, 25),
    Element = Color3.fromRGB(35, 35, 35),
    ElementActive = Color3.fromRGB(50, 150, 50),
    Accent = Color3.fromRGB(255, 255, 255),
    Text = Color3.fromRGB(220, 220, 220),
    Border = Color3.fromRGB(50, 50, 50)
}

local ToggleMenuBtn = Instance.new("TextButton")
ToggleMenuBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleMenuBtn.Position = UDim2.new(0, 20, 0, 20)
ToggleMenuBtn.BackgroundColor3 = Colors.Bg
ToggleMenuBtn.Text = "HUB"
ToggleMenuBtn.TextColor3 = Colors.Accent
ToggleMenuBtn.Font = Enum.Font.GothamBold
ToggleMenuBtn.TextSize = 13
ToggleMenuBtn.Parent = UI

Instance.new("UICorner", ToggleMenuBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleMenuBtn).Color = Colors.Border

local btnDragging, btnDragInput, btnDragStart, btnStartPos
ToggleMenuBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        btnDragInput = input 
        btnDragStart = input.Position
        btnStartPos = ToggleMenuBtn.Position
    end
end)

local btnDragConn1 = UserInputService.InputChanged:Connect(function(input)
    if input == btnDragInput and btnDragging then
        local delta = input.Position - btnDragStart
        ToggleMenuBtn.Position = UDim2.new(
            btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, 
            btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y
        )
    end
end)

local btnDragConn2 = UserInputService.InputEnded:Connect(function(input)
    if input == btnDragInput then btnDragging = false; btnDragInput = nil end
end)
table.insert(connections, btnDragConn1)
table.insert(connections, btnDragConn2)

-- [Main Frame] Kích thước gọn gàng, không che màn hình
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 270, 0, 310)
MainFrame.Position = UDim2.new(0.5, -135, 0.5, -155)
MainFrame.BackgroundColor3 = Colors.Bg
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Parent = UI

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Colors.Border

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Violence District & Movement"
Title.TextColor3 = Colors.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true
Title.Parent = MainFrame

local TitlePadding = Instance.new("UIPadding")
TitlePadding.PaddingLeft = UDim.new(0, 10)
TitlePadding.Parent = Title

ToggleMenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

local dragging, dragInput, dragStart, startPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragInput = input 
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

local dragConn1 = UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

local dragConn2 = UserInputService.InputEnded:Connect(function(input)
    if input == dragInput then dragging = false; dragInput = nil end
end)
table.insert(connections, dragConn1)
table.insert(connections, dragConn2)

-- ==========================================
-- TẠO SCROLLING FRAME VỚI THANH TRƯỢT NGOÀI
-- ==========================================
local ScrollFrame = Instance.new("ScrollingFrame")
ScrollFrame.Size = UDim2.new(1, -10, 1, -45)
ScrollFrame.Position = UDim2.new(0, 5, 0, 40)
ScrollFrame.BackgroundColor3 = Colors.Bg
ScrollFrame.BackgroundTransparency = 1
ScrollFrame.BorderSizePixel = 0
ScrollFrame.ScrollBarThickness = 5
ScrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, 390) -- Tổng chiều dài nội dung (tự cuộn)
ScrollFrame.Parent = MainFrame

local UIListLayout = Instance.new("UIListLayout")
UIListLayout.Padding = UDim.new(0, 7)
UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
UIListLayout.Parent = ScrollFrame

-- Cập nhật tự động chiều dài của trang khi thêm/bớt nút
UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
    ScrollFrame.CanvasSize = UDim2.new(0, 0, 0, UIListLayout.AbsoluteContentSize.Y + 15)
end)

-- Helper: Tạo Toggle Button thường
local function CreateToggleButton(text, initialState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -15, 0, 35)
    btn.BackgroundColor3 = initialState and Colors.ElementActive or Colors.Element
    btn.Text = text .. (initialState and " [BẬT]" or " [TẮT]")
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.Parent = ScrollFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", btn).Color = Colors.Border
    
    local state = initialState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Colors.ElementActive or Colors.Element
        btn.Text = text .. (state and " [BẬT]" or " [TẮT]")
        pcall(callback, state)
    end)
    return btn
end

-- Helper: Tạo Button Action
local function CreateButton(text, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -15, 0, 35)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = Colors.Accent
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.Parent = ScrollFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", btn).Color = Colors.Border
    
    btn.MouseButton1Click:Connect(function()
        local oldColor = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        task.delay(0.1, function() btn.BackgroundColor3 = oldColor end)
        pcall(callback)
    end)
    return btn
end

-- Helper: Tạo TextBox thường
local function CreateTextBox(labelText, defaultValue, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -15, 0, 35)
    container.BackgroundColor3 = Colors.Element
    container.Parent = ScrollFrame
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", container).Color = Colors.Border

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Colors.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.3, -10, 0.7, 0)
    box.Position = UDim2.new(0.7, 0, 0.15, 0)
    box.BackgroundColor3 = Colors.Bg
    box.Text = tostring(defaultValue)
    box.TextColor3 = Colors.Accent
    box.Font = Enum.Font.GothamBold
    box.TextSize = 13
    box.ClearTextOnFocus = false
    box.Parent = container
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", box).Color = Colors.Border

    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num and num > 0 then
            callback(num)
        else
            box.Text = tostring(defaultValue)
        end
    end)
end

-- Helper: Tạo Combo "6 phần Textbox - 4 phần Button" cho (Speed & TP Walk)
local function CreateSplitControl(labelText, defaultValue, initialToggle, textCallback, toggleCallback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -15, 0, 35)
    container.BackgroundTransparency = 1
    container.Parent = ScrollFrame

    -- Phần 6 (60%): Text Label + Ô nhập liệu
    local leftBox = Instance.new("Frame")
    leftBox.Size = UDim2.new(0.58, 0, 1, 0)
    leftBox.Position = UDim2.new(0, 0, 0, 0)
    leftBox.BackgroundColor3 = Colors.Element
    leftBox.Parent = container
    Instance.new("UICorner", leftBox).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", leftBox).Color = Colors.Border

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText
    label.TextColor3 = Colors.Text
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = leftBox

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.38, -4, 0.7, 0)
    box.Position = UDim2.new(0.6, 0, 0.15, 0)
    box.BackgroundColor3 = Colors.Bg
    box.Text = tostring(defaultValue)
    box.TextColor3 = Colors.Accent
    box.Font = Enum.Font.GothamBold
    box.TextSize = 12
    box.ClearTextOnFocus = false
    box.Parent = leftBox
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", box).Color = Colors.Border

    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num and num > 0 then
            textCallback(num)
        else
            box.Text = tostring(defaultValue)
        end
    end)

    -- Phần 4 (40%): Nút Bật / Tắt (On/Off)
    local state = initialToggle
    local rightBtn = Instance.new("TextButton")
    rightBtn.Size = UDim2.new(0.39, 0, 1, 0)
    rightBtn.Position = UDim2.new(0.61, 0, 0, 0)
    rightBtn.BackgroundColor3 = state and Colors.ElementActive or Colors.Element
    rightBtn.Text = state and "ON" or "OFF"
    rightBtn.TextColor3 = Colors.Text
    rightBtn.Font = Enum.Font.GothamBold
    rightBtn.TextSize = 12
    rightBtn.Parent = container
    Instance.new("UICorner", rightBtn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", rightBtn).Color = Colors.Border

    rightBtn.MouseButton1Click:Connect(function()
        state = not state
        rightBtn.BackgroundColor3 = state and Colors.ElementActive or Colors.Element
        rightBtn.Text = state and "ON" or "OFF"
        pcall(toggleCallback, state)
    end)
end

-- ==========================================
-- 4. KHỞI TẠO CÁC NÚT BẤM VÀO GIAO DIỆN
-- ==========================================
InitESPObjects()

-- Nhóm ESP & Map
CreateToggleButton("Outline ESP", false, function(state)
    outlineEnabled = state
    UpdateESPVisibility()
end)

CreateToggleButton("Show Distance", false, function(state)
    distanceEnabled = state
    UpdateESPVisibility()
end)

CreateToggleButton("Fullbright", false, function(state)
    fullbrightEnabled = state
    if not state then
        Lighting.Ambient = defaultLighting.Ambient
        Lighting.ColorShift_Top = defaultLighting.ColorShift_Top
        Lighting.ColorShift_Bottom = defaultLighting.ColorShift_Bottom
        Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient
        Lighting.ClockTime = defaultLighting.ClockTime
    end
end)

local clearFogBtn
clearFogBtn = CreateButton("Xoá Xương Mù", function()
    ClearFogOnce()
    clearFogBtn.Text = "Đã Xoá Xương Mù!"
    clearFogBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
    task.delay(1.5, function()
        if clearFogBtn and clearFogBtn.Parent then
            clearFogBtn.Text = "Xoá Xương Mù"
            clearFogBtn.TextColor3 = Colors.Accent
        end
    end)
end)

CreateTextBox("Cỡ chữ ESP:", currentTextSize, function(newSize)
    UpdateTextSize(newSize)
end)

CreateButton("🔄 Load Generators Trên Map", function()
    InitESPObjects()
end)

-- Nhóm Movement (Gộp 6/4 - Bên Trái Nhập Thông Số, Bên Phải Bật/Tắt)
CreateSplitControl("Speed:", getgenv().Walkspeed, getgenv().loopW, 
    function(val) -- Xử lý khi nhập textbox
        getgenv().Walkspeed = tonumber(val) or 18
        local char = LocalPlayer.Character
        local hum = char and char:FindFirstChild("Humanoid")
        if hum and not getgenv().loopW then
            hum.WalkSpeed = getgenv().Walkspeed
        end
    end, 
    function(state) -- Xử lý khi ấn nút ON/OFF
        getgenv().loopW = state
    end
)

CreateSplitControl("TP Walk:", getgenv().TPSpeed, getgenv().TPWalk, 
    function(val) -- Xử lý khi nhập textbox
        getgenv().TPSpeed = tonumber(val) or 0.01
    end, 
    function(state) -- Xử lý khi ấn nút ON/OFF
        getgenv().TPWalk = state
    end
)

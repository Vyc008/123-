-- ==========================================
-- 0. TỰ ĐỘNG DỌN DẸP SCRIPT CŨ (FIX CHẠY 2 LẦN)
-- ==========================================
if getgenv().GenEsp_Cleanup then
    pcall(getgenv().GenEsp_Cleanup)
end

-- Biến cờ hiệu để dừng vòng lặp ngầm khi chạy lại script
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
local CoreGui = (gethui and pcall(gethui)) and gethui() or game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- Cấu hình mặc định
local outlineEnabled = false
local distanceEnabled = false
local currentTextSize = 10 -- Cỡ chữ mặc định ban đầu

-- ==========================================
-- 1. LOGIC QUẢN LÝ TẢI MAP & TÌM GENERATOR
-- ==========================================
local function GetValidGenerators()
    local validBodies = {}
    local addedBodies = {} -- Bảng lưu trữ chống trùng lặp ESP
    
    -- Hàm phụ để thêm Generator an toàn
    local function AddBodySafe(body)
        if body and body:IsA("BasePart") and not addedBodies[body] then
            table.insert(validBodies, body)
            addedBodies[body] = true
        end
    end

    local map = workspace:FindFirstChild("Map")
    if not map then 
        return validBodies 
    end

    -- [1] THÊM THỦ CÔNG CÁC GENERATOR THEO ĐÚNG ĐƯỜNG DẪN YÊU CẦU
    pcall(function()
        local genFolder = map:FindFirstChild("Generator")
        if genFolder then
            local children = genFolder:GetChildren()
            
            -- Thêm từ index 7 lùi về 2
            for i = 7, 2, -1 do
                if children[i] then
                    AddBodySafe(children[i]:FindFirstChild("GeneratorBody"))
                end
            end
            
            -- Thêm workspace.Map.Generator.Generator.GeneratorBody
            local specificGen = genFolder:FindFirstChild("Generator")
            if specificGen then
                AddBodySafe(specificGen:FindFirstChild("GeneratorBody"))
            end
        end
    end)

    -- [2] QUÉT TỰ ĐỘNG DỰ PHÒNG (Cho các Generator khác trên Map)
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
    if espFolder then 
        espFolder:Destroy() 
    end
    espElements = {}
    
    espFolder = Instance.new("Folder")
    espFolder.Name = "GeneratorESP_System"
    espFolder.Parent = CoreGui
    table.insert(instancesToDestroy, espFolder)
    
    local targets = GetValidGenerators()
    
    for _, body in ipairs(targets) do
        -- Highlight (Outline)
        local highlight = Instance.new("Highlight")
        highlight.Adornee = body
        highlight.FillTransparency = 0.8
        highlight.FillColor = Color3.fromRGB(255, 50, 50)
        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
        highlight.OutlineTransparency = 0
        highlight.Enabled = outlineEnabled
        highlight.Parent = espFolder
        
        -- BillboardGui (Text Khoảng cách)
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

    if needsReinit then
        InitESPObjects()
    end
    
    for _, data in ipairs(espElements) do
        if data.Highlight then data.Highlight.Enabled = outlineEnabled end
        if data.Billboard then data.Billboard.Enabled = distanceEnabled end
    end
end

-- Cập nhật lại TextSize trực tiếp cho tất cả ESP hiện có
local function UpdateTextSize(newSize)
    currentTextSize = newSize
    for _, data in ipairs(espElements) do
        if data.Label then
            data.Label.TextSize = currentTextSize
        end
    end
end

-- RenderStepped Cập nhật vị trí & khoảng cách (Chỉ chạy khi bật Distance)
local renderConn = RunService.RenderStepped:Connect(function()
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

-- ==========================================
-- 3. GIAO DIỆN MENU (MINIMAL UI)
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

-- [Nút Ẩn/Hiện Menu]
local ToggleMenuBtn = Instance.new("TextButton")
ToggleMenuBtn.Size = UDim2.new(0, 45, 0, 45)
ToggleMenuBtn.Position = UDim2.new(0, 20, 0, 20)
ToggleMenuBtn.BackgroundColor3 = Colors.Bg
ToggleMenuBtn.Text = "ESP"
ToggleMenuBtn.TextColor3 = Colors.Accent
ToggleMenuBtn.Font = Enum.Font.GothamBold
ToggleMenuBtn.TextSize = 14
ToggleMenuBtn.Active = true
ToggleMenuBtn.Parent = UI

Instance.new("UICorner", ToggleMenuBtn).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", ToggleMenuBtn).Color = Colors.Border

-- Kéo thả nút Ẩn/Hiện Menu
local btnDragging, btnDragStart, btnStartPos
ToggleMenuBtn.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        btnDragging = true
        btnDragStart = input.Position
        btnStartPos = ToggleMenuBtn.Position
    end
end)
local btnDragConn1 = UserInputService.InputChanged:Connect(function(input)
    if btnDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - btnDragStart
        ToggleMenuBtn.Position = UDim2.new(
            btnStartPos.X.Scale, btnStartPos.X.Offset + delta.X, 
            btnStartPos.Y.Scale, btnStartPos.Y.Offset + delta.Y
        )
    end
end)
local btnDragConn2 = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
        btnDragging = false 
    end
end)
table.insert(connections, btnDragConn1)
table.insert(connections, btnDragConn2)

-- [Main Frame]
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 250, 0, 225)
MainFrame.Position = UDim2.new(0.5, -125, 0.5, -112)
MainFrame.BackgroundColor3 = Colors.Bg
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Parent = UI

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Colors.Border

-- [Chỉnh sửa phần Tiêu đề để không bị méo chữ]
local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "ESP Quân Chủ Bạo Lực MENU"
Title.TextColor3 = Colors.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true
Title.Parent = MainFrame

local TitlePadding = Instance.new("UIPadding")
TitlePadding.PaddingLeft = UDim.new(0, 10)
TitlePadding.Parent = Title

-- Click Nút Ẩn/Hiện Menu
ToggleMenuBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
end)

-- Dragging Logic Main Menu
local dragging, dragStart, startPos
Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true; dragStart = input.Position; startPos = MainFrame.Position
    end
end)
local dragConn1 = UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)
local dragConn2 = UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
end)
table.insert(connections, dragConn1)
table.insert(connections, dragConn2)

-- Helper: Tạo Button Bật/Tắt
local function CreateToggleButton(text, yPos, initialState, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = initialState and Colors.ElementActive or Colors.Element
    btn.Text = text .. (initialState and " [BẬT]" or " [TẮT]")
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.Parent = MainFrame
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

-- Helper: Tạo Button Thường
local function CreateButton(text, yPos, callback)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -20, 0, 35)
    btn.Position = UDim2.new(0, 10, 0, yPos)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = Colors.Accent
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 13
    btn.Parent = MainFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", btn).Color = Colors.Border
    
    btn.MouseButton1Click:Connect(function()
        local oldColor = btn.BackgroundColor3
        btn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
        task.delay(0.1, function()
            btn.BackgroundColor3 = oldColor
        end)
        pcall(callback)
    end)
    return btn
end

-- Helper: Tạo TextBox
local function CreateTextBox(labelText, yPos, defaultValue, callback)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -20, 0, 35)
    container.Position = UDim2.new(0, 10, 0, yPos)
    container.BackgroundColor3 = Colors.Element
    container.Parent = MainFrame
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
    
    local labelPadding = Instance.new("UIPadding")
    labelPadding.PaddingLeft = UDim.new(0, 10)
    labelPadding.Parent = label

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

    box.FocusLost:Connect(function(enterPressed)
        local num = tonumber(box.Text)
        if num and num > 0 then
            callback(num)
        else
            box.Text = tostring(currentTextSize)
        end
    end)
end

-- ==========================================
-- 4. KẾT NỐI CHỨC NĂNG VÀO MENU
-- ==========================================
InitESPObjects()

-- Nút 1: Outline ESP
CreateToggleButton("Outline ESP", 42, false, function(state)
    outlineEnabled = state
    UpdateESPVisibility()
end)

-- Nút 2: Show Distance
CreateToggleButton("Show Distance", 85, false, function(state)
    distanceEnabled = state
    UpdateESPVisibility()
end)

-- Ô nhập 3: TextBox chỉnh cỡ chữ ESP
CreateTextBox("Cỡ chữ ESP:", 128, currentTextSize, function(newSize)
    UpdateTextSize(newSize)
end)

-- Nút 4: Load lại ESP (Đã đổi tên)
CreateButton("🔄 Load Generators Trên Map", 171, function()
    InitESPObjects()
end)

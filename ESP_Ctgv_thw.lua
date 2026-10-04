--// ESP <Ctgv_thw>: Specialized ESP Hub (MODERN UI EDITION)
--// Bản Edit by Ctgv_thw: Chuyên biệt ESP, Nút ẩn/hiện ESP On/Off, Hiệu ứng 7 màu lướt.
--// Mặc định ESP màu Xanh Lá Cây (Green).
--// Tối ưu hóa: Tính ESP Distance từ Nhân vật (Character) & Đổi màu player tức thì trên UI.

if not game:IsLoaded() then game.Loaded:Wait() end

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Cam = workspace.CurrentCamera
local Player = Players.LocalPlayer

local TargetGui = (gethui and pcall(gethui)) and gethui() or game:GetService("CoreGui")

-- ==========================================
-- BẢO VỆ BỘ NHỚ & DỌN DẸP RÁC
-- ==========================================
if TargetGui:FindFirstChild("ESP_Ctgv_thw_GUI") then
    TargetGui["ESP_Ctgv_thw_GUI"]:Destroy()
end

pcall(function() RunService:UnbindFromRenderStep("ESP_Ctgv_thw_Render") end)

-- ==========================================
-- THEME & COLORS (HIỆN ĐẠI HƠN)
-- ==========================================
local Theme = {
    Background = Color3.fromRGB(20, 22, 30),      -- Xanh đen tối
    Frame = Color3.fromRGB(30, 32, 43),           -- Xanh đen sáng hơn
    ButtonOff = Color3.fromRGB(40, 42, 55),       -- Xám xanh (Tắt)
    ButtonOn = Color3.fromRGB(0, 200, 100),       -- Xanh lục bảo (Bật)
    Stroke = Color3.fromRGB(70, 75, 95),          -- Viền nổi
    Accent = Color3.fromRGB(0, 170, 255),         -- Xanh dương nhấn
    TextBase = Color3.fromRGB(240, 240, 255)      -- Trắng sáng
}

-- ==========================================
-- CẤU HÌNH ESP
-- ==========================================
local ESPSettings = {
    BoxESP = false, 
    OutlineESP = true, 
    ShowName = false,
    ShowDistance = true, 
    ESPTeammates = true, 
    TracerESP = true,
    TracerOrigin = "Top"
}

local NO_TEAM_COLOR = Color3.fromRGB(255, 255, 255)
local CustomPlayerColors = {} 
local currentESPColor = Color3.fromRGB(50, 255, 50) -- Xanh lá cây mặc định
local SelectedPlayerName = nil 
local colorOrder = {
    {name = "White", color = Color3.fromRGB(255, 255, 255)}, 
    {name = "Red", color = Color3.fromRGB(255, 50, 50)},
    {name = "Green", color = Color3.fromRGB(50, 255, 50)}, 
    {name = "Blue", color = Theme.Accent},
    {name = "Yellow", color = Color3.fromRGB(255, 215, 0)}, 
    {name = "Orange", color = Color3.fromRGB(255, 140, 0)},
    {name = "Purple", color = Color3.fromRGB(180, 50, 255)}, 
    {name = "Cyan", color = Color3.fromRGB(0, 255, 255)},
    {name = "Pink", color = Color3.fromRGB(255, 105, 180)}, 
    {name = "Black", color = Color3.fromRGB(20, 20, 20)}
}

-- ==========================================
-- HÀM HỖ TRỢ GIAO DIỆN & HIỆU ỨNG
-- ==========================================
local function applyUICorner(instance, radius)
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius or 6); corner.Parent = instance
end

local function applyUIStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Theme.Stroke
    stroke.Thickness = thickness or 1.2
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = instance
    return stroke
end

local function applyGradient(instance, color1, color2)
    local grad = Instance.new("UIGradient", instance)
    grad.Color = ColorSequence.new{ ColorSequenceKeypoint.new(0, color1), ColorSequenceKeypoint.new(1, color2) }
end

local function applyClickEffect(btn)
    local scale = btn:FindFirstChildOfClass("UIScale") or Instance.new("UIScale", btn)
    scale.Scale = 1
    btn.MouseButton1Down:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 0.92}):Play()
        if btn:FindFirstChildOfClass("UIStroke") then btn.UIStroke.Color = Theme.Accent end 
    end)
    btn.MouseButton1Up:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
        if btn:FindFirstChildOfClass("UIStroke") then btn.UIStroke.Color = Theme.Stroke end
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(scale, TweenInfo.new(0.05, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Scale = 1}):Play()
        if btn:FindFirstChildOfClass("UIStroke") then btn.UIStroke.Color = Theme.Stroke end
    end)
end

local function createToggle(parent, textOn, textOff, xPos, yPos, settingsTable, configKey, callback)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(0, 205, 0, 30); btn.Position = UDim2.new(0, xPos, 0, yPos)
    btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; btn.TextColor3 = Theme.TextBase
    applyUICorner(btn, 6)
    applyUIStroke(btn)
    applyClickEffect(btn)

    local function update()
        local state = settingsTable[configKey]
        btn.Text = state and textOn or textOff
        btn.BackgroundColor3 = state and Theme.ButtonOn or Theme.ButtonOff
    end
    btn.Activated:Connect(function()
        settingsTable[configKey] = not settingsTable[configKey]
        update()
        if callback then callback(settingsTable[configKey]) end
    end)
    update()
    return btn 
end

-- ==========================================
-- KHỞI TẠO UI CHÍNH
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ESP_Ctgv_thw_GUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true 
ScreenGui.Parent = TargetGui

-- Nút Ẩn/Hiện Menu ESP
local ToggleUIBtn = Instance.new("TextButton", ScreenGui)
ToggleUIBtn.Size = UDim2.new(0, 65, 0, 45); ToggleUIBtn.Position = UDim2.new(0, 10, 0, 150)
ToggleUIBtn.BackgroundColor3 = Theme.Frame
ToggleUIBtn.Text = "ESP Off"
ToggleUIBtn.TextColor3 = Theme.TextBase
ToggleUIBtn.Font = Enum.Font.GothamBold
ToggleUIBtn.TextSize = 12
ToggleUIBtn.Visible = false 
applyUICorner(ToggleUIBtn, 10); applyUIStroke(ToggleUIBtn, Theme.Accent, 1.5); applyClickEffect(ToggleUIBtn)

local MainFrame = Instance.new("Frame", ScreenGui)
MainFrame.Size = UDim2.new(0, 480, 0, 310); MainFrame.Position = UDim2.new(0.5, -240, 0.5, -155); MainFrame.BackgroundColor3 = Theme.Background; MainFrame.Active = true
MainFrame.Visible = false 
applyUICorner(MainFrame, 12); applyUIStroke(MainFrame, Theme.Stroke, 2)

local MenuScale = Instance.new("UIScale", MainFrame)
MenuScale.Scale = 0

-- HIỆU ỨNG TÊN 7 MÀU LƯỚT (By Ctgv_thw)
local TitleFrame = Instance.new("Frame", MainFrame)
TitleFrame.Size = UDim2.new(1, 0, 0, 40)
TitleFrame.BackgroundColor3 = Theme.Frame
TitleFrame.BorderSizePixel = 0
applyUICorner(TitleFrame, 12)

local TitleCornerFix = Instance.new("Frame", TitleFrame)
TitleCornerFix.Size = UDim2.new(1, 0, 0, 10)
TitleCornerFix.Position = UDim2.new(0, 0, 1, -10)
TitleCornerFix.BackgroundColor3 = Theme.Frame
TitleCornerFix.BorderSizePixel = 0

local Title = Instance.new("TextLabel", TitleFrame)
Title.Size = UDim2.new(1, 0, 1, 0)
Title.BackgroundTransparency = 1
Title.Text = "   🚀 ESP <Ctgv_thw>"
Title.TextColor3 = Color3.fromRGB(255, 255, 255)
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 18 
Title.TextXAlignment = Enum.TextXAlignment.Left

local TitleGradient = Instance.new("UIGradient", Title)
TitleGradient.Rotation = 15 

task.spawn(function()
    local rainbowColors = {
        Color3.fromRGB(255, 0, 0), Color3.fromRGB(255, 127, 0), Color3.fromRGB(255, 255, 0),
        Color3.fromRGB(0, 255, 0), Color3.fromRGB(0, 255, 255), Color3.fromRGB(0, 0, 255), Color3.fromRGB(148, 0, 211)
    }
    local colorIdx = 1
    while task.wait() do
        local oldColor = rainbowColors[colorIdx]
        colorIdx = colorIdx + 1
        if colorIdx > #rainbowColors then colorIdx = 1 end
        local newColor = rainbowColors[colorIdx]

        TitleGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, newColor),
            ColorSequenceKeypoint.new(0.48, newColor),
            ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(0.52, oldColor),
            ColorSequenceKeypoint.new(1, oldColor)
        })

        TitleGradient.Offset = Vector2.new(-1, 0)
        local tw = TweenService:Create(TitleGradient, TweenInfo.new(1, Enum.EasingStyle.Linear), {Offset = Vector2.new(1, 0)})
        tw:Play()
        tw.Completed:Wait() 
    end
end)

-- KHU VỰC ĐIỀU KHIỂN ESP
local ESPContainer = Instance.new("Frame", MainFrame)
ESPContainer.Size = UDim2.new(1, 0, 1, -40)
ESPContainer.Position = UDim2.new(0, 0, 0, 40)
ESPContainer.BackgroundTransparency = 1

createToggle(ESPContainer, "Box ESP: ON", "Box ESP: OFF", 15, 10, ESPSettings, "BoxESP")
createToggle(ESPContainer, "Outline (Chéo Tường): ON", "Outline (Chéo Tường): OFF", 15, 45, ESPSettings, "OutlineESP")

local TracerToggleBtn = createToggle(ESPContainer, "Tracer: ON", "Tracer: OFF", 15, 80, ESPSettings, "TracerESP")
TracerToggleBtn.Size = UDim2.new(0, 120, 0, 30)

local TracerPosBtn = Instance.new("TextButton", ESPContainer)
TracerPosBtn.Size = UDim2.new(0, 80, 0, 30); TracerPosBtn.Position = UDim2.new(0, 140, 0, 80)
TracerPosBtn.Font = Enum.Font.GothamBold; TracerPosBtn.TextSize = 10; TracerPosBtn.BackgroundColor3 = Theme.Accent; TracerPosBtn.TextColor3 = Theme.TextBase
applyUICorner(TracerPosBtn, 6); applyUIStroke(TracerPosBtn); applyClickEffect(TracerPosBtn)

local tracerPosList = {"Bottom", "Center", "Top"}
local currentTracerPosIdx = 3
local function updateTracerPosBtn()
    local pos = tracerPosList[currentTracerPosIdx]
    ESPSettings.TracerOrigin = pos
    if pos == "Bottom" then TracerPosBtn.Text = "Gốc: DƯỚI"
    elseif pos == "Center" then TracerPosBtn.Text = "Gốc: GIỮA"
    elseif pos == "Top" then TracerPosBtn.Text = "Gốc: TRÊN" end
end
TracerPosBtn.Activated:Connect(function()
    currentTracerPosIdx = currentTracerPosIdx + 1
    if currentTracerPosIdx > 3 then currentTracerPosIdx = 1 end
    updateTracerPosBtn()
end)
updateTracerPosBtn()

createToggle(ESPContainer, "ESP Name: ON", "ESP Name: OFF", 15, 115, ESPSettings, "ShowName")
createToggle(ESPContainer, "ESP Distance: ON", "ESP Distance: OFF", 15, 150, ESPSettings, "ShowDistance")
createToggle(ESPContainer, "ESP Teammates: ON", "ESP Teammates: OFF", 15, 185, ESPSettings, "ESPTeammates")

local FixBtn = Instance.new("TextButton", ESPContainer); FixBtn.Size = UDim2.new(0, 205, 0, 30); FixBtn.Position = UDim2.new(0, 15, 0, 220); FixBtn.BackgroundColor3 = Color3.fromRGB(220, 60, 60); FixBtn.Text = "🔄 Sửa Lỗi Tàng Hình Outline"; FixBtn.Font = Enum.Font.GothamBold; FixBtn.TextSize = 11; FixBtn.TextColor3 = Theme.TextBase; applyUICorner(FixBtn, 6); applyUIStroke(FixBtn); applyClickEffect(FixBtn)

-- PANEL CHỌN TARGET MÀU SẮC
local TargetPanel = Instance.new("Frame", ESPContainer); TargetPanel.Size = UDim2.new(0, 230, 0, 240); TargetPanel.Position = UDim2.new(0, 235, 0, 10); TargetPanel.BackgroundColor3 = Theme.Frame; applyUICorner(TargetPanel, 6); applyUIStroke(TargetPanel)

local SelectedLabel = Instance.new("TextLabel", TargetPanel); SelectedLabel.Size = UDim2.new(1, 0, 0, 20); SelectedLabel.Position = UDim2.new(0, 0, 0, 5); SelectedLabel.BackgroundTransparency = 1; SelectedLabel.Text = "Mục tiêu: TẤT CẢ (Global)"; SelectedLabel.TextColor3 = Color3.fromRGB(255, 230, 80); SelectedLabel.Font = Enum.Font.GothamBold; SelectedLabel.TextSize = 11

local SearchBar = Instance.new("TextBox", TargetPanel); SearchBar.Size = UDim2.new(1, -20, 0, 24); SearchBar.Position = UDim2.new(0, 10, 0, 25); SearchBar.BackgroundColor3 = Theme.Background; SearchBar.TextColor3 = Theme.TextBase; SearchBar.PlaceholderText = "Nhập tên đăng nhập..."; SearchBar.Font = Enum.Font.Gotham; SearchBar.TextSize = 11; SearchBar.Text = ""; applyUICorner(SearchBar, 4); applyUIStroke(SearchBar)

local btnAll = Instance.new("TextButton", TargetPanel); btnAll.Size = UDim2.new(0.5, -15, 0, 22); btnAll.Position = UDim2.new(0, 10, 0, 55); btnAll.Font = Enum.Font.GothamBold; btnAll.TextSize = 9; btnAll.BackgroundColor3 = Theme.Accent; btnAll.TextColor3 = Theme.TextBase; btnAll.Text = "[ CHỌN TẤT CẢ ]"; applyUICorner(btnAll, 4); applyUIStroke(btnAll); applyClickEffect(btnAll)
local resetColorBtn = Instance.new("TextButton", TargetPanel); resetColorBtn.Size = UDim2.new(0.5, -15, 0, 22); resetColorBtn.Position = UDim2.new(0.5, 5, 0, 55); resetColorBtn.Font = Enum.Font.GothamBold; resetColorBtn.TextSize = 9; resetColorBtn.BackgroundColor3 = Color3.fromRGB(200, 60, 60); resetColorBtn.TextColor3 = Theme.TextBase; resetColorBtn.Text = "[ RESET MÀU ]"; applyUICorner(resetColorBtn, 4); applyUIStroke(resetColorBtn); applyClickEffect(resetColorBtn)

local PlayerScroll = Instance.new("ScrollingFrame", TargetPanel); PlayerScroll.Size = UDim2.new(1, -20, 0, 100); PlayerScroll.Position = UDim2.new(0, 10, 0, 85); PlayerScroll.BackgroundColor3 = Theme.Background; PlayerScroll.ScrollBarThickness = 4; PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, 0); applyUICorner(PlayerScroll, 4); applyUIStroke(PlayerScroll); local PlayerListLayout = Instance.new("UIListLayout", PlayerScroll); PlayerListLayout.SortOrder = Enum.SortOrder.Name; PlayerListLayout.Padding = UDim.new(0, 3)

local ColorScroll = Instance.new("ScrollingFrame", TargetPanel); ColorScroll.Size = UDim2.new(1, -20, 0, 40); ColorScroll.Position = UDim2.new(0, 10, 0, 190); ColorScroll.BackgroundColor3 = Theme.Background; ColorScroll.ScrollBarThickness = 0; ColorScroll.CanvasSize = UDim2.new(0, (#colorOrder * 35) + 5, 0, 0); ColorScroll.ScrollingDirection = Enum.ScrollingDirection.X; applyUICorner(ColorScroll, 4); applyUIStroke(ColorScroll); local ColorListLayout = Instance.new("UIListLayout", ColorScroll); ColorListLayout.FillDirection = Enum.FillDirection.Horizontal; ColorListLayout.SortOrder = Enum.SortOrder.LayoutOrder; ColorListLayout.Padding = UDim.new(0, 5)

local function updateSelection(name)
    SelectedPlayerName = name
    if name then SelectedLabel.Text = "Mục tiêu: " .. name; SelectedLabel.TextColor3 = CustomPlayerColors[name] or Color3.fromRGB(50, 255, 100)
    else SelectedLabel.Text = "Mục tiêu: TẤT CẢ (Global)"; SelectedLabel.TextColor3 = Color3.fromRGB(255, 230, 80) end
end

local function RefreshPlayerList()
    for _, child in pairs(PlayerScroll:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
    local filter = string.lower(SearchBar.Text); local count = 0
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= Player and (filter == "" or string.find(string.lower(p.Name), filter) or string.find(string.lower(p.DisplayName), filter)) then
            count = count + 1
            local b = Instance.new("TextButton", PlayerScroll); 
            b.Size = UDim2.new(1, 0, 0, 22); 
            b.BackgroundColor3 = Theme.ButtonOff; 
            b.Text = p.DisplayName .. " (@" .. p.Name .. ")"; 
            b.TextColor3 = CustomPlayerColors[p.Name] or Theme.TextBase; 
            b.Font = Enum.Font.Gotham; 
            b.TextSize = 11; 
            applyUICorner(b, 4)
            applyUIStroke(b, Theme.Stroke, 1)
            applyClickEffect(b) 
            
            b.MouseButton1Click:Connect(function() updateSelection(p.Name) end)
        end
    end
    PlayerScroll.CanvasSize = UDim2.new(0, 0, 0, count * 25)
end

for i, c in ipairs(colorOrder) do
    local cb = Instance.new("TextButton", ColorScroll); cb.Size = UDim2.new(0, 30, 0, 30); cb.BackgroundColor3 = c.color; cb.Text = ""; cb.LayoutOrder = i; applyUICorner(cb, 15); applyUIStroke(cb, Color3.fromRGB(255,255,255), 1.5); applyClickEffect(cb)
    cb.MouseButton1Click:Connect(function()
        if SelectedPlayerName then 
            CustomPlayerColors[SelectedPlayerName] = c.color; 
            SelectedLabel.TextColor3 = c.color
        else 
            currentESPColor = c.color; 
            table.clear(CustomPlayerColors) 
        end
        RefreshPlayerList()
    end)
end

SearchBar.Changed:Connect(function(prop) if prop == "Text" then RefreshPlayerList() end end); Players.PlayerAdded:Connect(RefreshPlayerList); Players.PlayerRemoving:Connect(RefreshPlayerList)
btnAll.MouseButton1Click:Connect(function() updateSelection(nil) end)
resetColorBtn.MouseButton1Click:Connect(function()
    if SelectedPlayerName then CustomPlayerColors[SelectedPlayerName] = nil; SelectedLabel.TextColor3 = Color3.fromRGB(50, 255, 100)
    else currentESPColor = Color3.fromRGB(50, 255, 50); table.clear(CustomPlayerColors) end
    RefreshPlayerList()
end)

-- ==========================================
-- XỬ LÝ KÉO THẢ UI & AN/HIEN MENU (ESP On / ESP Off)
-- ==========================================
local function makeDraggable(dragObject, moveObject)
    local dragging, dragInput, dragStart, startPos
    dragObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then 
            dragging = true; 
            dragStart = input.Position; 
            startPos = moveObject.Position; 
            input.Changed:Connect(function() 
                if input.UserInputState == Enum.UserInputState.End then dragging = false end 
            end) 
        end
    end)
    dragObject.InputChanged:Connect(function(input) 
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then 
            dragInput = input 
        end 
    end)
    UserInputService.InputChanged:Connect(function(input) 
        if input == dragInput and dragging then 
            local delta = input.Position - dragStart; 
            moveObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) 
        end 
    end)
end

makeDraggable(TitleFrame, MainFrame); 
makeDraggable(ToggleUIBtn, ToggleUIBtn); 

local isMenuOpen = false
local function toggleMenu()
    isMenuOpen = not isMenuOpen
    if isMenuOpen then
        ToggleUIBtn.Text = "ESP On"
        ToggleUIBtn.BackgroundColor3 = Theme.ButtonOn
        MainFrame.Visible = true
        TweenService:Create(MenuScale, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Scale = 1}):Play()
    else
        ToggleUIBtn.Text = "ESP Off"
        ToggleUIBtn.BackgroundColor3 = Theme.Frame
        local tw = TweenService:Create(MenuScale, TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Scale = 0})
        tw:Play()
        tw.Completed:Connect(function()
            if not isMenuOpen then MainFrame.Visible = false end
        end)
    end
end

ToggleUIBtn.Activated:Connect(toggleMenu)

-- ==========================================
-- LOGIC ESP CHÍNH
-- ==========================================
local ESP = {}
local activeHighlights = 0
local function getESPColor(p) return CustomPlayerColors[p.Name] or currentESPColor or (p.Team and p.Team.TeamColor.Color or NO_TEAM_COLOR) end

local function cleanESP(p) 
    if ESP[p] then 
        if ESP[p].Box then ESP[p].Box:Destroy() end
        if ESP[p].HL then ESP[p].HL:Destroy(); activeHighlights = activeHighlights - 1 end
        if ESP[p].BB then ESP[p].BB:Destroy() end
        if ESP[p].Tracer then ESP[p].Tracer:Destroy() end
        ESP[p] = nil 
    end 
end

local function setupESP(p)
    if p == Player then return end; cleanESP(p)
    local box = Instance.new("SelectionBox"); box.LineThickness = 0.05; box.SurfaceTransparency = 1; box.Parent = ScreenGui 
    local hl = Instance.new("Highlight"); hl.FillTransparency = 1; hl.OutlineTransparency = 0; hl.Enabled = false
    if activeHighlights < 31 then hl.Parent = ScreenGui; activeHighlights = activeHighlights + 1 end
    local bb = Instance.new("BillboardGui"); bb.AlwaysOnTop = true; bb.Size = UDim2.new(0, 200, 0, 50); bb.StudsOffset = Vector3.new(0, 2, 0); bb.Parent = ScreenGui
    local txt = Instance.new("TextLabel"); txt.Size = UDim2.new(1, 0, 1, 0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.GothamBold; txt.TextSize = 12; txt.TextStrokeTransparency = 0; txt.Parent = bb
    local tracerFrame = Instance.new("Frame"); tracerFrame.AnchorPoint = Vector2.new(0.5, 0.5); tracerFrame.BorderSizePixel = 0; tracerFrame.Visible = false; tracerFrame.Parent = ScreenGui
    ESP[p] = { Box = box, HL = hl, BB = bb, TXT = txt, Tracer = tracerFrame }
end

for _, p in pairs(Players:GetPlayers()) do setupESP(p) end
Players.PlayerAdded:Connect(setupESP); Players.PlayerRemoving:Connect(cleanESP)

local function RebuildHighlights()
    for p, e in pairs(ESP) do if e.HL then pcall(function() e.HL:Destroy() end); e.HL = nil end end
    activeHighlights = 0
    for p, e in pairs(ESP) do
        if activeHighlights < 31 then
            local newHl = Instance.new("Highlight"); newHl.FillTransparency = 1; newHl.OutlineTransparency = 0; newHl.Enabled = false; newHl.Parent = ScreenGui
            e.HL = newHl; activeHighlights = activeHighlights + 1
        end
    end
end

UserInputService.WindowFocused:Connect(RebuildHighlights)
FixBtn.Activated:Connect(RebuildHighlights)

RunService:BindToRenderStep("ESP_Ctgv_thw_Render", Enum.RenderPriority.Camera.Value + 2, function()
    local origin = ESPSettings.TracerOrigin == "Bottom" and Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y) or (ESPSettings.TracerOrigin == "Center" and Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2) or Vector2.new(Cam.ViewportSize.X / 2, 0))

    for p, e in pairs(ESP) do
        local c = p.Character; local hrp = c and c:FindFirstChild("HumanoidRootPart"); local head = c and c:FindFirstChild("Head"); local hum = c and c:FindFirstChildOfClass("Humanoid")
        local isVisible = hrp and head and hum and hum.Health > 0 and (ESPSettings.ESPTeammates or p.Team ~= Player.Team)
        if isVisible then
            local col = getESPColor(p)
            e.Box.Visible = ESPSettings.BoxESP; e.Box.Adornee = ESPSettings.BoxESP and c or nil; e.Box.Color3 = col
            if ESPSettings.OutlineESP and e.HL then e.HL.Enabled = true; e.HL.Adornee = c; e.HL.OutlineColor = col elseif e.HL then e.HL.Enabled = false; e.HL.Adornee = nil end
            if ESPSettings.ShowName or ESPSettings.ShowDistance then
                e.BB.Adornee = head; e.BB.Enabled = true; e.TXT.TextColor3 = col
                local str = ""; if ESPSettings.ShowName then str = p.Name end
                
                -- TÍNH KHOẢNG CÁCH TỪ NHÂN VẬT THAY VÌ CAMERA
                if ESPSettings.ShowDistance then 
                    local myHrp = Player.Character and Player.Character:FindFirstChild("HumanoidRootPart")
                    local myPos = myHrp and myHrp.Position or Cam.CFrame.Position
                    str = str .. (ESPSettings.ShowName and "\n" or "") .. "[" .. math.floor((myPos - hrp.Position).Magnitude) .. "m]" 
                end
                
                e.TXT.Text = str
            else e.BB.Enabled = false end
            
            if ESPSettings.TracerESP then
                local pos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    local target = Vector2.new(pos.X, pos.Y); local dist = (target - origin).Magnitude
                    e.Tracer.Size = UDim2.new(0, dist, 0, 1.5); e.Tracer.Position = UDim2.new(0, (origin.X + target.X) / 2, 0, (origin.Y + target.Y) / 2)
                    e.Tracer.Rotation = math.deg(math.atan2(target.Y - origin.Y, target.X - origin.X)); e.Tracer.BackgroundColor3 = col; e.Tracer.Visible = true
                else e.Tracer.Visible = false end
            else e.Tracer.Visible = false end
        else e.Box.Visible = false; if e.HL then e.HL.Enabled = false; e.HL.Adornee = nil end; e.BB.Enabled = false; e.Tracer.Visible = false end
    end
end)

UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.KeyCode == Enum.KeyCode.RightShift then toggleMenu() end
end)

-- ==========================================
-- GIAO DIỆN TẢI SCRIPT (% TRẠNG THÁI)
-- ==========================================
local LoadFrame = Instance.new("Frame", ScreenGui)
LoadFrame.Size = UDim2.new(0, 340, 0, 130)
LoadFrame.Position = UDim2.new(0.5, -170, 0.5, -65)
LoadFrame.BackgroundColor3 = Theme.Background
applyUICorner(LoadFrame, 12)
applyUIStroke(LoadFrame, Theme.Accent, 2)

local LoadTitle = Instance.new("TextLabel", LoadFrame)
LoadTitle.Size = UDim2.new(1, 0, 0, 40)
LoadTitle.Position = UDim2.new(0, 0, 0, 10)
LoadTitle.BackgroundTransparency = 1
LoadTitle.Text = "ESP <Ctgv_thw>"
LoadTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadTitle.Font = Enum.Font.GothamBlack
LoadTitle.TextSize = 22
applyGradient(LoadTitle, Color3.fromRGB(150, 50, 255), Color3.fromRGB(0, 170, 255))

local LoadStatus = Instance.new("TextLabel", LoadFrame)
LoadStatus.Size = UDim2.new(1, 0, 0, 25)
LoadStatus.Position = UDim2.new(0, 0, 0, 50)
LoadStatus.BackgroundTransparency = 1
LoadStatus.Text = "Đang khởi tạo hệ thống ESP..."
LoadStatus.TextColor3 = Color3.fromRGB(180, 180, 200)
LoadStatus.Font = Enum.Font.Gotham
LoadStatus.TextSize = 13

local LoadPercent = Instance.new("TextLabel", LoadFrame)
LoadPercent.Size = UDim2.new(0, 50, 0, 25)
LoadPercent.Position = UDim2.new(1, -65, 0, 85)
LoadPercent.BackgroundTransparency = 1
LoadPercent.Text = "0%"
LoadPercent.TextColor3 = Theme.Accent
LoadPercent.Font = Enum.Font.GothamBold
LoadPercent.TextSize = 14
LoadPercent.TextXAlignment = Enum.TextXAlignment.Right

local LoadingBarBG = Instance.new("Frame", LoadFrame)
LoadingBarBG.Size = UDim2.new(0, 260, 0, 10)
LoadingBarBG.Position = UDim2.new(0, 20, 0, 92)
LoadingBarBG.BackgroundColor3 = Theme.Frame
applyUICorner(LoadingBarBG, 5)
applyUIStroke(LoadingBarBG, Theme.Stroke, 1)

local LoadingBarFill = Instance.new("Frame", LoadingBarBG)
LoadingBarFill.Size = UDim2.new(0, 0, 1, 0)
LoadingBarFill.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
applyUICorner(LoadingBarFill, 5)
applyGradient(LoadingBarFill, Color3.fromRGB(0, 170, 255), Color3.fromRGB(0, 255, 170))

task.spawn(function()
    local duration = 2.5
    local startTime = tick()
    
    while tick() - startTime < duration do
        local elapsed = tick() - startTime
        local progress = math.clamp(elapsed / duration, 0, 1)
        local pct = math.floor(progress * 100)
        
        LoadPercent.Text = tostring(pct) .. "%"
        LoadingBarFill.Size = UDim2.new(progress, 0, 1, 0)
        
        if pct < 35 then
            LoadStatus.Text = "Khởi tạo Module ESP & Highlights..."
        elseif pct < 70 then
            LoadStatus.Text = "Tải danh sách Player & Render Tracers..."
        elseif pct < 90 then
            LoadStatus.Text = "Hoàn thiện giao diện ESP Menu..."
        else
            LoadStatus.Text = "Sẵn sàng! Đang khởi động..."
        end
        
        RunService.RenderStepped:Wait()
    end
    
    LoadPercent.Text = "100%"
    LoadingBarFill.Size = UDim2.new(1, 0, 1, 0)
    LoadStatus.Text = "Thành công!"
    task.wait(0.3)
    
    for _, child in pairs(LoadFrame:GetDescendants()) do
        if child:IsA("GuiObject") then
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.5), {TextTransparency = 1}):Play()
            else
                TweenService:Create(child, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
            end
            if child:FindFirstChildOfClass("UIStroke") then
                TweenService:Create(child.UIStroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
            end
        end
    end
    TweenService:Create(LoadFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
    TweenService:Create(LoadFrame.UIStroke, TweenInfo.new(0.5), {Transparency = 1}):Play()
    
    task.wait(0.5)
    LoadFrame:Destroy()
    
    ToggleUIBtn.Visible = true
    toggleMenu()
end)

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
        if conn and conn.Connected then conn:Disconnect() end
    end
    for _, inst in ipairs(instancesToDestroy) do
        if inst and inst.Destroy then pcall(function() inst:Destroy() end) end
    end
    if getgenv()._ESP_Tracer_Cache then
        for _, tracer in pairs(getgenv()._ESP_Tracer_Cache) do pcall(function() tracer:Remove() end) end
    end
    getgenv()._ESP_Tracer_Cache = {}
    connections = {}
    instancesToDestroy = {}
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local CoreGui = (gethui and pcall(gethui)) and gethui() or game:GetService("CoreGui")
local Cam = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

getgenv()._ESP_Tracer_Cache = {}

-- ==========================================
-- CẤU HÌNH WORLD & MOVEMENT
-- ==========================================
local outlineEnabled = false
local distanceEnabled = false
local fullbrightEnabled = false
local currentTextSize = 10 

getgenv().Walkspeed = 17
getgenv().loopW = false
getgenv().TPSpeed = 0.04
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
-- CẤU HÌNH PLAYER ESP
-- ==========================================
local PlayerESPSettings = {
    BoxESP = false,
    OutlineESP = true, 
    ShowName = false,
    ShowDistance = true,
    ESPTeammates = true,
    TracerESP = true
}

local NO_TEAM_COLOR = Color3.fromRGB(255, 255, 255)
local currentESPColor = nil 
local CustomPlayerColors = {} 
local SelectedPlayerName = nil 
local PlayerESP = {}
local activeHighlights = 0

local colorOrder = {
    {name = "White",   color = Color3.fromRGB(255, 255, 255)},
    {name = "Red",     color = Color3.fromRGB(255, 0, 0)},
    {name = "Green",   color = Color3.fromRGB(0, 255, 0)},
    {name = "Blue",    color = Color3.fromRGB(0, 0, 255)},
    {name = "Yellow",  color = Color3.fromRGB(255, 255, 0)},
    {name = "Orange",  color = Color3.fromRGB(255, 165, 0)},
    {name = "Purple",  color = Color3.fromRGB(160, 32, 240)},
    {name = "Cyan",    color = Color3.fromRGB(0, 255, 255)},
    {name = "Pink",    color = Color3.fromRGB(255, 105, 180)},
}

-- ==========================================
-- 1. LOGIC QUẢN LÝ WORLD ESP (GENERATORS)
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

local espFolder = nil
local espElements = {}

local function InitGeneratorESP()
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
        
        table.insert(espElements, {Part = body, Highlight = highlight, Billboard = billboard, Label = textLabel})
    end
end

local function UpdateGeneratorVisibility()
    local needsReinit = false
    if not espFolder or #espElements == 0 then
        needsReinit = true
    else
        for _, data in ipairs(espElements) do
            if not data.Part or not data.Part.Parent then needsReinit = true; break end
        end
    end
    if needsReinit then InitGeneratorESP() end
    for _, data in ipairs(espElements) do
        if data.Highlight then data.Highlight.Enabled = outlineEnabled end
        if data.Billboard then data.Billboard.Enabled = distanceEnabled end
    end
end

local function ClearFogOnce()
    Lighting.FogStart = 9e9
    Lighting.FogEnd = 9e9
    local function DisableEffect(v)
        if v:IsA("Atmosphere") then v.Density = 0; v.Haze = 0; v.Offset = 0
        elseif v:IsA("DepthOfFieldEffect") or v:IsA("BlurEffect") or v:IsA("SunRaysEffect") or v:IsA("BloomEffect") then v.Enabled = false end
    end
    for _, v in ipairs(Lighting:GetChildren()) do pcall(function() DisableEffect(v) end) end
    for _, v in ipairs(Workspace:GetDescendants()) do pcall(function() DisableEffect(v) end) end
end

-- ==========================================
-- 2. LOGIC PLAYER ESP
-- ==========================================
local PlayerESPFolder = Instance.new("Folder")
PlayerESPFolder.Name = "PlayerESP_System"
PlayerESPFolder.Parent = CoreGui
table.insert(instancesToDestroy, PlayerESPFolder)

local function shouldESP(p)
    if p == LocalPlayer then return false end
    if not PlayerESPSettings.ESPTeammates and LocalPlayer.Team and p.Team and LocalPlayer.Team == p.Team then return false end
    return true
end

local function getESPColor(p)
    if CustomPlayerColors[p.Name] then return CustomPlayerColors[p.Name] end
    if currentESPColor then return currentESPColor end 
    if p.Team then return p.Team.TeamColor.Color end 
    return NO_TEAM_COLOR 
end

local function cleanESP(p)
    if PlayerESP[p] then
        pcall(function() if PlayerESP[p].Box then PlayerESP[p].Box:Destroy() end end)
        pcall(function() if PlayerESP[p].HL then PlayerESP[p].HL:Destroy(); activeHighlights = activeHighlights - 1 end end)
        pcall(function() if PlayerESP[p].BB then PlayerESP[p].BB:Destroy() end end)
        pcall(function() 
            if PlayerESP[p].Tracer then 
                PlayerESP[p].Tracer:Remove() 
                local idx = table.find(getgenv()._ESP_Tracer_Cache, PlayerESP[p].Tracer)
                if idx then table.remove(getgenv()._ESP_Tracer_Cache, idx) end
            end 
        end)
        PlayerESP[p] = nil
    end
end

local function setupESP(p)
    if p == LocalPlayer then return end
    cleanESP(p)

    local box = Instance.new("SelectionBox")
    box.LineThickness = 0.05
    box.SurfaceTransparency = 1
    box.Parent = PlayerESPFolder 

    local hl = Instance.new("Highlight")
    hl.FillTransparency = 1
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false 
    if activeHighlights < 31 then hl.Parent = PlayerESPFolder; activeHighlights = activeHighlights + 1 end

    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 40)
    bb.AlwaysOnTop = true
    bb.StudsOffset = Vector3.new(0, 3, 0)
    bb.Parent = PlayerESPFolder 

    local txt = Instance.new("TextLabel", bb)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Font = Enum.Font.SourceSansBold
    txt.TextStrokeTransparency = 0.5 
    txt.TextSize = 13

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Color = Color3.new(1, 1, 1)
    tracer.Thickness = 1.5
    tracer.Transparency = 1
    table.insert(getgenv()._ESP_Tracer_Cache, tracer)

    PlayerESP[p] = {Box = box, HL = hl, BB = bb, TXT = txt, Tracer = tracer}
end

for _, p in pairs(Players:GetPlayers()) do setupESP(p) end
table.insert(connections, Players.PlayerAdded:Connect(setupESP))
table.insert(connections, Players.PlayerRemoving:Connect(function(p)
    cleanESP(p) 
    if CustomPlayerColors[p.Name] then CustomPlayerColors[p.Name] = nil end
    if SelectedPlayerName == p.Name then SelectedPlayerName = nil end
end))

local function RebuildPlayerHighlights()
    for p, e in pairs(PlayerESP) do if e.HL then pcall(function() e.HL:Destroy() end); e.HL = nil end end
    activeHighlights = 0
    for p, e in pairs(PlayerESP) do
        if activeHighlights < 31 then
            local newHl = Instance.new("Highlight")
            newHl.FillTransparency = 1
            newHl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            newHl.Enabled = false 
            newHl.Parent = PlayerESPFolder 
            e.HL = newHl
            activeHighlights = activeHighlights + 1
        end
    end
end
table.insert(connections, UserInputService.WindowFocused:Connect(RebuildPlayerHighlights))

-- ==========================================
-- 3. CORE LOGIC (RENDER & HEARTBEAT)
-- ==========================================
local renderConn = RunService.RenderStepped:Connect(function()
    if fullbrightEnabled then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Top = Color3.fromRGB(255, 255, 255)
        Lighting.ColorShift_Bottom = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(255, 255, 255)
        Lighting.ClockTime = 14
    end

    local char = LocalPlayer.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if distanceEnabled and root then
        for _, data in ipairs(espElements) do
            if data.Part and data.Part.Parent then
                data.Label.Text = string.format("Generator\n[%.1f m]", (root.Position - data.Part.Position).Magnitude)
            else data.Label.Text = "" end
        end
    end

    local CamPos = Cam.CFrame.Position 
    local ViewportCenter = Vector2.new(Cam.ViewportSize.X / 2, 0)

    for p, e in pairs(PlayerESP) do
        if not p or p.Parent ~= Players then cleanESP(p); continue end

        local c = p.Character
        local hrp = c and c:FindFirstChild("HumanoidRootPart")
        local hum = c and c:FindFirstChildOfClass("Humanoid")
        local isVisible = hum and hum.Health > 0 and hrp and shouldESP(p)
        
        if isVisible then
            local col = getESPColor(p)
            e.Box.Color3 = col; e.TXT.TextColor3 = col
            e.Box.Visible = PlayerESPSettings.BoxESP; e.Box.Adornee = PlayerESPSettings.BoxESP and c or nil 
            
            if PlayerESPSettings.OutlineESP and e.HL then e.HL.Enabled = true; e.HL.OutlineColor = col; e.HL.Adornee = c 
            elseif e.HL then e.HL.Enabled = false; e.HL.Adornee = nil end

            local showBB = PlayerESPSettings.ShowName or PlayerESPSettings.ShowDistance
            e.BB.Enabled = showBB; e.BB.Adornee = showBB and hrp or nil 

            if showBB then
                local t = ""
                if PlayerESPSettings.ShowName then t = p.Name end
                if PlayerESPSettings.ShowDistance then
                    local dist = math.floor((CamPos - hrp.Position).Magnitude)
                    t = PlayerESPSettings.ShowName and (t .. " [" .. dist .. "m]") or (dist .. "m")
                end
                e.TXT.Text = t
            end

            if PlayerESPSettings.TracerESP then
                local pos, onScreen = Cam:WorldToViewportPoint(hrp.Position)
                if onScreen then
                    e.Tracer.From = ViewportCenter; e.Tracer.To = Vector2.new(pos.X, pos.Y)
                    e.Tracer.Color = col; e.Tracer.Visible = true
                else e.Tracer.Visible = false end
            else e.Tracer.Visible = false end
        else
            e.Box.Visible = false; e.Box.Adornee = nil
            if e.HL then e.HL.Enabled = false; e.HL.Adornee = nil end
            e.BB.Enabled = false; e.BB.Adornee = nil; e.Tracer.Visible = false
        end
    end
end)
table.insert(connections, renderConn)

-- ==========================================================
-- LOGIC DI CHUYỂN AN TOÀN CHỐNG ANTI-CHEAT & CHỐNG KẸT
-- ==========================================================
local moveConn = RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local root = char and char:FindFirstChild("HumanoidRootPart")
    
    if not (char and hum and root and hum.Parent) then return end
    
    -- Lớp 1: Kiểm tra trạng thái vật lý chuẩn
    local isPhysicsLocked = hum.PlatformStand or hum.Sit or root.Anchored
    
    -- Lớp 2: Kiểm tra liên kết vật lý (Phát hiện bị bế/trói)
    local isCarriedOrBound = false
    for _, joint in ipairs(root:GetJoints()) do
        local otherPart = (joint.Part0 == root) and joint.Part1 or joint.Part0
        if otherPart and otherPart.Parent and not otherPart:IsDescendantOf(char) then
            isCarriedOrBound = true; break
        end
    end

    -- Lớp 3: Kiểm tra cờ trạng thái game Violence District
    local isDownedState = char:FindFirstChild("Knocked") 
        or char:FindFirstChild("Carried") 
        or char:FindFirstChild("Grabbed") 
        or char:GetAttribute("Downed") == true

    if isPhysicsLocked or isCarriedOrBound or isDownedState then
        if hum.WalkSpeed ~= 16 then hum.WalkSpeed = 16 end
        return 
    end

    -- Thực thi Speed & TP Walk nếu tự do
    if getgenv().loopW then 
        local targetWS = tonumber(getgenv().Walkspeed) or 16
        if hum.WalkSpeed ~= targetWS then hum.WalkSpeed = targetWS end 
    end
    
    if getgenv().TPWalk and hum.MoveDirection.Magnitude > 0 then
        local speed = tonumber(getgenv().TPSpeed) or 0.04
        root.CFrame = root.CFrame + (hum.MoveDirection * speed)
        root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
    end
end)
table.insert(connections, moveConn)

-- ==========================================
-- 4. GIAO DIỆN MENU & NÚT NỔI BÊN NGOÀI
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

local function MakeDraggable(dragObject, moveObject)
    local dragging, dragInput, dragStart, startPos
    dragObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragInput = input; dragStart = input.Position; startPos = moveObject.Position
        end
    end)
    table.insert(connections, UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            moveObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end))
    table.insert(connections, UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then dragging = false; dragInput = nil end
    end))
end

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
MakeDraggable(ToggleMenuBtn, ToggleMenuBtn)

local FloatMoveBtn = Instance.new("TextButton")
FloatMoveBtn.Size = UDim2.new(0, 120, 0, 35)
FloatMoveBtn.Position = UDim2.new(0, 75, 0, 25)
FloatMoveBtn.BackgroundColor3 = Colors.Element
FloatMoveBtn.Text = "🏃 TỐC ĐỘ: TẮT"
FloatMoveBtn.TextColor3 = Colors.Text
FloatMoveBtn.Font = Enum.Font.GothamBold
FloatMoveBtn.TextSize = 11
FloatMoveBtn.Visible = false 
FloatMoveBtn.Parent = UI
Instance.new("UICorner", FloatMoveBtn).CornerRadius = UDim.new(0, 6)
Instance.new("UIStroke", FloatMoveBtn).Color = Colors.Border
MakeDraggable(FloatMoveBtn, FloatMoveBtn)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 300, 0, 360)
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -180)
MainFrame.BackgroundColor3 = Colors.Bg
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Parent = UI
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)
Instance.new("UIStroke", MainFrame).Color = Colors.Border

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 35)
Title.BackgroundTransparency = 1
Title.Text = "Violence District Hub <Ctgv-thw>"
Title.TextColor3 = Colors.Accent
Title.Font = Enum.Font.GothamBold
Title.TextSize = 12
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true
Title.Parent = MainFrame
Instance.new("UIPadding", Title).PaddingLeft = UDim.new(0, 10)
MakeDraggable(Title, MainFrame)

ToggleMenuBtn.MouseButton1Click:Connect(function() MainFrame.Visible = not MainFrame.Visible end)

local TabFrame = Instance.new("Frame")
TabFrame.Size = UDim2.new(1, 0, 0, 30)
TabFrame.Position = UDim2.new(0, 0, 0, 35)
TabFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
TabFrame.BorderSizePixel = 0
TabFrame.Parent = MainFrame

local TabWorld = Instance.new("TextButton", TabFrame)
TabWorld.Size = UDim2.new(0.5, 0, 1, 0)
TabWorld.Text = "🌍 WORLD"
TabWorld.Font = Enum.Font.GothamBold
TabWorld.TextSize = 12
TabWorld.TextColor3 = Color3.new(1, 1, 1)
TabWorld.BackgroundColor3 = Color3.fromRGB(60, 120, 180) 
TabWorld.BorderSizePixel = 0

local TabESP = Instance.new("TextButton", TabFrame)
TabESP.Size = UDim2.new(0.5, 0, 1, 0)
TabESP.Position = UDim2.new(0.5, 0, 0, 0)
TabESP.Text = "👁️ ESP (PLAYER)"
TabESP.Font = Enum.Font.GothamBold
TabESP.TextSize = 12
TabESP.TextColor3 = Color3.new(1, 1, 1)
TabESP.BackgroundColor3 = Color3.fromRGB(45, 45, 50) 
TabESP.BorderSizePixel = 0

local function createScroll(name)
    local Scroll = Instance.new("ScrollingFrame")
    Scroll.Name = name
    Scroll.Size = UDim2.new(1, -10, 1, -75)
    Scroll.Position = UDim2.new(0, 5, 0, 70)
    Scroll.BackgroundColor3 = Colors.Bg
    Scroll.BackgroundTransparency = 1
    Scroll.BorderSizePixel = 0
    Scroll.ScrollBarThickness = 5
    Scroll.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
    Scroll.Parent = MainFrame
    
    local Layout = Instance.new("UIListLayout")
    Layout.Padding = UDim.new(0, 7)
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Parent = Scroll
    Layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Scroll.CanvasSize = UDim2.new(0, 0, 0, Layout.AbsoluteContentSize.Y + 15) end)
    return Scroll
end

local WorldScroll = createScroll("WorldScroll")
local ESPScroll = createScroll("ESPScroll"); ESPScroll.Visible = false

TabWorld.Activated:Connect(function()
    WorldScroll.Visible = true; ESPScroll.Visible = false
    TabWorld.BackgroundColor3 = Color3.fromRGB(60, 120, 180); TabESP.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
end)
TabESP.Activated:Connect(function()
    WorldScroll.Visible = false; ESPScroll.Visible = true
    TabESP.BackgroundColor3 = Color3.fromRGB(60, 120, 180); TabWorld.BackgroundColor3 = Color3.fromRGB(45, 45, 50)
end)

local function CreateToggleButton(text, initialState, callback, parentFrame)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -15, 0, 32)
    btn.BackgroundColor3 = initialState and Colors.ElementActive or Colors.Element
    btn.Text = text .. (initialState and " [ON]" or " [OFF]")
    btn.TextColor3 = Colors.Text
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.Parent = parentFrame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", btn).Color = Colors.Border
    
    local state = initialState
    btn.MouseButton1Click:Connect(function()
        state = not state
        btn.BackgroundColor3 = state and Colors.ElementActive or Colors.Element
        btn.Text = text .. (state and " [ON]" or " [OFF]")
        pcall(callback, state)
    end)
    return btn
end

local function CreateButton(text, callback, parentFrame)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -15, 0, 32)
    btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    btn.Text = text
    btn.TextColor3 = Colors.Accent
    btn.Font = Enum.Font.GothamMedium
    btn.TextSize = 12
    btn.Parent = parentFrame
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

local function CreateTextBox(labelText, defaultValue, callback, parentFrame)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -15, 0, 32)
    container.BackgroundColor3 = Colors.Element
    container.Parent = parentFrame
    Instance.new("UICorner", container).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", container).Color = Colors.Border

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.65, 0, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText; label.TextColor3 = Colors.Text; label.Font = Enum.Font.GothamMedium; label.TextSize = 12
    label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = container

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.3, -10, 0.7, 0)
    box.Position = UDim2.new(0.7, 0, 0.15, 0)
    box.BackgroundColor3 = Colors.Bg; box.Text = tostring(defaultValue); box.TextColor3 = Colors.Accent
    box.Font = Enum.Font.GothamBold; box.TextSize = 12; box.ClearTextOnFocus = false; box.Parent = container
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", box).Color = Colors.Border

    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num and num > 0 then callback(num) else box.Text = tostring(defaultValue) end
    end)
end

local function CreateSplitControl(labelText, defaultValue, initialToggle, textCallback, toggleCallback, parentFrame)
    local container = Instance.new("Frame")
    container.Size = UDim2.new(1, -15, 0, 32)
    container.BackgroundTransparency = 1
    container.Parent = parentFrame

    local leftBox = Instance.new("Frame")
    leftBox.Size = UDim2.new(0.58, 0, 1, 0)
    leftBox.BackgroundColor3 = Colors.Element
    leftBox.Parent = container
    Instance.new("UICorner", leftBox).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", leftBox).Color = Colors.Border

    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0.55, 0, 1, 0)
    label.Position = UDim2.new(0, 8, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = labelText; label.TextColor3 = Colors.Text; label.Font = Enum.Font.GothamMedium
    label.TextSize = 11; label.TextXAlignment = Enum.TextXAlignment.Left; label.Parent = leftBox

    local box = Instance.new("TextBox")
    box.Size = UDim2.new(0.38, -4, 0.7, 0)
    box.Position = UDim2.new(0.6, 0, 0.15, 0)
    box.BackgroundColor3 = Colors.Bg; box.Text = tostring(defaultValue); box.TextColor3 = Colors.Accent
    box.Font = Enum.Font.GothamBold; box.TextSize = 11; box.ClearTextOnFocus = false; box.Parent = leftBox
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 4)
    Instance.new("UIStroke", box).Color = Colors.Border
    box.FocusLost:Connect(function()
        local num = tonumber(box.Text)
        if num and num > 0 then textCallback(num) else box.Text = tostring(defaultValue) end
    end)

    local state = initialToggle
    local rightBtn = Instance.new("TextButton")
    rightBtn.Size = UDim2.new(0.39, 0, 1, 0)
    rightBtn.Position = UDim2.new(0.61, 0, 0, 0)
    rightBtn.BackgroundColor3 = state and Colors.ElementActive or Colors.Element
    rightBtn.Text = state and "ON" or "OFF"
    rightBtn.TextColor3 = Colors.Text; rightBtn.Font = Enum.Font.GothamBold; rightBtn.TextSize = 11
    rightBtn.Parent = container
    Instance.new("UICorner", rightBtn).CornerRadius = UDim.new(0, 6)
    Instance.new("UIStroke", rightBtn).Color = Colors.Border
    rightBtn.MouseButton1Click:Connect(function()
        state = not state
        rightBtn.BackgroundColor3 = state and Colors.ElementActive or Colors.Element
        rightBtn.Text = state and "ON" or "OFF"
        pcall(toggleCallback, state)
    end)
    return {
        SetState = function(newState)
            state = newState
            rightBtn.BackgroundColor3 = state and Colors.ElementActive or Colors.Element
            rightBtn.Text = state and "ON" or "OFF"
            pcall(toggleCallback, state)
        end
    }
end

-- ==========================================
-- WORLD TAB SETUP
-- ==========================================
InitGeneratorESP()
CreateToggleButton("Outline Gens", false, function(s) outlineEnabled = s; UpdateGeneratorVisibility() end, WorldScroll)
CreateToggleButton("Distance Gens", false, function(s) distanceEnabled = s; UpdateGeneratorVisibility() end, WorldScroll)
CreateToggleButton("Fullbright", false, function(s) 
    fullbrightEnabled = s
    if not s then Lighting.Ambient = defaultLighting.Ambient; Lighting.ColorShift_Top = defaultLighting.ColorShift_Top; Lighting.ColorShift_Bottom = defaultLighting.ColorShift_Bottom; Lighting.OutdoorAmbient = defaultLighting.OutdoorAmbient; Lighting.ClockTime = defaultLighting.ClockTime end
end, WorldScroll)

local clearFogBtn = CreateButton("Xoá Sương Mù", function()
    ClearFogOnce(); clearFogBtn.Text = "Đã Xoá!"; clearFogBtn.TextColor3 = Color3.fromRGB(0, 255, 100)
    task.delay(1.5, function() if clearFogBtn then clearFogBtn.Text = "Xoá Sương Mù"; clearFogBtn.TextColor3 = Colors.Accent end end)
end, WorldScroll)

CreateTextBox("Cỡ chữ ESP:", currentTextSize, function(val) currentTextSize = val end, WorldScroll)
CreateButton("🔄 Load Generators Trên Map", function() InitGeneratorESP() end, WorldScroll)
CreateToggleButton("📌 Ghim Nút Tốc Độ Rời", false, function(s) FloatMoveBtn.Visible = s end, WorldScroll)

local speedControl = CreateSplitControl("Speed:", getgenv().Walkspeed, getgenv().loopW, 
    function(val) 
        getgenv().Walkspeed = tonumber(val) or 16
        if getgenv().loopW then
            local char = LocalPlayer.Character; local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = getgenv().Walkspeed end
        end
    end, 
    function(s) 
        getgenv().loopW = s 
        if not s then
            local char = LocalPlayer.Character; local hum = char and char:FindFirstChild("Humanoid")
            if hum then hum.WalkSpeed = 16 end
        end
    end, WorldScroll)

local tpWalkControl = CreateSplitControl("TP Walk:", getgenv().TPSpeed, getgenv().TPWalk, 
    function(val) getgenv().TPSpeed = tonumber(val) or 0.04 end, 
    function(s) 
        getgenv().TPWalk = s 
        if not s then
            local char = LocalPlayer.Character; local root = char and char:FindFirstChild("HumanoidRootPart")
            if root then root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0) end
        end
    end, WorldScroll)

local masterMoveState = false
FloatMoveBtn.MouseButton1Click:Connect(function()
    masterMoveState = not masterMoveState
    FloatMoveBtn.BackgroundColor3 = masterMoveState and Colors.ElementActive or Colors.Element
    FloatMoveBtn.Text = masterMoveState and "🏃 TỐC ĐỘ: BẬT" or "🏃 TỐC ĐỘ: TẮT"
    speedControl.SetState(masterMoveState); tpWalkControl.SetState(masterMoveState)
end)

-- ==========================================
-- ESP PLAYER TAB SETUP
-- ==========================================
CreateToggleButton("👥 ESP Box", PlayerESPSettings.BoxESP, function(s) PlayerESPSettings.BoxESP = s end, ESPScroll)
CreateToggleButton("👥 ESP Outline", PlayerESPSettings.OutlineESP, function(s) PlayerESPSettings.OutlineESP = s end, ESPScroll)
CreateToggleButton("👥 ESP Tracer (Line)", PlayerESPSettings.TracerESP, function(s) PlayerESPSettings.TracerESP = s end, ESPScroll)
CreateToggleButton("👥 ESP Name", PlayerESPSettings.ShowName, function(s) PlayerESPSettings.ShowName = s end, ESPScroll)
CreateToggleButton("👥 ESP Distance", PlayerESPSettings.ShowDistance, function(s) PlayerESPSettings.ShowDistance = s end, ESPScroll)
CreateToggleButton("👥 ESP Teammates", PlayerESPSettings.ESPTeammates, function(s) PlayerESPSettings.ESPTeammates = s end, ESPScroll)
CreateButton("🔄 Sửa Lỗi Tàng Hình Outline (Fix)", function() RebuildPlayerHighlights() end, ESPScroll)

local TargetStatus = Instance.new("TextLabel")
TargetStatus.Size = UDim2.new(1, -15, 0, 20)
TargetStatus.BackgroundTransparency = 1
TargetStatus.Text = "Đang chọn: TẤT CẢ (Global)"; TargetStatus.TextColor3 = Color3.fromRGB(255, 255, 0)
TargetStatus.Font = Enum.Font.GothamBold; TargetStatus.TextSize = 11; TargetStatus.Parent = ESPScroll

local SearchBox = Instance.new("TextBox")
SearchBox.Size = UDim2.new(1, -15, 0, 30)
SearchBox.BackgroundColor3 = Color3.fromRGB(45, 45, 45); SearchBox.TextColor3 = Color3.new(1, 1, 1)
SearchBox.PlaceholderText = "🔍 Tìm kiếm tên người chơi..."
SearchBox.Font = Enum.Font.Gotham; SearchBox.TextSize = 11; SearchBox.Parent = ESPScroll
Instance.new("UICorner", SearchBox).CornerRadius = UDim.new(0, 5)

local PListFrame = Instance.new("ScrollingFrame")
PListFrame.Size = UDim2.new(1, -15, 0, 90)
PListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
PListFrame.BorderSizePixel = 0; PListFrame.ScrollBarThickness = 4; PListFrame.Parent = ESPScroll
Instance.new("UICorner", PListFrame).CornerRadius = UDim.new(0, 5)

local PListLayout = Instance.new("UIListLayout")
PListLayout.Padding = UDim.new(0, 2); PListLayout.Parent = PListFrame
PListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() PListFrame.CanvasSize = UDim2.new(0, 0, 0, PListLayout.AbsoluteContentSize.Y) end)

local currentSearch = ""
local function SetTargetPlayer(name)
    SelectedPlayerName = name
    TargetStatus.Text = name and ("Đang chọn: " .. name) or "Đang chọn: TẤT CẢ (Global)"
    TargetStatus.TextColor3 = name and Color3.fromRGB(0, 255, 0) or Color3.fromRGB(255, 255, 0)
end

local function RefreshPlayerListUI()
    for _, v in pairs(PListFrame:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    
    local btnAll = Instance.new("TextButton", PListFrame)
    btnAll.Size = UDim2.new(1, 0, 0, 22)
    btnAll.Text = "[ TẤT CẢ MỌI NGƯỜI ]"
    btnAll.BackgroundColor3 = Color3.fromRGB(80, 80, 20); btnAll.TextColor3 = Color3.new(1, 1, 1)
    btnAll.Font = Enum.Font.GothamBold; btnAll.TextSize = 11; btnAll.BorderSizePixel = 0
    btnAll.MouseButton1Click:Connect(function() SetTargetPlayer(nil) end)

    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and (currentSearch == "" or string.find(string.lower(p.Name), currentSearch) or string.find(string.lower(p.DisplayName), currentSearch)) then
            local btn = Instance.new("TextButton", PListFrame)
            btn.Size = UDim2.new(1, 0, 0, 22)
            btn.Text = p.Name; btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45); btn.TextColor3 = Color3.new(1, 1, 1)
            btn.Font = Enum.Font.Gotham; btn.TextSize = 11; btn.BorderSizePixel = 0
            btn.MouseButton1Click:Connect(function() SetTargetPlayer(p.Name) end)
        end
    end
end
SearchBox:GetPropertyChangedSignal("Text"):Connect(function() currentSearch = string.lower(SearchBox.Text); RefreshPlayerListUI() end)
RefreshPlayerListUI()
table.insert(connections, Players.PlayerAdded:Connect(RefreshPlayerListUI))
table.insert(connections, Players.PlayerRemoving:Connect(RefreshPlayerListUI))

CreateButton("🗑️ Reset Màu ESP Về Mặc Định", function()
    if SelectedPlayerName then CustomPlayerColors[SelectedPlayerName] = nil else currentESPColor = nil; table.clear(CustomPlayerColors) end
end, ESPScroll)

local CListFrame = Instance.new("ScrollingFrame")
CListFrame.Size = UDim2.new(1, -15, 0, 70)
CListFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
CListFrame.BorderSizePixel = 0; CListFrame.ScrollBarThickness = 4; CListFrame.Parent = ESPScroll
Instance.new("UICorner", CListFrame).CornerRadius = UDim.new(0, 5)

local CListLayout = Instance.new("UIListLayout")
CListLayout.Padding = UDim.new(0, 2); CListLayout.Parent = CListFrame
CListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() CListFrame.CanvasSize = UDim2.new(0, 0, 0, CListLayout.AbsoluteContentSize.Y) end)

for _, cData in ipairs(colorOrder) do
    local btn = Instance.new("TextButton", CListFrame)
    btn.Size = UDim2.new(1, 0, 0, 22)
    btn.Text = cData.name; btn.BackgroundColor3 = cData.color
    btn.TextColor3 = (cData.color.R + cData.color.G + cData.color.B) / 3 > 0.5 and Color3.new(0,0,0) or Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamMedium; btn.TextSize = 11; btn.BorderSizePixel = 0
    btn.MouseButton1Click:Connect(function()
        if SelectedPlayerName then CustomPlayerColors[SelectedPlayerName] = cData.color else currentESPColor = cData.color; table.clear(CustomPlayerColors) end
    end)
end

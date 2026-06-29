--[[
    =========================================================
    🎵 ROBLOX MUSIC PLAYER & PLAYLIST (BATMAN GUI STYLE)
    👤 Cập nhật: Thêm bộ kiểm tra ID thông minh báo lỗi nếu nhạc hỏng
    =========================================================
]]

local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService") 

local Player = Players.LocalPlayer

-- ================= TÊN THƯ MỤC LƯU TRỮ =================
local FOLDER_NAME = "BatmanMusicHub"

-- ================= CƠ CHẾ BẢO VỆ UI & DỌN DẸP =================
local TargetGui = (gethui and pcall(gethui)) and gethui() or CoreGui
if TargetGui:FindFirstChild("BatmanMusicGUI") then
    TargetGui["BatmanMusicGUI"]:Destroy()
end

if getgenv()._MusicVisLoop then getgenv()._MusicVisLoop:Disconnect(); getgenv()._MusicVisLoop = nil end
if workspace:FindFirstChild("BatmanMusicPlayer") then workspace.BatmanMusicPlayer:Destroy() end

-- ================= KHỞI TẠO ÂM THANH =================
local sound = Instance.new("Sound")
sound.Name = "BatmanMusicPlayer"
sound.Parent = workspace
sound.Volume = 2
sound.Looped = true
sound.PlaybackSpeed = 1 

local savedSongs = {} 
local currentSpeedStep = 0.25 

-- ================= HÀM XỬ LÝ FOLDER & FILE =================
local function SanitizeFileName(name) return string.gsub(name, '[\\/:*?"<>|]', "_") end
local function InitFolder() if makefolder and not isfolder(FOLDER_NAME) then makefolder(FOLDER_NAME) end end
local function SaveSongToFile(name, id)
    InitFolder()
    if writefile then
        local safeName = SanitizeFileName(name)
        local path = FOLDER_NAME .. "/" .. safeName .. ".json"
        local data = HttpService:JSONEncode({Name = name, ID = id})
        pcall(function() writefile(path, data) end)
    end
end
local function DeleteSongFile(name)
    if delfile then
        local path = FOLDER_NAME .. "/" .. SanitizeFileName(name) .. ".json"
        if isfile and isfile(path) then pcall(function() delfile(path) end) end
    end
end

-- ================= HÀM HỖ TRỢ UI & MÀU SẮC SÓNG NHẠC =================
local function applyUICorner(instance, radius)
    local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, radius or 6); corner.Parent = instance
end
local function applyUIStroke(instance, color, thickness)
    local stroke = Instance.new("UIStroke"); stroke.Color = color or Color3.fromRGB(70, 70, 75); stroke.Thickness = thickness or 1.5; stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; stroke.Parent = instance
end
local function makeDraggable(dragObject, moveObject)
    local dragging, dragInput, dragStart, startPos
    dragObject.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true; dragStart = input.Position; startPos = moveObject.Position
            input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
        end
    end)
    dragObject.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            moveObject.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local function getHeightColor(height)
    local pct = math.clamp((height - 5) / 40, 0, 1) 
    if pct <= 0.5 then
        return Color3.fromRGB(0, 255, 150):Lerp(Color3.fromRGB(255, 220, 0), pct * 2)
    else
        return Color3.fromRGB(255, 220, 0):Lerp(Color3.fromRGB(255, 20, 20), (pct - 0.5) * 2)
    end
end

-- ================= XÂY DỰNG GIAO DIỆN CHÍNH =================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "BatmanMusicGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = TargetGui

local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0, 50, 0, 50)
ToggleBtn.Position = UDim2.new(0, 20, 0.5, -25)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
ToggleBtn.Text = "🎵"
ToggleBtn.TextSize = 26
ToggleBtn.Parent = ScreenGui
applyUICorner(ToggleBtn, 50)
applyUIStroke(ToggleBtn, Color3.fromRGB(0, 255, 150), 2)
makeDraggable(ToggleBtn, ToggleBtn)

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 0, 0, 0); MainFrame.AnchorPoint = Vector2.new(0.5, 0.5); MainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25); MainFrame.ClipsDescendants = true; MainFrame.Visible = false; MainFrame.Parent = ScreenGui
applyUICorner(MainFrame, 10); applyUIStroke(MainFrame, Color3.fromRGB(60, 60, 65), 1.5); makeDraggable(MainFrame, MainFrame)

local Title = Instance.new("TextLabel", MainFrame)
Title.Size = UDim2.new(1, 0, 0, 35); Title.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
Title.Text = "  🎵 MUSIC HUB <Ctgv-thw>"; Title.TextColor3 = Color3.fromRGB(255, 255, 255); Title.Font = Enum.Font.GothamBold; Title.TextSize = 13; Title.TextXAlignment = Enum.TextXAlignment.Left
applyUICorner(Title, 10); local tCover = Instance.new("Frame", Title); tCover.Size = UDim2.new(1,0,0,10); tCover.Position = UDim2.new(0,0,1,-10); tCover.BackgroundColor3 = Color3.fromRGB(35,35,40); tCover.BorderSizePixel = 0
makeDraggable(Title, MainFrame)

local TabBar = Instance.new("Frame", MainFrame)
TabBar.Size = UDim2.new(1, -30, 0, 30); TabBar.Position = UDim2.new(0, 15, 0, 45); TabBar.BackgroundTransparency = 1

local PlayerTabBtn = Instance.new("TextButton", TabBar)
PlayerTabBtn.Size = UDim2.new(0.48, 0, 1, 0); PlayerTabBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); PlayerTabBtn.Text = "▶ Nhạc"; PlayerTabBtn.TextColor3 = Color3.fromRGB(255, 255, 255); PlayerTabBtn.Font = Enum.Font.GothamBold; PlayerTabBtn.TextSize = 12; applyUICorner(PlayerTabBtn, 5)

local PlaylistTabBtn = Instance.new("TextButton", TabBar)
PlaylistTabBtn.Size = UDim2.new(0.48, 0, 1, 0); PlaylistTabBtn.Position = UDim2.new(0.52, 0, 0, 0); PlaylistTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); PlaylistTabBtn.Text = "📂 Lưu Nhạc"; PlaylistTabBtn.TextColor3 = Color3.fromRGB(180, 180, 180); PlaylistTabBtn.Font = Enum.Font.GothamBold; PlaylistTabBtn.TextSize = 12; applyUICorner(PlaylistTabBtn, 5)

local PageContainer = Instance.new("Frame", MainFrame)
PageContainer.Size = UDim2.new(1, 0, 1, -85); PageContainer.Position = UDim2.new(0, 0, 0, 85); PageContainer.BackgroundTransparency = 1

-- ================= TAB 1: PLAYER =================
local PlayerPage = Instance.new("Frame", PageContainer)
PlayerPage.Size = UDim2.new(1, 0, 1, 0); PlayerPage.BackgroundTransparency = 1; PlayerPage.Visible = true

local VisFrame = Instance.new("Frame", PlayerPage)
VisFrame.Size = UDim2.new(1, -30, 0, 45)
VisFrame.Position = UDim2.new(0, 15, 0, 0)
VisFrame.BackgroundTransparency = 1

local VisLayout = Instance.new("UIListLayout", VisFrame)
VisLayout.FillDirection = Enum.FillDirection.Horizontal; VisLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
VisLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
VisLayout.Padding = UDim.new(0, 2)

local bars = {}; local numBars = 36 
for i = 1, numBars do
    local bar = Instance.new("Frame", VisFrame)
    bar.Size = UDim2.new(0, 8, 0, 5)
    bar.BackgroundColor3 = Color3.fromRGB(0, 255, 150)
    bar.BorderSizePixel = 0
    applyUICorner(bar, 3)
    table.insert(bars, bar)
end

local ProgressBg = Instance.new("TextButton", PlayerPage)
ProgressBg.Size = UDim2.new(1, -30, 0, 8) 
ProgressBg.Position = UDim2.new(0, 15, 0, 50)
ProgressBg.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
ProgressBg.AutoButtonColor = false; ProgressBg.Text = ""; ProgressBg.BorderSizePixel = 0; applyUICorner(ProgressBg, 4)

local ProgressFill = Instance.new("Frame", ProgressBg)
ProgressFill.Size = UDim2.new(0, 0, 1, 0); ProgressFill.BackgroundColor3 = Color3.fromRGB(255, 0, 0); ProgressFill.BorderSizePixel = 0; applyUICorner(ProgressFill, 4)

local TimeLabel = Instance.new("TextLabel", PlayerPage)
TimeLabel.Size = UDim2.new(1, -30, 0, 15); TimeLabel.Position = UDim2.new(0, 15, 0, 62); TimeLabel.BackgroundTransparency = 1
TimeLabel.Text = "00:00 / 00:00"; TimeLabel.TextColor3 = Color3.fromRGB(180, 180, 180); TimeLabel.Font = Enum.Font.GothamMedium; TimeLabel.TextSize = 11; TimeLabel.TextXAlignment = Enum.TextXAlignment.Right

local SpeedFrame = Instance.new("Frame", PlayerPage)
SpeedFrame.Size = UDim2.new(0.5, -20, 0, 30); SpeedFrame.Position = UDim2.new(0, 15, 0, 90); SpeedFrame.BackgroundTransparency = 1

local SlowBtn = Instance.new("TextButton", SpeedFrame)
SlowBtn.Size = UDim2.new(0.2, 0, 1, 0); SlowBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55); SlowBtn.Text = "<<"; SlowBtn.TextColor3 = Color3.new(1,1,1); SlowBtn.Font = Enum.Font.GothamBold; SlowBtn.TextSize = 14; applyUICorner(SlowBtn, 5); applyUIStroke(SlowBtn)

local SpeedLabel = Instance.new("TextLabel", SpeedFrame)
SpeedLabel.Size = UDim2.new(0.56, 0, 1, 0); SpeedLabel.Position = UDim2.new(0.22, 0, 0, 0); SpeedLabel.BackgroundColor3 = Color3.fromRGB(30, 30, 35); SpeedLabel.Text = "Tốc độ: 1.00x"; SpeedLabel.TextColor3 = Color3.fromRGB(0, 255, 150); SpeedLabel.Font = Enum.Font.GothamBold; SpeedLabel.TextSize = 12; applyUICorner(SpeedLabel, 5); applyUIStroke(SpeedLabel)

local FastBtn = Instance.new("TextButton", SpeedFrame)
FastBtn.Size = UDim2.new(0.2, 0, 1, 0); FastBtn.Position = UDim2.new(0.8, 0, 0, 0); FastBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 55); FastBtn.Text = ">>"; FastBtn.TextColor3 = Color3.new(1,1,1); FastBtn.Font = Enum.Font.GothamBold; FastBtn.TextSize = 14; applyUICorner(FastBtn, 5); applyUIStroke(FastBtn)

local StepDropdownFrame = Instance.new("Frame", PlayerPage)
StepDropdownFrame.Size = UDim2.new(0.5, -20, 0, 70); StepDropdownFrame.Position = UDim2.new(0, 15, 0, 130); StepDropdownFrame.BackgroundTransparency = 1
local StepToggleBtn = Instance.new("TextButton", StepDropdownFrame)
StepToggleBtn.Size = UDim2.new(1, 0, 0, 25); StepToggleBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 50); StepToggleBtn.Text = "Mức nhảy: " .. currentSpeedStep .. " ▼"; StepToggleBtn.TextColor3 = Color3.new(1, 1, 1); StepToggleBtn.Font = Enum.Font.GothamBold; StepToggleBtn.TextSize = 11; applyUICorner(StepToggleBtn, 5); applyUIStroke(StepToggleBtn, Color3.fromRGB(80, 80, 85), 1)
local StepListScroll = Instance.new("ScrollingFrame", StepDropdownFrame)
StepListScroll.Size = UDim2.new(1, 0, 0, 35); StepListScroll.Position = UDim2.new(0, 0, 0, 30); StepListScroll.BackgroundTransparency = 1; StepListScroll.ScrollBarThickness = 3; StepListScroll.BorderSizePixel = 0; StepListScroll.Visible = false
local StepLayout = Instance.new("UIListLayout", StepListScroll)
StepLayout.FillDirection = Enum.FillDirection.Horizontal; StepLayout.SortOrder = Enum.SortOrder.LayoutOrder; StepLayout.Padding = UDim.new(0, 5); StepLayout.VerticalAlignment = Enum.VerticalAlignment.Center

local presetSpeeds = {"0.1", "0.5", "0.10", "0.15", "0.20", "0.25", "0.50"}
local stepButtons = {}
for _, v in ipairs(presetSpeeds) do
    local btn = Instance.new("TextButton", StepListScroll)
    btn.Size = UDim2.new(0, 40, 0, 25); btn.BackgroundColor3 = Color3.fromRGB(45, 45, 50); btn.Text = "+" .. v; btn.TextColor3 = Color3.fromRGB(220, 220, 220); btn.Font = Enum.Font.GothamBold; btn.TextSize = 11; applyUICorner(btn, 4); applyUIStroke(btn, Color3.fromRGB(80, 80, 85), 1)
    if tonumber(v) == currentSpeedStep then btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255) end
    table.insert(stepButtons, btn)
    btn.Activated:Connect(function()
        currentSpeedStep = tonumber(v)
        StepToggleBtn.Text = "Mức nhảy: " .. currentSpeedStep .. " ▲"
        for _, b in ipairs(stepButtons) do b.BackgroundColor3 = Color3.fromRGB(45, 45, 50) end
        btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    end)
end
StepLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() StepListScroll.CanvasSize = UDim2.new(0, StepLayout.AbsoluteContentSize.X, 0, 0) end)
StepToggleBtn.Activated:Connect(function() StepListScroll.Visible = not StepListScroll.Visible; StepToggleBtn.Text = "Mức nhảy: " .. currentSpeedStep .. (StepListScroll.Visible and " ▲" or " ▼") end)

local MusicBox = Instance.new("TextBox", PlayerPage)
MusicBox.Size = UDim2.new(0.5, -15, 0, 30); MusicBox.Position = UDim2.new(0.5, 5, 0, 90); MusicBox.BackgroundColor3 = Color3.fromRGB(30, 30, 35); MusicBox.TextColor3 = Color3.fromRGB(255, 255, 255); MusicBox.PlaceholderText = "NHẬP ID NHẠC..."; MusicBox.Font = Enum.Font.GothamBold; MusicBox.TextSize = 12; applyUICorner(MusicBox, 5); applyUIStroke(MusicBox)

local PlayBtn = Instance.new("TextButton", PlayerPage)
PlayBtn.Size = UDim2.new(0.23, 0, 0, 35); PlayBtn.Position = UDim2.new(0.5, 5, 0, 128); PlayBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80); PlayBtn.Text = "▶ PLAY"; PlayBtn.TextColor3 = Color3.fromRGB(255, 255, 255); PlayBtn.Font = Enum.Font.GothamBold; PlayBtn.TextSize = 12; applyUICorner(PlayBtn, 5)

local StopBtn = Instance.new("TextButton", PlayerPage)
StopBtn.Size = UDim2.new(0.23, 0, 0, 35); StopBtn.Position = UDim2.new(0.77, -15, 0, 128); StopBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50); StopBtn.Text = "⏹ STOP"; StopBtn.TextColor3 = Color3.fromRGB(255, 255, 255); StopBtn.Font = Enum.Font.GothamBold; StopBtn.TextSize = 12; applyUICorner(StopBtn, 5)

local LoopBtn = Instance.new("TextButton", PlayerPage)
LoopBtn.Size = UDim2.new(0.5, -15, 0, 25); LoopBtn.Position = UDim2.new(0.5, 5, 0, 172); LoopBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); LoopBtn.Text = "🔁 Lặp lại: BẬT"; LoopBtn.TextColor3 = Color3.new(1,1,1); LoopBtn.Font = Enum.Font.GothamBold; LoopBtn.TextSize = 11; applyUICorner(LoopBtn, 5)

local StatusLabel = Instance.new("TextLabel", PlayerPage)
StatusLabel.Size = UDim2.new(1, 0, 0, 15); StatusLabel.Position = UDim2.new(0, 0, 1, -20); StatusLabel.BackgroundTransparency = 1; StatusLabel.Text = "Trạng thái: Sẵn sàng"; StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150); StatusLabel.Font = Enum.Font.Gotham; StatusLabel.TextSize = 11

-- ================= TAB 2: PLAYLIST =================
local PlaylistPage = Instance.new("Frame", PageContainer)
PlaylistPage.Size = UDim2.new(1, 0, 1, 0); PlaylistPage.BackgroundTransparency = 1; PlaylistPage.Visible = false
local NameInput = Instance.new("TextBox", PlaylistPage)
NameInput.Size = UDim2.new(0.46, 0, 0, 30); NameInput.Position = UDim2.new(0, 15, 0, 0); NameInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35); NameInput.TextColor3 = Color3.new(1,1,1); NameInput.PlaceholderText = "Tên bài hát..."; NameInput.Font = Enum.Font.Gotham; NameInput.TextSize = 12; applyUICorner(NameInput, 5); applyUIStroke(NameInput)
local IDInput = Instance.new("TextBox", PlaylistPage)
IDInput.Size = UDim2.new(0.46, 0, 0, 30); IDInput.Position = UDim2.new(0.54, -15, 0, 0); IDInput.BackgroundColor3 = Color3.fromRGB(30, 30, 35); IDInput.TextColor3 = Color3.new(1,1,1); IDInput.PlaceholderText = "ID Nhạc..."; IDInput.Font = Enum.Font.Gotham; IDInput.TextSize = 12; applyUICorner(IDInput, 5); applyUIStroke(IDInput)
local SaveSongBtn = Instance.new("TextButton", PlaylistPage)
SaveSongBtn.Size = UDim2.new(1, -30, 0, 30); SaveSongBtn.Position = UDim2.new(0, 15, 0, 38); SaveSongBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 200); SaveSongBtn.Text = "💾 LƯU BÀI HÁT"; SaveSongBtn.TextColor3 = Color3.new(1,1,1); SaveSongBtn.Font = Enum.Font.GothamBold; SaveSongBtn.TextSize = 12; applyUICorner(SaveSongBtn, 5)
local ListScroll = Instance.new("ScrollingFrame", PlaylistPage)
ListScroll.Size = UDim2.new(1, -30, 1, -85); ListScroll.Position = UDim2.new(0, 15, 0, 75); ListScroll.BackgroundTransparency = 1; ListScroll.ScrollBarThickness = 4; ListScroll.BorderSizePixel = 0
local ListLayout = Instance.new("UIListLayout", ListScroll); ListLayout.SortOrder = Enum.SortOrder.LayoutOrder; ListLayout.Padding = UDim.new(0, 5)
ListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() ListScroll.CanvasSize = UDim2.new(0, 0, 0, ListLayout.AbsoluteContentSize.Y + 10) end)

-- ================= LOGIC CHUYỂN TAB & ẨN HIỆN GUI =================
local function switchTab(tab)
    if tab == "Player" then
        PlayerPage.Visible = true; PlaylistPage.Visible = false
        PlayerTabBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255); PlayerTabBtn.TextColor3 = Color3.new(1,1,1); PlaylistTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); PlaylistTabBtn.TextColor3 = Color3.fromRGB(180,180,180)
    else
        PlayerPage.Visible = false; PlaylistPage.Visible = true
        PlaylistTabBtn.BackgroundColor3 = Color3.fromRGB(150, 100, 200); PlaylistTabBtn.TextColor3 = Color3.new(1,1,1); PlayerTabBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 45); PlayerTabBtn.TextColor3 = Color3.fromRGB(180,180,180)
    end
end
PlayerTabBtn.Activated:Connect(function() switchTab("Player") end)
PlaylistTabBtn.Activated:Connect(function() switchTab("Playlist") end)

local isMenuOpen = false
ToggleBtn.MouseButton1Click:Connect(function()
    TweenService:Create(ToggleBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 40, 0, 40)}):Play()
    task.wait(0.1); TweenService:Create(ToggleBtn, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(0, 50, 0, 50)}):Play()
    isMenuOpen = not isMenuOpen
    if isMenuOpen then MainFrame.Visible = true; TweenService:Create(MainFrame, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.new(0, 480, 0, 300) }):Play()
    else
        local closeTween = TweenService:Create(MainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Size = UDim2.new(0, 0, 0, 0) })
        closeTween:Play(); closeTween.Completed:Wait(); if not isMenuOpen then MainFrame.Visible = false end
    end
end)

-- ================= LOGIC KÉO TUA NHẠC (SEEKING BAR) =================
local isDraggingProgress = false

local function updateSongPosition(input)
    if sound.IsLoaded and sound.TimeLength > 0 then
        local relativeX = math.clamp(input.Position.X - ProgressBg.AbsolutePosition.X, 0, ProgressBg.AbsoluteSize.X)
        local percent = relativeX / ProgressBg.AbsoluteSize.X
        sound.TimePosition = percent * sound.TimeLength
        ProgressFill.Size = UDim2.new(percent, 0, 1, 0)
    end
end

ProgressBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingProgress = true; updateSongPosition(input)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if isDraggingProgress and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        updateSongPosition(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        isDraggingProgress = false
    end
end)

-- ================= HỆ THỐNG KIỂM TRA & PHÁT NHẠC THÔNG MINH =================
local isChecking = false

local function PlayMusicWithCheck(id, songName)
    if isChecking then return end
    isChecking = true
    
    sound:Stop()
    sound.SoundId = "rbxassetid://" .. id
    
    -- Cập nhật thanh trạng thái báo đang load
    StatusLabel.Text = "⏳ Đang tải & kiểm tra " .. (songName and ("("..songName..")") or "ID: " .. id)
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0) -- Màu Vàng
    
    -- Chuyển về màn hình Player để người dùng xem kết quả
    switchTab("Player")
    MusicBox.Text = id 
    
    -- Tạo Thread riêng biệt để không làm đơ game trong lúc đợi tải nhạc
    task.spawn(function()
        local timeout = 4 -- Giới hạn chờ 4 giây
        local elapsed = 0
        
        -- Chờ âm thanh load xong
        while not sound.IsLoaded and elapsed < timeout do
            task.wait(0.2)
            elapsed = elapsed + 0.2
        end
        
        -- Sau khi tải xong (hoặc hết 4 giây), kiểm tra xem nhạc có độ dài không
        if sound.IsLoaded and sound.TimeLength > 0 then
            sound.TimePosition = 0
            sound:Play()
            StatusLabel.Text = "▶ Đang phát: " .. (songName or ("ID " .. id))
            StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 150) -- Xanh lá
        else
            -- Báo lỗi nếu ID sai, bị xóa, hoặc không công khai (Private)
            StatusLabel.Text = "❌ Lỗi: ID sai, bị xóa hoặc bị tác giả ẩn (Private)!"
            StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80) -- Đỏ
            sound:Stop()
        end
        
        isChecking = false
    end)
end

-- ================= GẮN NÚT ĐIỀU KHIỂN =================
local function setSpeed(newSpeed) newSpeed = math.clamp(newSpeed, 0.1, 10.0); sound.PlaybackSpeed = newSpeed; SpeedLabel.Text = string.format("Tốc độ: %.2fx", newSpeed) end
SlowBtn.Activated:Connect(function() setSpeed(sound.PlaybackSpeed - currentSpeedStep) end)
FastBtn.Activated:Connect(function() setSpeed(sound.PlaybackSpeed + currentSpeedStep) end)

LoopBtn.Activated:Connect(function()
    sound.Looped = not sound.Looped
    if sound.Looped then
        LoopBtn.Text = "🔁 Lặp lại: BẬT"; LoopBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    else
        LoopBtn.Text = "🔁 Lặp lại: TẮT"; LoopBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 85)
    end
end)

PlayBtn.MouseButton1Click:Connect(function()
    local id = MusicBox.Text:match("%d+") 
    if id then
        PlayMusicWithCheck(id, nil)
    else
        StatusLabel.Text = "❌ Vui lòng nhập đúng ID số!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
    end
end)

StopBtn.MouseButton1Click:Connect(function()
    sound:Stop()
    StatusLabel.Text = "Trạng thái: Đã dừng"
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    ProgressFill.Size = UDim2.new(0, 0, 1, 0)
end)

sound.Ended:Connect(function()
    if not sound.Looped then
        StatusLabel.Text = "Trạng thái: Đã tắt (Hát hết bài)"
        StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
        ProgressFill.Size = UDim2.new(0, 0, 1, 0)
    end
end)

-- ================= TẠO & LƯU BÀI HÁT =================
local function createSongRow(name, id)
    local Row = Instance.new("Frame", ListScroll); Row.Size = UDim2.new(1, -6, 0, 35); Row.BackgroundColor3 = Color3.fromRGB(40, 40, 45); applyUICorner(Row, 5); applyUIStroke(Row, Color3.fromRGB(60,60,65), 1)
    local lbl = Instance.new("TextLabel", Row); lbl.Size = UDim2.new(0.65, 0, 1, 0); lbl.Position = UDim2.new(0, 10, 0, 0); lbl.BackgroundTransparency = 1; lbl.Text = name; lbl.TextColor3 = Color3.new(1,1,1); lbl.Font = Enum.Font.GothamMedium; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.TextTruncate = Enum.TextTruncate.AtEnd
    local PlayRowBtn = Instance.new("TextButton", Row); PlayRowBtn.Size = UDim2.new(0, 25, 0, 25); PlayRowBtn.Position = UDim2.new(1, -60, 0.5, -12.5); PlayRowBtn.BackgroundColor3 = Color3.fromRGB(40, 150, 80); PlayRowBtn.Text = "▶"; PlayRowBtn.TextColor3 = Color3.new(1,1,1); applyUICorner(PlayRowBtn, 5)
    local DelRowBtn = Instance.new("TextButton", Row); DelRowBtn.Size = UDim2.new(0, 25, 0, 25); DelRowBtn.Position = UDim2.new(1, -30, 0.5, -12.5); DelRowBtn.BackgroundColor3 = Color3.fromRGB(180, 50, 50); DelRowBtn.Text = "X"; DelRowBtn.TextColor3 = Color3.new(1,1,1); applyUICorner(DelRowBtn, 5)

    -- Đã cập nhật nút Play ở list sử dụng chung hàm kiểm tra
    PlayRowBtn.Activated:Connect(function() PlayMusicWithCheck(id, name) end)
    
    DelRowBtn.Activated:Connect(function() savedSongs[tostring(id)] = nil; Row:Destroy(); DeleteSongFile(name) end)
end

SaveSongBtn.Activated:Connect(function()
    local name = NameInput.Text; local id = IDInput.Text:match("%d+")
    if not id then SaveSongBtn.Text = "❌ LỖI: CẦN ID SỐ"; task.wait(1); SaveSongBtn.Text = "💾 LƯU BÀI HÁT"; return end
    if name == "" then name = "Nhạc " .. id end
    if not savedSongs[tostring(id)] then
        savedSongs[tostring(id)] = name; createSongRow(name, tostring(id)); SaveSongToFile(name, tostring(id))
        NameInput.Text = ""; IDInput.Text = ""; SaveSongBtn.Text = "✅ ĐÃ LƯU VÀO MÁY"; task.wait(1); SaveSongBtn.Text = "💾 LƯU BÀI HÁT"
    else SaveSongBtn.Text = "⚠️ BÀI NÀY ĐÃ LƯU RỒI"; task.wait(1); SaveSongBtn.Text = "💾 LƯU BÀI HÁT" end
end)

local function LoadAllSongsFromFolder()
    if isfolder and isfolder(FOLDER_NAME) and listfiles then
        for _, filePath in ipairs(listfiles(FOLDER_NAME)) do
            if string.match(filePath, "%.json$") then
                local success, content = pcall(function() return readfile(filePath) end)
                if success then
                    local s2, data = pcall(function() return HttpService:JSONDecode(content) end)
                    if s2 and data.Name and data.ID then
                        if not savedSongs[tostring(data.ID)] then savedSongs[tostring(data.ID)] = data.Name; createSongRow(data.Name, tostring(data.ID)) end
                    end
                end
            end
        end
    end
end
LoadAllSongsFromFolder()

-- ================= HÀM FORMAT THỜI GIAN =================
local function FormatTime(seconds)
    if not seconds or math.isnan(seconds) then return "00:00" end
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%02d:%02d", m, s)
end

-- ================= MẢNG LƯU TRỮ LỊCH SỬ ÂM THANH =================
local MAX_HISTORY = 20
local loudnessHistory = {}
for i = 1, MAX_HISTORY do
    table.insert(loudnessHistory, 0)
end

-- ================= VÒNG LẶP VISUALIZER & THANH THỜI GIAN =================
getgenv()._MusicVisLoop = RunService.RenderStepped:Connect(function()
    -- 1. CẬP NHẬT THANH THỜI GIAN & TEXT
    if sound.IsLoaded and sound.TimeLength > 0 then
        if not isDraggingProgress then
            local percent = math.clamp(sound.TimePosition / sound.TimeLength, 0, 1)
            ProgressFill.Size = UDim2.new(percent, 0, 1, 0)
        end
        TimeLabel.Text = FormatTime(sound.TimePosition) .. " / " .. FormatTime(sound.TimeLength)
    else
        if not isDraggingProgress then ProgressFill.Size = UDim2.new(0, 0, 1, 0) end
        TimeLabel.Text = "00:00 / 00:00"
    end

    -- 2. CẬP NHẬT LỊCH SỬ ÂM LƯỢNG
    table.insert(loudnessHistory, 1, sound.PlaybackLoudness)
    if #loudnessHistory > MAX_HISTORY then 
        table.remove(loudnessHistory, MAX_HISTORY + 1) 
    end

    -- 3. ĐIỀU CHỈNH SÓNG NHẠC
    for i, bar in ipairs(bars) do
        local dist = math.max(0, math.abs(i - 18.5) - 1.5)
        local histIndex = math.clamp(math.floor(dist) + 1, 1, MAX_HISTORY)
        local barLoudness = loudnessHistory[histIndex] or 0
        local damping = 1 - (dist / 18) * 0.25 
        local noise = math.random(90, 110) / 100
        local targetHeight = 5 + (barLoudness / 5.5) * damping * noise
        targetHeight = math.clamp(targetHeight, 5, 45) 
        
        local currentHeight = bar.Size.Y.Offset
        local newHeight = currentHeight + (targetHeight - currentHeight) * 0.35
        bar.Size = UDim2.new(0, 8, 0, newHeight)
        bar.BackgroundColor3 = getHeightColor(newHeight)
    end
end)

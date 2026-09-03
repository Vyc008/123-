local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

-- Xóa script cũ nếu chạy lại
local existing = LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("UIEditor_WuW")
if existing then existing:Destroy() end

local SAVE_FILE = "WuW_UISave_" .. game.PlaceId .. ".json"
local modifiedUIs = {}

-- ==========================================
-- 1. TẠO GIAO DIỆN CÔNG CỤ
-- ==========================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UIEditor_WuW"
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Global
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999999

-- Khung Aura
local AuraFrame = Instance.new("Frame")
AuraFrame.Name = "AuraFrame"
AuraFrame.Parent = ScreenGui
AuraFrame.BackgroundTransparency = 1
AuraFrame.Visible = false
AuraFrame.ZIndex = 99999
AuraFrame.Interactable = false

local AuraStroke = Instance.new("UIStroke")
AuraStroke.Parent = AuraFrame
AuraStroke.Color = Color3.fromRGB(0, 255, 255)
AuraStroke.Thickness = 3

local AuraCorner = Instance.new("UICorner")
AuraCorner.Parent = AuraFrame
AuraCorner.CornerRadius = UDim.new(0, 0)

-- Nút mở lại menu
local ShowMenuBtn = Instance.new("TextButton")
ShowMenuBtn.Parent = ScreenGui
ShowMenuBtn.Position = UDim2.new(0.5, -40, 0, 10)
ShowMenuBtn.Size = UDim2.new(0, 80, 0, 30)
ShowMenuBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ShowMenuBtn.Text = "MỞ MENU"
ShowMenuBtn.TextColor3 = Color3.fromRGB(0, 255, 255)
ShowMenuBtn.Font = Enum.Font.SourceSansBold
ShowMenuBtn.TextSize = 14
ShowMenuBtn.Visible = false
ShowMenuBtn.BackgroundTransparency = 0.3
Instance.new("UICorner", ShowMenuBtn).CornerRadius = UDim.new(0, 8)

-- Bảng Menu Chính
local MainFrame = Instance.new("Frame")
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
MainFrame.Position = UDim2.new(0.5, -90, 0, 40)
MainFrame.Size = UDim2.new(0, 180, 0, 180)
MainFrame.Active = true

local MainStroke = Instance.new("UIStroke")
MainStroke.Parent = MainFrame
MainStroke.Color = Color3.fromRGB(255, 255, 255)
MainStroke.Thickness = 2

-- Thanh tiêu đề
local TitleBar = Instance.new("TextLabel")
TitleBar.Parent = MainFrame
TitleBar.BackgroundTransparency = 1
TitleBar.Size = UDim2.new(1, -30, 0, 30)
TitleBar.Font = Enum.Font.SourceSansBold
TitleBar.Text = " CÔNG CỤ SỬA NÚT"
TitleBar.TextColor3 = Color3.fromRGB(255, 255, 0)
TitleBar.TextSize = 16
TitleBar.TextXAlignment = Enum.TextXAlignment.Left

-- Nút Ẩn
local HideBtn = Instance.new("TextButton")
HideBtn.Parent = MainFrame
HideBtn.BackgroundTransparency = 1
HideBtn.Position = UDim2.new(1, -30, 0, 0)
HideBtn.Size = UDim2.new(0, 30, 0, 30)
HideBtn.Font = Enum.Font.SourceSansBold
HideBtn.Text = "-"
HideBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
HideBtn.TextSize = 24

local ToggleEditBtn = Instance.new("TextButton")
ToggleEditBtn.Parent = MainFrame
ToggleEditBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
ToggleEditBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
ToggleEditBtn.Size = UDim2.new(0.9, 0, 0, 30)
ToggleEditBtn.Font = Enum.Font.SourceSansBold
ToggleEditBtn.Text = "BẬT CHỈNH SỬA"
ToggleEditBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
ToggleEditBtn.TextSize = 14

-- Slider
local SliderLabel = Instance.new("TextLabel")
SliderLabel.Parent = MainFrame
SliderLabel.BackgroundTransparency = 1
SliderLabel.Position = UDim2.new(0.05, 0, 0.4, 0)
SliderLabel.Size = UDim2.new(0.9, 0, 0, 20)
SliderLabel.Font = Enum.Font.SourceSansBold
SliderLabel.Text = "Kích thước: 100%"
SliderLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
SliderLabel.TextSize = 13

local SliderBar = Instance.new("Frame")
SliderBar.Parent = MainFrame
SliderBar.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
SliderBar.Position = UDim2.new(0.05, 0, 0.52, 0)
SliderBar.Size = UDim2.new(0.9, 0, 0, 8)

local SliderKnob = Instance.new("TextButton")
SliderKnob.Parent = SliderBar
SliderKnob.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
SliderKnob.Position = UDim2.new(0.25, 0, 0.5, 0)
SliderKnob.Size = UDim2.new(0, 14, 0, 20)
SliderKnob.AnchorPoint = Vector2.new(0.5, 0.5)
SliderKnob.Text = ""

-- Nút LƯU & TẢI
local originalSaveColor = Color3.fromRGB(50, 100, 200)
local SaveBtn = Instance.new("TextButton")
SaveBtn.Parent = MainFrame
SaveBtn.BackgroundColor3 = originalSaveColor
SaveBtn.Position = UDim2.new(0.05, 0, 0.65, 0)
SaveBtn.Size = UDim2.new(0.42, 0, 0, 30)
SaveBtn.Font = Enum.Font.SourceSansBold
SaveBtn.Text = "LƯU UI"
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.TextSize = 13

local LoadBtn = Instance.new("TextButton")
LoadBtn.Parent = MainFrame
LoadBtn.BackgroundColor3 = Color3.fromRGB(200, 100, 50)
LoadBtn.Position = UDim2.new(0.53, 0, 0.65, 0)
LoadBtn.Size = UDim2.new(0.42, 0, 0, 30)
LoadBtn.Font = Enum.Font.SourceSansBold
LoadBtn.Text = "TẢI UI"
LoadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadBtn.TextSize = 13

local StatusLog = Instance.new("TextLabel")
StatusLog.Parent = MainFrame
StatusLog.BackgroundTransparency = 1
StatusLog.Position = UDim2.new(0.05, 0, 0.85, 0)
StatusLog.Size = UDim2.new(0.9, 0, 0, 20)
StatusLog.Font = Enum.Font.SourceSans
StatusLog.Text = "Sẵn sàng!"
StatusLog.TextColor3 = Color3.fromRGB(150, 255, 150)
StatusLog.TextSize = 12

local connections = {}

-- ==========================================
-- 2. KÉO MENU
-- ==========================================
local isDraggingMenu = false
local dragMenuStartPos = nil
local dragMenuInputStart = nil

table.insert(connections, TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDraggingMenu = true
		dragMenuStartPos = MainFrame.Position
		dragMenuInputStart = input.Position
	end
end))

table.insert(connections, TitleBar.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDraggingMenu = false
	end
end))

table.insert(connections, HideBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = false
	ShowMenuBtn.Visible = true
	if isEditing then ToggleEditBtn.MouseButton1Click:Fire() end 
end))

table.insert(connections, ShowMenuBtn.MouseButton1Click:Connect(function()
	MainFrame.Visible = true
	ShowMenuBtn.Visible = false
end))

-- ==========================================
-- 3. LOGIC LƯU VÀ TẢI SETTINGS (CÓ XÁC NHẬN)
-- ==========================================
local function saveSettings()
	local dataToSave = {}
	for uiElement, data in pairs(modifiedUIs) do
		if uiElement and uiElement.Parent then
			local id = uiElement.Parent.Name .. "_" .. uiElement.Name
			local scale = 1
			local uiScale = uiElement:FindFirstChildOfClass("UIScale")
			if uiScale then scale = uiScale.Scale end
			
			dataToSave[id] = {
				Pos = {uiElement.Position.X.Scale, uiElement.Position.X.Offset, uiElement.Position.Y.Scale, uiElement.Position.Y.Offset},
				Scale = scale
			}
		end
	end
	
	if writefile then
		pcall(function()
			writefile(SAVE_FILE, HttpService:JSONEncode(dataToSave))
			StatusLog.Text = "Đã lưu thành công!"
		end)
	else
		StatusLog.Text = "Lỗi: Executor ko hỗ trợ"
	end
end

-- LOGIC NÚT LƯU UI (XÁC NHẬN 2 LẦN)
local isConfirmingSave = false
local saveResetThread = nil

table.insert(connections, SaveBtn.MouseButton1Click:Connect(function()
	if not isConfirmingSave then
		-- Lần 1: Yêu cầu xác nhận
		isConfirmingSave = true
		SaveBtn.Text = "XÁC NHẬN?"
		SaveBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Đổi thành màu đỏ
		
		-- Hủy bỏ bộ đếm lùi cũ nếu có
		if saveResetThread then task.cancel(saveResetThread) end
		
		-- Sau 3 giây nếu không ấn lần 2 thì reset lại nút
		saveResetThread = task.delay(3, function()
			isConfirmingSave = false
			SaveBtn.Text = "LƯU UI"
			SaveBtn.BackgroundColor3 = originalSaveColor
		end)
	else
		-- Lần 2: Thực thi lệnh lưu
		if saveResetThread then task.cancel(saveResetThread) end
		isConfirmingSave = false
		
		saveSettings() -- Gọi hàm lưu data
		
		SaveBtn.Text = "OK!"
		SaveBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Đổi màu xanh lá báo thành công
		
		-- Trả lại nút bình thường sau 1.5 giây
		task.delay(1.5, function()
			SaveBtn.Text = "LƯU UI"
			SaveBtn.BackgroundColor3 = originalSaveColor
		end)
	end
end))

-- LOGIC NÚT TẢI UI
local function loadSettings()
	if not isfile or not readfile or not isfile(SAVE_FILE) then
		StatusLog.Text = "Không tìm thấy file!"
		return
	end
	
	pcall(function()
		local dataToLoad = HttpService:JSONDecode(readfile(SAVE_FILE))
		local appliedCount = 0
		
		for _, gui in ipairs(LocalPlayer.PlayerGui:GetDescendants()) do
			if gui:IsA("GuiObject") and gui.Parent then
				local id = gui.Parent.Name .. "_" .. gui.Name
				if dataToLoad[id] then
					gui.Position = UDim2.new(dataToLoad[id].Pos[1], dataToLoad[id].Pos[2], dataToLoad[id].Pos[3], dataToLoad[id].Pos[4])
					local uiScale = gui:FindFirstChildOfClass("UIScale")
					if not uiScale then
						uiScale = Instance.new("UIScale")
						uiScale.Parent = gui
					end
					uiScale.Scale = dataToLoad[id].Scale
					modifiedUIs[gui] = true
					appliedCount = appliedCount + 1
				end
			end
		end
		StatusLog.Text = "Đã tải " .. appliedCount .. " nút!"
	end)
end

table.insert(connections, LoadBtn.MouseButton1Click:Connect(loadSettings))

-- ==========================================
-- 4. LOGIC ĐIỀU KHIỂN & KÉO THẢ NÚT
-- ==========================================
local isEditing = false
local selectedUI = nil
local isDraggingUI = false
local isDraggingSlider = false
local dragStartPos = nil
local inputStartPos = nil

local function updateSliderVisuals(scale)
	local percent = math.clamp((scale - 0.5) / 2.0, 0, 1)
	SliderKnob.Position = UDim2.new(percent, 0, 0.5, 0)
	SliderLabel.Text = "Kích thước: " .. math.floor(scale * 100) .. "%"
end

table.insert(connections, ToggleEditBtn.MouseButton1Click:Connect(function()
	isEditing = not isEditing
	if isEditing then
		ToggleEditBtn.Text = "ĐANG SỬA (BẤM GHIM)"
		ToggleEditBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		MainStroke.Color = Color3.fromRGB(255, 0, 0)
	else
		ToggleEditBtn.Text = "BẬT CHỈNH SỬA"
		ToggleEditBtn.BackgroundColor3 = Color3.fromRGB(50, 150, 50)
		MainStroke.Color = Color3.fromRGB(255, 255, 255)
		selectedUI = nil
		isDraggingUI = false
	end
end))

table.insert(connections, UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		local inputPos = input.Position
		
		if isEditing then
			local sliderPos = SliderBar.AbsolutePosition
			local sliderSize = SliderBar.AbsoluteSize
			if inputPos.X >= sliderPos.X - 10 and inputPos.X <= sliderPos.X + sliderSize.X + 10 and
			   inputPos.Y >= sliderPos.Y - 15 and inputPos.Y <= sliderPos.Y + sliderSize.Y + 15 then
				if selectedUI and selectedUI.Parent then isDraggingSlider = true end
				return
			end

			if not isDraggingMenu then
				local guisAtPosition = LocalPlayer.PlayerGui:GetGuiObjectsAtPosition(inputPos.X, inputPos.Y)
				local foundUI = false
				
				for _, gui in ipairs(guisAtPosition) do
					if not gui:IsDescendantOf(ScreenGui) and gui.AbsoluteSize.X < workspace.CurrentCamera.ViewportSize.X * 0.8 then
						selectedUI = gui
						isDraggingUI = true
						dragStartPos = gui.Position
						inputStartPos = inputPos
						foundUI = true
						modifiedUIs[gui] = true 
						
						local uiScale = gui:FindFirstChildOfClass("UIScale")
						updateSliderVisuals(uiScale and uiScale.Scale or 1)
						break
					end
				end
				
				if not foundUI then selectedUI = nil end
			end
		end
	end
end))

table.insert(connections, UserInputService.InputChanged:Connect(function(input, gameProcessed)
	if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
		
		if isDraggingMenu then
			local delta = input.Position - dragMenuInputStart
			MainFrame.Position = UDim2.new(
				dragMenuStartPos.X.Scale, dragMenuStartPos.X.Offset + delta.X,
				dragMenuStartPos.Y.Scale, dragMenuStartPos.Y.Offset + delta.Y
			)
			return
		end

		if not isEditing then return end
		
		if isDraggingUI and selectedUI and selectedUI.Parent then
			local delta = input.Position - inputStartPos
			selectedUI.Position = UDim2.new(
				dragStartPos.X.Scale, dragStartPos.X.Offset + delta.X,
				dragStartPos.Y.Scale, dragStartPos.Y.Offset + delta.Y
			)
		end
		
		if isDraggingSlider and selectedUI and selectedUI.Parent then
			local mouseX = input.Position.X
			local barPos = SliderBar.AbsolutePosition.X
			local barSize = SliderBar.AbsoluteSize.X
			local percent = math.clamp((mouseX - barPos) / barSize, 0, 1)
			
			local scaleValue = 0.5 + (percent * 2.0) 
			updateSliderVisuals(scaleValue)
			
			local uiScale = selectedUI:FindFirstChildOfClass("UIScale")
			if not uiScale then
				uiScale = Instance.new("UIScale")
				uiScale.Parent = selectedUI
			end
			uiScale.Scale = scaleValue
		end
	end
end))

table.insert(connections, UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
		isDraggingUI = false
		isDraggingSlider = false
		isDraggingMenu = false
	end
end))

-- Hiệu ứng Aura bám sát
table.insert(connections, RunService.RenderStepped:Connect(function()
	if isEditing and selectedUI and selectedUI.Parent then
		AuraFrame.Visible = true
		local pulse = (math.sin(time() * 5) + 1) / 2
		AuraStroke.Transparency = 0.2 + (pulse * 0.4)
		AuraFrame.Size = UDim2.new(0, selectedUI.AbsoluteSize.X, 0, selectedUI.AbsoluteSize.Y)
		AuraFrame.Position = UDim2.new(0, selectedUI.AbsolutePosition.X, 0, selectedUI.AbsolutePosition.Y)
		AuraFrame.AnchorPoint = Vector2.new(0, 0)
		
		local targetCorner = selectedUI:FindFirstChildOfClass("UICorner")
		if targetCorner then
			AuraCorner.CornerRadius = targetCorner.CornerRadius
		else
			AuraCorner.CornerRadius = UDim.new(0, 0)
		end
	else
		AuraFrame.Visible = false
	end
end))

-- Ngắt sự kiện quét khi GUI bị tắt
ScreenGui.AncestryChanged:Connect(function(_, parent)
	if not parent then
		for _, conn in pairs(connections) do
			if conn.Disconnect then conn:Disconnect() end
		end
	end
end)

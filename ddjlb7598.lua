-- 卡密验证系统（Roblox修正版）
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ======================== 配置区域 ========================
local CONFIG = {
    -- 有效卡密列表（可替换为远程获取，此处为本地示例）
    VALID_KEYS = {
        "WINTER_2025_VIP",
        "ROBLOX_SCRIPT_001",
        "ADMIN_TEST_KEY"
    },
    -- 最大验证尝试次数
    MAX_ATTEMPTS = 3,
    -- 验证成功后执行的脚本（替换为你的目标脚本）
    TARGET_SCRIPT_URL = "https://raw.githubusercontent.com/tfcygvunbind/Apple/main/%E9%BB%91%E7%99%BD%E8%84%9A%E6%9C%AC%E6%9C%80%E6%96%B0"
}

-- ======================== Roblox DataStore存储功能 ========================
local AuthDataStore = DataStoreService:GetDataStore("KeyAuthSystem")

-- 保存授权状态
local function SaveAuthStatus()
    local success, errorMessage = pcall(function()
        local authData = {
            PlayerName = player.Name,
            UserId = player.UserId,
            Authorized = true,
            AuthTime = os.time(),
            ExpireTime = os.time() + 86400 * 7 -- 授权有效期7天
        }
        AuthDataStore:SetAsync(tostring(player.UserId), authData)
    end)
    
    if not success then
        warn("[卡密系统] 保存授权状态失败: " .. tostring(errorMessage))
        return false
    end
    return true
end

-- 读取授权状态
local function LoadAuthStatus()
    local success, data = pcall(function()
        return AuthDataStore:GetAsync(tostring(player.UserId))
    end)
    
    if success and data then
        -- 检查授权是否未过期且玩家信息匹配
        local isNotExpired = data.ExpireTime and data.ExpireTime > os.time()
        local playerMatches = data.UserId == player.UserId
        
        if data.Authorized and isNotExpired and playerMatches then
            print("[卡密系统] 找到有效授权记录")
            return true
        else
            print("[卡密系统] 授权已过期或信息不匹配")
            return false
        end
    else
        print("[卡密系统] 无授权记录或读取失败")
        return false
    end
end

-- ======================== UI创建 ========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KeyAuthUI"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false

-- 主窗口（支持拖拽）
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
MainFrame.Position = UDim2.new(0.5, -130, 0.5, -80)
MainFrame.Size = UDim2.new(0, 260, 0, 160)
MainFrame.BackgroundTransparency = 0.1
MainFrame.Visible = false
MainFrame.Active = true
MainFrame.Draggable = true

-- 圆角效果
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- 标题栏
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(30, 40, 60)
TitleBar.Size = UDim2.new(1, 0, 0, 30)

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "TitleLabel"
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.Text = "卡密验证系统"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.SourceSansBold

-- 关闭按钮
local CloseBtn = Instance.new("TextButton")
CloseBtn.Name = "CloseBtn"
CloseBtn.Parent = TitleBar
CloseBtn.BackgroundTransparency = 1
CloseBtn.Position = UDim2.new(0.9, 0, 0, 0)
CloseBtn.Size = UDim2.new(0.1, 0, 1, 0)
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
CloseBtn.TextSize = 18
CloseBtn.Font = Enum.Font.SourceSansBold

-- 卡密输入框
local KeyInput = Instance.new("TextBox")
KeyInput.Name = "KeyInput"
KeyInput.Parent = MainFrame
KeyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
KeyInput.Position = UDim2.new(0.05, 0, 0.25, 0)
KeyInput.Size = UDim2.new(0.9, 0, 0, 40)
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.PlaceholderText = "输入卡密（区分大小写）"
KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
KeyInput.TextSize = 14
KeyInput.ClearTextOnFocus = false

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = KeyInput

-- 验证按钮
local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Name = "VerifyBtn"
VerifyBtn.Parent = MainFrame
VerifyBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
VerifyBtn.Position = UDim2.new(0.1, 0, 0.6, 0)
VerifyBtn.Size = UDim2.new(0.8, 0, 0, 35)
VerifyBtn.Text = "验证并进入"
VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.TextSize = 14
VerifyBtn.Font = Enum.Font.SourceSansBold

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 6)
ButtonCorner.Parent = VerifyBtn

-- 状态提示
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.85, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Text = "请输入卡密进行验证"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.SourceSans

-- ======================== 核心验证逻辑 ========================
local errorCount = 0
local isAuthorized = LoadAuthStatus()

-- 输入清理函数
local function SanitizeInput(input)
    return string.gsub(input, "%s+", "") -- 去除所有空格
end

-- 执行目标脚本
local function ExecuteTargetScript()
    local success, errorMessage = pcall(function()
        local scriptContent = game:HttpGet(CONFIG.TARGET_SCRIPT_URL, true)
        local loadedFunction = loadstring(scriptContent)
        if loadedFunction then
            loadedFunction()
            return true
        else
            return false
        end
    end)
    
    if not success then
        warn("[卡密系统] 脚本执行失败: " .. tostring(errorMessage))
        StatusLabel.Text = "脚本加载失败，但验证成功"
        StatusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
    else
        print("[卡密系统] 目标脚本执行成功")
    end
end

-- 验证卡密
local function VerifyKey(inputKey)
    local cleanKey = SanitizeInput(inputKey)
    
    for _, validKey in ipairs(CONFIG.VALID_KEYS) do
        if cleanKey == validKey then
            return true
        end
    end
    return false
end

-- 验证按钮点击事件
VerifyBtn.MouseButton1Click:Connect(function()
    local inputKey = KeyInput.Text
    
    if errorCount >= CONFIG.MAX_ATTEMPTS then
        StatusLabel.Text = "尝试次数已达上限！"
        StatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
        task.wait(1)
        player:Kick("多次输入错误卡密，请稍后再试")
        return
    end

    if string.len(SanitizeInput(inputKey)) == 0 then
        StatusLabel.Text = "请输入有效的卡密"
        StatusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
        return
    end

    if VerifyKey(inputKey) then
        -- 验证成功
        local saveSuccess = SaveAuthStatus()
        isAuthorized = true
        StatusLabel.Text = "验证成功！正在加载..."
        StatusLabel.TextColor3 = Color3.fromRGB(34, 197, 94)
        VerifyBtn.Text = "加载中..."
        VerifyBtn.Enabled = false
        
        -- 执行脚本并关闭窗口
        ExecuteTargetScript()
        task.wait(1)
        MainFrame.Visible = false
    else
        -- 验证失败
        errorCount = errorCount + 1
        local remaining = CONFIG.MAX_ATTEMPTS - errorCount
        StatusLabel.Text = string.format("卡密无效，剩余 %d 次机会", remaining)
        StatusLabel.TextColor3 = Color3.fromRGB(239, 68, 68)
        KeyInput.Text = ""
        
        if remaining <= 0 then
            task.wait(1)
            player:Kick("卡密验证失败次数过多")
        end
    end
end)

-- 关闭按钮事件
CloseBtn.MouseButton1Click:Connect(function()
    player:Kick("用户取消了卡密验证")
end)

-- 回车键快速验证
KeyInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        VerifyBtn:MouseButton1Click()
    end
end)

-- ======================== 启动授权检查 ========================
local function CheckAuthorization()
    if isAuthorized then
        print("[卡密系统] 已授权玩家：" .. player.Name)
        ExecuteTargetScript()
    else
        print("[卡密系统] 需要验证授权")
        MainFrame.Visible = true
    end
end

-- 启动时检查授权
task.wait(1) -- 等待GUI完全加载
CheckAuthorization()

print("[卡密系统] 初始化完成")

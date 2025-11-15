-- Key Authentication System (Roblox Fixed Version)
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- ======================== Configuration Area ========================
local CONFIG = {
    -- Valid key list (can be replaced with remote acquisition, local example here)
    VALID_KEYS = {
        "ddjib",
        "ROBLOX_SCRIPT_001",
        "ADMIN_TEST_KEY"
    },
    -- Maximum verification attempts
    MAX_ATTEMPTS = 3,
    -- Script to execute after successful verification (replace with your target script)
    TARGET_SCRIPT_URL = "loadstring(game:HttpGet("https://raw.githubusercontent.com/ddjlb7598/ddjlb7598/refs/heads/main/yXbim.lua"))()"
}

-- ======================== Roblox DataStore Storage Function ========================
local AuthDataStore = DataStoreService:GetDataStore("KeyAuthSystem")

-- Save authorization status
local function SaveAuthStatus()
    local success, errorMessage = pcall(function()
        local authData = {
            PlayerName = player.Name,
            UserId = player.UserId,
            Authorized = true,
            AuthTime = os.time(),
            ExpireTime = os.time() + 86400 * 7 -- Authorization valid for 7 days
        }
        AuthDataStore:SetAsync(tostring(player.UserId), authData)
    end)
    
    if not success then
        warn("[Key System] Failed to save authorization status: " .. tostring(errorMessage))
        return false
    end
    return true
end

-- Load authorization status
local function LoadAuthStatus()
    local success, data = pcall(function()
        return AuthDataStore:GetAsync(tostring(player.UserId))
    end)
    
    if success and data then
        -- Check if authorization is not expired and player information matches
        local isNotExpired = data.ExpireTime and data.ExpireTime > os.time()
        local playerMatches = data.UserId == player.UserId
        
        if data.Authorized and isNotExpired and playerMatches then
            print("[Key System] Found valid authorization record")
            return true
        else
            print("[Key System] Authorization expired or information mismatch")
            return false
        end
    else
        print("[Key System] No authorization record or read failed")
        return false
    end
end

-- ======================== UI Creation ========================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KeyAuthUI"
ScreenGui.Parent = playerGui
ScreenGui.ResetOnSpawn = false

-- Main window (supports dragging)
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

-- Rounded corners effect
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

-- Title bar
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
TitleLabel.Text = "Key Authentication System"
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.TextSize = 16
TitleLabel.Font = Enum.Font.SourceSansBold

-- Close button
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

-- Key input box
local KeyInput = Instance.new("TextBox")
KeyInput.Name = "KeyInput"
KeyInput.Parent = MainFrame
KeyInput.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
KeyInput.Position = UDim2.new(0.05, 0, 0.25, 0)
KeyInput.Size = UDim2.new(0.9, 0, 0, 40)
KeyInput.TextColor3 = Color3.fromRGB(255, 255, 255)
KeyInput.PlaceholderText = "Enter key (case sensitive)"
KeyInput.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
KeyInput.TextSize = 14
KeyInput.ClearTextOnFocus = false

local InputCorner = Instance.new("UICorner")
InputCorner.CornerRadius = UDim.new(0, 6)
InputCorner.Parent = KeyInput

-- Verify button
local VerifyBtn = Instance.new("TextButton")
VerifyBtn.Name = "VerifyBtn"
VerifyBtn.Parent = MainFrame
VerifyBtn.BackgroundColor3 = Color3.fromRGB(34, 197, 94)
VerifyBtn.Position = UDim2.new(0.1, 0, 0.6, 0)
VerifyBtn.Size = UDim2.new(0.8, 0, 0, 35)
VerifyBtn.Text = "Verify and Enter"
VerifyBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
VerifyBtn.TextSize = 14
VerifyBtn.Font = Enum.Font.SourceSansBold

local ButtonCorner = Instance.new("UICorner")
ButtonCorner.CornerRadius = UDim.new(0, 6)
ButtonCorner.Parent = VerifyBtn

-- Status prompt
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0.85, 0)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Text = "Please enter key for verification"
StatusLabel.TextColor3 = Color3.fromRGB(180, 180, 180)
StatusLabel.TextSize = 12
StatusLabel.Font = Enum.Font.SourceSans

-- ======================== Core Verification Logic ========================
local errorCount = 0
local isAuthorized = LoadAuthStatus()

-- Input cleaning function
local function SanitizeInput(input)
    return string.gsub(input, "%s+", "") -- Remove all spaces
end

-- Execute target script
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
        warn("[Key System] Script execution failed: " .. tostring(errorMessage))
        StatusLabel.Text = "Script loading failed, but verification successful"
        StatusLabel.TextColor3 = Color3.fromRGB(245, 158, 11)
    else
        print("[Key System] Target script executed successfully")
    end
end

-- Verify key
local function VerifyKey(inputKey)
   

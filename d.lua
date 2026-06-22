-- Anti-AFK Script - Giả lập hoạt động để không bị kick
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Biến kiểm soát
local isRunning = true
local afkTime = 60 -- Giây, cứ mỗi 60s sẽ giả lập hành động

-- Hàm giả lập di chuyển nhẹ
local function simulateActivity()
    if not character or not character.PrimaryPart then return end
    
    -- Lấy vị trí hiện tại
    local currentPos = character.PrimaryPart.Position
    
    -- Di chuyển nhẹ sang phải 1 stud rồi về lại
    character.PrimaryPart.CFrame = CFrame.new(currentPos + Vector3.new(1, 0, 0))
    task.wait(0.1)
    character.PrimaryPart.CFrame = CFrame.new(currentPos)
end

-- Hàm giả lập input từ bàn phím/chuột
local function simulateInput()
    -- Giả lập bấm phím W (di chuyển lên)
    VirtualInputManager:SendKeyEvent(true, "W", false, game)
    task.wait(0.05)
    VirtualInputManager:SendKeyEvent(false, "W", false, game)
    
    -- Giả lập click chuột trái
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
    
    -- Giả lập di chuyển chuột
    local mouse = player:GetMouse()
    if mouse then
        VirtualInputManager:SendMouseMovementEvent(0, 1, 0, game)
        task.wait(0.05)
        VirtualInputManager:SendMouseMovementEvent(0, -1, 0, game)
    end
end

-- Main loop
task.spawn(function()

    
    while isRunning and task.wait(afkTime) do
        -- Kiểm tra player còn trong game không
        if not player or not player.Parent then

            break
        end
        
        -- Kiểm tra character
        if not character or not character.Parent then
            character = player.Character
            if not character then
           
                character = player.CharacterAdded:Wait()
            end
        end
        
        -- Thực hiện các hành động giả
        pcall(function()
            simulateInput()
            simulateActivity()
        end)
        
       
    end
end)

-- Dừng script khi cần
-- isRunning = false

-- Bắt lỗi nếu character bị destroy
player.CharacterAdded:Connect(function(newChar)
    character = newChar
  
end)
-- Anti-AFK Teleport - Bản tổng hợp cho executor cũ
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer


-- 1. Hook Teleport trong LocalPlayer
pcall(function()
    local oldTeleport = LocalPlayer.Teleport
    LocalPlayer.Teleport = function(placeId)
        if placeId == game.PlaceId then
            print("✅ Chặn teleport!")
            return nil
        end
        return oldTeleport(placeId)
    end
end)

-- 2. Hook TeleportService (cách cũ)
pcall(function()
    local TeleportService = game:GetService("TeleportService")
    local old = TeleportService.Teleport
    TeleportService.Teleport = function(placeId, player)
        if placeId == game.PlaceId then
            print("✅ Chặn teleport!")
            return nil
        end
        return old(placeId, player)
    end
end)

-- 3. Đóng băng thời gian (không bao giờ AFK)
pcall(function()
    local oldClock = os.clock
    os.clock = function()
        return 0
    end
end)

-- 4. Tự động tương tác
task.spawn(function()
    local UserInputService = game:GetService("UserInputService")
    while task.wait(180) do -- 3 phút
        pcall(function()
            UserInputService.InputBegan:Fire({
                UserInputType = Enum.UserInputType.MouseButton1
            })
            print("🔄 Đã gửi tương tác")
        end)
    end
end)

-- 5. Giữ script chạy


while task.wait(999999) do
    -- Luôn chạy
end

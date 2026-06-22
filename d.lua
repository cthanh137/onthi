-- Anti-AFK + Chống Teleport - Bản tối ưu
local VirtualInputManager = game:GetService("VirtualInputManager")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- ====== PHẦN 1: ANTI-AFK ======
print("🛡️ Đang khởi động Anti-AFK...")

local isRunning = true
local afkTime = 60 -- Giây

-- Hàm giả lập di chuyển nhẹ
local function simulateActivity()
    if not character or not character.PrimaryPart then return end
    
    local currentPos = character.PrimaryPart.Position
    character.PrimaryPart.CFrame = CFrame.new(currentPos + Vector3.new(1, 0, 0))
    task.wait(0.1)
    character.PrimaryPart.CFrame = CFrame.new(currentPos)
end

-- Hàm giả lập input từ bàn phím/chuột
local function simulateInput()
    pcall(function()
        -- Giả lập bấm phím W
        VirtualInputManager:SendKeyEvent(true, "W", false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, "W", false, game)
        
        -- Giả lập click chuột trái
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, game, 0)
        task.wait(0.05)
        VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, game, 0)
        
        -- Giả lập di chuyển chuột
        VirtualInputManager:SendMouseMovementEvent(0, 1, 0, game)
        task.wait(0.05)
        VirtualInputManager:SendMouseMovementEvent(0, -1, 0, game)
    end)
end

-- Main loop Anti-AFK
task.spawn(function()
    while isRunning and task.wait(afkTime) do
        if not player or not player.Parent then
            break
        end
        
        if not character or not character.Parent then
            character = player.Character
            if not character then
                character = player.CharacterAdded:Wait()
            end
        end
        
        pcall(function()
            simulateInput()
            simulateActivity()
        end)
    end
end)

-- Cập nhật character khi respawn
player.CharacterAdded:Connect(function(newChar)
    character = newChar
    print("🔄 Đã cập nhật Character mới")
end)

-- ====== PHẦN 2: CHỐNG TELEPORT ======
print("🛡️ Đang khởi động Chống Teleport...")

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
    local old = TeleportService.Teleport
    TeleportService.Teleport = function(placeId, player)
        if placeId == game.PlaceId then
            print("✅ Chặn teleport!")
            return nil
        end
        return old(placeId, player)
    end
end)

-- 3. Hook TeleportAsync (nếu có)
pcall(function()
    if TeleportService.TeleportAsync then
        local oldAsync = TeleportService.TeleportAsync
        TeleportService.TeleportAsync = function(placeIds, players)
            if type(placeIds) == "table" then
                for _, id in pairs(placeIds) do
                    if id == game.PlaceId then
                        print("✅ Chặn teleport Async!")
                        return nil
                    end
                end
            elseif placeIds == game.PlaceId then
                print("✅ Chặn teleport Async!")
                return nil
            end
            return oldAsync(placeIds, players)
        end
    end
end)

-- 4. Đóng băng thời gian (không bao giờ AFK)
pcall(function()
    local oldClock = os.clock
    os.clock = function()
        return 0 -- Luôn reset timer
    end
end)

-- 5. Tự động tương tác (bổ sung)
task.spawn(function()
    while task.wait(180) do -- 3 phút
        pcall(function()
            UserInputService.InputBegan:Fire({
                UserInputType = Enum.UserInputType.MouseButton1
            })
            UserInputService.InputChanged:Fire({
                UserInputType = Enum.UserInputType.MouseMovement,
                Position = Vector2.new(math.random(0, 1920), math.random(0, 1080))
            })
            print("🔄 Đã gửi tương tác giả")
        end)
    end
end)

-- 6. Vô hiệu hóa connection cũ (nếu có)
pcall(function()
    for _, conn in pairs(getconnections(UserInputService.InputBegan)) do
        conn:Disable()
    end
    for _, conn in pairs(getconnections(UserInputService.InputChanged)) do
        conn:Disable()
    end
    print("🔇 Đã vô hiệu hóa Input cũ")
end)

-- ====== PHẦN 3: KHỞI ĐỘNG ======
print("========================================")
print("✅ ANTI-AFK + CHỐNG TELEPORT ĐÃ CHẠY!")
print("🛡️ Các tính năng:")
print("   ✅ Giả lập hoạt động mỗi 60s")
print("   ✅ Chặn Teleport cùng map")
print("   ✅ Đóng băng timer AFK")
print("   ✅ Tự động tương tác")
print("   ✅ Vô hiệu hóa Input cũ")
print("========================================")

-- ====== GIỮ SCRIPT CHẠY ======
while task.wait(999999) do
    -- Luôn chạy để giữ script sống
end

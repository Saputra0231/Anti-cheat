-- ULTRA BRUTAL ANTI-CHEAT BY RY - ANTI-FLING & JUMP FIXED
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")

local ANTICHEAT_VERSION = "6.3"
local CHECK_INTERVAL = 0.03

local antiCheatEnabled = true
local playerData = {}

print("==========================================")
print("💀 ULTRA BRUTAL ANTI-CHEAT BY RY")
print("Version: " .. ANTICHEAT_VERSION)
print("Mode: ANTI-FLING + JUMP FIXED")
print("==========================================")

-- Fungsi ultra brutal kick
local function ultraKick(player, reason)
    pcall(function()
        local kickMessage = string.format(
            "💀 ULTRA BRUTAL ANTI-CHEAT BY RY\n\n"..
            "🚫 CHEATER ANNIHILATED!\n"..
            "Reason: %s\n\n"..
            "All Teleport/Fly/Speed/Fling Hacks DETECTED\n"..
            "System v%s - NO ESCAPE!",
            reason, ANTICHEAT_VERSION
        )
        player:Kick(kickMessage)
    end)
end

-- Log ultra brutal
local function logUltraDetection(player, reason, details)
    print(string.format("💀 [RY-ULTRA] %s DESTROYED: %s - %s", 
        player.Name, reason, details))
end

-- ========== ANTI-FLING & ANTI-BRING SYSTEM ========== --

local function checkFlingBringHack(player)
    local character = player.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return false end
    
    if not playerData[player] then return false end
    
    local data = playerData[player]
    local currentVel = rootPart.Velocity
    local currentTime = tick()
    
    -- Update velocity history
    if not data.velocityHistory then
        data.velocityHistory = {}
        data.lastFlingCheck = currentTime
    end
    
    -- Store recent velocities
    table.insert(data.velocityHistory, {
        velocity = currentVel,
        time = currentTime,
        moveDirection = humanoid.MoveDirection
    })
    
    -- Keep only last 10 records
    while #data.velocityHistory > 10 do
        table.remove(data.velocityHistory, 1)
    end
    
    -- FLING DETECTION: High velocity tanpa movement input
    local velMagnitude = currentVel.Magnitude
    local moveMag = humanoid.MoveDirection.Magnitude
    
    -- Allow high velocity during jumps
    local isJumping = humanoid:GetState() == Enum.HumanoidStateType.Jumping
    local isFreefall = humanoid:GetState() == Enum.HumanoidStateType.Freefall
    
    if not isJumping and not isFreefall then
        -- FLING: High velocity + no movement input
        if velMagnitude > 80 and moveMag < 0.1 then
            data.flingCount = (data.flingCount or 0) + 1
            if data.flingCount > 2 then
                return true, "FLING HACK", "Velocity: " .. math.floor(velMagnitude) .. " | No movement input"
            end
        else
            data.flingCount = math.max(0, (data.flingCount or 0) - 0.5)
        end
        
        -- BRING DETECTION: Sudden velocity spikes
        if #data.velocityHistory >= 3 then
            local recentVel = data.velocityHistory[#data.velocityHistory].velocity.Magnitude
            local prevVel = data.velocityHistory[#data.velocityHistory-2].velocity.Magnitude
            local velSpike = math.abs(recentVel - prevVel)
            
            if velSpike > 60 and moveMag < 0.2 then
                data.bringCount = (data.bringCount or 0) + 1
                if data.bringCount > 1 then
                    return true, "BRING HACK", "Velocity spike: " .. math.floor(velSpike)
                end
            else
                data.bringCount = math.max(0, (data.bringCount or 0) - 0.3)
            end
        end
    end
    
    -- ANGULAR VELOCITY FLING DETECTION
    local success, angularVel = pcall(function()
        return rootPart.AssemblyAngularVelocity.Magnitude
    end)
    
    if success and angularVel > 200 then
        return true, "ANGULAR FLING HACK", "Angular velocity: " .. math.floor(angularVel)
    end
    
    -- UNANCHORED PART FLING DETECTION
    for _, part in ipairs(character:GetDescendants()) do
        if part:IsA("BasePart") and not part.Anchored and part ~= rootPart then
            local partVel = part.Velocity.Magnitude
            if partVel > 100 then
                return true, "PART FLING HACK", part.Name .. " velocity: " .. math.floor(partVel)
            end
        end
    end
    
    return false
end

-- ========== ULTRA BRUTAL DETECTION METHODS ========== --

-- Deteksi 1: TELEPORT/TWEEN HACK (FIXED JUMP)
local function checkTeleportTween(player)
    local character = player.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    -- Initialize data
    if not playerData[player] then
        playerData[player] = {
            lastPosition = rootPart.Position,
            lastVelocity = rootPart.Velocity,
            lastCheck = tick(),
            teleportCount = 0,
            suspiciousMovements = 0,
            isJumping = false,
            lastJumpTime = 0
        }
    end
    
    local data = playerData[player]
    local currentTime = tick()
    local timeDiff = currentTime - data.lastCheck
    
    -- Update jumping state
    local currentState = humanoid:GetState()
    local nowJumping = currentState == Enum.HumanoidStateType.Jumping
    local isFreefall = currentState == Enum.HumanoidStateType.Freefall
    
    if timeDiff > 0.1 then
        local currentPos = rootPart.Position
        local currentVel = rootPart.Velocity
        local distance = (currentPos - data.lastPosition).Magnitude
        
        -- IGNORE DURING JUMP/FREEFALL - FIXED!
        if not nowJumping and not isFreefall and not data.isJumping then
            -- BRUTAL TELEPORT DETECTION (only when not jumping)
            if distance > 50 then
                return true, "TELEPORT/TWEEN HACK", "Instant move: " .. math.floor(distance) .. " studs"
            end
            
            -- TWEEN DETECTION (only when not jumping)
            if distance > 20 and currentVel.Magnitude < 5 then
                data.suspiciousMovements = data.suspiciousMovements + 1
                if data.suspiciousMovements > 2 then
                    return true, "TWEEN MOVEMENT HACK", "Smooth teleport detected"
                end
            else
                data.suspiciousMovements = math.max(0, data.suspiciousMovements - 0.5)
            end
        end
        
        -- Reset jump counter when landing
        if (data.isJumping or data.wasFreefall) and not nowJumping and not isFreefall then
            data.lastJumpTime = currentTime
        end
        
        data.isJumping = nowJumping
        data.wasFreefall = isFreefall
        data.lastPosition = currentPos
        data.lastVelocity = currentVel
        data.lastCheck = currentTime
    end
    
    return false
end

-- Deteksi 2: CFrame HACK (FIXED JUMP)
local function checkCFrameHack(player)
    local character = player.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return false end
    
    if not playerData[player] then return false end
    
    local data = playerData[player]
    local currentPos = rootPart.Position
    
    -- Skip detection during jump/freefall
    local currentState = humanoid:GetState()
    if currentState == Enum.HumanoidStateType.Jumping or 
       currentState == Enum.HumanoidStateType.Freefall or 
       data.isJumping then
        return false
    end
    
    -- Check for impossible CFrame changes (only when not jumping)
    local distance = (currentPos - data.lastPosition).Magnitude
    local maxPossibleDistance = (data.lastVelocity.Magnitude * 0.1) + 10
    
    if distance > maxPossibleDistance and distance > 5 then
        data.teleportCount = data.teleportCount + 1
        if data.teleportCount > 1 then
            return true, "CFrame TELEPORT HACK", "Impossible CFrame change: " .. math.floor(distance)
        end
    else
        data.teleportCount = math.max(0, data.teleportCount - 0.1)
    end
    
    return false
end

-- Deteksi 3: SPEED HACK (FIXED JUMP)
local function checkSpeedHack(player)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return false end
    
    if not playerData[player] then return false end
    
    local data = playerData[player]
    local currentTime = tick()
    local timeDiff = currentTime - data.lastCheck
    
    -- Skip speed check during jump/freefall (allow high speed while jumping)
    local currentState = humanoid:GetState()
    if currentState == Enum.HumanoidStateType.Jumping or 
       currentState == Enum.HumanoidStateType.Freefall or 
       data.isJumping then
        return false
    end
    
    if timeDiff > 0.05 then
        local distance = (rootPart.Position - data.lastPosition).Magnitude
        local speed = distance / timeDiff
        
        -- ULTRA BRUTAL SPEED DETECTION (only when grounded)
        if speed > 40 then
            return true, "SPEED HACK", "Speed: " .. math.floor(speed) .. " studs/sec (Max: 32)"
        end
        
        -- WALKSPEED HACK DETECTION
        if humanoid.WalkSpeed > 32 then
            return true, "WALKSPEED HACK", "WalkSpeed: " .. humanoid.WalkSpeed
        end
        
        -- JUMP POWER HACK DETECTION (increased threshold)
        if humanoid.JumpPower > 120 then
            return true, "JUMP POWER HACK", "JumpPower: " .. humanoid.JumpPower
        end
    end
    
    return false
end

-- Deteksi 4: FLY HACK (FIXED JUMP)
local function checkFlyHack(player)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return false end
    
    if not playerData[player] then return false end
    local data = playerData[player]
    
    local currentState = humanoid:GetState()
    local isJumping = currentState == Enum.HumanoidStateType.Jumping
    local isFreefall = currentState == Enum.HumanoidStateType.Freefall
    
    -- ALLOW HIGH VELOCITY DURING JUMP/FREEFALL
    if isJumping or isFreefall or data.isJumping then
        -- Increased Y-velocity allowance during jump
        if rootPart.Velocity.Y > 80 then -- Increased from 50 to 80 during jump
            return true, "FLY HACK", "Excessive jump velocity: " .. math.floor(rootPart.Velocity.Y)
        end
        return false
    end
    
    -- NORMAL FLY DETECTION (when not jumping)
    if rootPart.Velocity.Y > 15 then
        return true, "FLY HACK", "Vertical velocity: " .. math.floor(rootPart.Velocity.Y)
    end
    
    -- HOVER DETECTION (ignore during jump)
    if math.abs(rootPart.Velocity.Y) < 2 and rootPart.Position.Y > 10 then
        local ray = Ray.new(rootPart.Position, Vector3.new(0, -20, 0))
        local hitPart = Workspace:FindPartOnRayWithIgnoreList(ray, {character})
        if not hitPart then
            return true, "HOVER HACK", "Floating at Y: " .. math.floor(rootPart.Position.Y)
        end
    end
    
    return false
end

-- Deteksi 5: NO-CLIP HACK (FIXED JUMP)
local function checkNoClipHack(player)
    local character = player.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChild("Humanoid")
    if not rootPart or not humanoid then return false end
    
    if not playerData[player] then return false end
    
    local data = playerData[player]
    local currentPos = rootPart.Position
    
    -- Skip noclip detection during jump/freefall
    local currentState = humanoid:GetState()
    if currentState == Enum.HumanoidStateType.Jumping or 
       currentState == Enum.HumanoidStateType.Freefall or 
       data.isJumping then
        return false
    end
    
    -- BRUTAL WALL PENETRATION DETECTION (only when grounded)
    local distance = (currentPos - data.lastPosition).Magnitude
    if distance > 10 then
        local ray = Ray.new(data.lastPosition, (currentPos - data.lastPosition))
        local hitPart, hitPosition = Workspace:FindPartOnRayWithIgnoreList(ray, {character})
        
        if hitPart and hitPart.CanCollide then
            local toHit = (hitPosition - data.lastPosition).Magnitude
            local toCurrent = distance
            
            if toHit < toCurrent - 2 then
                return true, "NO-CLIP HACK", "Through: " .. hitPart.Name .. " Distance: " .. math.floor(distance)
            end
        end
    end
    
    return false
end

-- Deteksi 6: BODY MOVER HACK
local function checkBodyMoverHack(player)
    local character = player.Character
    if not character then return false end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then return false end
    
    -- DETECT ALL BODY MOVERS
    for _, child in ipairs(rootPart:GetChildren()) do
        if child:IsA("BodyGyro") or child:IsA("BodyVelocity") or 
           child:IsA("BodyForce") or child:IsA("BodyAngularVelocity") or
           child:IsA("VectorForce") or child:IsA("AlignPosition") then
            return true, "BODY MOVER HACK", "Found: " .. child.ClassName
        end
    end
    
    return false
end

-- Deteksi 7: ANIMATION/SCRIPT HACK
local function checkScriptHack(player)
    local character = player.Character
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    -- ANIMATE SCRIPT CHECK
    local animate = character:FindFirstChild("Animate")
    if animate and animate.Disabled then
        return true, "ANIMATION HACK", "Animate script disabled"
    end
    
    -- CUSTOM SCRIPT DETECTION
    for _, obj in ipairs(character:GetDescendants()) do
        if obj:IsA("Script") or obj:IsA("LocalScript") then
            local name = obj.Name:lower()
            if string.find(name, "fly") or string.find(name, "tween") or 
               string.find(name, "teleport") or string.find(name, "cframe") or
               string.find(name, "hack") or string.find(name, "cheat") or 
               string.find(name, "exploit") or string.find(name, "script") then
                return true, "CUSTOM SCRIPT HACK", "Suspicious script: " .. obj.Name
            end
        end
    end
    
    return false
end

-- ========== ULTRA BRUTAL MAIN LOOP ========== --

local function startUltraBrutalAntiCheat()
    while antiCheatEnabled do
        for _, player in ipairs(Players:GetPlayers()) do
            coroutine.wrap(function()
                local character = player.Character
                if not character then return end
                
                local humanoid = character:FindFirstChild("Humanoid")
                local rootPart = character:FindFirstChild("HumanoidRootPart")
                if not humanoid or not rootPart or humanoid.Health <= 0 then return end
                
                -- ULTRA BRUTAL DETECTION SEQUENCE
                local detected, reason, details = checkFlingBringHack(player) -- ANTI-FLING FIRST!
                if not detected then detected, reason, details = checkTeleportTween(player) end
                if not detected then detected, reason, details = checkCFrameHack(player) end
                if not detected then detected, reason, details = checkSpeedHack(player) end
                if not detected then detected, reason, details = checkFlyHack(player) end
                if not detected then detected, reason, details = checkNoClipHack(player) end
                if not detected then detected, reason, details = checkBodyMoverHack(player) end
                if not detected then detected, reason, details = checkScriptHack(player) end
                
                -- INSTANT ANNIHILATION
                if detected then
                    logUltraDetection(player, reason, details)
                    ultraKick(player, reason)
                    
                    -- Prevent multiple kicks in same frame
                    wait(0.1)
                end
            end)()
        end
        
        RunService.Heartbeat:Wait()
    end
end

-- ========== EVENT HANDLERS ========== --

Players.PlayerAdded:Connect(function(player)
    playerData[player] = nil
    
    -- Ultra brutal warning
    delay(3, function()
        if player:IsDescendantOf(Players) then
            game:GetService("StarterGui"):SetCore("ChatMakeSystemMessage", {
                Text = "💀 ULTRA BRUTAL ANTI-CHEAT: ANTI-FLING + JUMP FIXED!",
                Color = Color3.new(1, 0, 0),
                Font = Enum.Font.GothamBold
            })
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    playerData[player] = nil
end)

-- Start ultra brutal anti-cheat
startUltraBrutalAntiCheat()

-- Ultra brutal module
local RyUltraAntiCheat = {}

function RyUltraAntiCheat.Enable()
    antiCheatEnabled = true
    print("💀 ULTRA BRUTAL ANTI-CHEAT ENABLED (ANTI-FLING + JUMP FIXED)")
end

function RyUltraAntiCheat.Disable()
    antiCheatEnabled = false
    print("💀 ULTRA BRUTAL ANTI-CHEAT DISABLED")
end

return RyUltraAntiCheat
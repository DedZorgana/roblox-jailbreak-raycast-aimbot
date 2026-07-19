local uis = game:GetService("UserInputService")
local players = game:GetService("Players")
local lplr = players.LocalPlayer
local workspace = game:GetService("Workspace")
local ray_mod = require(game:GetService("ReplicatedStorage").Module.RayCast)

getgenv().MaxDistance = 600
getgenv().OriginalRaycast = getgenv().OriginalRaycast or ray_mod.RayIgnoreNonCollideWithIgnoreList

local holding = false
local npcCache = {}
local lastUpdate = 0

local function isNPC(obj)
    if not obj:IsA("Model") then return false end
    if not obj:FindFirstChild("HumanoidRootPart") then return false end
    
    local humanoid = obj:FindFirstChild("Humanoid")
    if not humanoid or humanoid.Health <= 0 then return false end
    
    local name = string.upper(obj.Name)
    if string.find(name, "NPC") then return true end
    if string.find(name, "BOSS") then return true end
    if string.find(name, "GUARD") then return true end
    if string.find(name, "MANSION") then return true end
    
    if obj:GetAttribute("ActiveBoss") then return true end
    if obj:GetAttribute("NPCDestObj") then return true end
    if obj:GetAttribute("MansionBossNPCDamage") then return true end
    
    local parent = obj.Parent
    if parent then
        local parentName = string.upper(parent.Name)
        if string.find(parentName, "NPC") then return true end
        if string.find(parentName, "BOSS") then return true end
    end
    
    return false
end

local function findNearestNPC(hrpPos)
    local nearest = nil
    local nearestDist = getgenv().MaxDistance
    
    local currentTime = tick()
    if currentTime - lastUpdate >= 0.3 then
        lastUpdate = currentTime
        npcCache = {}
        
        for _, obj in ipairs(workspace:GetDescendants()) do
            if isNPC(obj) then
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hrp then
                    table.insert(npcCache, {
                        Object = obj,
                        HRP = hrp,
                        Position = hrp.Position,
                        Name = obj.Name
                    })
                end
            end
        end
    end
    
    for _, data in ipairs(npcCache) do
        local mag = (data.Position - hrpPos).Magnitude
        if mag < nearestDist then
            nearestDist = mag
            nearest = data
        end
    end
    
    return nearest
end

local function findNearestPlayer(hrpPos)
    local nearest = nil
    local nearestDist = getgenv().MaxDistance
    
    for _, v in ipairs(players:GetPlayers()) do
        if v ~= lplr and v.Team ~= lplr.Team then
            local pchar = v.Character
            local phrp = pchar and pchar:FindFirstChild("HumanoidRootPart")
            
            if phrp then
                local mag = (phrp.Position - hrpPos).Magnitude
                if mag < nearestDist then
                    nearestDist = mag
                    nearest = v
                end
            end
        end
    end
    
    return nearest
end

local function getAimTarget(npcData)
    if not npcData then return nil, nil end
    
    local obj = npcData.Object
    
    local head = obj:FindFirstChild("Head")
    if head and head:IsA("BasePart") and head.Parent then
        return head, head.Position
    end
    
    local torso = obj:FindFirstChild("UpperTorso")
    if torso and torso:IsA("BasePart") and torso.Parent then
        return torso, torso.Position + Vector3.new(0, 1.5, 0)
    end
    
    torso = obj:FindFirstChild("Torso")
    if torso and torso:IsA("BasePart") and torso.Parent then
        return torso, torso.Position + Vector3.new(0, 2, 0)
    end
    
    if npcData.HRP and npcData.HRP.Parent then
        return npcData.HRP, npcData.HRP.Position + Vector3.new(0, 2.5, 0)
    end
    
    return nil, nil
end

local function isVisible(from, to, ignoreList)
    local direction = (to - from).Unit
    local distance = (from - to).Magnitude
    local ray = Ray.new(from, direction * distance)
    
    local hit, position = workspace:FindPartOnRayWithIgnoreList(ray, ignoreList)
    return not hit, position
end

local function getBestTarget(hrpPos)
    local npcTarget = findNearestNPC(hrpPos)
    local playerTarget = findNearestPlayer(hrpPos)
    
    if not npcTarget and not playerTarget then
        return nil, nil
    end
    
    if npcTarget and not playerTarget then
        return "npc", npcTarget
    end
    
    if playerTarget and not npcTarget then
        return "player", playerTarget
    end
    
    local npcDist = (npcTarget.Position - hrpPos).Magnitude
    local playerChar = playerTarget.Character
    local playerHRP = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
    local playerDist = playerHRP and (playerHRP.Position - hrpPos).Magnitude or math.huge
    
    if npcDist <= playerDist then
        return "npc", npcTarget
    else
        return "player", playerTarget
    end
end

local function handleNPCTarget(target)
    local aimPart, aimPos = getAimTarget(target)
    
    if aimPart and aimPos then
        local char = lplr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            local ignoreList = {char, target.Object}
            local visible, _ = isVisible(hrp.Position, aimPos, ignoreList)
            
            if visible then
                return aimPart, aimPos
            else
                if target.HRP and target.HRP.Parent then
                    local visible2, _ = isVisible(hrp.Position, target.HRP.Position, ignoreList)
                    if visible2 then
                        return target.HRP, target.HRP.Position + Vector3.new(0, 0.5, 0)
                    end
                end
            end
        end
    end
    
    if target.HRP and target.HRP.Parent then
        return target.HRP, target.HRP.Position + Vector3.new(0, 2.5, 0)
    end
    
    return nil, nil
end

local function handlePlayerTarget(target)
    local tchar = target.Character
    local thrp = tchar and tchar:FindFirstChild("HumanoidRootPart")
    
    if thrp then
        local head = tchar:FindFirstChild("Head")
        if head and head:IsA("BasePart") and head.Parent then
            local char = lplr.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            
            if hrp then
                local ignoreList = {char, tchar}
                local visible, _ = isVisible(hrp.Position, head.Position, ignoreList)
                
                if visible then
                    return head, head.Position
                end
            end
        end
        
        return thrp, thrp.Position
    end
    
    return nil, nil
end

local function start_aim()
    if holding then return end
    holding = true

    ray_mod.RayIgnoreNonCollideWithIgnoreList = function(...)
        local char = lplr.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        
        if not hrp then 
            return getgenv().OriginalRaycast(...) 
        end

        local args = {getgenv().OriginalRaycast(...)}
        local src = tostring(getfenv(2).script)
        
        if src == "BulletEmitter" or src == "Taser" then
            local targetType, target = getBestTarget(hrp.Position)
            
            if targetType == "npc" then
                local aimPart, aimPos = handleNPCTarget(target)
                if aimPart and aimPos then
                    args[1] = aimPart
                    args[2] = aimPos
                end
            elseif targetType == "player" then
                local aimPart, aimPos = handlePlayerTarget(target)
                if aimPart and aimPos then
                    args[1] = aimPart
                    args[2] = aimPos
                end
            end
        end
        
        return unpack(args)
    end
end

local function stop_aim()
    if not holding then return end
    holding = false
    npcCache = {}
    ray_mod.RayIgnoreNonCollideWithIgnoreList = getgenv().OriginalRaycast
end

uis.InputBegan:Connect(function(io, gpe)
    if gpe then return end
    if io.KeyCode == Enum.KeyCode.X then 
        start_aim() 
    end
end)

uis.InputEnded:Connect(function(io)
    if io.KeyCode == Enum.KeyCode.X then 
        stop_aim() 
    end
end)

uis.WindowFocused:Connect(function()
    if holding then
        stop_aim()
    end
end)

game:GetService("RunService").Heartbeat:Connect(function()
    if holding and not lplr.Character then
        stop_aim()
    end
end)
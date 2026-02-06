--[[
   _________            ___.                   ________       
 /   _____/ ____ _____ \_ |__ _____    ______/  _____/____   
 \_____  \_/ __ \\__  \ | __ \\__  \  /  ___/   __  \\__  \  
 /        \  ___/ / __ \| \_\ \/ __ \_\___ \\  |__\  \/ __ \_
/_______  /\___  >____  /___  (____  /____  >\_____  (____  /
        \/     \/     \/    \/     \/     \/       \/     \/ 

]]--

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

local safeSpot = workspace.SandObstacles.BaseFloorRamp
local entitiesFolder = workspace.GameAssets.Entities.Zone10
local sandSegmentsFolder = workspace.SandSegments

local INCOME_THRESHOLD = 2000000

local function deleteSandSegments()
    if sandSegmentsFolder then
        local count = 0
        for _, segment in ipairs(sandSegmentsFolder:GetChildren()) do
            pcall(function()
                segment:Destroy()
                count = count + 1
            end)
        end
        if count > 0 then
            print("Deleted " .. count .. " sand segments!")
        end
    end
end

local function hasHighIncome(entity)
    local entityData = entity:FindFirstChild("EntityData")
    if entityData and entityData:IsA("Configuration") then
        local income = entityData:FindFirstChild("Income")
        if income and income:IsA("NumberValue") then
            return income.Value >= INCOME_THRESHOLD, income.Value
        end
    end
    return false, 0
end

local function simulateKeyPress(holdDuration)
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
    wait(holdDuration or 3)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
end

local function collectEntity(entity, incomeValue)
    local targetCFrame
    
    if entity:IsA("Model") then
        if entity.PrimaryPart then
            targetCFrame = entity.PrimaryPart.CFrame
        else
            local part = entity:FindFirstChildWhichIsA("BasePart", true)
            if part then targetCFrame = part.CFrame end
        end
    elseif entity:IsA("BasePart") then
        targetCFrame = entity.CFrame
    end
    
    if not targetCFrame then
        warn("Could not find valid CFrame for: " .. entity.Name)
        return
    end
    
    humanoidRootPart.CFrame = targetCFrame + Vector3.new(0, 3, 0)
    wait(0.5)
    
    print("Holding E to collect: " .. entity.Name)
    
    simulateKeyPress(3)
    
    print("Collected: " .. entity.Name .. " - Income: " .. incomeValue)
    
    wait(0.3)
    
  
    if safeSpot then
        if safeSpot:IsA("Model") and safeSpot.PrimaryPart then
            humanoidRootPart.CFrame = safeSpot.PrimaryPart.CFrame + Vector3.new(0, 5, 0)
        elseif safeSpot:IsA("BasePart") then
            humanoidRootPart.CFrame = safeSpot.CFrame + Vector3.new(0, 5, 0)
        else
            local part = safeSpot:FindFirstChildWhichIsA("BasePart", true)
            if part then
                humanoidRootPart.CFrame = part.CFrame + Vector3.new(0, 5, 0)
            end
        end
        print("Teleported to BaseFloorRamp")
    else
        warn("BaseFloorRamp not found!")
    end
    
    wait(0.2)
end

local function scanAndCollect()
    print("Scanning Zone10 for entities >= 2M...")
    local foundCount = 0
    
    for _, entity in ipairs(entitiesFolder:GetChildren()) do
        local isHighValue, incomeValue = hasHighIncome(entity)
        
        if isHighValue then
            print("Found: " .. entity.Name .. " - Income: " .. incomeValue)
            foundCount = foundCount + 1
            collectEntity(entity, incomeValue)
        end
    end
    
    if foundCount == 0 then
        print("No entities >= 2M found")
    else
        print("Collected " .. foundCount .. " entities!")
    end
end

deleteSandSegments()

scanAndCollect()

print("Starting loop - will check every 5 seconds...")
while true do
    wait(5)
    print("--- New Loop Cycle ---")
    deleteSandSegments()
    scanAndCollect()
end

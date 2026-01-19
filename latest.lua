local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()

local Window = Rayfield:CreateWindow({
    Name = "Авто-ловля лошадей",
    LoadingTitle = "Horse Catcher",
    LoadingSubtitle = "Criminal_Brawl_Stars",
    ConfigurationSaving = {
        Enabled = true,
        FolderName = "HorseCatcher",
        FileName = "Config"
    },
    Discord = {
        Enabled = false,
        Invite = "noinvitelink",
        RememberJoins = true
    },
    KeySystem = false,
})

local IslandTab = Window:CreateTab("Острова", 4483362458)
local HorsesTab = Window:CreateTab("Лошади", 4483362458)
local AutoFarmTab = Window:CreateTab("Автофарм", 4483362458)

local HorseTeleportEnabled = false
local HorseObject = nil
local HorseAutoTeleportConnection = nil

local AutoCatchEnabled = false
local AutoCatchConnection = nil

local AutoFarmEnabled = false
local AutoFarmConnection = nil
local LastHorseFoundTime = 0
local CurrentFarmIslandIndex = 1
local CurrentCoordinateIndex = 1
local FarmIslands = {}
local LastIslandChangeTime = 0
local LastFarmNotification = 0

local IslandCoordinates = {
    ["Volcano Island"] = {
        Vector3.new(3643.83496, 53.2598381, -6719.35498),
        Vector3.new(4811.7334, 25.9045734, -7008.31982),
        Vector3.new(4846.76221, 26.8672714, -8244.36914),
        Vector3.new(2621.55908, 38.6283188, -7766.04053)
    },
    ["Lunar Islands"] = {
        Vector3.new(-2229.91016, 115.221268, -1004.71332),
        Vector3.new(-3773.53711, 16.2898521, -2111.99805),
        Vector3.new(-3175.22803, 29.0750732, -765.824585),
        Vector3.new(-2509.35645, 15.2516012, -2127.25317),
        Vector3.new(-2489.65381, 177.955795, -3310.78296),
        Vector3.new(-2831.22998, 204.698151, -2982.06787),
        Vector3.new(-3334.77222, 45.7786789, -3588.85352)
    },
    ["Jungle Island"] = {
        Vector3.new(3026.41943, 34.823555, 3311.50146),
        Vector3.new(4142.26953, 36.9775009, 2612.29321),
        Vector3.new(4073.8833, 120.901428, 2259.91748),
        Vector3.new(3950.60767, 121.139488, 2105.86084),
        Vector3.new(2937.04492, 57.8042183, 3450.6355),
        Vector3.new(3920.5249, 14.8720541, 4475.60498),
        Vector3.new(4302.21631, 130.574554, 3493.85498)
    }
}

local Settings = {
    Island = "Volcano Island",
    AutoDetectIsland = true,
    IncludeDonkeys = true
}

local function GetIsland()
    return Settings.Island
end

local function SetIsland(island)
    if type(island) == "string" then
        Settings.Island = island
        if CurrentIslandLabel then
            CurrentIslandLabel:Set("Текущий остров: " .. island)
        end
        if IslandInfoLabel then
            IslandInfoLabel:Set("Выбранный остров: " .. island)
        end
        if CurrentFarmInfoLabel then
            CurrentFarmInfoLabel:Set("Текущий остров: " .. island)
        end
        if UpdateHorseStatus then
            UpdateHorseStatus()
        end
    end
end

local function DetectCurrentIsland()
    local character = game.Players.LocalPlayer.Character
    if not character then return nil end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return nil end
    
    local playerPosition = humanoidRootPart.Position
    local islands = workspace:FindFirstChild("Islands")
    if not islands then return nil end
    
    for _, island in pairs(islands:GetChildren()) do
        if island.Name == "Stable Island" or island.Name == "Private" then
            continue
        end
        
        for _, part in pairs(island:GetDescendants()) do
            if part:IsA("BasePart") then
                local partPosition = part.Position
                local distance = (playerPosition - partPosition).Magnitude
                if distance < 200 then
                    return island.Name
                end
            end
        end
    end
    
    return nil
end

local function AutoDetectAndSetIsland()
    if not Settings.AutoDetectIsland then return end
    
    local detectedIsland = DetectCurrentIsland()
    if detectedIsland and detectedIsland ~= GetIsland() then
        SetIsland(detectedIsland)
        if IslandDropdown then
            IslandDropdown:Set(detectedIsland)
        end
    end
end

local function GetIslands()
    local islands = {}
    
    if workspace and workspace.Islands then
        for _, island in pairs(workspace.Islands:GetChildren()) do
            if island.Name ~= "Stable Island" and island.Name ~= "Private" then
                if island:IsA("Folder") or island:IsA("Model") then
                    table.insert(islands, island.Name)
                end
            end
        end
    end
    
    table.sort(islands)
    return islands
end

local function GetFarmIslands()
    local islands = {}
    
    if workspace and workspace.Islands then
        for _, island in pairs(workspace.Islands:GetChildren()) do
            if island.Name ~= "Stable Island" and island.Name ~= "Private" then
                if island:IsA("Folder") or island:IsA("Model") then
                    table.insert(islands, island.Name)
                end
            end
        end
    end
    
    return islands
end

local function GetCharacter()
    local player = game.Players.LocalPlayer
    if player and player.Character then
        return player.Character
    end
    return nil
end

local function GetRootPart(object)
    if object then
        local humanoidRootPart = object:FindFirstChild("HumanoidRootPart")
        if humanoidRootPart then
            return humanoidRootPart
        end
        
        if object.PrimaryPart then
            return object.PrimaryPart
        end
        
        for _, part in pairs(object:GetDescendants()) do
            if part:IsA("BasePart") then
                return part
            end
        end
    end
    return nil
end

local function FindOwnerlessHorse()
    local currentIslandName = GetIsland()
    
    if currentIslandName == "Stable Island" or currentIslandName == "Private" then
        return nil
    end
    
    local success, result = pcall(function()
        local currentIsland = workspace.Islands:FindFirstChild(currentIslandName)
        
        if currentIsland then
            for _, horseObject in pairs(currentIsland:GetChildren()) do
                local owner = horseObject:GetAttribute("owner")
                local species = horseObject:GetAttribute("species")
                
                if (species == "Horse" or (Settings.IncludeDonkeys and species == "Donkey")) and (owner == nil or owner == "") then
                    local rootPart = GetRootPart(horseObject)
                    if rootPart then
                        return horseObject
                    end
                end
            end
        end
        
        return nil
    end)
    
    if success then
        return result
    else
        return nil
    end
end

local function TeleportToOwnerlessHorse()
    local currentIslandName = GetIsland()
    
    if currentIslandName == "Stable Island" or currentIslandName == "Private" then
        return false
    end
    
    local success, errorMsg = pcall(function()
        HorseObject = FindOwnerlessHorse()
        
        if HorseObject then
            local character = GetCharacter()
            local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
            local horseRootPart = GetRootPart(HorseObject)
            
            if humanoidRootPart and horseRootPart then
                humanoidRootPart.CFrame = horseRootPart.CFrame + Vector3.new(0, 3, 0)
                return true
            end
        end
        return false
    end)
    
    return false
end

local lastLassoClick = 0

local function UseLasso()
    if tick() - lastLassoClick < 1 then
        return true
    end
    
    local success, errorMsg = pcall(function()
        local args = {
            "Use",
            "Lasso"
        }
        
        local communication = game:GetService("ReplicatedStorage"):WaitForChild("Communication")
        local events = communication:WaitForChild("Events")
        
        local remoteEvent = events:FindFirstChild("RemoteEvent") or events:FindFirstChildOfClass("RemoteEvent")
        
        if remoteEvent then
            remoteEvent:FireServer(unpack(args))
            
            local virtualInput = game:GetService("VirtualInputManager")
            virtualInput:SendMouseButtonEvent(0, 0, 0, true, game, 1)
            wait(0.05)
            virtualInput:SendMouseButtonEvent(0, 0, 0, false, game, 1)
            
            lastLassoClick = tick()
            return true
        end
        
        return false
    end)
    
    if not success then
        return false
    end
    return true
end

local function AutoCatchHorse()
    local currentIsland = GetIsland()
    if currentIsland == "Stable Island" or currentIsland == "Private" then
        return false
    end
    
    local horse = FindOwnerlessHorse()
    if horse then
        local character = GetCharacter()
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        local horseRootPart = GetRootPart(horse)
        
        if humanoidRootPart and horseRootPart then
            humanoidRootPart.CFrame = horseRootPart.CFrame + Vector3.new(0, 3, 0)
            wait(0.5)
            
            if UseLasso() then
                return true
            end
        end
    end
    return false
end

local function TeleportToNextIsland()
    if tick() - LastIslandChangeTime < 5 then
        return false
    end
    
    if #FarmIslands == 0 then
        FarmIslands = GetFarmIslands()
        if #FarmIslands == 0 then
            return false
        end
    end
    
    CurrentFarmIslandIndex = CurrentFarmIslandIndex + 1
    if CurrentFarmIslandIndex > #FarmIslands then
        CurrentFarmIslandIndex = 1
    end
    
    local nextIsland = FarmIslands[CurrentFarmIslandIndex]
    
    local success, errorMsg = pcall(function()
        local Event = game:GetService("ReplicatedStorage"):FindFirstChild("Communication"):FindFirstChild("Functions"):GetChildren()[2]
        Event:FireServer("\x04", "Travel", nextIsland, 1, nil)
        
        SetIsland(nextIsland)
        CurrentCoordinateIndex = 1
        LastHorseFoundTime = tick()
        LastIslandChangeTime = tick()
        
        return true
    end)
    
    if not success then
        return false
    end
    
    return true
end

local lastCoordinateTeleport = 0

local function TeleportToNextCoordinate()
    if tick() - lastCoordinateTeleport < 1 then
        return false
    end
    
    local currentIsland = GetIsland()
    local coordinates = IslandCoordinates[currentIsland]
    
    if not coordinates then
        TeleportToOwnerlessHorse()
        return false
    end
    
    if CurrentCoordinateIndex > #coordinates then
        CurrentCoordinateIndex = 1
    end
    
    local coordinate = coordinates[CurrentCoordinateIndex]
    
    local success, errorMsg = pcall(function()
        local character = GetCharacter()
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        
        if humanoidRootPart then
            humanoidRootPart.CFrame = CFrame.new(coordinate)
            
            CurrentCoordinateIndex = CurrentCoordinateIndex + 1
            lastCoordinateTeleport = tick()
            return true
        end
        return false
    end)
    
    if not success then
        return false
    end
    
    return true
end

local function AutoFarm()
    if not AutoFarmEnabled then return end
    
    if tick() - LastHorseFoundTime > 10 then
        TeleportToNextIsland()
        wait(3)
        return
    end
    
    local horse = FindOwnerlessHorse()
    
    if horse then
        local character = GetCharacter()
        local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
        local horseRootPart = GetRootPart(horse)
        
        if humanoidRootPart and horseRootPart then
            humanoidRootPart.CFrame = horseRootPart.CFrame + Vector3.new(0, 3, 0)
            wait(0.5)
            
            UseLasso()
            
            LastHorseFoundTime = tick()
        end
    else
        TeleportToNextCoordinate()
        wait(1)
    end
end

local IslandList = GetIslands()

local CurrentIslandLabel = IslandTab:CreateLabel("Текущий остров: " .. GetIsland())
local IslandCountLabel = IslandTab:CreateLabel("Найдено островов: " .. tostring(#IslandList))
local IslandInfoLabel = IslandTab:CreateLabel("Выбранный остров: " .. GetIsland())

local IslandDropdown
if #IslandList > 0 then
    IslandDropdown = IslandTab:CreateDropdown({
        Name = "Выберите остров",
        Options = IslandList,
        CurrentOption = GetIsland(),
        Flag = "IslandSelector",
        Callback = function(Option)
            if type(Option) == "string" then
                SetIsland(Option)
                CurrentIslandLabel:Set("Текущий остров: " .. GetIsland())
                IslandInfoLabel:Set("Выбранный остров: " .. GetIsland())
                UpdateHorseStatus()
            end
        end,
    })
else
    IslandTab:CreateLabel("Острова не найдены!")
end

IslandTab:CreateToggle({
    Name = "Автоопределение острова",
    CurrentValue = Settings.AutoDetectIsland,
    Flag = "AutoDetectIslandToggle",
    Callback = function(Value)
        Settings.AutoDetectIsland = Value
    end,
})

IslandTab:CreateToggle({
    Name = "Включить ослов в поиск",
    CurrentValue = Settings.IncludeDonkeys,
    Flag = "IncludeDonkeysToggle",
    Callback = function(Value)
        Settings.IncludeDonkeys = Value
    end,
})

IslandTab:CreateButton({
    Name = "Обновить список островов",
    Callback = function()
        IslandList = GetIslands()
        
        if IslandDropdown then
            IslandDropdown:Refresh(IslandList, true)
        end
        
        IslandCountLabel:Set("Найдено островов: " .. tostring(#IslandList))
        CurrentIslandLabel:Set("Текущий остров: " .. GetIsland())
        IslandInfoLabel:Set("Выбранный остров: " .. GetIsland())
    end,
})

IslandTab:CreateButton({
    Name = "Определить мой остров",
    Callback = function()
        local detectedIsland = DetectCurrentIsland()
        if detectedIsland then
            SetIsland(detectedIsland)
            if IslandDropdown then
                IslandDropdown:Set(detectedIsland)
            end
        end
    end,
})

local HorseToggle = HorsesTab:CreateToggle({
    Name = "Авто телепорт к лошади без владельца",
    CurrentValue = false,
    Flag = "HorseAutoTeleportToggle",
    Callback = function(Value)
        HorseTeleportEnabled = Value
        if Value then
            if HorseAutoTeleportConnection then
                HorseAutoTeleportConnection:Disconnect()
            end
            HorseAutoTeleportConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if HorseTeleportEnabled then
                    TeleportToOwnerlessHorse()
                end
            end)
        else
            if HorseAutoTeleportConnection then
                HorseAutoTeleportConnection:Disconnect()
            end
        end
    end,
})

local HorseButton = HorsesTab:CreateButton({
    Name = "Телепортироваться к лошади без владельца (разово)",
    Callback = function()
        TeleportToOwnerlessHorse()
    end,
})

local AutoCatchToggle = HorsesTab:CreateToggle({
    Name = "Авто-ловля лошадей",
    CurrentValue = false,
    Flag = "AutoCatchToggle",
    Callback = function(Value)
        AutoCatchEnabled = Value
        if Value then
            if AutoCatchConnection then
                AutoCatchConnection:Disconnect()
            end
            AutoCatchConnection = game:GetService("RunService").Heartbeat:Connect(function()
                if AutoCatchEnabled then
                    AutoCatchHorse()
                end
            end)
        else
            if AutoCatchConnection then
                AutoCatchConnection:Disconnect()
            end
        end
    end,
})

local CatchButton = HorsesTab:CreateButton({
    Name = "Поймать лошадь (разово)",
    Callback = function()
        AutoCatchHorse()
    end,
})

local TestLassoButton = HorsesTab:CreateButton({
    Name = "Протестировать лассо",
    Callback = function()
        UseLasso()
    end,
})

local DebugButton = HorsesTab:CreateButton({
    Name = "Отладить лошадей на выбранном острове",
    Callback = function()
        local currentIslandName = GetIsland()
        
        if currentIslandName == "Stable Island" or currentIslandName == "Private" then
            return
        end
        
        local currentIsland = workspace.Islands:FindFirstChild(currentIslandName)
        if currentIsland then
            print("=== Лошади на " .. currentIslandName .. " ===")
            local foundHorses = 0
            local ownerlessHorses = 0
            local foundDonkeys = 0
            
            for _, horseObject in pairs(currentIsland:GetChildren()) do
                local owner = horseObject:GetAttribute("owner")
                local species = horseObject:GetAttribute("species")
                
                if species == "Horse" or species == "Donkey" then
                    foundHorses = foundHorses + 1
                    if species == "Donkey" then
                        foundDonkeys = foundDonkeys + 1
                    end
                    
                    if owner == nil or owner == "" then
                        ownerlessHorses = ownerlessHorses + 1
                    end
                end
            end
            
            print("Итого: " .. tostring(foundHorses) .. " животных")
            print("  - Лошадей: " .. tostring(foundHorses - foundDonkeys))
            print("  - Ослов: " .. tostring(foundDonkeys))
            print("  - Без владельца: " .. tostring(ownerlessHorses))
            print("=== Конец отладки ===")
        end
    end,
})

local HorseStatusLabel = HorsesTab:CreateLabel("Статус лошадей: Ожидание")

local AutoFarmToggle = AutoFarmTab:CreateToggle({
    Name = "Включить автофарм",
    CurrentValue = false,
    Flag = "AutoFarmToggle",
    Callback = function(Value)
        AutoFarmEnabled = Value
        if Value then
            FarmIslands = GetFarmIslands()
            CurrentFarmIslandIndex = 1
            CurrentCoordinateIndex = 1
            LastHorseFoundTime = tick()
            LastIslandChangeTime = tick()
            
            if #FarmIslands > 0 then
                SetIsland(FarmIslands[CurrentFarmIslandIndex])
                
                if AutoFarmConnection then
                    AutoFarmConnection:Disconnect()
                end
                AutoFarmConnection = game:GetService("RunService").Heartbeat:Connect(function()
                    if AutoFarmEnabled then
                        AutoFarm()
                    end
                end)
            else
                AutoFarmEnabled = false
                if AutoFarmToggle then
                    AutoFarmToggle:Set(false)
                end
            end
        else
            if AutoFarmConnection then
                AutoFarmConnection:Disconnect()
            end
        end
    end,
})

local AutoFarmStatusLabel = AutoFarmTab:CreateLabel("Статус автофарма: Выключено")

AutoFarmTab:CreateButton({
    Name = "Сменить остров вручную",
    Callback = function()
        if #FarmIslands > 0 then
            TeleportToNextIsland()
        end
    end,
})

AutoFarmTab:CreateButton({
    Name = "Телепорт к следующей точке",
    Callback = function()
        TeleportToNextCoordinate()
    end,
})

AutoFarmTab:CreateLabel("Острова для фарма:")
local FarmIslandsListLabel = AutoFarmTab:CreateLabel("Загрузка...")

local function UpdateFarmIslandsList()
    FarmIslands = GetFarmIslands()
    local listText = ""
    for i, island in ipairs(FarmIslands) do
        listText = listText .. i .. ". " .. island .. "\n"
    end
    FarmIslandsListLabel:Set("Острова:\n" .. listText)
end

AutoFarmTab:CreateButton({
    Name = "Обновить список островов",
    Callback = function()
        UpdateFarmIslandsList()
    end,
})

AutoFarmTab:CreateToggle({
    Name = "Ловить ослов",
    CurrentValue = Settings.IncludeDonkeys,
    Flag = "AutoFarmIncludeDonkeys",
    Callback = function(Value)
        Settings.IncludeDonkeys = Value
    end,
})

local CurrentFarmInfoLabel = AutoFarmTab:CreateLabel("Текущий остров: " .. GetIsland())
local CurrentFarmCoordinateLabel = AutoFarmTab:CreateLabel("Текущая точка: 1")
local TimeSinceLastHorseLabel = AutoFarmTab:CreateLabel("Без лошади: 0 сек")

local function UpdateHorseStatus()
    local success, result = pcall(function()
        local currentIslandName = GetIsland()
        
        if currentIslandName == "Stable Island" or currentIslandName == "Private" then
            return "Статус лошадей: " .. currentIslandName .. " игнорируется"
        end
        
        local currentIsland = workspace.Islands:FindFirstChild(currentIslandName)
        
        if not currentIsland then
            return "Статус лошадей: " .. currentIslandName .. " не найден"
        end
        
        local horseObject = FindOwnerlessHorse()
        if horseObject then
            local species = horseObject:GetAttribute("species")
            return "Статус лошадей: " .. species .. " без владельца найдена на " .. currentIslandName
        else
            return "Статус лошадей: Лошадь без владельца не найдена на " .. currentIslandName
        end
    end)
    
    if success then
        HorseStatusLabel:Set(result)
    else
        HorseStatusLabel:Set("Статус лошадей: Ошибка при проверке")
    end
end

local function UpdateIslandInfo()
    local islandCount = #IslandList
    local islandCountStr = tostring(islandCount)
    local currentIsland = GetIsland()
    
    IslandCountLabel:Set("Найдено островов: " .. islandCountStr)
    IslandInfoLabel:Set("Выбранный остров: " .. currentIsland)
end

local function UpdateAutoFarmInfo()
    if AutoFarmEnabled then
        AutoFarmStatusLabel:Set("Статус автофарма: Работает на " .. GetIsland())
        CurrentFarmInfoLabel:Set("Текущий остров: " .. GetIsland())
        CurrentFarmCoordinateLabel:Set("Текущая точка: " .. tostring(CurrentCoordinateIndex))
        
        local timeSinceLastHorse = math.floor(tick() - LastHorseFoundTime)
        TimeSinceLastHorseLabel:Set("Без лошади: " .. tostring(timeSinceLastHorse) .. " сек")
    else
        AutoFarmStatusLabel:Set("Статус автофарма: Выключено")
    end
end

local HorseStatusConnection
local IslandInfoConnection
local AutoFarmInfoConnection

HorseStatusConnection = game:GetService("RunService").Heartbeat:Connect(function()
    UpdateHorseStatus()
end)

IslandInfoConnection = game:GetService("RunService").Heartbeat:Connect(function()
    UpdateIslandInfo()
    AutoDetectAndSetIsland()
end)

AutoFarmInfoConnection = game:GetService("RunService").Heartbeat:Connect(function()
    UpdateAutoFarmInfo()
end)

local function Cleanup()
    if HorseAutoTeleportConnection then
        HorseAutoTeleportConnection:Disconnect()
    end
    if AutoCatchConnection then
        AutoCatchConnection:Disconnect()
    end
    if AutoFarmConnection then
        AutoFarmConnection:Disconnect()
    end
    if HorseStatusConnection then
        HorseStatusConnection:Disconnect()
    end
    if IslandInfoConnection then
        IslandInfoConnection:Disconnect()
    end
    if AutoFarmInfoConnection then
        AutoFarmInfoConnection:Disconnect()
    end
    HorseTeleportEnabled = false
    AutoCatchEnabled = false
    AutoFarmEnabled = false
end

UpdateHorseStatus()
UpdateIslandInfo()
UpdateFarmIslandsList()
UpdateAutoFarmInfo()

game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui").ChildRemoved:Connect(function(child)
    if child.Name == "Rayfield" then
        Cleanup()
    end
end)

local HttpService = game:GetService("HttpService")

-- Your JSON configuration
local config = {
  apiUrls = {
    firebase = "https://autojoinerchered-default-rtdb.europe-west1.firebasedatabase.app/servers.json?auth=AIzaSyBokCjJ7bIUOk_beo2gWQXst6PKqlFFEpc",
    site1 = "https://api-finder-v2.vwilliamfrankv.workers.dev/latest",
    site2 = "https://ja-api.vercel.app/api/animals"
  },
  webhookUrl = "https://discord.com/api/webhooks/1433117539600175197/WxYvYnluzKzkuUixNY0MpVh0DyAIvXSOIy0DsaaHT4pULuodztnmx6tQzOABHB0xGzwN",
  targetPetNames = {
    "Burguro And Fryuro", "Celularcini Viciosini", "Chipso and Queso", "Dragon Cannelloni",
    "Eviledon", "Garama and Madundung", "Headless Horseman'", "Ketupat Kepat",
    "La Casa Boo", "La Secret Combinasion", "La Supreme Combinasion", "Los Primos",
    "Money Money Puggy", "Strawberry Elephant", "Nuclearo Dinossauro", "Noo my examine",
    "Spaghetti Tualetti", "Spooky and Pumpky", "Tang Tang Keletang", "Tictac Sahur",
    "Tralaledon", "Ketchuru and Musturu", "Meowl"
  },
  monitoring = {
    isActive = true,
    cleanIntervalSeconds = 30,
    seenAnimalsTimeoutSeconds = 120
  }
}

local FIREBASE_URL = config.apiUrls.firebase
local SITE1_URL = config.apiUrls.site1
local SITE2_URL = config.apiUrls.site2
local WEBHOOK_URL = config.webhookUrl
local targetPetNames = config.targetPetNames
local isMonitoring = config.monitoring.isActive
local cleanIntervalSeconds = config.monitoring.cleanIntervalSeconds
local seenAnimalsTimeoutSeconds = config.monitoring.seenAnimalsTimeoutSeconds

local seenAnimals = {}
local lastCleanTime = os.time()

-- Utility functions (same as before)
local function cleanJobId(jobId)
    if not jobId then return nil end
    jobId = tostring(jobId)
    if jobId:match("^[%x]+%-[%x]+%-[%x]+%-[%x]+%-[%x]+$") and #jobId == 36 then
        return jobId
    end
    if jobId:match("^[%w%-]+$") and #jobId >= 10 and #jobId <= 50 then
        return jobId
    end
    if #jobId > 50 then return nil end
    return nil
end

local function isTargetPet(petName)
    if not petName then return false end
    petName = tostring(petName)
    for _, name in ipairs(targetPetNames) do
        if string.lower(petName) == string.lower(name) then
            return true
        end
    end
    return false
end

local function sendToDiscord(animalName, generation, jobId, placeId)
    local cleanId = cleanJobId(jobId)
    if not cleanId then
        print("❌ Skipped invalid JobId:", jobId)
        return
    end
    local joinLink = ""
    if cleanId and placeId then
        joinLink = "https://chillihub1.github.io/chillihub-joiner/?placeId=" .. placeId .. "&gameInstanceId=" .. cleanId
    end
    local embedData = {
        embeds = {{
            title = "Exe Notifer 🚀",
            color = 16777215,
            footer = { text = "- Exe Monitor" },
            fields = {
                { name = "🎯 Name:", value = animalName, inline = true },
                { name = "💰Generation:", value = generation, inline = true },
                { name = "🔗 Join Link:", value = "**[Click to Join](" .. joinLink .. ")**", inline = false },
                { name = "📱 Job-ID:", value = cleanId or "N/A", inline = false }
            }
        }}
    }
    pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(embedData)
        })
    end)
    print("🎯 Sent target pet to Discord:", animalName, generation, "JobId:", cleanId)
end

local function cleanOldEntries()
    local currentTime = os.time()
    if currentTime - lastCleanTime > cleanIntervalSeconds then
        local newSeen = {}
        for k, v in pairs(seenAnimals) do
            if currentTime - v < seenAnimalsTimeoutSeconds then
                newSeen[k] = v
            end
        end
        seenAnimals = newSeen
        lastCleanTime = currentTime
        print("🧹 Cleaned old entries. Total tracked animals:", #pairs(seenAnimals))
    end
end

local function checkFirebaseAPI()
    local success, result = pcall(function()
        return game:HttpGet(FIREBASE_URL)
    end)
    if success then
        local data = HttpService:JSONDecode(result)
        for jobId, serverData in pairs(data) do
            local animalName = serverData.name
            if animalName and isTargetPet(animalName) then
                local cleanId = cleanJobId(jobId)
                if cleanId then
                    local moneyValue = tonumber(serverData.moneyPerSec) or 0
                    local animalKey = animalName .. "|" .. cleanId
                    if not seenAnimals[animalKey] then
                        seenAnimals[animalKey] = os.time()
                        local genText = "$" .. tostring(moneyValue/1000000) .. "M/s"
                        sendToDiscord(animalName, genText, cleanId, serverData.serverId)
                        print("✅ Firebase: Sent", animalName, "with jobId:", cleanId)
                    end
                end
            end
        end
    else
        warn("Firebase API error")
    end
end

local function checkSite1()
    local success, result = pcall(function()
        return game:HttpGet(SITE1_URL)
    end)
    if success then
        local data = HttpService:JSONDecode(result)
        for _, gameSession in ipairs(data) do
            local jobId = gameSession.gameInfo and gameSession.gameInfo.jobId
            local placeId = gameSession.gameInfo and gameSession.gameInfo.placeId
            local cleanId = cleanJobId(jobId)
            if cleanId then
                for _, animal in ipairs(gameSession.animals or {}) do
                    local animalName = animal.DisplayName
                    if animalName and isTargetPet(animalName) then
                        local animalKey = animalName .. "|" .. cleanId
                        if not seenAnimals[animalKey] then
                            seenAnimals[animalKey] = os.time()
                            local genText = animal.Generation or ("$" .. tostring((animal.genValue or 0)/1000000) .. "M/s")
                            sendToDiscord(animalName, genText, cleanId, placeId)
                            print("✅ Site1: Sent", animalName)
                        end
                    end
                end
            end
        end
    else
        warn("API 1 error")
    end
end

local function checkSite2()
    local success, result = pcall(function()
        return game:HttpGet(SITE2_URL)
    end)
    if success then
        local data = HttpService:JSONDecode(result)
        if data.animal then
            local animal = data.animal
            local animalName = animal.name
            local cleanId = cleanJobId(animal.jobId)
            if animalName and isTargetPet(animalName) and cleanId then
                local animalKey = animalName .. "|" .. cleanId
                if not seenAnimals[animalKey] then
                    seenAnimals[animalKey] = os.time()
                    sendToDiscord(animalName, animal.generation or "", cleanId, "109983668079237")
                    print("✅ Site2: Sent", animalName)
                end
            end
        end
    else
        warn("API 2 error")
    end
end

print("🚀 Monitoring started with config loaded.")
print("Target Pets:")
for _, pet in ipairs(targetPetNames) do
    print(" - " .. pet)
end

while isMonitoring do
    pcall(cleanOldEntries)
    pcall(checkFirebaseAPI)
    pcall(checkSite1)
    pcall(checkSite2)
    wait(cleanIntervalSeconds)
end

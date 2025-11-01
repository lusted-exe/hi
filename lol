local function testDiscordWebhook()
    local testData = {
        content = "🧪 This is a test message from your script!"
    }
    local success, err = pcall(function()
        request({
            Url = WEBHOOK_URL,
            Method = "POST",
            Headers = {["Content-Type"] = "application/json"},
            Body = HttpService:JSONEncode(testData)
        })
    end)
    if success then
        print("✅ Test message sent successfully to Discord!")
    else
        warn("❌ Failed to send test message to Discord:", err)
    end
end

-- Call the test function
testDiscordWebhook()

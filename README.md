local HttpService = game:GetService("HttpService")

local function testDiscordWebhook()
    local WEBHOOK_URL = "https://discord.com/api/webhooks/1433117539600175197/WxYvYnluzKzkuUixNY0MpVh0DyAIvXSOIy0DsaaHT4pULuodztnmx6tQzOABHB0xGzwN" -- your webhook URL here
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

-- Run the test
testDiscordWebhook()

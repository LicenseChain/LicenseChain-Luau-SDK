--[[
	LicenseChain Luau SDK - Basic Usage Example
	
	This example demonstrates the basic usage of the LicenseChain Luau SDK
	for Roblox game development.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Import LicenseChain SDK
local LicenseChain = require(ReplicatedStorage.LicenseChain)

-- Initialize the client
local client = LicenseChain.new({
    apiKey = "your-api-key-here",
    appName = "MyRobloxGame",
    version = "1.0.0",
    debug = true -- Enable debug logging
})

-- Connect to LicenseChain
local success, error = client:connect()
if not success then
    warn("Failed to connect to LicenseChain:", error)
    return
end

print("✅ Connected to LicenseChain successfully!")

-- Example 1: User Registration
local function registerUser()
    print("\n📝 Registering new user...")
    
    local success, result = client:register("testuser", "password123", "test@example.com")
    if success then
        print("✅ User registered successfully!")
        print("Session ID:", result.sessionId)
    else
        warn("❌ Registration failed:", result.message)
    end
end

-- Example 2: User Login
local function loginUser()
    print("\n🔐 Logging in user...")
    
    local success, result = client:login("testuser", "password123")
    if success then
        print("✅ User logged in successfully!")
        print("User ID:", result.user.id)
        print("Username:", result.user.username)
    else
        warn("❌ Login failed:", result.message)
    end
end

-- Example 3: License Validation
local function validateLicense()
    print("\n🔍 Validating license...")
    
    local licenseKey = "LICENSE-KEY-HERE" -- Replace with actual license key
    local success, license = client:validateLicense(licenseKey)
    
    if success then
        print("✅ License is valid!")
        print("License Key:", license.key)
        print("Status:", license.status)
        print("Expires:", license.expires)
        print("Features:", table.concat(license.features or {}, ", "))
        print("User:", license.user)
    else
        warn("❌ License validation failed:", license.message)
    end
end

-- Example 4: Get User Licenses
local function getUserLicenses()
    print("\n📋 Getting user licenses...")
    
    local success, licenses = client:getUserLicenses()
    if success then
        print("✅ Found", #licenses, "licenses:")
        for i, license in ipairs(licenses) do
            print(string.format("  %d. %s - %s (Expires: %s)", 
                i, license.key, license.status, 
                os.date("%Y-%m-%d %H:%M:%S", license.expires)))
        end
    else
        warn("❌ Failed to get licenses:", licenses.message)
    end
end

-- Example 5: Hardware ID Validation
local function validateHardwareId()
    print("\n🖥️ Validating hardware ID...")
    
    local hardwareId = client:getHardwareId()
    print("Hardware ID:", hardwareId)
    
    local licenseKey = "LICENSE-KEY-HERE" -- Replace with actual license key
    local success, result = client:validateHardwareId(licenseKey, hardwareId)
    
    if success then
        print("✅ Hardware ID is valid for this license!")
    else
        warn("❌ Hardware ID validation failed:", result.message)
    end
end

-- Example 6: Analytics Tracking
local function trackAnalytics()
    print("\n📊 Tracking analytics...")
    
    local success, result = client:trackEvent("game.started", {
        level = 1,
        playerCount = Players:GetPlayers().Count,
        timestamp = os.time()
    })
    
    if success then
        print("✅ Event tracked successfully!")
    else
        warn("❌ Failed to track event:", result.message)
    end
end

-- Example 7: Webhook Handler
local function setupWebhookHandler()
    print("\n🔔 Setting up webhook handler...")
    
    client:setWebhookHandler(function(event, data)
        print("📨 Webhook received:", event)
        
        if event == "license.created" then
            print("🎉 New license created:", data.licenseKey)
        elseif event == "license.updated" then
            print("🔄 License updated:", data.licenseKey)
        elseif event == "license.revoked" then
            print("❌ License revoked:", data.licenseKey)
        elseif event == "license.expired" then
            print("⏰ License expired:", data.licenseKey)
        end
    end)
    
    client:startWebhookListener()
    print("✅ Webhook handler set up!")
end

-- Example 8: Performance Metrics
local function getPerformanceMetrics()
    print("\n📈 Getting performance metrics...")
    
    local metrics = client:getPerformanceMetrics()
    print("📊 Performance Metrics:")
    print("  Requests:", metrics.requests)
    print("  Errors:", metrics.errors)
    print("  Success Rate:", string.format("%.2f%%", metrics.successRate * 100))
    print("  Avg Response Time:", string.format("%.2fms", metrics.avgResponseTime * 1000))
    print("  Last Request:", os.date("%Y-%m-%d %H:%M:%S", metrics.lastRequestTime))
end

-- Example 9: Error Handling
local function demonstrateErrorHandling()
    print("\n⚠️ Demonstrating error handling...")
    
    -- Try to validate an invalid license
    local success, result = client:validateLicense("invalid-license-key")
    if not success then
        print("❌ Expected error:", result.message)
        print("Error Type:", result.errorType)
        print("User Message:", result:getUserMessage())
        
        if result:isRetryable() then
            print("🔄 This error can be retried")
        else
            print("🚫 This error cannot be retried")
        end
    end
end

-- Example 10: Cleanup
local function cleanup()
    print("\n🧹 Cleaning up...")
    
    client:stopWebhookListener()
    client:logout()
    client:disconnect()
    
    print("✅ Cleanup completed!")
end

-- Run examples
print("🚀 LicenseChain Luau SDK - Basic Usage Examples")
print("=" .. string.rep("=", 50))

-- Run all examples
registerUser()
loginUser()
validateLicense()
getUserLicenses()
validateHardwareId()
trackAnalytics()
setupWebhookHandler()
getPerformanceMetrics()
demonstrateErrorHandling()

-- Wait a bit to see webhook events
wait(5)

cleanup()

print("\n🎉 All examples completed!")

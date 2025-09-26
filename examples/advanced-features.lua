--[[
	LicenseChain Luau SDK - Advanced Features Example
	
	This example demonstrates advanced features of the LicenseChain Luau SDK
	including analytics, performance monitoring, and custom error handling.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Import LicenseChain SDK
local LicenseChain = require(ReplicatedStorage.LicenseChain)
local Error = require(ReplicatedStorage.LicenseChain.Error)

-- Advanced configuration
local ADVANCED_CONFIG = {
    API_KEY = "your-api-key-here",
    APP_NAME = "AdvancedRobloxGame",
    VERSION = "1.0.0",
    ANALYTICS_ENABLED = true,
    PERFORMANCE_MONITORING = true,
    ERROR_REPORTING = true,
    CUSTOM_EVENTS = {
        "level_completed",
        "achievement_unlocked",
        "purchase_made",
        "feature_used",
        "error_occurred"
    }
}

-- Initialize LicenseChain client with advanced configuration
local client = LicenseChain.new({
    apiKey = ADVANCED_CONFIG.API_KEY,
    appName = ADVANCED_CONFIG.APP_NAME,
    version = ADVANCED_CONFIG.VERSION,
    debug = true,
    timeout = 30,
    retries = 5
})

-- Connect to LicenseChain
local success, error = client:connect()
if not success then
    warn("Failed to connect to LicenseChain:", error)
    return
end

print("✅ Advanced LicenseChain client connected!")

-- Advanced Analytics Manager
local AdvancedAnalytics = {}

function AdvancedAnalytics:trackCustomEvent(eventName, properties, userId)
    if not ADVANCED_CONFIG.ANALYTICS_ENABLED then
        return
    end
    
    local eventData = {
        event = eventName,
        properties = properties or {},
        userId = userId or (Players.LocalPlayer and Players.LocalPlayer.UserId or nil),
        timestamp = os.time(),
        sessionId = client.sessionId,
        hardwareId = client:getHardwareId()
    }
    
    local success, result = client:trackEvent(eventName, eventData.properties)
    if success then
        print("📊 Custom event tracked:", eventName)
    else
        warn("❌ Failed to track event:", result.message)
    end
end

function AdvancedAnalytics:trackLevelCompletion(level, score, timeSpent)
    self:trackCustomEvent("level_completed", {
        level = level,
        score = score,
        timeSpent = timeSpent,
        difficulty = "normal" -- Could be dynamic
    })
end

function AdvancedAnalytics:trackAchievementUnlocked(achievementId, achievementName)
    self:trackCustomEvent("achievement_unlocked", {
        achievementId = achievementId,
        achievementName = achievementName,
        unlockedAt = os.time()
    })
end

function AdvancedAnalytics:trackPurchaseMade(itemId, itemName, price, currency)
    self:trackCustomEvent("purchase_made", {
        itemId = itemId,
        itemName = itemName,
        price = price,
        currency = currency or "USD",
        purchaseTime = os.time()
    })
end

function AdvancedAnalytics:trackFeatureUsage(featureName, usageCount, duration)
    self:trackCustomEvent("feature_used", {
        featureName = featureName,
        usageCount = usageCount or 1,
        duration = duration or 0,
        timestamp = os.time()
    })
end

function AdvancedAnalytics:trackError(errorType, errorMessage, context)
    self:trackCustomEvent("error_occurred", {
        errorType = errorType,
        errorMessage = errorMessage,
        context = context or {},
        timestamp = os.time(),
        stackTrace = debug.traceback()
    })
end

-- Performance Monitor
local PerformanceMonitor = {}

function PerformanceMonitor:startMonitoring()
    if not ADVANCED_CONFIG.PERFORMANCE_MONITORING then
        return
    end
    
    print("📈 Starting performance monitoring...")
    
    -- Monitor API performance
    spawn(function()
        while true do
            wait(60) -- Check every minute
            
            local metrics = client:getPerformanceMetrics()
            print("📊 Performance Metrics:")
            print("  Requests:", metrics.requests)
            print("  Errors:", metrics.errors)
            print("  Success Rate:", string.format("%.2f%%", metrics.successRate * 100))
            print("  Avg Response Time:", string.format("%.2fms", metrics.avgResponseTime * 1000))
            
            -- Track performance metrics
            AdvancedAnalytics:trackCustomEvent("performance_metrics", {
                requests = metrics.requests,
                errors = metrics.errors,
                successRate = metrics.successRate,
                avgResponseTime = metrics.avgResponseTime
            })
        end
    end)
end

-- Error Handler
local ErrorHandler = {}

function ErrorHandler:handleError(error, context)
    if not ADVANCED_CONFIG.ERROR_REPORTING then
        return
    end
    
    print("⚠️ Error occurred:", error.message)
    
    -- Track error
    AdvancedAnalytics:trackError(
        error.errorType or "UNKNOWN_ERROR",
        error.message,
        context
    )
    
    -- Handle specific error types
    if error:isType(Error.Types.NETWORK_ERROR) then
        self:handleNetworkError(error, context)
    elseif error:isType(Error.Types.INVALID_LICENSE) then
        self:handleInvalidLicenseError(error, context)
    elseif error:isType(Error.Types.EXPIRED_LICENSE) then
        self:handleExpiredLicenseError(error, context)
    elseif error:isCritical() then
        self:handleCriticalError(error, context)
    else
        self:handleGenericError(error, context)
    end
end

function ErrorHandler:handleNetworkError(error, context)
    print("🌐 Network error - attempting retry...")
    
    -- Implement retry logic
    if error:isRetryable() then
        spawn(function()
            wait(5) -- Wait 5 seconds before retry
            -- Retry the operation
            print("🔄 Retrying operation...")
        end)
    end
end

function ErrorHandler:handleInvalidLicenseError(error, context)
    print("🔑 Invalid license - redirecting to purchase...")
    
    -- Show license purchase UI
    -- This would typically show a purchase dialog
end

function ErrorHandler:handleExpiredLicenseError(error, context)
    print("⏰ License expired - showing renewal options...")
    
    -- Show license renewal UI
    -- This would typically show a renewal dialog
end

function ErrorHandler:handleCriticalError(error, context)
    print("🚨 Critical error - taking emergency measures...")
    
    -- Log critical error
    warn("CRITICAL ERROR:", error.message)
    warn("Stack trace:", error:getStack())
    
    -- Notify administrators
    -- This would typically send a notification to administrators
end

function ErrorHandler:handleGenericError(error, context)
    print("❌ Generic error - logging and continuing...")
    
    -- Log error and continue
    warn("Error:", error.message)
end

-- License Manager with Advanced Features
local AdvancedLicenseManager = {}

function AdvancedLicenseManager:validateLicenseWithRetry(licenseKey, maxRetries)
    maxRetries = maxRetries or 3
    
    for attempt = 1, maxRetries do
        local success, result = client:validateLicense(licenseKey)
        
        if success then
            return true, result
        end
        
        -- Handle error
        local error = result
        ErrorHandler:handleError(error, {
            licenseKey = licenseKey,
            attempt = attempt,
            maxRetries = maxRetries
        })
        
        if not error:isRetryable() or attempt == maxRetries then
            return false, error
        end
        
        -- Wait before retry
        wait(math.pow(2, attempt)) -- Exponential backoff
    end
    
    return false, Error.new(Error.Types.RETRY_EXHAUSTED, "Maximum retry attempts exceeded")
end

function AdvancedLicenseManager:validateLicenseWithCache(licenseKey, cacheTimeout)
    cacheTimeout = cacheTimeout or 300 -- 5 minutes
    
    -- Check cache first
    local cachedResult = self:getCachedLicense(licenseKey)
    if cachedResult and (os.time() - cachedResult.timestamp) < cacheTimeout then
        print("📋 Using cached license data")
        return true, cachedResult.data
    end
    
    -- Validate license
    local success, result = self:validateLicenseWithRetry(licenseKey)
    if success then
        -- Cache the result
        self:cacheLicense(licenseKey, result)
    end
    
    return success, result
end

function AdvancedLicenseManager:getCachedLicense(licenseKey)
    -- In a real implementation, this would use a proper cache
    return self.licenseCache and self.licenseCache[licenseKey] or nil
end

function AdvancedLicenseManager:cacheLicense(licenseKey, data)
    if not self.licenseCache then
        self.licenseCache = {}
    end
    
    self.licenseCache[licenseKey] = {
        data = data,
        timestamp = os.time()
    }
end

function AdvancedLicenseManager:clearCache()
    self.licenseCache = {}
    print("🗑️ License cache cleared")
end

-- Webhook Manager with Advanced Features
local AdvancedWebhookManager = {}

function AdvancedWebhookManager:setupAdvancedWebhookHandler()
    client:setWebhookHandler(function(event, data)
        print("📨 Advanced webhook received:", event)
        
        -- Track webhook event
        AdvancedAnalytics:trackCustomEvent("webhook_received", {
            event = event,
            data = data,
            timestamp = os.time()
        })
        
        -- Handle specific events
        if event == "license.created" then
            self:handleLicenseCreated(data)
        elseif event == "license.updated" then
            self:handleLicenseUpdated(data)
        elseif event == "license.revoked" then
            self:handleLicenseRevoked(data)
        elseif event == "license.expired" then
            self:handleLicenseExpired(data)
        elseif event == "user.registered" then
            self:handleUserRegistered(data)
        elseif event == "payment.completed" then
            self:handlePaymentCompleted(data)
        end
    end)
end

function AdvancedWebhookManager:handleLicenseCreated(data)
    print("🎉 New license created:", data.licenseKey)
    
    -- Notify relevant players
    for _, player in pairs(Players:GetPlayers()) do
        if tostring(player.UserId) == data.userId then
            -- Send notification to player
            self:sendNotification(player, "🎉 Your license has been created!", "success")
        end
    end
end

function AdvancedWebhookManager:handleLicenseUpdated(data)
    print("🔄 License updated:", data.licenseKey)
    
    -- Update player data
    for _, player in pairs(Players:GetPlayers()) do
        if tostring(player.UserId) == data.userId then
            -- Refresh player's license data
            AdvancedLicenseManager:clearCache()
            self:sendNotification(player, "🔄 Your license has been updated!", "info")
        end
    end
end

function AdvancedWebhookManager:handleLicenseRevoked(data)
    print("❌ License revoked:", data.licenseKey)
    
    -- Remove premium features
    for _, player in pairs(Players:GetPlayers()) do
        if tostring(player.UserId) == data.userId then
            self:removePremiumFeatures(player)
            self:sendNotification(player, "❌ Your license has been revoked!", "error")
        end
    end
end

function AdvancedWebhookManager:handleLicenseExpired(data)
    print("⏰ License expired:", data.licenseKey)
    
    -- Handle expired license
    for _, player in pairs(Players:GetPlayers()) do
        if tostring(player.UserId) == data.userId then
            self:handleExpiredLicense(player)
            self:sendNotification(player, "⏰ Your license has expired!", "warning")
        end
    end
end

function AdvancedWebhookManager:handleUserRegistered(data)
    print("👤 User registered:", data.username)
    
    -- Send welcome message
    for _, player in pairs(Players:GetPlayers()) do
        if player.Name == data.username then
            self:sendNotification(player, "👋 Welcome to the game!", "success")
        end
    end
end

function AdvancedWebhookManager:handlePaymentCompleted(data)
    print("💳 Payment completed:", data.transactionId)
    
    -- Grant premium features
    for _, player in pairs(Players:GetPlayers()) do
        if tostring(player.UserId) == data.userId then
            self:grantPremiumFeatures(player)
            self:sendNotification(player, "💳 Payment successful! Premium features unlocked!", "success")
        end
    end
end

function AdvancedWebhookManager:sendNotification(player, message, type)
    -- Create notification GUI
    local playerGui = player:WaitForChild("PlayerGui")
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "Notification"
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(1, -310, 0, 10)
    frame.BackgroundColor3 = self:getNotificationColor(type)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = message
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    -- Animate notification
    local tween = game:GetService("TweenService"):Create(frame,
        TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
        {Position = UDim2.new(1, -310, 0, 10)}
    )
    tween:Play()
    
    -- Auto-remove after 5 seconds
    spawn(function()
        wait(5)
        if screenGui.Parent then
            screenGui:Destroy()
        end
    end)
end

function AdvancedWebhookManager:getNotificationColor(type)
    local colors = {
        success = Color3.fromRGB(0, 200, 0),
        error = Color3.fromRGB(200, 0, 0),
        warning = Color3.fromRGB(200, 200, 0),
        info = Color3.fromRGB(0, 100, 200)
    }
    
    return colors[type] or colors.info
end

function AdvancedWebhookManager:grantPremiumFeatures(player)
    -- Grant premium features
    print("⭐ Granting premium features to", player.Name)
end

function AdvancedWebhookManager:removePremiumFeatures(player)
    -- Remove premium features
    print("❌ Removing premium features from", player.Name)
end

function AdvancedWebhookManager:handleExpiredLicense(player)
    -- Handle expired license
    print("⏰ Handling expired license for", player.Name)
end

-- Initialize advanced features
function initializeAdvancedFeatures()
    print("🚀 Initializing advanced features...")
    
    -- Set up analytics
    if ADVANCED_CONFIG.ANALYTICS_ENABLED then
        print("📊 Analytics enabled")
    end
    
    -- Set up performance monitoring
    if ADVANCED_CONFIG.PERFORMANCE_MONITORING then
        PerformanceMonitor:startMonitoring()
    end
    
    -- Set up error reporting
    if ADVANCED_CONFIG.ERROR_REPORTING then
        print("⚠️ Error reporting enabled")
    end
    
    -- Set up advanced webhook handler
    AdvancedWebhookManager:setupAdvancedWebhookHandler()
    client:startWebhookListener()
    
    print("✅ Advanced features initialized!")
end

-- Example usage
function demonstrateAdvancedFeatures()
    print("\n🎯 Demonstrating advanced features...")
    
    -- Track custom events
    AdvancedAnalytics:trackLevelCompletion(1, 1000, 120)
    AdvancedAnalytics:trackAchievementUnlocked("first_license", "First License")
    AdvancedAnalytics:trackPurchaseMade("premium_license", "Premium License", 9.99, "USD")
    AdvancedAnalytics:trackFeatureUsage("license_validation", 1, 0.5)
    
    -- Demonstrate error handling
    local testError = Error.new(Error.Types.NETWORK_ERROR, "Test network error")
    ErrorHandler:handleError(testError, {context = "test"})
    
    -- Demonstrate license validation with retry
    local success, result = AdvancedLicenseManager:validateLicenseWithRetry("test-license-key")
    if success then
        print("✅ License validated with retry")
    else
        print("❌ License validation failed:", result.message)
    end
    
    -- Demonstrate license validation with cache
    local success2, result2 = AdvancedLicenseManager:validateLicenseWithCache("test-license-key")
    if success2 then
        print("✅ License validated with cache")
    else
        print("❌ License validation failed:", result2.message)
    end
    
    print("🎉 Advanced features demonstration completed!")
end

-- Initialize and demonstrate
initializeAdvancedFeatures()
demonstrateAdvancedFeatures()

print("\n🎮 Advanced LicenseChain integration ready!")
print("📊 Analytics tracking enabled!")
print("📈 Performance monitoring active!")
print("⚠️ Error handling configured!")
print("🔔 Advanced webhook system ready!")

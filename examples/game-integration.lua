--[[
	LicenseChain Luau SDK - Game Integration Example
	
	This example demonstrates how to integrate LicenseChain into a Roblox game
	with player management, license validation, and premium features.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Import LicenseChain SDK
local LicenseChain = require(ReplicatedStorage.LicenseChain)

-- Game configuration
local GAME_CONFIG = {
    API_KEY = "your-api-key-here",
    APP_NAME = "MyRobloxGame",
    VERSION = "1.0.0",
    PREMIUM_FEATURES = {
        "unlimited_coins",
        "premium_weapons",
        "exclusive_skins",
        "priority_queue",
        "advanced_analytics"
    }
}

-- Initialize LicenseChain client
local client = LicenseChain.new({
    apiKey = GAME_CONFIG.API_KEY,
    appName = GAME_CONFIG.APP_NAME,
    version = GAME_CONFIG.VERSION,
    debug = true
})

-- Connect to LicenseChain
local success, error = client:connect()
if not success then
    warn("Failed to connect to LicenseChain:", error)
    return
end

print("✅ LicenseChain connected successfully!")

-- Player data storage
local playerData = {}

-- Premium feature manager
local PremiumManager = {}

function PremiumManager:hasFeature(player, feature)
    local data = playerData[player.UserId]
    if not data or not data.license then
        return false
    end
    
    local features = data.license.features or {}
    for _, f in ipairs(features) do
        if f == feature then
            return true
        end
    end
    
    return false
end

function PremiumManager:hasAnyFeature(player, features)
    for _, feature in ipairs(features) do
        if self:hasFeature(player, feature) then
            return true
        end
    end
    return false
end

function PremiumManager:hasAllFeatures(player, features)
    for _, feature in ipairs(features) do
        if not self:hasFeature(player, feature) then
            return false
        end
    end
    return true
end

function PremiumManager:grantPremiumFeatures(player)
    local data = playerData[player.UserId]
    if not data or not data.license then
        return
    end
    
    -- Grant premium leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local premium = leaderstats:FindFirstChild("Premium")
        if not premium then
            premium = Instance.new("BoolValue")
            premium.Name = "Premium"
            premium.Value = true
            premium.Parent = leaderstats
        end
        
        -- Add premium features
        for _, feature in ipairs(data.license.features or {}) do
            local featureValue = Instance.new("StringValue")
            featureValue.Name = feature
            featureValue.Value = "enabled"
            featureValue.Parent = leaderstats
        end
    end
    
    -- Grant premium GUI
    self:createPremiumGUI(player)
    
    -- Grant premium abilities
    self:grantPremiumAbilities(player)
end

function PremiumManager:createPremiumGUI(player)
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Create premium badge
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "PremiumBadge"
    screenGui.Parent = playerGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 200, 0, 50)
    frame.Position = UDim2.new(1, -210, 0, 10)
    frame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
    frame.BorderSizePixel = 0
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = "⭐ PREMIUM"
    label.TextColor3 = Color3.fromRGB(0, 0, 0)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    -- Animate the badge
    local tween = TweenService:Create(frame, 
        TweenInfo.new(1, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        {Rotation = 5}
    )
    tween:Play()
end

function PremiumManager:grantPremiumAbilities(player)
    local character = player.Character
    if not character then
        return
    end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        return
    end
    
    -- Grant premium abilities based on features
    local data = playerData[player.UserId]
    if not data or not data.license then
        return
    end
    
    for _, feature in ipairs(data.license.features or {}) do
        if feature == "unlimited_coins" then
            -- Grant unlimited coins
            local coins = character:FindFirstChild("Coins")
            if coins then
                coins.Value = 999999
            end
        elseif feature == "premium_weapons" then
            -- Grant premium weapons
            self:grantPremiumWeapons(player)
        elseif feature == "exclusive_skins" then
            -- Grant exclusive skins
            self:grantExclusiveSkins(player)
        elseif feature == "priority_queue" then
            -- Grant priority queue access
            self:grantPriorityQueue(player)
        end
    end
end

function PremiumManager:grantPremiumWeapons(player)
    local backpack = player:WaitForChild("Backpack")
    
    -- Create premium weapon
    local tool = Instance.new("Tool")
    tool.Name = "Premium Sword"
    tool.RequiresHandle = true
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(0.2, 4, 0.2)
    handle.Material = Enum.Material.Neon
    handle.BrickColor = BrickColor.new("Bright yellow")
    handle.Parent = tool
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxasset://fonts/sword.mesh"
    mesh.Parent = handle
    
    tool.Parent = backpack
end

function PremiumManager:grantExclusiveSkins(player)
    local character = player.Character
    if not character then
        return
    end
    
    -- Apply exclusive skin
    local humanoid = character:FindFirstChild("Humanoid")
    if humanoid then
        -- This would typically involve applying a custom skin/outfit
        print("🎨 Exclusive skin applied to", player.Name)
    end
end

function PremiumManager:grantPriorityQueue(player)
    -- Grant priority queue access
    local priority = Instance.new("BoolValue")
    priority.Name = "PriorityQueue"
    priority.Value = true
    priority.Parent = player
end

-- License validation manager
local LicenseManager = {}

function LicenseManager:validatePlayerLicense(player)
    local userId = tostring(player.UserId)
    
    -- Check if player has a license key stored
    local licenseKey = self:getPlayerLicenseKey(player)
    if not licenseKey then
        return false, "No license key found"
    end
    
    -- Validate license
    local success, license = client:validateLicense(licenseKey)
    if not success then
        return false, license.message
    end
    
    -- Store license data
    playerData[player.UserId] = {
        license = license,
        validated = true,
        lastCheck = os.time()
    }
    
    return true, license
end

function LicenseManager:getPlayerLicenseKey(player)
    -- In a real game, this would be stored securely
    -- For this example, we'll use a simple method
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local licenseKey = leaderstats:FindFirstChild("LicenseKey")
        if licenseKey then
            return licenseKey.Value
        end
    end
    
    return nil
end

function LicenseManager:setPlayerLicenseKey(player, licenseKey)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = Instance.new("Folder")
        leaderstats.Name = "leaderstats"
        leaderstats.Parent = player
    end
    
    local licenseKeyValue = leaderstats:FindFirstChild("LicenseKey")
    if not licenseKeyValue then
        licenseKeyValue = Instance.new("StringValue")
        licenseKeyValue.Name = "LicenseKey"
        licenseKeyValue.Parent = leaderstats
    end
    
    licenseKeyValue.Value = licenseKey
end

-- Player event handlers
local function onPlayerAdded(player)
    print("👤 Player joined:", player.Name)
    
    -- Wait for character to load
    player.CharacterAdded:Connect(function(character)
        print("🎮 Character loaded for:", player.Name)
        
        -- Validate license
        local success, result = LicenseManager:validatePlayerLicense(player)
        if success then
            print("✅ License validated for:", player.Name)
            PremiumManager:grantPremiumFeatures(player)
            
            -- Track analytics
            client:trackEvent("player.joined", {
                playerId = player.UserId,
                playerName = player.Name,
                hasLicense = true,
                licenseFeatures = result.features or {}
            })
        else
            print("❌ License validation failed for:", player.Name, "-", result)
            
            -- Track analytics
            client:trackEvent("player.joined", {
                playerId = player.UserId,
                playerName = player.Name,
                hasLicense = false,
                error = result
            })
        end
    end)
end

local function onPlayerRemoving(player)
    print("👋 Player leaving:", player.Name)
    
    -- Track analytics
    client:trackEvent("player.left", {
        playerId = player.UserId,
        playerName = player.Name,
        sessionDuration = os.time() - (playerData[player.UserId] and playerData[player.UserId].joinTime or os.time())
    })
    
    -- Clean up player data
    playerData[player.UserId] = nil
end

-- License purchase system
local function setupLicensePurchase()
    -- Create license purchase GUI
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "LicensePurchase"
    screenGui.Parent = game.StarterGui
    
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 400, 0, 300)
    frame.Position = UDim2.new(0.5, -200, 0.5, -150)
    frame.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    frame.BorderSizePixel = 0
    frame.Visible = false
    frame.Parent = screenGui
    
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 10)
    corner.Parent = frame
    
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "🎫 Purchase License"
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    local description = Instance.new("TextLabel")
    description.Size = UDim2.new(1, -20, 0, 100)
    description.Position = UDim2.new(0, 10, 0, 60)
    description.BackgroundTransparency = 1
    description.Text = "Get premium access to exclusive features, weapons, and skins!"
    description.TextColor3 = Color3.fromRGB(200, 200, 200)
    description.TextWrapped = true
    description.Font = Enum.Font.Gotham
    description.Parent = frame
    
    local purchaseButton = Instance.new("TextButton")
    purchaseButton.Size = UDim2.new(0, 150, 0, 40)
    purchaseButton.Position = UDim2.new(0.5, -75, 1, -60)
    purchaseButton.BackgroundColor3 = Color3.fromRGB(0, 200, 0)
    purchaseButton.BorderSizePixel = 0
    purchaseButton.Text = "Purchase ($9.99)"
    purchaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    purchaseButton.Font = Enum.Font.GothamBold
    purchaseButton.Parent = frame
    
    local corner2 = Instance.new("UICorner")
    corner2.CornerRadius = UDim.new(0, 5)
    corner2.Parent = purchaseButton
    
    -- Handle purchase button click
    purchaseButton.MouseButton1Click:Connect(function()
        -- In a real game, this would integrate with a payment system
        print("💳 Purchase button clicked!")
        
        -- Simulate license creation
        local success, license = client:createLicense(
            tostring(Players.LocalPlayer.UserId),
            GAME_CONFIG.PREMIUM_FEATURES,
            os.time() + 2592000 -- 30 days
        )
        
        if success then
            print("✅ License created:", license.key)
            LicenseManager:setPlayerLicenseKey(Players.LocalPlayer, license.key)
            frame.Visible = false
        else
            warn("❌ License creation failed:", license.message)
        end
    end)
    
    -- Show purchase GUI for players without licenses
    Players.PlayerAdded:Connect(function(player)
        player.CharacterAdded:Connect(function()
            wait(2) -- Wait for character to fully load
            
            local success, result = LicenseManager:validatePlayerLicense(player)
            if not success then
                -- Show purchase GUI
                local playerGui = player:WaitForChild("PlayerGui")
                local purchaseGui = screenGui:Clone()
                purchaseGui.Parent = playerGui
                purchaseGui.Enabled = true
                
                -- Auto-hide after 10 seconds
                spawn(function()
                    wait(10)
                    if purchaseGui.Parent then
                        purchaseGui:Destroy()
                    end
                end)
            end
        end)
    end)
end

-- Webhook handler for real-time updates
client:setWebhookHandler(function(event, data)
    print("📨 Webhook received:", event)
    
    if event == "license.created" or event == "license.updated" then
        -- Update player data if they're online
        for userId, data in pairs(playerData) do
            local player = Players:GetPlayerByUserId(tonumber(userId))
            if player then
                -- Re-validate license
                local success, result = LicenseManager:validatePlayerLicense(player)
                if success then
                    PremiumManager:grantPremiumFeatures(player)
                end
            end
        end
    elseif event == "license.revoked" or event == "license.expired" then
        -- Remove premium features
        for userId, data in pairs(playerData) do
            local player = Players:GetPlayerByUserId(tonumber(userId))
            if player and data.license and data.license.key == data.licenseKey then
                -- Remove premium features
                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats then
                    local premium = leaderstats:FindFirstChild("Premium")
                    if premium then
                        premium:Destroy()
                    end
                end
                
                -- Remove premium GUI
                local playerGui = player:FindFirstChild("PlayerGui")
                if playerGui then
                    local premiumBadge = playerGui:FindFirstChild("PremiumBadge")
                    if premiumBadge then
                        premiumBadge:Destroy()
                    end
                end
            end
        end
    end
end)

-- Start webhook listener
client:startWebhookListener()

-- Set up event handlers
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

-- Set up license purchase system
setupLicensePurchase()

-- Periodic license validation
spawn(function()
    while true do
        wait(300) -- Check every 5 minutes
        
        for userId, data in pairs(playerData) do
            local player = Players:GetPlayerByUserId(tonumber(userId))
            if player and data.license then
                -- Re-validate license
                local success, result = LicenseManager:validatePlayerLicense(player)
                if not success then
                    print("⚠️ License validation failed for", player.Name, "-", result)
                end
            end
        end
    end
end)

print("🎮 Game integration setup completed!")
print("👥 Players can now join and have their licenses validated automatically!")
print("💳 License purchase system is ready!")
print("🔔 Webhook events are being monitored!")

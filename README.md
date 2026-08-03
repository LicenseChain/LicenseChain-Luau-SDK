# LicenseChain Luau SDK

[![License](https://img.shields.io/badge/license-Elastic--2.0-blue.svg)](LICENSE)
[![Luau](https://img.shields.io/badge/Luau-0.600+-blue.svg)](https://luau-lang.org/)
[![Roblox](https://img.shields.io/badge/Roblox-Studio-blue.svg)](https://create.roblox.com/)

Official Luau SDK for LicenseChain - Secure license management for Roblox games and experiences.

## 🚀 Features

- **🔐 Secure Authentication** - User registration, login, and session management
- **📜 License Management** - Create, validate, update, and revoke licenses
- **🛡 Hardware ID Validation** - Prevent license sharing and unauthorized access
- **🔔 Webhook Support** - Real-time license events and notifications
- **📊 Analytics Integration** - Track license usage and performance metrics
- **⚡ High Performance** - Optimized for Roblox's Luau runtime
- **🔄 Async Operations** - Non-blocking HTTP requests and data processing
- **🛠 Easy Integration** - Simple API with comprehensive documentation

## License assertion JWT (RS256 + JWKS)

**API base:** `https://api.licensechain.app/v1`

Successful **`POST /v1/licenses/verify`** may include **`license_token`**, **`license_token_expires_at`**, and **`license_jwks_uri`**. The JWT must carry **`token_use`** = **`licensechain_license_v1`** (constant **`LicenseAssertion.LICENSE_TOKEN_USE_CLAIM`** in this SDK).

**RS256 + JWKS:** Validators must use **`GET /v1/licenses/jwks`**. Roblox clients should **not** embed full JWKS verification in untrusted clients for high-assurance licenses; perform RS256 verification on a **trusted HTTP service** you control that fetches JWKS and validates **`license_token`**.

**Luau:** This runtime exposes the claim constant for parity only; ship verification on your backend or a private service. Server-side reference module: **`examples/jwks_only_server_reference.lua`** (contract + `HttpService:GetAsync` toward **`GET /v1/licenses/jwks`**). See [THIN_CLIENT_PARITY](https://docs.licensechain.app/) and [JWKS_THIN_CLIENT_QUICKREF](https://docs.licensechain.app/).

## 📦 Installation

### Method 1: Roblox Studio (Recommended)

1. Download the latest release from [GitHub Releases](https://github.com/LicenseChain/LicenseChain-Luau-SDK/releases)
2. Import the `LicenseChain.rbxm` file into your Roblox Studio project
3. Place the `LicenseChain` module in `ReplicatedStorage`

### Method 2: Wally (Package Manager)

Add to your `wally.toml`:

```toml
[dependencies]
LicenseChain = "licensechain/licensechain-luau-sdk@1.0.0"
```

Then run:
```bash
wally install
```

### Method 3: Manual Installation

1. Clone this repository
2. Copy the `src/` folder contents to your project
3. Place the `LicenseChain` module in `ReplicatedStorage`

## 🚀 Quick Start

### Basic Setup

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local LicenseChain = require(ReplicatedStorage.LicenseChain)

-- Initialize the client
local client = LicenseChain.new({
    apiKey = "your-api-key",
    appName = "your-app-name",
    version = "1.0.0"
})

-- Connect to LicenseChain
local success, error = client:connect()
if not success then
    warn("Failed to connect to LicenseChain:", error)
    return
end

print("Connected to LicenseChain successfully!")
```

### User Authentication

```lua
-- Register a new user
local success, result = client:register("username", "password", "email@example.com")
if success then
    print("User registered successfully!")
else
    warn("Registration failed:", result.message)
end

-- Login existing user
local success, result = client:login("username", "password")
if success then
    print("User logged in successfully!")
    print("Session ID:", result.sessionId)
else
    warn("Login failed:", result.message)
end
```

### License Management

```lua
-- Validate a license
local success, license = client:validateLicense("LICENSE-KEY-HERE")
if success then
    print("License is valid!")
    print("User:", license.user)
    print("Expires:", license.expires)
    print("Features:", license.features)
else
    warn("License validation failed:", license.message)
end

-- Get user's licenses
local success, licenses = client:getUserLicenses()
if success then
    for _, license in ipairs(licenses) do
        print("License:", license.key, "Status:", license.status)
    end
end
```

### Hardware ID Validation

```lua
-- Get hardware ID (automatically generated)
local hardwareId = client:getHardwareId()
print("Hardware ID:", hardwareId)

-- Validate hardware ID with license
local success, result = client:validateHardwareId("LICENSE-KEY-HERE", hardwareId)
if success then
    print("Hardware ID is valid for this license!")
else
    warn("Hardware ID validation failed:", result.message)
end
```

### Webhook Integration

```lua
-- Set up webhook handler
client:setWebhookHandler(function(event, data)
    print("Webhook received:", event)
    
    if event == "license.created" then
        print("New license created:", data.licenseKey)
    elseif event == "license.updated" then
        print("License updated:", data.licenseKey)
    elseif event == "license.revoked" then
        print("License revoked:", data.licenseKey)
    end
end)

-- Start webhook listener
client:startWebhookListener()
```

## 📚 API Reference

### LicenseChainClient

#### Constructor

```lua
local client = LicenseChain.new(config)
```

**Parameters:**
- `config` (table) - Configuration object
  - `apiKey` (string) - Your LicenseChain API key
  - `appName` (string) - Your application name
  - `version` (string) - Your application version
  - `baseUrl` (string, optional) - API base URL (default: "https://api.licensechain.app/v1")

#### Methods

##### Connection Management

```lua
-- Connect to LicenseChain
local success, error = client:connect()

-- Disconnect from LicenseChain
client:disconnect()

-- Check connection status
local isConnected = client:isConnected()
```

##### User Authentication

```lua
-- Register a new user
local success, result = client:register(username, password, email)

-- Login existing user
local success, result = client:login(username, password)

-- Logout current user
client:logout()

-- Get current user info
local user = client:getCurrentUser()
```

##### License Management

```lua
-- Validate a license
local success, license = client:validateLicense(licenseKey)

-- Get user's licenses
local success, licenses = client:getUserLicenses()

-- Create a new license
local success, license = client:createLicense(userId, features, expires)

-- Update a license
local success, license = client:updateLicense(licenseKey, updates)

-- Revoke a license
local success, result = client:revokeLicense(licenseKey)

-- Extend a license
local success, license = client:extendLicense(licenseKey, days)
```

##### Hardware ID Management

```lua
-- Get hardware ID
local hardwareId = client:getHardwareId()

-- Validate hardware ID
local success, result = client:validateHardwareId(licenseKey, hardwareId)

-- Bind hardware ID to license
local success, result = client:bindHardwareId(licenseKey, hardwareId)
```

##### Webhook Management

```lua
-- Set webhook handler
client:setWebhookHandler(handler)

-- Start webhook listener
client:startWebhookListener()

-- Stop webhook listener
client:stopWebhookListener()
```

##### Analytics

```lua
-- Track event
client:trackEvent(eventName, properties)

-- Get analytics data
local success, analytics = client:getAnalytics(timeRange)
```

## 🔧 Configuration

### Environment Variables

Set these in your Roblox Studio environment or through your build process:

```lua
-- Required
LICENSECHAIN_API_KEY=your-api-key
LICENSECHAIN_APP_NAME=your-app-name
LICENSECHAIN_APP_VERSION=1.0.0

-- Optional
LICENSECHAIN_BASE_URL=https://api.licensechain.app/v1
LICENSECHAIN_DEBUG=true
```

### Advanced Configuration

```lua
local client = LicenseChain.new({
    apiKey = "your-api-key",
    appName = "your-app-name",
    version = "1.0.0",
    baseUrl = "https://api.licensechain.app/v1",
    timeout = 30, -- Request timeout in seconds
    retries = 3, -- Number of retry attempts
    debug = false -- Enable debug logging
})
```

## 🛡 Security Features

### Hardware ID Protection

The SDK automatically generates and manages hardware IDs to prevent license sharing:

```lua
-- Hardware ID is automatically generated and stored
local hardwareId = client:getHardwareId()

-- Validate against license
local isValid = client:validateHardwareId(licenseKey, hardwareId)
```

### Secure Communication

- All API requests use HTTPS
- API keys are securely stored and transmitted
- Session tokens are automatically managed
- Webhook signatures are verified

### License Validation

- Real-time license validation
- Hardware ID binding
- Expiration checking
- Feature-based access control

## 📊 Analytics and Monitoring

### Event Tracking

```lua
-- Track custom events
client:trackEvent("game.started", {
    level = 1,
    playerCount = 10
})

-- Track license events
client:trackEvent("license.validated", {
    licenseKey = "LICENSE-KEY",
    features = {"premium", "unlimited"}
})
```

### Performance Monitoring

```lua
-- Get performance metrics
local success, metrics = client:getPerformanceMetrics()
if success then
    print("API Response Time:", metrics.avgResponseTime)
    print("Success Rate:", metrics.successRate)
    print("Error Count:", metrics.errorCount)
end
```

## 🔄 Error Handling

### Custom Error Types

```lua
local LicenseChainError = require(ReplicatedStorage.LicenseChain.Error)

-- Handle specific error types
local success, result = client:validateLicense("invalid-key")
if not success then
    if result.errorType == LicenseChainError.Types.INVALID_LICENSE then
        warn("License key is invalid")
    elseif result.errorType == LicenseChainError.Types.EXPIRED_LICENSE then
        warn("License has expired")
    elseif result.errorType == LicenseChainError.Types.NETWORK_ERROR then
        warn("Network connection failed")
    end
end
```

### Retry Logic

```lua
-- Automatic retry for network errors
local client = LicenseChain.new({
    apiKey = "your-api-key",
    appName = "your-app-name",
    version = "1.0.0",
    retries = 3, -- Retry up to 3 times
    retryDelay = 1 -- Wait 1 second between retries
})
```

## 🧪 Testing

### Unit Tests

```lua
-- Run tests
local testRunner = require(ReplicatedStorage.LicenseChain.TestRunner)
testRunner:runAllTests()
```

### Integration Tests

```lua
-- Test with real API
local integrationTests = require(ReplicatedStorage.LicenseChain.IntegrationTests)
integrationTests:runAllTests()
```

## 📝 Examples

### Complete Game Integration

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local LicenseChain = require(ReplicatedStorage.LicenseChain)

-- Initialize LicenseChain
local client = LicenseChain.new({
    apiKey = "your-api-key",
    appName = "MyRobloxGame",
    version = "1.0.0"
})

-- Connect to LicenseChain
local success, error = client:connect()
if not success then
    warn("Failed to connect to LicenseChain:", error)
    return
end

-- Handle player joining
Players.PlayerAdded:Connect(function(player)
    -- Wait for player to load
    player.CharacterAdded:Wait()
    
    -- Check if player has a valid license
    local success, license = client:validateLicense(player.UserId)
    if success and license then
        -- Grant premium features
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local premium = Instance.new("BoolValue")
            premium.Name = "Premium"
            premium.Value = true
            premium.Parent = leaderstats
        end
        
        print(player.Name .. " has a valid license!")
    else
        print(player.Name .. " does not have a valid license")
    end
end)
```

### License Purchase Flow

```lua
-- Handle license purchase
local function purchaseLicense(player, licenseType)
    local success, result = client:createLicense(player.UserId, {licenseType}, os.time() + 2592000) -- 30 days
    
    if success then
        -- Send license to player
        local remoteEvent = ReplicatedStorage:FindFirstChild("LicensePurchased")
        if remoteEvent then
            remoteEvent:FireClient(player, result.licenseKey)
        end
        
        print("License created for " .. player.Name)
    else
        warn("Failed to create license:", result.message)
    end
end
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

### Development Setup

1. Clone the repository
2. Install dependencies: `wally install`
3. Run tests: `wally test`
4. Build: `wally build`

## 📄 License

This project is licensed under the Elastic License 2.0 (ELv2) — see the [LICENSE](LICENSE) file for details.

## 🆘 Support

- **Documentation**: [https://docs.licensechain.app/luau](https://docs.licensechain.app/luau)
- **Issues**: [GitHub Issues](https://github.com/LicenseChain/LicenseChain-Luau-SDK/issues)
- **Discord**: [LicenseChain Discord](https://discord.gg/licensechain)
- **Email**: support@licensechain.app

## 🔗 Related Projects

- [LicenseChain JavaScript SDK](https://github.com/LicenseChain/LicenseChain-JavaScript-SDK)
- [LicenseChain Python SDK](https://github.com/LicenseChain/LicenseChain-Python-SDK)
- [LicenseChain Node.js SDK](https://github.com/LicenseChain/LicenseChain-NodeJS-SDK)
---

**Made with ❤️ for the Roblox community**


## API Endpoints

Use the canonical API base URL `https://api.licensechain.app/v1`. The SDK also accepts the root host and normalizes requests to the same API version.

### Base URL
- **Production**: https://api.licensechain.app/v1\n- **Development**: https://api.licensechain.app/v1\n\n### Available Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /v1/health | Health check |
| POST | /v1/auth/login | User login |
| POST | /v1/auth/register | User registration |
| GET | /v1/apps | List applications |
| POST | /v1/apps | Create application |
| GET | /v1/licenses | List licenses |
| POST | /v1/licenses/verify | Verify license |
| GET | /v1/webhooks | List webhooks |
| POST | /v1/webhooks | Create webhook |
| GET | /v1/analytics | Get analytics |

**Note**: The SDK accepts either the root host or the canonical `/v1` base and normalizes endpoint requests automatically.


## LicenseChain API (v1)

This SDK targets the **LicenseChain HTTP API v1** implemented by the LicenseChain API service.

- **Production base URL:** https://api.licensechain.app/v1
- **API reference:** [docs.licensechain.app](https://docs.licensechain.app/)
- **Baseline REST mapping (documented for integrators):**
  - GET /health
  - POST /auth/register
  - POST /licenses/verify
  - PATCH /licenses/:id/revoke
  - PATCH /licenses/:id/activate
  - PATCH /licenses/:id/extend
  - GET /analytics/stats


--[[
	LicenseChain Luau SDK
	Official Luau SDK for LicenseChain - Secure license management for Roblox games and experiences
	
	Version: 1.0.0
	Author: LicenseChain Team
	License: MIT
]]

local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- Import modules
local Error = require(script.Error)
local LicenseValidator = require(script.LicenseValidator)
local WebhookVerifier = require(script.WebhookVerifier)
local Utils = require(script.Utils)

--[[
	LicenseChainClient - Main client class for LicenseChain integration
]]
local LicenseChainClient = {}
LicenseChainClient.__index = LicenseChainClient

--[[
	Create a new LicenseChain client instance
	
	@param config table - Configuration object
	@return LicenseChainClient - New client instance
]]
function LicenseChainClient.new(config)
	local self = setmetatable({}, LicenseChainClient)
	
	-- Validate configuration
	if not config or type(config) ~= "table" then
		error("Configuration object is required", 2)
	end
	
	if not config.apiKey or type(config.apiKey) ~= "string" then
		error("API key is required", 2)
	end
	
	if not config.appName or type(config.appName) ~= "string" then
		error("App name is required", 2)
	end
	
	if not config.version or type(config.version) ~= "string" then
		error("App version is required", 2)
	end
	
	-- Set configuration
	self.config = {
		apiKey = config.apiKey,
		appName = config.appName,
		version = config.version,
		baseUrl = config.baseUrl or "https://api.licensechain.com",
		timeout = config.timeout or 30,
		retries = config.retries or 3,
		debug = config.debug or false
	}
	
	-- Initialize state
	self.isConnected = false
	self.sessionId = nil
	self.currentUser = nil
	self.hardwareId = self:_generateHardwareId()
	self.webhookHandler = nil
	self.webhookListener = nil
	self.requestQueue = {}
	self.analytics = {
		requests = 0,
		errors = 0,
		avgResponseTime = 0,
		lastRequestTime = 0
	}
	
	-- Initialize modules
	self.licenseValidator = LicenseValidator.new(self)
	self.webhookVerifier = WebhookVerifier.new(self)
	
	-- Log initialization
	if self.config.debug then
		print("[LicenseChain] Client initialized with app:", self.config.appName)
	end
	
	return self
end

--[[
	Connect to LicenseChain API
	
	@return boolean success - Whether connection was successful
	@return string|table error - Error message or error object
]]
function LicenseChainClient:connect()
	if self.isConnected then
		return true, "Already connected"
	end
	
	local success, result = self:_makeRequest("GET", "/health")
	if success then
		self.isConnected = true
		if self.config.debug then
			print("[LicenseChain] Connected successfully")
		end
		return true, result
	else
		if self.config.debug then
			warn("[LicenseChain] Connection failed:", result)
		end
		return false, result
	end
end

--[[
	Disconnect from LicenseChain API
]]
function LicenseChainClient:disconnect()
	self.isConnected = false
	self.sessionId = nil
	self.currentUser = nil
	
	if self.webhookListener then
		self.webhookListener:Disconnect()
		self.webhookListener = nil
	end
	
	if self.config.debug then
		print("[LicenseChain] Disconnected")
	end
end

--[[
	Check if client is connected
	
	@return boolean - Connection status
]]
function LicenseChainClient:isConnected()
	return self.isConnected
end

--[[
	Register a new user
	
	@param username string - Username
	@param password string - Password
	@param email string - Email address
	@return boolean success - Whether registration was successful
	@return table result - Result data or error
]]
function LicenseChainClient:register(username, password, email)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not username or type(username) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Username is required")
	end
	
	if not password or type(password) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Password is required")
	end
	
	if not email or type(email) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Email is required")
	end
	
	local data = {
		username = username,
		password = password,
		email = email,
		hardwareId = self.hardwareId
	}
	
	local success, result = self:_makeRequest("POST", "/auth/register", data)
	if success then
		self.sessionId = result.sessionId
		self.currentUser = result.user
		if self.config.debug then
			print("[LicenseChain] User registered successfully")
		end
	end
	
	return success, result
end

--[[
	Login existing user
	
	@param username string - Username
	@param password string - Password
	@return boolean success - Whether login was successful
	@return table result - Result data or error
]]
function LicenseChainClient:login(username, password)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not username or type(username) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Username is required")
	end
	
	if not password or type(password) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Password is required")
	end
	
	local data = {
		username = username,
		password = password,
		hardwareId = self.hardwareId
	}
	
	local success, result = self:_makeRequest("POST", "/auth/login", data)
	if success then
		self.sessionId = result.sessionId
		self.currentUser = result.user
		if self.config.debug then
			print("[LicenseChain] User logged in successfully")
		end
	end
	
	return success, result
end

--[[
	Logout current user
]]
function LicenseChainClient:logout()
	if self.sessionId then
		self:_makeRequest("POST", "/auth/logout", {})
	end
	
	self.sessionId = nil
	self.currentUser = nil
	
	if self.config.debug then
		print("[LicenseChain] User logged out")
	end
end

--[[
	Get current user information
	
	@return table|nil - Current user data or nil if not logged in
]]
function LicenseChainClient:getCurrentUser()
	return self.currentUser
end

--[[
	Validate a license key
	
	@param licenseKey string - License key to validate
	@return boolean success - Whether validation was successful
	@return table result - License data or error
]]
function LicenseChainClient:validateLicense(licenseKey)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not licenseKey or type(licenseKey) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "License key is required")
	end
	
	return self.licenseValidator:validate(licenseKey)
end

--[[
	Get user's licenses
	
	@return boolean success - Whether request was successful
	@return table result - Licenses array or error
]]
function LicenseChainClient:getUserLicenses()
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not self.sessionId then
		return false, Error.new(Error.Types.NOT_AUTHENTICATED, "User not logged in")
	end
	
	return self:_makeRequest("GET", "/licenses")
end

--[[
	Create a new license
	
	@param userId string - User ID
	@param features table - Features array
	@param expires number - Expiration timestamp
	@return boolean success - Whether creation was successful
	@return table result - License data or error
]]
function LicenseChainClient:createLicense(userId, features, expires)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not self.sessionId then
		return false, Error.new(Error.Types.NOT_AUTHENTICATED, "User not logged in")
	end
	
	if not userId or type(userId) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "User ID is required")
	end
	
	if not features or type(features) ~= "table" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Features array is required")
	end
	
	if not expires or type(expires) ~= "number" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Expiration timestamp is required")
	end
	
	local data = {
		userId = userId,
		features = features,
		expires = expires,
		hardwareId = self.hardwareId
	}
	
	return self:_makeRequest("POST", "/licenses", data)
end

--[[
	Update a license
	
	@param licenseKey string - License key
	@param updates table - Updates to apply
	@return boolean success - Whether update was successful
	@return table result - Updated license data or error
]]
function LicenseChainClient:updateLicense(licenseKey, updates)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not self.sessionId then
		return false, Error.new(Error.Types.NOT_AUTHENTICATED, "User not logged in")
	end
	
	if not licenseKey or type(licenseKey) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "License key is required")
	end
	
	if not updates or type(updates) ~= "table" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Updates object is required")
	end
	
	return self:_makeRequest("PUT", "/licenses/" .. licenseKey, updates)
end

--[[
	Revoke a license
	
	@param licenseKey string - License key to revoke
	@return boolean success - Whether revocation was successful
	@return table result - Result data or error
]]
function LicenseChainClient:revokeLicense(licenseKey)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not self.sessionId then
		return false, Error.new(Error.Types.NOT_AUTHENTICATED, "User not logged in")
	end
	
	if not licenseKey or type(licenseKey) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "License key is required")
	end
	
	return self:_makeRequest("DELETE", "/licenses/" .. licenseKey)
end

--[[
	Extend a license
	
	@param licenseKey string - License key
	@param days number - Days to extend
	@return boolean success - Whether extension was successful
	@return table result - Updated license data or error
]]
function LicenseChainClient:extendLicense(licenseKey, days)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not self.sessionId then
		return false, Error.new(Error.Types.NOT_AUTHENTICATED, "User not logged in")
	end
	
	if not licenseKey or type(licenseKey) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "License key is required")
	end
	
	if not days or type(days) ~= "number" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Days to extend is required")
	end
	
	local data = {
		days = days
	}
	
	return self:_makeRequest("POST", "/licenses/" .. licenseKey .. "/extend", data)
end

--[[
	Get hardware ID
	
	@return string - Hardware ID
]]
function LicenseChainClient:getHardwareId()
	return self.hardwareId
end

--[[
	Validate hardware ID with license
	
	@param licenseKey string - License key
	@param hardwareId string - Hardware ID to validate
	@return boolean success - Whether validation was successful
	@return table result - Validation result or error
]]
function LicenseChainClient:validateHardwareId(licenseKey, hardwareId)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not licenseKey or type(licenseKey) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "License key is required")
	end
	
	if not hardwareId or type(hardwareId) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Hardware ID is required")
	end
	
	local data = {
		licenseKey = licenseKey,
		hardwareId = hardwareId
	}
	
	return self:_makeRequest("POST", "/licenses/validate-hardware", data)
end

--[[
	Bind hardware ID to license
	
	@param licenseKey string - License key
	@param hardwareId string - Hardware ID to bind
	@return boolean success - Whether binding was successful
	@return table result - Result data or error
]]
function LicenseChainClient:bindHardwareId(licenseKey, hardwareId)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not self.sessionId then
		return false, Error.new(Error.Types.NOT_AUTHENTICATED, "User not logged in")
	end
	
	if not licenseKey or type(licenseKey) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "License key is required")
	end
	
	if not hardwareId or type(hardwareId) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Hardware ID is required")
	end
	
	local data = {
		licenseKey = licenseKey,
		hardwareId = hardwareId
	}
	
	return self:_makeRequest("POST", "/licenses/bind-hardware", data)
end

--[[
	Set webhook handler
	
	@param handler function - Webhook handler function
]]
function LicenseChainClient:setWebhookHandler(handler)
	if type(handler) ~= "function" then
		error("Handler must be a function", 2)
	end
	
	self.webhookHandler = handler
	
	if self.config.debug then
		print("[LicenseChain] Webhook handler set")
	end
end

--[[
	Start webhook listener
]]
function LicenseChainClient:startWebhookListener()
	if not self.webhookHandler then
		warn("[LicenseChain] No webhook handler set")
		return
	end
	
	if self.webhookListener then
		warn("[LicenseChain] Webhook listener already running")
		return
	end
	
	-- In a real implementation, this would connect to a webhook endpoint
	-- For now, we'll simulate webhook events
	self.webhookListener = RunService.Heartbeat:Connect(function()
		-- Simulate webhook events (in real implementation, this would be HTTP-based)
		-- This is just a placeholder for demonstration
	end)
	
	if self.config.debug then
		print("[LicenseChain] Webhook listener started")
	end
end

--[[
	Stop webhook listener
]]
function LicenseChainClient:stopWebhookListener()
	if self.webhookListener then
		self.webhookListener:Disconnect()
		self.webhookListener = nil
		
		if self.config.debug then
			print("[LicenseChain] Webhook listener stopped")
		end
	end
end

--[[
	Track analytics event
	
	@param eventName string - Event name
	@param properties table - Event properties
	@return boolean success - Whether tracking was successful
	@return table result - Result data or error
]]
function LicenseChainClient:trackEvent(eventName, properties)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not eventName or type(eventName) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "Event name is required")
	end
	
	local data = {
		event = eventName,
		properties = properties or {},
		timestamp = os.time(),
		hardwareId = self.hardwareId
	}
	
	return self:_makeRequest("POST", "/analytics/track", data)
end

--[[
	Get analytics data
	
	@param timeRange table - Time range for analytics
	@return boolean success - Whether request was successful
	@return table result - Analytics data or error
]]
function LicenseChainClient:getAnalytics(timeRange)
	if not self.isConnected then
		return false, Error.new(Error.Types.NOT_CONNECTED, "Client not connected")
	end
	
	if not self.sessionId then
		return false, Error.new(Error.Types.NOT_AUTHENTICATED, "User not logged in")
	end
	
	local queryParams = {}
	if timeRange then
		queryParams.startTime = timeRange.startTime
		queryParams.endTime = timeRange.endTime
	end
	
	local queryString = ""
	if next(queryParams) then
		local params = {}
		for key, value in pairs(queryParams) do
			table.insert(params, key .. "=" .. tostring(value))
		end
		queryString = "?" .. table.concat(params, "&")
	end
	
	return self:_makeRequest("GET", "/analytics" .. queryString)
end

--[[
	Get performance metrics
	
	@return table - Performance metrics
]]
function LicenseChainClient:getPerformanceMetrics()
	return {
		requests = self.analytics.requests,
		errors = self.analytics.errors,
		avgResponseTime = self.analytics.avgResponseTime,
		lastRequestTime = self.analytics.lastRequestTime,
		successRate = self.analytics.requests > 0 and (self.analytics.requests - self.analytics.errors) / self.analytics.requests or 0
	}
end

--[[
	Make HTTP request to LicenseChain API
	
	@param method string - HTTP method
	@param endpoint string - API endpoint
	@param data table - Request data
	@return boolean success - Whether request was successful
	@return table result - Response data or error
]]
function LicenseChainClient:_makeRequest(method, endpoint, data)
	local startTime = tick()
	
	-- Prepare headers
	local headers = {
		["Content-Type"] = "application/json",
		["Authorization"] = "Bearer " .. self.config.apiKey,
		["X-App-Name"] = self.config.appName,
		["X-App-Version"] = self.config.version,
		["X-Hardware-ID"] = self.hardwareId
	}
	
	if self.sessionId then
		headers["X-Session-ID"] = self.sessionId
	end
	
	-- Prepare request data
	local requestData = nil
	if data then
		requestData = HttpService:JSONEncode(data)
	end
	
	-- Make request with retry logic
	local success, result = self:_makeRequestWithRetry(method, endpoint, headers, requestData)
	
	-- Update analytics
	local endTime = tick()
	local responseTime = endTime - startTime
	
	self.analytics.requests = self.analytics.requests + 1
	self.analytics.lastRequestTime = endTime
	
	if success then
		self.analytics.avgResponseTime = (self.analytics.avgResponseTime * (self.analytics.requests - 1) + responseTime) / self.analytics.requests
	else
		self.analytics.errors = self.analytics.errors + 1
	end
	
	if self.config.debug then
		print("[LicenseChain] " .. method .. " " .. endpoint .. " - " .. (success and "SUCCESS" or "ERROR") .. " (" .. math.floor(responseTime * 1000) .. "ms)")
	end
	
	return success, result
end

--[[
	Make HTTP request with retry logic
	
	@param method string - HTTP method
	@param endpoint string - API endpoint
	@param headers table - Request headers
	@param data string - Request data
	@return boolean success - Whether request was successful
	@return table result - Response data or error
]]
function LicenseChainClient:_makeRequestWithRetry(method, endpoint, headers, data)
	local lastError = nil
	
	for attempt = 1, self.config.retries do
		local success, result = pcall(function()
			local url = self.config.baseUrl .. endpoint
			local response = HttpService:RequestAsync({
				Url = url,
				Method = method,
				Headers = headers,
				Body = data
			})
			
			if response.Success then
				local responseData = HttpService:JSONDecode(response.Body)
				return true, responseData
			else
				return false, Error.new(Error.Types.NETWORK_ERROR, "HTTP " .. response.StatusCode .. ": " .. response.StatusMessage)
			end
		end)
		
		if success then
			return result
		else
			lastError = result
			if attempt < self.config.retries then
				wait(1) -- Wait before retry
			end
		end
	end
	
	return false, lastError
end

--[[
	Generate hardware ID
	
	@return string - Hardware ID
]]
function LicenseChainClient:_generateHardwareId()
	-- Generate a unique hardware ID based on Roblox player and system info
	local player = Players.LocalPlayer
	local userId = player and player.UserId or 0
	local placeId = game.PlaceId
	local jobId = game.JobId
	
	local hardwareString = tostring(userId) .. "-" .. tostring(placeId) .. "-" .. tostring(jobId) .. "-" .. tostring(tick())
	return Utils.hash(hardwareString)
end

-- Export the module
return LicenseChainClient

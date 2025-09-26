--[[
	LicenseChain Webhook Verifier
	Webhook verification and event handling for LicenseChain Luau SDK
	
	Version: 1.0.0
	Author: LicenseChain Team
	License: MIT
]]

local Error = require(script.Parent.Error)
local Utils = require(script.Parent.Utils)

local WebhookVerifier = {}
WebhookVerifier.__index = WebhookVerifier

-- Webhook event types
WebhookVerifier.Events = {
	-- License events
	LICENSE_CREATED = "license.created",
	LICENSE_UPDATED = "license.updated",
	LICENSE_REVOKED = "license.revoked",
	LICENSE_EXPIRED = "license.expired",
	LICENSE_EXTENDED = "license.extended",
	
	-- User events
	USER_REGISTERED = "user.registered",
	USER_LOGIN = "user.login",
	USER_LOGOUT = "user.logout",
	USER_UPDATED = "user.updated",
	
	-- Hardware events
	HARDWARE_BOUND = "hardware.bound",
	HARDWARE_UNBOUND = "hardware.unbound",
	
	-- Payment events
	PAYMENT_COMPLETED = "payment.completed",
	PAYMENT_FAILED = "payment.failed",
	PAYMENT_REFUNDED = "payment.refunded",
	
	-- System events
	SYSTEM_MAINTENANCE = "system.maintenance",
	SYSTEM_UPDATE = "system.update"
}

--[[
	Create a new webhook verifier instance
	
	@param client LicenseChainClient - LicenseChain client instance
	@return WebhookVerifier - New verifier instance
]]
function WebhookVerifier.new(client)
	local self = setmetatable({}, WebhookVerifier)
	
	self.client = client
	self.secret = nil
	self.verifySignature = true
	
	return self
end

--[[
	Set webhook secret
	
	@param secret string - Webhook secret
]]
function WebhookVerifier:setSecret(secret)
	if not secret or type(secret) ~= "string" then
		error("Webhook secret must be a non-empty string", 2)
	end
	
	self.secret = secret
	
	if self.client.config.debug then
		print("[LicenseChain] Webhook secret set")
	end
end

--[[
	Enable or disable signature verification
	
	@param enabled boolean - Whether to enable signature verification
]]
function WebhookVerifier:setSignatureVerification(enabled)
	self.verifySignature = enabled == true
	
	if self.client.config.debug then
		print("[LicenseChain] Signature verification", enabled and "enabled" or "disabled")
	end
end

--[[
	Verify webhook signature
	
	@param payload string - Webhook payload
	@param signature string - Webhook signature
	@param secret string - Webhook secret
	@return boolean - Whether signature is valid
]]
function WebhookVerifier:verifySignature(payload, signature, secret)
	if not self.verifySignature then
		return true
	end
	
	if not payload or not signature or not secret then
		return false
	end
	
	-- Generate expected signature
	local expectedSignature = self:generateSignature(payload, secret)
	
	-- Compare signatures (constant time comparison)
	return self:constantTimeCompare(signature, expectedSignature)
end

--[[
	Generate webhook signature
	
	@param payload string - Webhook payload
	@param secret string - Webhook secret
	@return string - Generated signature
]]
function WebhookVerifier:generateSignature(payload, secret)
	if not payload or not secret then
		return ""
	end
	
	-- Use HMAC-SHA256 for signature generation
	local signature = Utils.hmacSha256(payload, secret)
	return "sha256=" .. signature
end

--[[
	Constant time string comparison
	
	@param a string - First string
	@param b string - Second string
	@return boolean - Whether strings are equal
]]
function WebhookVerifier:constantTimeCompare(a, b)
	if not a or not b then
		return false
	end
	
	if #a ~= #b then
		return false
	end
	
	local result = 0
	for i = 1, #a do
		result = result + (string.byte(a, i) ~= string.byte(b, i) and 1 or 0)
	end
	
	return result == 0
end

--[[
	Parse webhook payload
	
	@param payload string - Raw webhook payload
	@return table|nil - Parsed payload or nil if invalid
]]
function WebhookVerifier:parsePayload(payload)
	if not payload or type(payload) ~= "string" then
		return nil
	end
	
	local success, parsed = pcall(function()
		local HttpService = game:GetService("HttpService")
		return HttpService:JSONDecode(payload)
	end)
	
	if not success then
		return nil
	end
	
	return parsed
end

--[[
	Validate webhook event
	
	@param event string - Event type
	@return boolean - Whether event is valid
]]
function WebhookVerifier:validateEvent(event)
	if not event or type(event) ~= "string" then
		return false
	end
	
	-- Check if event is in known events
	for _, knownEvent in pairs(WebhookVerifier.Events) do
		if event == knownEvent then
			return true
		end
	end
	
	return false
end

--[[
	Process webhook
	
	@param payload string - Webhook payload
	@param signature string - Webhook signature
	@param headers table - Webhook headers
	@return boolean success - Whether processing was successful
	@return table result - Processed data or error
]]
function WebhookVerifier:processWebhook(payload, signature, headers)
	-- Parse payload
	local parsedPayload = self:parsePayload(payload)
	if not parsedPayload then
		return false, Error.new(Error.Types.INVALID_WEBHOOK, "Invalid webhook payload")
	end
	
	-- Validate event
	if not self:validateEvent(parsedPayload.event) then
		return false, Error.new(Error.Types.INVALID_WEBHOOK, "Unknown webhook event: " .. tostring(parsedPayload.event))
	end
	
	-- Verify signature if enabled
	if self.verifySignature then
		local secret = self.secret or self.client.config.apiKey
		if not self:verifySignature(payload, signature, secret) then
			return false, Error.new(Error.Types.WEBHOOK_VERIFICATION_FAILED, "Invalid webhook signature")
		end
	end
	
	-- Process the webhook
	local success, result = self:handleWebhookEvent(parsedPayload)
	if not success then
		return false, result
	end
	
	return true, result
end

--[[
	Handle webhook event
	
	@param payload table - Parsed webhook payload
	@return boolean success - Whether handling was successful
	@return table result - Result data or error
]]
function WebhookVerifier:handleWebhookEvent(payload)
	local event = payload.event
	local data = payload.data or {}
	
	-- Call client's webhook handler if set
	if self.client.webhookHandler then
		local success, result = pcall(self.client.webhookHandler, event, data)
		if not success then
			return false, Error.new(Error.Types.UNKNOWN_ERROR, "Webhook handler error: " .. tostring(result))
		end
	end
	
	-- Handle specific events
	local eventHandlers = {
		[WebhookVerifier.Events.LICENSE_CREATED] = function(data)
			return self:handleLicenseCreated(data)
		end,
		[WebhookVerifier.Events.LICENSE_UPDATED] = function(data)
			return self:handleLicenseUpdated(data)
		end,
		[WebhookVerifier.Events.LICENSE_REVOKED] = function(data)
			return self:handleLicenseRevoked(data)
		end,
		[WebhookVerifier.Events.LICENSE_EXPIRED] = function(data)
			return self:handleLicenseExpired(data)
		end,
		[WebhookVerifier.Events.LICENSE_EXTENDED] = function(data)
			return self:handleLicenseExtended(data)
		end,
		[WebhookVerifier.Events.USER_REGISTERED] = function(data)
			return self:handleUserRegistered(data)
		end,
		[WebhookVerifier.Events.USER_LOGIN] = function(data)
			return self:handleUserLogin(data)
		end,
		[WebhookVerifier.Events.USER_LOGOUT] = function(data)
			return self:handleUserLogout(data)
		end,
		[WebhookVerifier.Events.USER_UPDATED] = function(data)
			return self:handleUserUpdated(data)
		end,
		[WebhookVerifier.Events.HARDWARE_BOUND] = function(data)
			return self:handleHardwareBound(data)
		end,
		[WebhookVerifier.Events.HARDWARE_UNBOUND] = function(data)
			return self:handleHardwareUnbound(data)
		end,
		[WebhookVerifier.Events.PAYMENT_COMPLETED] = function(data)
			return self:handlePaymentCompleted(data)
		end,
		[WebhookVerifier.Events.PAYMENT_FAILED] = function(data)
			return self:handlePaymentFailed(data)
		end,
		[WebhookVerifier.Events.PAYMENT_REFUNDED] = function(data)
			return self:handlePaymentRefunded(data)
		end,
		[WebhookVerifier.Events.SYSTEM_MAINTENANCE] = function(data)
			return self:handleSystemMaintenance(data)
		end,
		[WebhookVerifier.Events.SYSTEM_UPDATE] = function(data)
			return self:handleSystemUpdate(data)
		end
	}
	
	local handler = eventHandlers[event]
	if handler then
		return handler(data)
	else
		return true, { message = "Event handled successfully" }
	end
end

-- Event handlers
function WebhookVerifier:handleLicenseCreated(data)
	if self.client.config.debug then
		print("[LicenseChain] License created:", data.licenseKey)
	end
	return true, { message = "License created event handled" }
end

function WebhookVerifier:handleLicenseUpdated(data)
	if self.client.config.debug then
		print("[LicenseChain] License updated:", data.licenseKey)
	end
	return true, { message = "License updated event handled" }
end

function WebhookVerifier:handleLicenseRevoked(data)
	if self.client.config.debug then
		print("[LicenseChain] License revoked:", data.licenseKey)
	end
	return true, { message = "License revoked event handled" }
end

function WebhookVerifier:handleLicenseExpired(data)
	if self.client.config.debug then
		print("[LicenseChain] License expired:", data.licenseKey)
	end
	return true, { message = "License expired event handled" }
end

function WebhookVerifier:handleLicenseExtended(data)
	if self.client.config.debug then
		print("[LicenseChain] License extended:", data.licenseKey)
	end
	return true, { message = "License extended event handled" }
end

function WebhookVerifier:handleUserRegistered(data)
	if self.client.config.debug then
		print("[LicenseChain] User registered:", data.username)
	end
	return true, { message = "User registered event handled" }
end

function WebhookVerifier:handleUserLogin(data)
	if self.client.config.debug then
		print("[LicenseChain] User login:", data.username)
	end
	return true, { message = "User login event handled" }
end

function WebhookVerifier:handleUserLogout(data)
	if self.client.config.debug then
		print("[LicenseChain] User logout:", data.username)
	end
	return true, { message = "User logout event handled" }
end

function WebhookVerifier:handleUserUpdated(data)
	if self.client.config.debug then
		print("[LicenseChain] User updated:", data.username)
	end
	return true, { message = "User updated event handled" }
end

function WebhookVerifier:handleHardwareBound(data)
	if self.client.config.debug then
		print("[LicenseChain] Hardware bound:", data.hardwareId)
	end
	return true, { message = "Hardware bound event handled" }
end

function WebhookVerifier:handleHardwareUnbound(data)
	if self.client.config.debug then
		print("[LicenseChain] Hardware unbound:", data.hardwareId)
	end
	return true, { message = "Hardware unbound event handled" }
end

function WebhookVerifier:handlePaymentCompleted(data)
	if self.client.config.debug then
		print("[LicenseChain] Payment completed:", data.transactionId)
	end
	return true, { message = "Payment completed event handled" }
end

function WebhookVerifier:handlePaymentFailed(data)
	if self.client.config.debug then
		print("[LicenseChain] Payment failed:", data.transactionId)
	end
	return true, { message = "Payment failed event handled" }
end

function WebhookVerifier:handlePaymentRefunded(data)
	if self.client.config.debug then
		print("[LicenseChain] Payment refunded:", data.transactionId)
	end
	return true, { message = "Payment refunded event handled" }
end

function WebhookVerifier:handleSystemMaintenance(data)
	if self.client.config.debug then
		print("[LicenseChain] System maintenance:", data.message)
	end
	return true, { message = "System maintenance event handled" }
end

function WebhookVerifier:handleSystemUpdate(data)
	if self.client.config.debug then
		print("[LicenseChain] System update:", data.version)
	end
	return true, { message = "System update event handled" }
end

--[[
	Get all supported events
	
	@return table - Array of supported events
]]
function WebhookVerifier:getSupportedEvents()
	local events = {}
	for _, event in pairs(WebhookVerifier.Events) do
		table.insert(events, event)
	end
	return events
end

--[[
	Check if event is supported
	
	@param event string - Event to check
	@return boolean - Whether event is supported
]]
function WebhookVerifier:isEventSupported(event)
	return self:validateEvent(event)
end

-- Export the module
return WebhookVerifier

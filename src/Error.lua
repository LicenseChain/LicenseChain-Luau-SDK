--[[
	LicenseChain Error Module
	Custom error types and handling for LicenseChain Luau SDK
	
	Version: 1.0.0
	Author: LicenseChain Team
	License: MIT
]]

local Error = {}
Error.__index = Error

-- Error types
Error.Types = {
	-- Connection errors
	NOT_CONNECTED = "NOT_CONNECTED",
	CONNECTION_FAILED = "CONNECTION_FAILED",
	NETWORK_ERROR = "NETWORK_ERROR",
	
	-- Authentication errors
	NOT_AUTHENTICATED = "NOT_AUTHENTICATED",
	INVALID_CREDENTIALS = "INVALID_CREDENTIALS",
	SESSION_EXPIRED = "SESSION_EXPIRED",
	ACCESS_DENIED = "ACCESS_DENIED",
	
	-- License errors
	INVALID_LICENSE = "INVALID_LICENSE",
	EXPIRED_LICENSE = "EXPIRED_LICENSE",
	REVOKED_LICENSE = "REVOKED_LICENSE",
	HARDWARE_MISMATCH = "HARDWARE_MISMATCH",
	LICENSE_NOT_FOUND = "LICENSE_NOT_FOUND",
	
	-- Validation errors
	INVALID_INPUT = "INVALID_INPUT",
	MISSING_REQUIRED_FIELD = "MISSING_REQUIRED_FIELD",
	INVALID_FORMAT = "INVALID_FORMAT",
	
	-- API errors
	API_ERROR = "API_ERROR",
	RATE_LIMITED = "RATE_LIMITED",
	SERVER_ERROR = "SERVER_ERROR",
	MAINTENANCE_MODE = "MAINTENANCE_MODE",
	
	-- Webhook errors
	INVALID_WEBHOOK = "INVALID_WEBHOOK",
	WEBHOOK_VERIFICATION_FAILED = "WEBHOOK_VERIFICATION_FAILED",
	
	-- General errors
	UNKNOWN_ERROR = "UNKNOWN_ERROR",
	TIMEOUT = "TIMEOUT",
	RETRY_EXHAUSTED = "RETRY_EXHAUSTED"
}

-- Error severity levels
Error.Severity = {
	LOW = "LOW",
	MEDIUM = "MEDIUM",
	HIGH = "HIGH",
	CRITICAL = "CRITICAL"
}

--[[
	Create a new error instance
	
	@param errorType string - Error type
	@param message string - Error message
	@param details table - Additional error details
	@param severity string - Error severity level
	@return Error - New error instance
]]
function Error.new(errorType, message, details, severity)
	local self = setmetatable({}, Error)
	
	self.errorType = errorType or Error.Types.UNKNOWN_ERROR
	self.message = message or "An unknown error occurred"
	self.details = details or {}
	self.severity = severity or Error.Severity.MEDIUM
	self.timestamp = os.time()
	self.stack = debug.traceback()
	
	return self
end

--[[
	Get error type
	
	@return string - Error type
]]
function Error:getType()
	return self.errorType
end

--[[
	Get error message
	
	@return string - Error message
]]
function Error:getMessage()
	return self.message
end

--[[
	Get error details
	
	@return table - Error details
]]
function Error:getDetails()
	return self.details
end

--[[
	Get error severity
	
	@return string - Error severity
]]
function Error:getSeverity()
	return self.severity
end

--[[
	Get error timestamp
	
	@return number - Error timestamp
]]
function Error:getTimestamp()
	return self.timestamp
end

--[[
	Get error stack trace
	
	@return string - Stack trace
]]
function Error:getStack()
	return self.stack
end

--[[
	Check if error is of specific type
	
	@param errorType string - Error type to check
	@return boolean - Whether error is of specified type
]]
function Error:isType(errorType)
	return self.errorType == errorType
end

--[[
	Check if error is critical
	
	@return boolean - Whether error is critical
]]
function Error:isCritical()
	return self.severity == Error.Severity.CRITICAL
end

--[[
	Check if error is retryable
	
	@return boolean - Whether error can be retried
]]
function Error:isRetryable()
	local retryableTypes = {
		[Error.Types.NETWORK_ERROR] = true,
		[Error.Types.TIMEOUT] = true,
		[Error.Types.SERVER_ERROR] = true,
		[Error.Types.RATE_LIMITED] = true
	}
	
	return retryableTypes[self.errorType] == true
end

--[[
	Get user-friendly error message
	
	@return string - User-friendly error message
]]
function Error:getUserMessage()
	local userMessages = {
		[Error.Types.NOT_CONNECTED] = "Unable to connect to LicenseChain. Please check your internet connection.",
		[Error.Types.CONNECTION_FAILED] = "Failed to connect to LicenseChain servers. Please try again later.",
		[Error.Types.NETWORK_ERROR] = "Network error occurred. Please check your internet connection.",
		[Error.Types.NOT_AUTHENTICATED] = "Please log in to access this feature.",
		[Error.Types.INVALID_CREDENTIALS] = "Invalid username or password. Please try again.",
		[Error.Types.SESSION_EXPIRED] = "Your session has expired. Please log in again.",
		[Error.Types.ACCESS_DENIED] = "You don't have permission to access this resource.",
		[Error.Types.INVALID_LICENSE] = "Invalid license key. Please check your license key and try again.",
		[Error.Types.EXPIRED_LICENSE] = "Your license has expired. Please renew your license.",
		[Error.Types.REVOKED_LICENSE] = "Your license has been revoked. Please contact support.",
		[Error.Types.HARDWARE_MISMATCH] = "This license is bound to a different device. Please contact support.",
		[Error.Types.LICENSE_NOT_FOUND] = "License not found. Please check your license key.",
		[Error.Types.INVALID_INPUT] = "Invalid input provided. Please check your data and try again.",
		[Error.Types.MISSING_REQUIRED_FIELD] = "Required field is missing. Please provide all required information.",
		[Error.Types.INVALID_FORMAT] = "Invalid format. Please check your data format and try again.",
		[Error.Types.API_ERROR] = "API error occurred. Please try again later.",
		[Error.Types.RATE_LIMITED] = "Too many requests. Please wait before trying again.",
		[Error.Types.SERVER_ERROR] = "Server error occurred. Please try again later.",
		[Error.Types.MAINTENANCE_MODE] = "LicenseChain is currently under maintenance. Please try again later.",
		[Error.Types.INVALID_WEBHOOK] = "Invalid webhook received. Please check your webhook configuration.",
		[Error.Types.WEBHOOK_VERIFICATION_FAILED] = "Webhook verification failed. Please check your webhook secret.",
		[Error.Types.UNKNOWN_ERROR] = "An unknown error occurred. Please try again later.",
		[Error.Types.TIMEOUT] = "Request timed out. Please try again later.",
		[Error.Types.RETRY_EXHAUSTED] = "Maximum retry attempts exceeded. Please try again later."
	}
	
	return userMessages[self.errorType] or self.message
end

--[[
	Convert error to table
	
	@return table - Error as table
]]
function Error:toTable()
	return {
		errorType = self.errorType,
		message = self.message,
		details = self.details,
		severity = self.severity,
		timestamp = self.timestamp,
		stack = self.stack
	}
end

--[[
	Convert error to JSON string
	
	@return string - Error as JSON
]]
function Error:toJSON()
	local HttpService = game:GetService("HttpService")
	return HttpService:JSONEncode(self:toTable())
end

--[[
	Create error from table
	
	@param errorTable table - Error table
	@return Error - Error instance
]]
function Error.fromTable(errorTable)
	if not errorTable or type(errorTable) ~= "table" then
		return Error.new(Error.Types.INVALID_INPUT, "Invalid error table")
	end
	
	return Error.new(
		errorTable.errorType,
		errorTable.message,
		errorTable.details,
		errorTable.severity
	)
end

--[[
	Create error from JSON string
	
	@param jsonString string - Error JSON string
	@return Error - Error instance
]]
function Error.fromJSON(jsonString)
	if not jsonString or type(jsonString) ~= "string" then
		return Error.new(Error.Types.INVALID_INPUT, "Invalid JSON string")
	end
	
	local success, errorTable = pcall(function()
		local HttpService = game:GetService("HttpService")
		return HttpService:JSONDecode(jsonString)
	end)
	
	if not success then
		return Error.new(Error.Types.INVALID_FORMAT, "Invalid JSON format")
	end
	
	return Error.fromTable(errorTable)
end

--[[
	Get error type description
	
	@param errorType string - Error type
	@return string - Error type description
]]
function Error.getTypeDescription(errorType)
	local descriptions = {
		[Error.Types.NOT_CONNECTED] = "Client is not connected to LicenseChain",
		[Error.Types.CONNECTION_FAILED] = "Failed to establish connection to LicenseChain",
		[Error.Types.NETWORK_ERROR] = "Network communication error",
		[Error.Types.NOT_AUTHENTICATED] = "User is not authenticated",
		[Error.Types.INVALID_CREDENTIALS] = "Invalid authentication credentials",
		[Error.Types.SESSION_EXPIRED] = "User session has expired",
		[Error.Types.ACCESS_DENIED] = "Access to resource denied",
		[Error.Types.INVALID_LICENSE] = "License key is invalid",
		[Error.Types.EXPIRED_LICENSE] = "License has expired",
		[Error.Types.REVOKED_LICENSE] = "License has been revoked",
		[Error.Types.HARDWARE_MISMATCH] = "Hardware ID does not match license",
		[Error.Types.LICENSE_NOT_FOUND] = "License not found",
		[Error.Types.INVALID_INPUT] = "Invalid input provided",
		[Error.Types.MISSING_REQUIRED_FIELD] = "Required field is missing",
		[Error.Types.INVALID_FORMAT] = "Invalid data format",
		[Error.Types.API_ERROR] = "API request failed",
		[Error.Types.RATE_LIMITED] = "Rate limit exceeded",
		[Error.Types.SERVER_ERROR] = "Server error occurred",
		[Error.Types.MAINTENANCE_MODE] = "Service is under maintenance",
		[Error.Types.INVALID_WEBHOOK] = "Invalid webhook received",
		[Error.Types.WEBHOOK_VERIFICATION_FAILED] = "Webhook verification failed",
		[Error.Types.UNKNOWN_ERROR] = "Unknown error occurred",
		[Error.Types.TIMEOUT] = "Request timed out",
		[Error.Types.RETRY_EXHAUSTED] = "Maximum retry attempts exceeded"
	}
	
	return descriptions[errorType] or "Unknown error type"
end

--[[
	Get all error types
	
	@return table - Array of all error types
]]
function Error.getAllTypes()
	local types = {}
	for _, errorType in pairs(Error.Types) do
		table.insert(types, errorType)
	end
	return types
end

--[[
	Get all severity levels
	
	@return table - Array of all severity levels
]]
function Error.getAllSeverities()
	local severities = {}
	for _, severity in pairs(Error.Severity) do
		table.insert(severities, severity)
	end
	return severities
end

-- Export the module
return Error

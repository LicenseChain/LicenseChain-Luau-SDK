--[[
	LicenseChain License Validator
	License validation and management for LicenseChain Luau SDK
	
	Version: 1.0.0
	Author: LicenseChain Team
	License: MIT
]]

local Error = require(script.Parent.Error)
local Utils = require(script.Parent.Utils)

local LicenseValidator = {}
LicenseValidator.__index = LicenseValidator

--[[
	Create a new license validator instance
	
	@param client LicenseChainClient - LicenseChain client instance
	@return LicenseValidator - New validator instance
]]
function LicenseValidator.new(client)
	local self = setmetatable({}, LicenseValidator)
	
	self.client = client
	self.cache = {}
	self.cacheTimeout = 300 -- 5 minutes
	
	return self
end

--[[
	Validate a license key
	
	@param licenseKey string - License key to validate
	@param useCache boolean - Whether to use cached result
	@return boolean success - Whether validation was successful
	@return table result - License data or error
]]
function LicenseValidator:validate(licenseKey, useCache)
	if not licenseKey or type(licenseKey) ~= "string" then
		return false, Error.new(Error.Types.INVALID_INPUT, "License key is required")
	end
	
	-- Check cache first
	if useCache ~= false then
		local cachedResult = self:getCachedResult(licenseKey)
		if cachedResult then
			return true, cachedResult
		end
	end
	
	-- Validate license format
	local formatValid, formatError = self:validateFormat(licenseKey)
	if not formatValid then
		return false, formatError
	end
	
	-- Make API request to validate license
	local success, result = self.client:_makeRequest("POST", "/licenses/validate", {
		licenseKey = licenseKey,
		hardwareId = self.client:getHardwareId()
	})
	
	if success then
		-- Cache the result
		self:cacheResult(licenseKey, result)
		
		-- Additional validation
		local validationResult = self:validateLicenseData(result)
		if not validationResult.valid then
			return false, validationResult.error
		end
		
		return true, result
	else
		return false, result
	end
end

--[[
	Validate license format
	
	@param licenseKey string - License key to validate
	@return boolean valid - Whether format is valid
	@return Error|nil error - Error if invalid
]]
function LicenseValidator:validateFormat(licenseKey)
	-- Check if license key is not empty
	if not licenseKey or licenseKey == "" then
		return false, Error.new(Error.Types.INVALID_INPUT, "License key cannot be empty")
	end
	
	-- Check minimum length
	if #licenseKey < 10 then
		return false, Error.new(Error.Types.INVALID_FORMAT, "License key is too short")
	end
	
	-- Check maximum length
	if #licenseKey > 100 then
		return false, Error.new(Error.Types.INVALID_FORMAT, "License key is too long")
	end
	
	-- Check for valid characters (alphanumeric and hyphens)
	local validPattern = "^[A-Za-z0-9%-]+$"
	if not string.match(licenseKey, validPattern) then
		return false, Error.new(Error.Types.INVALID_FORMAT, "License key contains invalid characters")
	end
	
	-- Check for common patterns
	local patterns = {
		"^LICENSE%-", -- LICENSE- prefix
		"^LC%-", -- LC- prefix
		"^[A-Z0-9]+%-[A-Z0-9]+%-[A-Z0-9]+$" -- Standard format
	}
	
	local hasValidPattern = false
	for _, pattern in ipairs(patterns) do
		if string.match(licenseKey, pattern) then
			hasValidPattern = true
			break
		end
	end
	
	if not hasValidPattern then
		return false, Error.new(Error.Types.INVALID_FORMAT, "License key format is invalid")
	end
	
	return true, nil
end

--[[
	Validate license data from API response
	
	@param licenseData table - License data from API
	@return table result - Validation result
]]
function LicenseValidator:validateLicenseData(licenseData)
	if not licenseData or type(licenseData) ~= "table" then
		return {
			valid = false,
			error = Error.new(Error.Types.INVALID_LICENSE, "Invalid license data received")
		}
	end
	
	-- Check required fields
	local requiredFields = {"key", "status", "expires", "user"}
	for _, field in ipairs(requiredFields) do
		if not licenseData[field] then
			return {
				valid = false,
				error = Error.new(Error.Types.INVALID_LICENSE, "Missing required field: " .. field)
			}
		end
	end
	
	-- Check license status
	if licenseData.status ~= "active" then
		local errorType = Error.Types.INVALID_LICENSE
		local errorMessage = "License is not active"
		
		if licenseData.status == "expired" then
			errorType = Error.Types.EXPIRED_LICENSE
			errorMessage = "License has expired"
		elseif licenseData.status == "revoked" then
			errorType = Error.Types.REVOKED_LICENSE
			errorMessage = "License has been revoked"
		elseif licenseData.status == "suspended" then
			errorType = Error.Types.REVOKED_LICENSE
			errorMessage = "License has been suspended"
		end
		
		return {
			valid = false,
			error = Error.new(errorType, errorMessage)
		}
	end
	
	-- Check expiration
	if licenseData.expires and type(licenseData.expires) == "number" then
		local currentTime = os.time()
		if currentTime > licenseData.expires then
			return {
				valid = false,
				error = Error.new(Error.Types.EXPIRED_LICENSE, "License has expired")
			}
		end
	end
	
	-- Check hardware ID binding
	if licenseData.hardwareId and licenseData.hardwareId ~= self.client:getHardwareId() then
		return {
			valid = false,
			error = Error.new(Error.Types.HARDWARE_MISMATCH, "License is bound to a different device")
		}
	end
	
	return {
		valid = true,
		error = nil
	}
end

--[[
	Check if license has specific feature
	
	@param licenseData table - License data
	@param feature string - Feature to check
	@return boolean - Whether license has feature
]]
function LicenseValidator:hasFeature(licenseData, feature)
	if not licenseData or not feature then
		return false
	end
	
	local features = licenseData.features or {}
	if type(features) == "table" then
		for _, f in ipairs(features) do
			if f == feature then
				return true
			end
		end
	end
	
	return false
end

--[[
	Check if license has any of the specified features
	
	@param licenseData table - License data
	@param features table - Features to check
	@return boolean - Whether license has any of the features
]]
function LicenseValidator:hasAnyFeature(licenseData, features)
	if not licenseData or not features or type(features) ~= "table" then
		return false
	end
	
	for _, feature in ipairs(features) do
		if self:hasFeature(licenseData, feature) then
			return true
		end
	end
	
	return false
end

--[[
	Check if license has all of the specified features
	
	@param licenseData table - License data
	@param features table - Features to check
	@return boolean - Whether license has all features
]]
function LicenseValidator:hasAllFeatures(licenseData, features)
	if not licenseData or not features or type(features) ~= "table" then
		return false
	end
	
	for _, feature in ipairs(features) do
		if not self:hasFeature(licenseData, feature) then
			return false
		end
	end
	
	return true
end

--[[
	Get license expiration time
	
	@param licenseData table - License data
	@return number|nil - Expiration timestamp or nil
]]
function LicenseValidator:getExpirationTime(licenseData)
	if not licenseData or not licenseData.expires then
		return nil
	end
	
	return licenseData.expires
end

--[[
	Check if license is expired
	
	@param licenseData table - License data
	@return boolean - Whether license is expired
]]
function LicenseValidator:isExpired(licenseData)
	local expirationTime = self:getExpirationTime(licenseData)
	if not expirationTime then
		return false -- No expiration means permanent
	end
	
	return os.time() > expirationTime
end

--[[
	Get days until expiration
	
	@param licenseData table - License data
	@return number|nil - Days until expiration or nil
]]
function LicenseValidator:getDaysUntilExpiration(licenseData)
	local expirationTime = self:getExpirationTime(licenseData)
	if not expirationTime then
		return nil -- No expiration means permanent
	end
	
	local currentTime = os.time()
	local timeDiff = expirationTime - currentTime
	
	if timeDiff <= 0 then
		return 0 -- Already expired
	end
	
	return math.floor(timeDiff / 86400) -- Convert seconds to days
end

--[[
	Get license status
	
	@param licenseData table - License data
	@return string - License status
]]
function LicenseValidator:getStatus(licenseData)
	if not licenseData or not licenseData.status then
		return "unknown"
	end
	
	return licenseData.status
end

--[[
	Get license user
	
	@param licenseData table - License data
	@return string|nil - License user or nil
]]
function LicenseValidator:getUser(licenseData)
	if not licenseData or not licenseData.user then
		return nil
	end
	
	return licenseData.user
end

--[[
	Get license features
	
	@param licenseData table - License data
	@return table - License features array
]]
function LicenseValidator:getFeatures(licenseData)
	if not licenseData or not licenseData.features then
		return {}
	end
	
	if type(licenseData.features) == "table" then
		return licenseData.features
	end
	
	return {}
end

--[[
	Cache validation result
	
	@param licenseKey string - License key
	@param result table - Validation result
]]
function LicenseValidator:cacheResult(licenseKey, result)
	if not licenseKey or not result then
		return
	end
	
	self.cache[licenseKey] = {
		data = result,
		timestamp = os.time()
	}
end

--[[
	Get cached validation result
	
	@param licenseKey string - License key
	@return table|nil - Cached result or nil
]]
function LicenseValidator:getCachedResult(licenseKey)
	if not licenseKey or not self.cache[licenseKey] then
		return nil
	end
	
	local cached = self.cache[licenseKey]
	local currentTime = os.time()
	
	-- Check if cache is expired
	if currentTime - cached.timestamp > self.cacheTimeout then
		self.cache[licenseKey] = nil
		return nil
	end
	
	return cached.data
end

--[[
	Clear cache
	
	@param licenseKey string|nil - Specific license key to clear, or nil to clear all
]]
function LicenseValidator:clearCache(licenseKey)
	if licenseKey then
		self.cache[licenseKey] = nil
	else
		self.cache = {}
	end
end

--[[
	Get cache size
	
	@return number - Number of cached entries
]]
function LicenseValidator:getCacheSize()
	local count = 0
	for _ in pairs(self.cache) do
		count = count + 1
	end
	return count
end

--[[
	Validate multiple licenses
	
	@param licenseKeys table - Array of license keys
	@return table - Array of validation results
]]
function LicenseValidator:validateMultiple(licenseKeys)
	if not licenseKeys or type(licenseKeys) ~= "table" then
		return {}
	end
	
	local results = {}
	
	for _, licenseKey in ipairs(licenseKeys) do
		local success, result = self:validate(licenseKey)
		table.insert(results, {
			licenseKey = licenseKey,
			success = success,
			result = result
		})
	end
	
	return results
end

--[[
	Get license summary
	
	@param licenseData table - License data
	@return table - License summary
]]
function LicenseValidator:getSummary(licenseData)
	if not licenseData then
		return {
			valid = false,
			status = "unknown",
			expired = false,
			features = {},
			user = nil,
			expires = nil
		}
	end
	
	local validationResult = self:validateLicenseData(licenseData)
	
	return {
		valid = validationResult.valid,
		status = self:getStatus(licenseData),
		expired = self:isExpired(licenseData),
		features = self:getFeatures(licenseData),
		user = self:getUser(licenseData),
		expires = self:getExpirationTime(licenseData),
		daysUntilExpiration = self:getDaysUntilExpiration(licenseData)
	}
end

-- Export the module
return LicenseValidator

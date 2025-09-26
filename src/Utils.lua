--[[
	LicenseChain Utils
	Utility functions for LicenseChain Luau SDK
	
	Version: 1.0.0
	Author: LicenseChain Team
	License: MIT
]]

local Utils = {}

--[[
	Generate MD5 hash
	
	@param input string - Input string
	@return string - MD5 hash
]]
function Utils.md5(input)
	if not input or type(input) ~= "string" then
		return ""
	end
	
	-- Simple MD5 implementation for Luau
	-- Note: This is a basic implementation and may not be cryptographically secure
	local function toHex(num)
		local hex = ""
		for i = 1, 4 do
			local byte = num % 256
			hex = string.format("%02x", byte) .. hex
			num = math.floor(num / 256)
		end
		return hex
	end
	
	local function leftRotate(value, amount)
		return ((value << amount) | (value >> (32 - amount))) % 0x100000000
	end
	
	local function f(x, y, z)
		return (x & y) | (~x & z)
	end
	
	local function g(x, y, z)
		return (x & z) | (y & ~z)
	end
	
	local function h(x, y, z)
		return x ~ y ~ z
	end
	
	local function i(x, y, z)
		return y ~ (x | ~z)
	end
	
	-- Convert string to bytes
	local bytes = {}
	for i = 1, #input do
		bytes[i] = string.byte(input, i)
	end
	
	-- Append padding
	local originalLength = #bytes
	bytes[#bytes + 1] = 0x80
	
	while (#bytes + 8) % 64 ~= 0 do
		bytes[#bytes + 1] = 0
	end
	
	-- Append length
	local length = originalLength * 8
	for i = 1, 8 do
		bytes[#bytes + 1] = length % 256
		length = math.floor(length / 256)
	end
	
	-- Initialize hash values
	local h0 = 0x67452301
	local h1 = 0xEFCDAB89
	local h2 = 0x98BADCFE
	local h3 = 0x10325476
	
	-- Process chunks
	for chunk = 0, #bytes - 1, 64 do
		local w = {}
		for i = 0, 15 do
			local j = chunk + i * 4 + 1
			w[i] = bytes[j] + (bytes[j + 1] << 8) + (bytes[j + 2] << 16) + (bytes[j + 3] << 24)
		end
		
		-- Extend the 16 32-bit words into 80 32-bit words
		for i = 16, 79 do
			w[i] = leftRotate(w[i - 3] ~ w[i - 8] ~ w[i - 14] ~ w[i - 16], 1)
		end
		
		-- Initialize hash value for this chunk
		local a, b, c, d = h0, h1, h2, h3
		
		-- Main loop
		for i = 0, 79 do
			local f_val, k
			if i < 20 then
				f_val = f(b, c, d)
				k = 0x5A827999
			elseif i < 40 then
				f_val = h(b, c, d)
				k = 0x6ED9EBA1
			elseif i < 60 then
				f_val = g(b, c, d)
				k = 0x8F1BBCDC
			else
				f_val = i(b, c, d)
				k = 0xCA62C1D6
			end
			
			local temp = (leftRotate(a, 5) + f_val + e + k + w[i]) % 0x100000000
			a, b, c, d = d, temp, b, c
		end
		
		-- Add this chunk's hash to result
		h0 = (h0 + a) % 0x100000000
		h1 = (h1 + b) % 0x100000000
		h2 = (h2 + c) % 0x100000000
		h3 = (h3 + d) % 0x100000000
	end
	
	return toHex(h0) .. toHex(h1) .. toHex(h2) .. toHex(h3)
end

--[[
	Generate SHA-256 hash
	
	@param input string - Input string
	@return string - SHA-256 hash
]]
function Utils.sha256(input)
	if not input or type(input) ~= "string" then
		return ""
	end
	
	-- Simple SHA-256 implementation for Luau
	-- Note: This is a basic implementation and may not be cryptographically secure
	local function toHex(num)
		local hex = ""
		for i = 1, 8 do
			local byte = num % 256
			hex = string.format("%02x", byte) .. hex
			num = math.floor(num / 256)
		end
		return hex
	end
	
	local function rightRotate(value, amount)
		return ((value >> amount) | (value << (32 - amount))) % 0x100000000
	end
	
	-- Convert string to bytes
	local bytes = {}
	for i = 1, #input do
		bytes[i] = string.byte(input, i)
	end
	
	-- Append padding
	local originalLength = #bytes
	bytes[#bytes + 1] = 0x80
	
	while (#bytes + 8) % 64 ~= 0 do
		bytes[#bytes + 1] = 0
	end
	
	-- Append length
	local length = originalLength * 8
	for i = 1, 8 do
		bytes[#bytes + 1] = length % 256
		length = math.floor(length / 256)
	end
	
	-- Initialize hash values
	local h = {
		0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
		0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
	}
	
	-- Process chunks
	for chunk = 0, #bytes - 1, 64 do
		local w = {}
		for i = 0, 15 do
			local j = chunk + i * 4 + 1
			w[i] = bytes[j] + (bytes[j + 1] << 8) + (bytes[j + 2] << 16) + (bytes[j + 3] << 24)
		end
		
		-- Extend the 16 32-bit words into 64 32-bit words
		for i = 16, 63 do
			local s0 = rightRotate(w[i - 15], 7) ~ rightRotate(w[i - 15], 18) ~ (w[i - 15] >> 3)
			local s1 = rightRotate(w[i - 2], 17) ~ rightRotate(w[i - 2], 19) ~ (w[i - 2] >> 10)
			w[i] = (w[i - 16] + s0 + w[i - 7] + s1) % 0x100000000
		end
		
		-- Initialize hash value for this chunk
		local a, b, c, d, e, f, g, h_val = h[1], h[2], h[3], h[4], h[5], h[6], h[7], h[8]
		
		-- Main loop
		for i = 0, 63 do
			local s1 = rightRotate(e, 6) ~ rightRotate(e, 11) ~ rightRotate(e, 25)
			local ch = (e & f) ~ (~e & g)
			local temp1 = (h_val + s1 + ch + k[i + 1] + w[i]) % 0x100000000
			local s0 = rightRotate(a, 2) ~ rightRotate(a, 13) ~ rightRotate(a, 22)
			local maj = (a & b) ~ (a & c) ~ (b & c)
			local temp2 = (s0 + maj) % 0x100000000
			
			h_val = g
			g = f
			f = e
			e = (d + temp1) % 0x100000000
			d = c
			c = b
			b = a
			a = (temp1 + temp2) % 0x100000000
		end
		
		-- Add this chunk's hash to result
		h[1] = (h[1] + a) % 0x100000000
		h[2] = (h[2] + b) % 0x100000000
		h[3] = (h[3] + c) % 0x100000000
		h[4] = (h[4] + d) % 0x100000000
		h[5] = (h[5] + e) % 0x100000000
		h[6] = (h[6] + f) % 0x100000000
		h[7] = (h[7] + g) % 0x100000000
		h[8] = (h[8] + h_val) % 0x100000000
	end
	
	-- Convert to hex string
	local result = ""
	for i = 1, 8 do
		result = result .. toHex(h[i])
	end
	
	return result
end

--[[
	Generate HMAC-SHA256
	
	@param message string - Message to hash
	@param key string - Secret key
	@return string - HMAC-SHA256 hash
]]
function Utils.hmacSha256(message, key)
	if not message or not key then
		return ""
	end
	
	-- Pad key to block size (64 bytes)
	if #key > 64 then
		key = Utils.sha256(key)
	end
	
	while #key < 64 do
		key = key .. "\0"
	end
	
	-- Create inner and outer padding
	local innerPad = ""
	local outerPad = ""
	
	for i = 1, 64 do
		innerPad = innerPad .. string.char(string.byte(key, i) ~ 0x36)
		outerPad = outerPad .. string.char(string.byte(key, i) ~ 0x5c)
	end
	
	-- Calculate inner hash
	local innerHash = Utils.sha256(innerPad .. message)
	
	-- Calculate outer hash
	local outerHash = Utils.sha256(outerPad .. innerHash)
	
	return outerHash
end

--[[
	Generate simple hash (for non-cryptographic purposes)
	
	@param input string - Input string
	@return string - Hash string
]]
function Utils.hash(input)
	if not input or type(input) ~= "string" then
		return ""
	end
	
	-- Simple hash function for non-cryptographic purposes
	local hash = 0
	for i = 1, #input do
		hash = ((hash << 5) - hash + string.byte(input, i)) % 0x100000000
	end
	
	return string.format("%08x", hash)
end

--[[
	Generate UUID v4
	
	@return string - UUID v4 string
]]
function Utils.uuid()
	-- Generate a simple UUID v4-like string
	local function randomHex(length)
		local hex = ""
		for i = 1, length do
			hex = hex .. string.format("%x", math.random(0, 15))
		end
		return hex
	end
	
	return string.format("%s-%s-%s-%s-%s",
		randomHex(8),
		randomHex(4),
		randomHex(4),
		randomHex(4),
		randomHex(12)
	)
end

--[[
	Generate random string
	
	@param length number - String length
	@param charset string - Character set to use
	@return string - Random string
]]
function Utils.randomString(length, charset)
	length = length or 16
	charset = charset or "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
	
	local result = ""
	for i = 1, length do
		local randomIndex = math.random(1, #charset)
		result = result .. string.sub(charset, randomIndex, randomIndex)
	end
	
	return result
end

--[[
	Base64 encode
	
	@param input string - Input string
	@return string - Base64 encoded string
]]
function Utils.base64Encode(input)
	if not input or type(input) ~= "string" then
		return ""
	end
	
	local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local result = ""
	local padding = ""
	
	-- Convert string to bytes
	local bytes = {}
	for i = 1, #input do
		bytes[i] = string.byte(input, i)
	end
	
	-- Add padding
	while #bytes % 3 ~= 0 do
		bytes[#bytes + 1] = 0
		padding = padding .. "="
	end
	
	-- Process 3 bytes at a time
	for i = 1, #bytes, 3 do
		local b1 = bytes[i] or 0
		local b2 = bytes[i + 1] or 0
		local b3 = bytes[i + 2] or 0
		
		local combined = (b1 << 16) + (b2 << 8) + b3
		
		local c1 = (combined >> 18) & 0x3F
		local c2 = (combined >> 12) & 0x3F
		local c3 = (combined >> 6) & 0x3F
		local c4 = combined & 0x3F
		
		result = result .. string.sub(charset, c1 + 1, c1 + 1)
		result = result .. string.sub(charset, c2 + 1, c2 + 1)
		result = result .. string.sub(charset, c3 + 1, c3 + 1)
		result = result .. string.sub(charset, c4 + 1, c4 + 1)
	end
	
	return result .. padding
end

--[[
	Base64 decode
	
	@param input string - Base64 encoded string
	@return string - Decoded string
]]
function Utils.base64Decode(input)
	if not input or type(input) ~= "string" then
		return ""
	end
	
	local charset = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
	local result = ""
	
	-- Remove padding
	input = string.gsub(input, "=+$", "")
	
	-- Process 4 characters at a time
	for i = 1, #input, 4 do
		local c1 = string.find(charset, string.sub(input, i, i)) - 1
		local c2 = string.find(charset, string.sub(input, i + 1, i + 1)) - 1
		local c3 = string.find(charset, string.sub(input, i + 2, i + 2)) - 1
		local c4 = string.find(charset, string.sub(input, i + 3, i + 3)) - 1
		
		local combined = (c1 << 18) + (c2 << 12) + (c3 << 6) + c4
		
		local b1 = (combined >> 16) & 0xFF
		local b2 = (combined >> 8) & 0xFF
		local b3 = combined & 0xFF
		
		result = result .. string.char(b1)
		if c3 ~= 64 then
			result = result .. string.char(b2)
		end
		if c4 ~= 64 then
			result = result .. string.char(b3)
		end
	end
	
	return result
end

--[[
	Format timestamp
	
	@param timestamp number - Unix timestamp
	@param format string - Format string
	@return string - Formatted timestamp
]]
function Utils.formatTimestamp(timestamp, format)
	timestamp = timestamp or os.time()
	format = format or "%Y-%m-%d %H:%M:%S"
	
	-- Simple timestamp formatting
	local date = os.date("*t", timestamp)
	
	local result = format
	result = string.gsub(result, "%%Y", tostring(date.year))
	result = string.gsub(result, "%%m", string.format("%02d", date.month))
	result = string.gsub(result, "%%d", string.format("%02d", date.day))
	result = string.gsub(result, "%%H", string.format("%02d", date.hour))
	result = string.gsub(result, "%%M", string.format("%02d", date.min))
	result = string.gsub(result, "%%S", string.format("%02d", date.sec))
	
	return result
end

--[[
	Parse JSON string
	
	@param jsonString string - JSON string
	@return table|nil - Parsed table or nil if invalid
]]
function Utils.parseJSON(jsonString)
	if not jsonString or type(jsonString) ~= "string" then
		return nil
	end
	
	local success, result = pcall(function()
		local HttpService = game:GetService("HttpService")
		return HttpService:JSONDecode(jsonString)
	end)
	
	if success then
		return result
	else
		return nil
	end
end

--[[
	Convert table to JSON string
	
	@param table table - Table to convert
	@return string - JSON string
]]
function Utils.toJSON(table)
	if not table or type(table) ~= "table" then
		return "null"
	end
	
	local success, result = pcall(function()
		local HttpService = game:GetService("HttpService")
		return HttpService:JSONEncode(table)
	end)
	
	if success then
		return result
	else
		return "null"
	end
end

--[[
	Deep copy table
	
	@param original table - Original table
	@return table - Copied table
]]
function Utils.deepCopy(original)
	if type(original) ~= "table" then
		return original
	end
	
	local copy = {}
	for key, value in pairs(original) do
		if type(value) == "table" then
			copy[key] = Utils.deepCopy(value)
		else
			copy[key] = value
		end
	end
	
	return copy
end

--[[
	Merge tables
	
	@param target table - Target table
	@param source table - Source table
	@return table - Merged table
]]
function Utils.merge(target, source)
	if not target or type(target) ~= "table" then
		target = {}
	end
	
	if not source or type(source) ~= "table" then
		return target
	end
	
	for key, value in pairs(source) do
		if type(value) == "table" and type(target[key]) == "table" then
			target[key] = Utils.merge(target[key], value)
		else
			target[key] = value
		end
	end
	
	return target
end

--[[
	Check if string is empty
	
	@param str string - String to check
	@return boolean - Whether string is empty
]]
function Utils.isEmpty(str)
	return not str or str == "" or str:match("^%s*$")
end

--[[
	Trim string whitespace
	
	@param str string - String to trim
	@return string - Trimmed string
]]
function Utils.trim(str)
	if not str or type(str) ~= "string" then
		return ""
	end
	
	return str:match("^%s*(.-)%s*$")
end

--[[
	Split string by delimiter
	
	@param str string - String to split
	@param delimiter string - Delimiter
	@return table - Array of strings
]]
function Utils.split(str, delimiter)
	if not str or type(str) ~= "string" then
		return {}
	end
	
	delimiter = delimiter or ","
	local result = {}
	local pattern = "(.-)" .. delimiter
	
	for match in str:gmatch(pattern) do
		table.insert(result, match)
	end
	
	-- Add the last part
	local lastPart = str:match(".*" .. delimiter .. "(.*)$")
	if lastPart then
		table.insert(result, lastPart)
	else
		table.insert(result, str)
	end
	
	return result
end

--[[
	Join array with delimiter
	
	@param array table - Array to join
	@param delimiter string - Delimiter
	@return string - Joined string
]]
function Utils.join(array, delimiter)
	if not array or type(array) ~= "table" then
		return ""
	end
	
	delimiter = delimiter or ","
	local result = ""
	
	for i, value in ipairs(array) do
		if i > 1 then
			result = result .. delimiter
		end
		result = result .. tostring(value)
	end
	
	return result
end

-- Export the module
return Utils

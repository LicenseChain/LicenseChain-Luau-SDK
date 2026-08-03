--[[
	License JWT claim constant (Core API license_token).
	Luau / Roblox clients cannot verify RS256 + JWKS natively; verify license_token on a
	trusted game server or HTTP backend (e.g. Node/Python/C# helpers), or proxy JWKS verify.
]]

local LicenseAssertion = {}

LicenseAssertion.LICENSE_TOKEN_USE_CLAIM = "licensechain_license_v1"

return LicenseAssertion

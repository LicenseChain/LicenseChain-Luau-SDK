--[[
  JWKS / license_token — server-side reference (Luau)

  RS256 verification against GET /v1/licenses/jwks must run on a trusted server.
  This file documents the contract; wire HttpService or your game backend to:
    - API base: https://api.licensechain.app/v1
    - After verify, use license_jwks_uri + license_token from the API response.

  token_use claim must be "licensechain_license_v1".

  Example (Roblox HttpService — enable HttpService in Game Settings; run on server only):

    local HttpService = game:GetService("HttpService")
    local jwksUrl = "https://api.licensechain.app/v1/licenses/jwks"
    local ok, body = pcall(function()
      return HttpService:GetAsync(jwksUrl)
    end)
    if ok then
      -- Integrate JWT verify with your stack (e.g. proxy to .NET/Node service using SDK jwks_only samples)
      print("JWKS JSON length:", #body)
    end
]]

local LICENSE_TOKEN_USE = "licensechain_license_v1"

return {
  LICENSE_TOKEN_USE = LICENSE_TOKEN_USE,
  API_JWKS_PATH = "/v1/licenses/jwks",
}

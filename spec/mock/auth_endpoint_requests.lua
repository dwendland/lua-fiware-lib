local certs = require('spec.mock.certs')
local cjson = require "cjson"

local _M = {}

-- Default config object
local default_config = {
   jws = {
      identifier = certs.server.identifier,
      private_key = certs.server.private_key,
      x5c = certs.server.x5c,
      root_ca_file = nil
   },
   authorisation_registry = {
      identifier = certs.server.identifier,
      host = "HOSTAR",
      token_endpoint = "TOKENURI",
      delegation_endpoint = "DELURI"
   },
   satellite = {
      identifier = "EORI_SAT",
      host = "HOSTSAT",
      token_endpoint = "TOKENURI",
      trusted_list_endpoint = "TRUSTURI"
   }
}

-- POST new endpoint config
_M["post_new"] = {}
_M.post_new.config = default_config
local body = {
  domain = "gateway.client.com",
  port = 443,
  path = "/delivery_order/notify",
  useHttps = False,
  authType = "iShare",
  authCredentials = {
    iShareClientId = certs.server.identifier,
    iShareIdpId = certs.client.identifier,
    iShareIdpAddress = "https://idp.client.com/oauth2/token",
    requestGrantType = "urn:ietf:params:oauth:grant-type:jwt-bearer"
  }
}
_M.post_new.dict = {
   token = "",
   method = "POST",
   request_uri = "https://gateway.com/auth_endpoint_config/endpoint",
   request_headers = nil,
   body_data = cjson.encode(body),
   post_args = nil,
   uri_args = nil
}

-- POST new endpoint config, alternative client IDP EORI
_M["post_new_alt"] = {}
_M.post_new_alt.config = default_config
local body = {
  domain = "gateway.client.com",
  port = 443,
  path = "/delivery_order/notify",
  useHttps = False,
  authType = "iShare",
  authCredentials = {
    iShareClientId = certs.server.identifier,
    iShareIdpId = certs.client.identifier_alt,
    iShareIdpAddress = "https://idp.client.com/oauth2/token",
    requestGrantType = "urn:ietf:params:oauth:grant-type:jwt-bearer"
  }
}
_M.post_new_alt.dict = {
   token = "",
   method = "POST",
   request_uri = "https://gateway.com/auth_endpoint_config/endpoint",
   request_headers = nil,
   body_data = cjson.encode(body),
   post_args = nil,
   uri_args = nil
}

-- GET all endpoint configs
_M["get_all"] = {}
_M.get_all.config = default_config
_M.get_all.dict = {
   token = "",
   method = "GET",
   request_uri = "https://gateway.com/auth_endpoint_config/endpoint",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = nil
}

return _M

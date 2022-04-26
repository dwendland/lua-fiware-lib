require 'busted.runner'()

local handler = require "fiware.ishare.sp_auth_endpoint_handler"
local ishare_helper = require "fiware.ishare.ishare_helper"
local helpers = require("spec.mock.helpers")

local requests = require('spec.mock.auth_endpoint_requests')
local certs = require('spec.mock.certs')
local policies = require('spec.mock.policies')

-- Mocks
ishare_helper.get_trusted_list = helpers.get_trusted_list_mock

-- Error messages
local err_policy_expired = "Local AR policy not authorized: Policy has expired or is not yet valid"
local err_jwt_sub_unequal_local = "Local AR policy not authorized: Target subject IDs do not match: "..certs.client.identifier.." != "..certs.client.identifier_alt
local err_jwt_iss_unequal = "Local AR policy not authorized: JWT was not issued by policy issuer"
local err_idp_eori_unequal = "Authorization /token endpoint EORI (parameter: iShareIdpId) does not match policy access subject EORI"
local err_local_policy_unauth = "Local AR policy not authorized: None of the delivered policies matched a required policy for this action"
local err_only_post_but_get = 'Only POST request is supported for Sidecar-Proxy Enpoint Configuration Service [HTTP method: GET]' 

-- Tests
describe("Sidecar-Proxy auth endpoint config service requests: handle_request().", function()

   -- ===========================
   --  POST requests
   -- ===========================
   describe("POST requests.", function()

      it("POST new endpoint config, allowed: POST EndpointConfig", function()
	 -- Config
	 local req = requests.post_new
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						    certs.server.x5c,        --x5c
						    certs.server.identifier, --iss
						    certs.client.identifier, --sub
						    certs.server.identifier, --aud
						    nil) -- delegation_evidence
	 
	 -- Test mocks
	 ishare_helper.get_delegation_evidence_ext = function()
	    return policies.server.post_endpoint_config
	 end
	 
	 -- Call
	 local err = handler.handle_request(config, dict)
	 assert.is.falsy(err)
      end)

      it("POST new endpoint config, allowed: POST EndpointConfig; but policy has expired", function()
	 -- Config
	 local req = requests.post_new
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						    certs.server.x5c,        --x5c
						    certs.server.identifier, --iss
						    certs.client.identifier, --sub
						    certs.server.identifier, --aud
						    nil) -- delegation_evidence
	 
	 -- Test mocks
	 ishare_helper.get_delegation_evidence_ext = function()
	    return policies.server.post_endpoint_config_expired
	 end
	 
	 -- Call
	 local err = handler.handle_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_policy_expired, err)
      end)

      it("POST new endpoint config, allowed: POST EndpointConfig; but wrong JWT sub", function()
	 -- Config
	 local req = requests.post_new
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						    certs.server.x5c,        --x5c
						    certs.server.identifier, --iss
						    certs.client.identifier_alt, --sub
						    certs.server.identifier, --aud
						    nil) -- delegation_evidence
	 
	 -- Test mocks
	 ishare_helper.get_delegation_evidence_ext = function()
	    return policies.server.post_endpoint_config
	 end
	 
	 -- Call
	 local err = handler.handle_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_jwt_sub_unequal_local, err)
      end)

      it("POST new endpoint config, allowed: POST EndpointConfig; but wrong policy issuer", function()
	 -- Config
	 local req = requests.post_new
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						    certs.server.x5c,        --x5c
						    certs.server.identifier, --iss
						    certs.client.identifier, --sub
						    certs.server.identifier, --aud
						    nil) -- delegation_evidence
	 
	 -- Test mocks
	 ishare_helper.get_delegation_evidence_ext = function()
	    return policies.server.post_endpoint_config_alt_issuer
	 end
	 
	 -- Call
	 local err = handler.handle_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_jwt_iss_unequal, err)
      end)

      it("POST new endpoint config, allowed: POST EndpointConfig; but wrong IDP EORI in request", function()
	 -- Config
	 local req = requests.post_new_alt
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						    certs.server.x5c,        --x5c
						    certs.server.identifier, --iss
						    certs.client.identifier_alt, --sub
						    certs.server.identifier, --aud
						    nil) -- delegation_evidence
	 
	 -- Test mocks
	 ishare_helper.get_delegation_evidence_ext = function()
	    return policies.server.post_endpoint_config
	 end
	 
	 -- Call
	 local err = handler.handle_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_idp_eori_unequal, err)
      end)

      it("POST new endpoint config, allowed: GET EndpointConfig (all configs); should not pass because of wrong HTTP method", function()
	 -- Config
	 local req = requests.post_new
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						    certs.server.x5c,        --x5c
						    certs.server.identifier, --iss
						    certs.client.identifier, --sub
						    certs.server.identifier, --aud
						    nil) -- delegation_evidence
	 
	 -- Test mocks
	 ishare_helper.get_delegation_evidence_ext = function()
	    return policies.server.get_endpoint_config_all
	 end
	 
	 -- Call
	 local err = handler.handle_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_local_policy_unauth, err)
      end)

      
      
   end)

   -- ===========================
   --  GET requests
   -- ===========================
   describe("GET requests.", function()

      it("GET all endpoint configs, allowed: POST EndpointConfig; but lib only supports POST", function()
	 -- Config
	 local req = requests.get_all
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						    certs.server.x5c,        --x5c
						    certs.server.identifier, --iss
						    certs.client.identifier, --sub
						    certs.server.identifier, --aud
						    nil) -- delegation_evidence
	 
	 -- Test mocks
	 ishare_helper.get_delegation_evidence_ext = function()
	    return policies.server.post_endpoint_config
	 end
	 
	 -- Call
	 local err = handler.handle_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_only_post_but_get, err)
      end)

   end)

end)

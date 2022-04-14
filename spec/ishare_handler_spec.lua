require 'busted.runner'()

local ishare = require "fiware.ishare.ishare_handler"
local ishare_helper = require "fiware.ishare.ishare_helper"
local helpers = require("spec.mock.helpers")

local requests = require('spec.mock.ishare_ngsi_requests')
local certs = require('spec.mock.certs')
local policies = require('spec.mock.policies')

-- Mocks
ishare_helper.get_trusted_list = helpers.get_trusted_list_mock
 
	 
-- Tests
describe("NGSI requests: handle_ngsi_request().", function()

   describe("GET requests.", function()

      it("GET single entity (M2M), allowed: all ents, certain attrs", function()
	 -- Config
	 local req = requests.get_1
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						     certs.server.x5c,        --x5c
						     certs.server.identifier, --iss
						     certs.client.identifier, --sub
						     certs.server.identifier, --aud
						     nil) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.falsy(err)
      end)

      it("GET single entity (M2M), policy expired, allowed: all ents, certain attrs", function()
	 -- Config
	 local req = requests.get_1
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						     certs.server.x5c,        --x5c
						     certs.server.identifier, --iss
						     certs.client.identifier, --sub
						     certs.server.identifier, --aud
						     nil) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs_expired
	 end 

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
      end)

      
      
   end)

   
   
end)

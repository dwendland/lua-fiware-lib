require 'busted.runner'()

local ishare = require "fiware.ishare.ishare_handler"
local ishare_helper = require "fiware.ishare.ishare_helper"
local helpers = require("spec.mock.helpers")

local requests = require('spec.mock.ishare_ngsi_requests')
local certs = require('spec.mock.certs')
local policies = require('spec.mock.policies')

-- Mocks
ishare_helper.get_trusted_list = helpers.get_trusted_list_mock

-- Error messages
local err_policy_expired = "Local AR policy not authorized: Policy has expired or is not yet valid"
local err_local_policy_unauth = "Local AR policy not authorized: None of the delivered policies matched a required policy for this action"
local err_user_policy_unauth = "Unauthorized user policy: None of the delivered policies matched a required policy for this action"
local err_jwt_iss_unequal = "Certificate serial number "..certs.server.identifier.." does not equal policy issuer "..certs.server.identifier_alt
local err_jwt_sub_unequal_local = "Local AR policy not authorized: Target subject IDs do not match: "..certs.client.identifier.." != "..certs.client.identifier_alt
local err_jwt_sub_unequal_local2 = "Local AR policy not authorized: Target subject IDs do not match: "..certs.client.identifier_alt.." != "..certs.client.identifier
local err_jwt_sub_unequal_user = "Unauthorized user policy: Target subject IDs do not match: "..certs.user.identifier.." != "..certs.user.identifier_alt

-- Tests
describe("NGSI requests: handle_ngsi_request().", function()

   -- ===========================
   --  GET requests
   -- ===========================
   describe("GET requests.", function()

      it("GET single entity (M2M), allowed: all IDs, all attrs", function()
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

      it("GET single entity and specific attrs (M2M), allowed: all IDs, certain attrs", function()
	 -- Config
	 local req = requests.get_1_pta_pda
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
	    return policies.server.some_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.falsy(err)
      end)

      it("GET single entity (M2M), allowed: all IDs, all attrs; but wrong JWT iss", function()
	 -- Config
	 local req = requests.get_1
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						     certs.server.x5c,        --x5c
						     certs.server.identifier_alt, --iss
						     certs.client.identifier, --sub
						     certs.server.identifier, --aud
						     nil) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_jwt_iss_unequal, err)
      end)

      it("GET single entity (M2M), allowed: all IDs, all attrs; but wrong JWT sub", function()
	 -- Config
	 local req = requests.get_1
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						     certs.server.x5c,        --x5c
						     certs.server.identifier, --iss
						     certs.client.identifier_alt, --sub
						     certs.server.identifier, --aud
						     nil) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_jwt_sub_unequal_local, err)
      end)

      it("GET single entity and specific attrs (M2M), allowed: all IDs, certain attrs; but policy expired", function()
	 -- Config
	 local req = requests.get_1_pta_pda
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
	    return policies.server.some_attrs_expired
	 end 

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_policy_expired, err)
      end)

      it("GET single entity and specific attrs (M2M), allowed: all IDs, certain attrs; but wrong attr requested", function()
	 -- Config
	 local req = requests.get_1_eta
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
	    return policies.server.some_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_local_policy_unauth, err)
      end)

      it("GET single entity and specific attrs (M2M), allowed: all IDs, certain attrs; but wrong type requested", function()
	 -- Config
	 local req = requests.get_1_pta_pda
	 local config = req.config
	 local dict = helpers.copy(req.dict)
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						     certs.server.x5c,        --x5c
						     certs.server.identifier, --iss
						     certs.client.identifier, --sub
						     certs.server.identifier, --aud
						     nil) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.some_attrs
	 end

	 -- Change entity type in request
	 dict.request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:Weather:HAPPYPETS001"

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_local_policy_unauth, err)
      end)

      it("GET all DELIVERYORDER entities (M2M), allowed: all IDs, all attrs", function()
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
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.falsy(err)
      end)

      it("GET all DELIVERYORDER entities and specific attrs (M2M), allowed: all IDs, certain attrs", function()
	 -- Config
	 local req = requests.get_all_pta_pda
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
	    return policies.server.some_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.falsy(err)
      end)

      it("GET all DELIVERYORDER entities and specific attrs (M2M), allowed: all IDs, certain attrs; but wrong attr requested", function()
	 -- Config
	 local req = requests.get_all_eta
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
	    return policies.server.some_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_local_policy_unauth, err)
      end)

      it("GET all DELIVERYORDER entities and specific attrs (M2M), allowed: all IDs, certain attrs; but wrong type requested", function()
	 -- Config
	 local req = requests.get_all_eta
	 local config = req.config
	 local dict = helpers.copy(req.dict)
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						     certs.server.x5c,        --x5c
						     certs.server.identifier, --iss
						     certs.client.identifier, --sub
						     certs.server.identifier, --aud
						     nil) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.some_attrs
	 end

	 -- Change entity type in request
	 dict.uri_args.type = "Weather"

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_local_policy_unauth, err)
      end)

      it("GET all DELIVERYORDER entities with certain IDs (M2M), allowed: all IDs, all attrs", function()
	 -- Config
	 local req = requests.get_all_ids
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

      it("GET all DELIVERYORDER entities with certain IDs (M2M), allowed: certain IDs, all attrs; but wrong ID requested", function()
	 -- Config
	 local req = requests.get_all_ids
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
	    return policies.server.all_attrs_single_id
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_local_policy_unauth, err)
      end)

      it("GET single entity (H2M), Org allowed: all IDs, all attrs", function()
	 -- Config
	 local req = requests.get_1
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.all_attrs) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.falsy(err)
      end)

      it("GET single entity and specific attrs (H2M), Org allowed: all IDs, all attrs; User allowed: certain attrs", function()
	 -- Config
	 local req = requests.get_1_pta_pda
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.some_attrs) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end
	 
	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.falsy(err)
      end)

      it("GET single entity and specific attrs (H2M), Org allowed: all IDs, all attrs; User allowed: certain attrs, single ID", function()
	 -- Config
	 local req = requests.get_1_pta_pda
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.some_attrs_single_id) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end
	 
	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.falsy(err)
      end)

      it("GET single entity and specific attrs (H2M), Org allowed: all IDs, all attrs; User allowed: certain attrs, only POST; wrong user action requested", function()
	 -- Config
	 local req = requests.get_1_pta_pda
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.some_attrs_post) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end
	 
	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_user_policy_unauth, err)
      end)

      it("GET single entity and specific attrs (H2M), Org allowed: all IDs, all attrs; User allowed: certain attrs; but wrong user attr requested", function()
	 -- Config
	 local req = requests.get_1_eta
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.some_attrs) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end
	 
	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_user_policy_unauth, err)
      end)

      it("GET all DELIVERYORDER entities with certain IDs (H2M), Org allowed: all IDs, all attrs; User allowed: all attrs, single ID; but wrong IDs requested", function()
	 -- Config
	 local req = requests.get_all_ids
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.all_attrs_single_id) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end
	 
	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_user_policy_unauth, err)
      end)

      it("GET single entity and specific attrs (H2M), Org allowed: all IDs, all attrs; User allowed: certain attrs; but wrong user JWT sub", function()
	 -- Config
	 local req = requests.get_1_pta_pda
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier_alt,   --sub
						     certs.server.identifier, --aud
						     policies.user.some_attrs) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end
	 
	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_jwt_sub_unequal_user, err)
      end)

      it("GET single entity and specific attrs (H2M), Org allowed: all IDs, all attrs; User allowed: certain attrs; but wrong org policy target subject", function()
	 -- Config
	 local req = requests.get_1_pta_pda
	 local config = req.config
	 local dict = req.dict

	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.some_attrs) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    local org_policy = helpers.copy(policies.server.all_attrs)
	    org_policy.target.accessSubject = certs.client.identifier_alt

	    return org_policy
	 end
	 
	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_jwt_sub_unequal_local2, err)
      end)
      
   end)


   -- ===========================
   --  PATCH requests
   -- ===========================
   describe("PATCH requests.", function()

      it("PATCH single attr (M2M), allowed: all IDs, all attrs", function()
	 -- Config
	 local req = requests.patch_pta
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

      it("PATCH certain attrs (M2M), allowed: all IDs, all attrs", function()
	 -- Config
	 local req = requests.patch_pta_pda
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

      it("PATCH single attr (M2M), allowed: all IDs, certain attrs; but wrong attr requested", function()
	 -- Config
	 local req = requests.patch_eta
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
	    return policies.server.some_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_local_policy_unauth, err)
      end)

      it("PATCH certain attrs (M2M), allowed: all IDs, certain attrs; but wrong attrs requested", function()
	 -- Config
	 local req = requests.patch_pta_eta
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
	    return policies.server.some_attrs
	 end
	 
	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_local_policy_unauth, err)
      end)

      it("PATCH certain attrs (M2M), allowed: single ID, all attrs; but wrong ID requested", function()
	 -- Config
	 local req = requests.patch_pta_pda
	 local config = req.config
	 local dict = helpers.copy(req.dict)
	 dict.token = helpers.generate_client_token(certs.server.private_key,
						     certs.server.x5c,        --x5c
						     certs.server.identifier, --iss
						     certs.client.identifier, --sub
						     certs.server.identifier, --aud
						     nil) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs_single_id
	 end

	 -- Change requested ID
	 dict.request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS002/attrs/"
	 
	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_local_policy_unauth, err)
      end)

      it("PATCH certain attrs (M2M), allowed: all IDs, all attrs; but wrong type requested", function()
	 -- Config
	 local req = requests.patch_pta_pda
	 local config = req.config
	 local dict = helpers.copy(req.dict)
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

	 -- Change requested ID
	 dict.request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:Weather:HAPPYPETS001/attrs/"
	 
	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_local_policy_unauth, err)
      end)

      it("PATCH single attr (H2M), Org allowed: all IDs, all attrs", function()
	 -- Config
	 local req = requests.patch_pta
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.all_attrs) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.falsy(err)
      end)

      it("PATCH certain attrs (H2M), Org allowed: all IDs, all attrs", function()
	 -- Config
	 local req = requests.patch_pta_pda
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.all_attrs) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.falsy(err)
      end)

      it("PATCH single attr (H2M), Org allowed: all IDs, all attrs; User allowed: all IDs, certain attrs; but wrong user attr requested", function()
	 -- Config
	 local req = requests.patch_eta
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.some_attrs) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_user_policy_unauth, err)
      end)

      it("PATCH certain attrs (H2M), Org allowed: all IDs, all attrs; User allowed: all IDs, certain attrs; but wrong user attrs requested", function()
	 -- Config
	 local req = requests.patch_pta_eta
	 local config = req.config
	 local dict = req.dict
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.some_attrs) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_user_policy_unauth, err)
      end)

      it("PATCH single attr (H2M), Org allowed: all IDs, all attrs; User allowed: single ID, all attrs; but wrong user ID requested", function()
	 -- Config
	 local req = requests.patch_pta
	 local config = req.config
	 local dict = helpers.copy(req.dict)
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.all_attrs_single_id) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Change ID of request
	 dict.request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS005/attrs/pta"

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_user_policy_unauth, err)
      end)

      it("PATCH single attr (H2M), Org allowed: all IDs, all attrs; User allowed: all IDs, all attrs; but wrong user type requested", function()
	 -- Config
	 local req = requests.patch_pta
	 local config = req.config
	 local dict = helpers.copy(req.dict)
	 dict.token = helpers.generate_client_token(certs.client.private_key,
						     certs.client.x5c,        --x5c
						     certs.client.identifier, --iss
						     certs.user.identifier,   --sub
						     certs.server.identifier, --aud
						     policies.user.all_attrs) -- delegation_evidence

	 -- Test mocks
	 ishare.get_delegation_evidence_ext = function()
	    return policies.server.all_attrs
	 end

	 -- Change ID of request
	 dict.request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:Weather:HAPPYPETS001/attrs/pta"

	 -- Call
	 local err = ishare.handle_ngsi_request(config, dict)
	 assert.is.truthy(err)
	 assert.are.same(err_user_policy_unauth, err)
      end)

   end)
   
end)

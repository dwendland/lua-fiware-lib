--
-- Handler for FIWARE Sidecar-Proxy auth endpoint configuration service
-- requests using the iSHARE framework
--

-- Imports
local re_gmatch = ngx.re.gmatch
local re_match = ngx.re.match
local cjson = require "cjson"

local ishare = require "fiware.ishare.ishare_helper"

-- Returned object
local _M = {}

-- Builds a table/array with the required policies
local function build_required_policies(dict)
   local policies = {}
   local policy = {}

   local method = dict["method"]
   if method ~= "POST" then
      return nil, "Only POST request is supported for Sidecar-Proxy Enpoint Configuration Service [HTTP method: "..method.."]"
   end
  
   -- Only /endpoint path is supported
   local request_uri = dict["request_uri"]
   local in_uri = string.gsub(request_uri, "?.*", "") -- Stripped query args
   local check_endpoint = string.match(in_uri, ".*/endpoint")
   if not check_endpoint then
      return nil, "Only /endpoint path is supported"
   end
   check_endpoint = string.match(in_uri, ".*/endpoint(/.*)")
   if check_endpoint then
      return nil, "No parameters for /endpoint path are supported"
   end

   -- Validate body
   local body_data = dict["body_data"]
   local body_json = cjson.decode(body_data)
   if (not body_json["authType"]) or (body_json["authType" ~= "iShare"]) then
      return nil, "Only 'iShare' authType supported"
   end
   if (not body_json["authCredentials"]) then
      return nil, "Missing parameter 'authCredentials'"
   end
   if (not body_json["authCredentials"]["iShareIdpId"]) then
      return nil, "Missing EORI of token endpoint (parameter: iShareIdpId)"
   end

   -- Resource object
   policy.target = {}
   policy.target.resource = {}
   policy.target.resource.type = "EndpointConfig"

   local identifier = {}
   table.insert(identifier, "*")
   policy.target.resource.identifiers = identifier

   local attrs = {}
   table.insert(attrs, "*")
   policy.target.resource.attributes = attrs

   -- Action
   policy.target.actions = {}
   table.insert(policy.target.actions, method )

   -- Set permit rule
   policy.rules = {}
   local rule = {}
   rule.effect = "Permit"
   table.insert(policy.rules, rule)

   -- Add policy to array
   table.insert(policies, policy)

   return policies, nil
end


-- Function to handle access rights for requests to the Sidecar-Proxy auth endpoint configuration
-- service.
-- Will check at iSHARE AR for necessary policies to create endpoint config
-- 
-- * Input
-- config: Table with configuration parameters
-- {
--   jws = {
--     identifier = "", (Identifier/EORI of local authority)
--     private_key = "", (as PEM string)
--     x5c = {table/array with base64 encoded certificates, full chain},
--     root_ca_file = "", (path to root CA file, required if no iSHARE Satellite information is provided below)
--   },
--   authorisation_registry = {
--     identifier = "", (Identifier/EORI of Authorisation Registry)
--     host = "", (Host of Authorisation Registry)
--     token_endpoint = "", (Token endpoint of Authorisation Registry)
--     delegation_endpoint = "", (Delegation endpoint of Authorisation Registry)
--   },
--   satellite = { (Preferred, required if no root CA is set above)
--     identifier = "", (Identifier/EORI of iSHARE Satellite/Scheme Owner)
--     host = "", (Host of iSHARE Satellite/Scheme Owner)
--     token_endpoint = "", (Token endpoint of iSHARE Satellite/Scheme Owner)
--     trusted_list_endpoint = "" (Trusted List Endpoint of iSHARE Satellite/Scheme Owner))
--   }
-- }
-- dict: Table with request parameters
-- {
--   token = "", (iSHARE JWT from request)
--   method = "", (HTTP method, e.g. PATCH, POST, GET, DELETE)
--   request_uri = "", (URI of the request, incl. full path)
--   request_headers = {table with request headers},
--   body_data = "", (raw body data of request)
--   post_args = {table with arguments for POST requests}
--   uri_args = {table with arguments from URI}
-- }
--
-- * Result
--  - nil: If access is granted based on AR policies, nothing is returned
--  - string: If access is NOT granted, a string containing a message with the reason is returned
function _M.handle_request(config, dict)
   
   -- Check for required config parameters for AR
   local err = ishare.check_config_ar(config)
   if err then
      return err
   end
   
   -- Local parameters
   local local_eori = config["jws"]["identifier"]
   local local_ar_eori = config["authorisation_registry"]["identifier"]
   local local_ar_host = config["authorisation_registry"]["host"]
   local local_token_url = config["authorisation_registry"]["token_endpoint"]
   local local_delegation_url = config["authorisation_registry"]["delegation_endpoint"]

   -- Validate incoming iSHARE JWT
   if config["jws"]["root_ca_file"] then
      -- Root CA trusted file set
      ishare.init_root_ca(config["jws"]["root_ca_file"])
   else
      -- Satellite config is required
      local err = ishare.check_config_satellite(config)
      if err then
	 return err
      end
   end
   local decoded_jwt, err = ishare.validate_ishare_jwt(config, dict["token"])
   if err then
      return err
   end

   -- Build required policy from incoming request
   local req_policies, err = build_required_policies(dict)
   if err then
      return err
   end
   
   -- Enforce M2M interaction
   -- Check that JWT was issued by local EORI, otherwise throw error
   local decoded_payload = decoded_jwt["payload"]
   if local_eori ~= decoded_payload["iss"] then
      return "Authorization JWT was not issued by local authority"
   end

   -- Check for policy at local AR
   local local_delegation_evidence, err = ishare.get_delegation_evidence_ext(config, local_eori, decoded_payload["sub"], req_policies, local_token_url, local_ar_eori, local_delegation_url, nil)
   if err then
      return "Error when retrieving policies from local AR: "..err
   end
   
   
   -- Compare policy target subject with authCredentials token endpoint EORI
   if (not local_delegation_evidence["target"]) or (not local_delegation_evidence["target"]["accessSubject"]) then
      return "Missing target access subject in local policy"
   end
   local targetsub = local_delegation_evidence["target"]["accessSubject"]
   local body_data = dict["body_data"]
   local body_json = cjson.decode(body_data)
   local endpoint_eori =  body_json["authCredentials"]["iShareIdpId"]
   if targetsub ~= endpoint_eori then
      return "Authorization /token endpoint EORI (parameter: iShareIdpId) does not match policy access subject EORI"
   end

   
   -- Compare policy
   if local_delegation_evidence["policySets"] and local_delegation_evidence["policySets"][1] and local_delegation_evidence["policySets"][1]["policies"] then
      local local_user_policies = local_delegation_evidence["policySets"][1]["policies"]

      -- Check that policy issuer and JWT iss match
      if not local_delegation_evidence.policyIssuer then
	 return "Local AR policy not authorized: Missing policy issuer"
      end
      if local_delegation_evidence.policyIssuer ~= decoded_payload.iss then
	 return "Local AR policy not authorized: JWT was not issued by policy issuer"
      end

      -- Compare local AR policy with required policy
      local matching_policies, err = ishare.compare_policies(local_user_policies, req_policies, targetsub, decoded_payload["sub"])
      if err then
	 return "Local AR policy not authorized: "..err
      end
      
      -- Check for access permit and expiration
      err = ishare.check_permit_policies(local_user_policies, local_delegation_evidence["notBefore"], local_delegation_evidence["notOnOrAfter"])
      if err then
	 return "Local AR policy not authorized: "..err
      end
   end
   
   
   -- Policy validated, access granted
   return
end


return _M

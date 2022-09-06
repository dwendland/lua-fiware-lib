--
-- Handler for attribute-based access management for
-- NGSI requests using the iSHARE framework
--

-- Imports
local re_gmatch = ngx.re.gmatch
local re_match = ngx.re.match
local cjson = require "cjson"

local ishare = require "fiware.ishare.ishare_helper"
local ngsi = require "fiware.ngsi.ngsi_helper"

-- Returned object
local _M = {}

-- Builds a table/array with the required policies
local function build_required_policies(dict)
   local policies = {}

   -- Get policy parameters from NGSI request
   local parameters, err = ngsi.get_ngsi_parameters(dict)
   if err then
      return nil, err
   end

   -- Build array of required policies based on iSHARE format
   for ngsi_params_index, ngsi_params in ipairs(parameters) do
      -- Policy
      local policy = {}

      -- Resource object
      policy.target = {}
      policy.target.resource = {}
      policy.target.resource.type = ngsi_params.entity_type
      policy.target.resource.identifiers = ngsi_params.identifier
      policy.target.resource.attributes = ngsi_params.attributes

      -- Set action depending on operation type
      -- For single entity operations it is the HTTP method
      -- Otherwise extend by operation type
      policy.target.actions = {}
      local method = ngsi_params.method
      if ngsi_params.operation_type == ngsi.OP_TYPE_SUBSCRIPTION then
	 method = method..":Subscription"
      elseif ngsi_params.operation_type == ngsi.OP_TYPE_NOTIFICATION then
	 method = method..":Notification"
      elseif ngsi_params.operation_type == ngsi.OP_TYPE_BATCH then
	 method = method..":Batch"
      end
      table.insert(policy.target.actions, method )

      -- Set permit rule
      policy.rules = {}
      local rule = {}
      rule.effect = "Permit"
      table.insert(policy.rules, rule)

      -- Add policy to array
      table.insert(policies, policy)
   end

   return policies, nil

end

-- Function to handle access rights for NGSI requests
-- Will check at iSHARE AR for necessary policies to perform requested NGSI operation
-- 
-- * Input
-- config: Table with configuration parameters
-- {
--   jws = {
--     identifier = "", (Identifier/EORI of local authority)
--     private_key = "", (private key as PEM string)
--     x5c = "", (cert chain as PEM string)
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
function _M.handle_ngsi_request(config, dict)
   
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
   
   -- Check for user policy
   if not decoded_jwt["payload"] then
      return "Missing payload in JWT"
   end
   local decoded_payload = decoded_jwt["payload"]
   local user_policy = {}
   local user_policies = nil
   local user_policy_issuer = nil
   local user_policy_targetsub = nil
   local del_notBefore = nil
   local del_notAfter = nil
   if decoded_payload["delegationEvidence"] and decoded_payload["delegationEvidence"] ~= cjson.null and decoded_payload["delegationEvidence"]["policySets"] then
      -- Policy already provided in JWT
      if decoded_payload["delegationEvidence"]["policySets"][1] and decoded_payload["delegationEvidence"]["policySets"][1]["policies"] then
	       user_policies = decoded_payload["delegationEvidence"]["policySets"][1]["policies"]
	       user_policy_issuer = decoded_payload["delegationEvidence"]["policyIssuer"]
	       user_policy_targetsub = decoded_payload["delegationEvidence"]["target"]["accessSubject"]
	       del_notBefore = decoded_payload["delegationEvidence"]["notBefore"]
	       del_notAfter = decoded_payload["delegationEvidence"]["notOnOrAfter"]
      else
	       return "User policy could not be found in JWT"
      end
   elseif decoded_payload["authorisationRegistry"] and decoded_payload["authorisationRegistry"] ~= cjson.null then
      -- AR info provided in JWT, get user policy from AR
      local token_url = decoded_payload["authorisationRegistry"]["token_endpoint"]
      local delegation_url = decoded_payload["authorisationRegistry"]["delegation_endpoint"]
      local ar_eori = decoded_payload["authorisationRegistry"]["identifier"]
      local issuer = decoded_payload["iss"]
      local target = decoded_payload["sub"]
      local api_key = decoded_payload["api_key"]
      local user_del_evi = {}
      user_del_evi, err = ishare.get_delegation_evidence_ext(config, issuer, target, req_policies, token_url, ar_eori, delegation_url, nil)
      if err then
	       return "Error when retrieving delegation evidence from user AR: "..err
      end
      if user_del_evi["policySets"] and user_del_evi["policySets"][1] and user_del_evi["policySets"][1]["policies"] then
	       user_policies = user_del_evi["policySets"][1]["policies"]
	       user_policy_issuer = user_del_evi["policyIssuer"]
	       user_policy_targetsub = user_del_evi["target"]["accessSubject"]
	       del_notBefore = user_del_evi["notBefore"]
	       del_notAfter = user_del_evi["notOnOrAfter"]
      else
	       return "User policy could not be found in user AR response"
      end
   else
      -- Info in JWT missing, assuming M2M
      -- Therefore no user policy and skip to next step for organisational policy
      -- Set issuer to JWT target subject, so that in next step we check the AR
      -- whether there is a policy issued by local EORI to the JWT subject
      user_policy_issuer = decoded_payload["sub"]

      -- Check that JWT was issued by local EORI, otherwise throw error
      if local_eori ~= decoded_payload["iss"] then
	       return "No policies or authorisation registry info in JWT, or JWT was not issued by local authority"
      end
   end

   -- Validate user policy if available
   if user_policies then
      -- Compare user policy with required policy
      local matching_policies, err = ishare.compare_policies(user_policies, req_policies, user_policy_targetsub, decoded_payload["sub"])
      if err then
	       return "Unauthorized user policy: "..err
      end

      -- Check if policies permit access (permit rule, expiration date)
      err = ishare.check_permit_policies(matching_policies, del_notBefore, del_notAfter)
      if err then
	       return "Unauthorized user policy: "..err
      end
   end

   -- Check issuer of user policy or JWT:
   --   * If local EORI, the user/requester is authorized
   --   * If different EORI, then ask local AR for policy issued by local EORI to user's EORI
   if local_eori ~= user_policy_issuer then
      -- User policy was not issued by local authority or there was no user policy
      -- Check at local AR for policy issued by local EORI
      --   M2M: user_policy_issuer == sub of access token (target subject)
      --   H2M: user_policy_issuer == issuer of user policy
      local local_user_del_evi, err = ishare.get_delegation_evidence_ext(config, local_eori, user_policy_issuer, req_policies, local_token_url, local_ar_eori, local_delegation_url, nil)
      if err then
	       return "Error when retrieving policies from local AR: "..err
      end
      if local_user_del_evi["policySets"] and local_user_del_evi["policySets"][1] and local_user_del_evi["policySets"][1]["policies"] then
	       local local_user_policies = local_user_del_evi["policySets"][1]["policies"]
	 
	       -- Compare local AR policy with required policy
	       -- M2M: user_policy_issuer == sub of access token (target subject)
	       -- H2M: user_policy_issuer == issuer of user policy
	       local local_user_policy_targetsub = local_user_del_evi["target"]["accessSubject"]
	       local matching_policies, err = ishare.compare_policies(local_user_policies, req_policies, local_user_policy_targetsub, user_policy_issuer)
	       if err then
	          return "Local AR policy not authorized: "..err
	       end

	       -- Check for access permit and expiration
	       err = ishare.check_permit_policies(local_user_policies, local_user_del_evi["notBefore"], local_user_del_evi["notOnOrAfter"])
	       if err then
	          return "Local AR policy not authorized: "..err
	       end
      else
	       return "Policy could not be found in local AR response"
      end
   else
      -- User policy claims to be issued by local authority
      -- No uirther steps required? Access granted!
   end

   -- Policy validated, access granted
   return
   
end

return _M

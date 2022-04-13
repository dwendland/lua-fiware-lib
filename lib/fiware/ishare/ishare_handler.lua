-- Imports
local re_gmatch = ngx.re.gmatch
local re_match = ngx.re.match
local cjson = require "cjson"

local ishare = require "fiware.ishare.ishare_helper"
local ngsi = require "fiware.ngsi.ngsi_helper"

-- Returned object
local _M = {}

-- Checks if a table with a list of values contains a specific element
local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

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

-- Get delegation evidence from external authorisation registry
local function get_delegation_evidence_ext(config, issuer, target, policies, token_url, ar_eori, delegation_url, prev_steps)
   local del_evi = {}

   -- Check config for AR
   local err = ishare.check_config_ar(config)
   if err then
      return nil, err
   end

   -- Get token at external AR
   local local_eori = config["jws"]["identifier"]
   local token, err = ishare.get_token(config, token_url, local_eori, local_eori, ar_eori)
   if err then
      return nil, err
   end

   -- Get delegation evidence from external AR
   del_evi, err = ishare.get_delegation_evidence(issuer, target, policies, delegation_url, token, prev_steps)
   if err then
      return nil, err
   end

   return del_evi, nil
end

-- Compare user policies with required policies
-- Returns all matching user policies
-- Returns error, if there is no user policy for any of the required policies
local function compare_policies(user_policies, req_policies, user_policy_target, req_policy_target)

   -- Check if user IDs are equal
   if user_policy_target ~= req_policy_target then
      return nil, "User IDs do not match: "..user_policy_target.." != "..req_policy_target
   end

   -- Iterate over required policies
   -- Add matching user policy to array
   local matching_policies = {}
   for req_policy_index, req_policy in ipairs(req_policies) do
      local matching_policy_found = false

      -- Iterate over user policies, find policy matching this required policy
      -- If none is found, throw error
      for user_policy_index, user_policy in ipairs(user_policies) do
	       local actions_ok, attrs_ok, type_ok, ids_ok = true, true, true, true

	       -- Compare policy parameter: action
	       local user_actions = user_policy.target.actions
	       local req_actions = req_policy.target.actions
	       for index, value in ipairs(req_actions) do
	          if not has_value(user_actions, value) then
	             -- Missing action in policy
	             --return "User policy does not contain action "..value
	             actions_ok = false
	          end
	       end

	       -- Compare policy parameter: attributes
	       local user_attrs = user_policy.target.resource.attributes
	       local req_attrs = req_policy.target.resource.attributes
	       for index, value in ipairs(req_attrs) do
	          if (not has_value(user_attrs, "*")) and (not has_value(user_attrs, value)) then
	             -- Missing required attribute
	             --return "User policy does not contain required attribute: "..value
	             attrs_ok = false
	          end
	       end

	       -- Compare policy parameter: type
	       local user_type = user_policy.target.resource.type
	       local req_type = req_policy.target.resource.type
	       if user_type ~= req_type then
	          -- Wrong resource/entity type
	          --return "User policy resource is not of required type: "..req_type.." != "..user_type
	          type_ok = false
	       end

	       -- Compare policy parameter: identifier
	       local user_ids = user_policy.target.resource.identifiers
	       local req_ids = req_policy.target.resource.identifiers
	       -- Check for exact entity IDs
	       for index, value in ipairs(req_ids) do
	          if (not has_value(user_attrs, "*")) and (not has_value(user_ids, value)) then
	             -- Missing required identifier
	             --return "User policy does not contain required identifier: "..value
	             ids_ok = false
	          end
	       end

	       -- Policy ok?
	       if actions_ok and attrs_ok and type_ok and ids_ok then
	          --return user_policy, nil
	          table.insert(matching_policies, user_policy)
	          matching_policy_found = true
	       end
      end -- End user policy iteration

      if not matching_policy_found then
	       return nil, "None of the user policies matched a required policy for this action"
      end

   end -- End required policy iteration

   --return nil, "None of the user policies matched required policy for this action"
   return matching_policies, nil
end

-- Check for expiration and "Permit" rule in required user/org policies
local function check_permit_policies(policies, notBefore, notAfter)

   -- Check expiration of policies
   local now = os.time()
   if now < notBefore or now >= notAfter then
      return "Policy has expired or is not yet valid"
   end

   -- Iterate over user policies, find policy matching this required policy
   -- If none is found, throw error
   for policy_index, policy in ipairs(policies) do
      -- Check for Permit rule
      local rules = policy.rules
      local found = false
      for index, value in ipairs(rules) do
	       if value["effect"] and value["effect"] == "Permit" then
	          found = true
	          break
	       end
      end
      if not found then
	       return "No Permit rule found in one of the user/organisation policies required for this request"
      end
   end

   return nil
end

-- Function to handle access rights for NGSI requests
-- Will check at iSHARE AR for necessary policies to perform requested NGSI operation
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
   if decoded_payload["delegationEvidence"] and decoded_payload["delegationEvidence"]["policySets"] then
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
   elseif decoded_payload["authorisation_registry"] then
      -- AR info provided in JWT, get user policy from AR
      local token_url = decoded_payload["authorisation_registry"]["token_endpoint"]
      local delegation_url = decoded_payload["authorisation_registry"]["delegation_endpoint"]
      local ar_eori = decoded_payload["authorisation_registry"]["identifier"]
      local issuer = decoded_payload["iss"]
      local target = decoded_payload["sub"]
      local api_key = decoded_payload["api_key"]
      local user_del_evi = {}
      user_del_evi, err = get_delegation_evidence_ext(issuer, target, req_policies, token_url, ar_eori, delegation_url, api_key)
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
      local matching_policies, err = compare_policies(user_policies, req_policies, user_policy_targetsub, decoded_payload["sub"])
      if err then
	       return "Unauthorized user policy: "..err
      end

      -- Check if policies permit access (permit rule, expiration date)
      err = check_permit_policies(matching_policies, del_notBefore, del_notAfter)
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
      local local_user_del_evi, err = get_delegation_evidence_ext(local_eori, user_policy_issuer, req_policies, local_token_url, local_ar_eori, local_delegation_url, nil)
      if err then
	       return "Error when retrieving policies from local AR: "..err
      end
      if local_user_del_evi["policySets"] and local_user_del_evi["policySets"][1] and local_user_del_evi["policySets"][1]["policies"] then
	       local local_user_policies = local_user_del_evi["policySets"][1]["policies"]
	       err = check_permit_policies(local_user_policies, local_user_del_evi["notBefore"], local_user_del_evi["notOnOrAfter"])
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

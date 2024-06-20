-- Imports
local cjson = require "cjson"
local jwt = require "resty.jwt"
local x509 = require("resty.openssl.x509")
local http = require "resty.http"

-- Returned object
local _M = {
   root_ca_set = false,
   is_kong_debug = false
}

-- Check for debug mode if running within Kong
local env_kong_log_level = os.getenv("KONG_LOG_LEVEL")
if (env_kong_log_level) and (env_kong_log_level == "debug") then
   _M.is_kong_debug = true
end

-- Set trusted rootCA from file
local isTrustCASet = false
function _M.init_root_ca(root_ca_file)
   jwt:set_trusted_certs_file(root_ca_file)
   _M.root_ca_set = true
end

-- Transforms a raw binary string to HEX
local function tohex(str)
   return (str:gsub('.', function (c)
      return string.format('%02X', string.byte(c))
   end))
end

-- Checks if a table with a list of values contains a specific element
local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

-- Creates a table with the x5c array from a PEM cert chain
local function get_x5c_table(pem_certs)

   if _M.is_kong_debug then
      print("Preparing x5c chain from certs: ")
      print(pem_certs)
   end

   local x5c = {}
   local start = 1
   local b = "-----BEGIN CERTIFICATE-----"
   local e = "-----END CERTIFICATE-----"
   local bl = string.len(b)
   local el = string.len(e)
   while start do
      local begin_cert = string.find(pem_certs, b, start)
      local end_cert = string.find(pem_certs, e, start)
      if (not begin_cert) or (not end_cert) then
	 start = nil
      else
	 table.insert(x5c, string.sub(pem_certs, begin_cert+bl, end_cert-1))
	 start = end_cert+el
      end      
   end

   return x5c
   
end

-- Generate random string with characters and digits
local function random_string(l)
   local chars = 'abcdefghijklmnopqrstuvwxyz0123456789'
   local length = l
   local randomString = ''
   
   --math.randomseed(os.time())
   
   local charTable = {}
   for c in chars:gmatch"." do
      table.insert(charTable, c)
   end
   
   for i = 1, length do
      randomString = randomString .. charTable[math.random(1, #charTable)]
   end
   
   return randomString
   
end

-- Send HTTP request
local function request(url, options)

   if _M.is_kong_debug then
      print("Sending request to: ", url)
   end

   local httpc = http.new()
   -- httpc:set_timeout(45000)
   local res, err =  httpc:request_uri(url, options)

   local msg = ""
   if not res then
      msg = "Empty response on request to "..url
      return nil, msg 
   elseif (res.status ~= 200 and res.status ~= 201) then
      msg = "Request to "..url.." not ok, received status code "..res.status
      if res.reason then
	       msg = msg..", Reason: "..res.reason
      end
      if res.body then
	       msg = msg..", Body: "..res.body
      end 
      return nil, msg
   elseif err then
      return nil, err
   end

   return res, nil
end

-- Check required AR config parameters
function _M.check_config_ar(config)

   if _M.is_kong_debug then
      print("Checking config for AR...")
   end

   -- Check for required config parameters
   if ( (not config["jws"]) or (not config["jws"]["private_key"]) or (not config["jws"]["x5c"]) ) then
      return "Missing JWS information (PrivateKey+Certificates) in config"
   end
   if (not config["jws"]) or (not config["jws"]["identifier"]) then
      return "Missing local identifier information in jws config"
   end
   local local_eori = config["jws"]["identifier"]
   if (not config["authorisation_registry"]) or (not config["authorisation_registry"]["identifier"]) then
      return "Missing identifier information in AR config"
   end
   local local_ar_eori = config["authorisation_registry"]["identifier"]
   if not config["authorisation_registry"]["host"] then
      return "Missing local authorisation registry host information in config"
   end
   local local_ar_host = config["authorisation_registry"]["host"]
   local local_token_url = config["authorisation_registry"]["token_endpoint"]
   local local_delegation_url = config["authorisation_registry"]["delegation_endpoint"]
   if not local_token_url then
      return "Missing local authorisation registry /token endpoint information in config"
   end
   if not local_delegation_url then
      return "Missing local authorisation registry /delegation endpoint information in config"
   end
   
end

-- Check required API Umbrella config parameters
function _M.check_config_satellite(config)

   if _M.is_kong_debug then
      print("Checking config for satellite...")
   end

   -- Check for required config parameters
   if ( (not config["jws"]) or (not config["jws"]["private_key"]) or (not config["jws"]["x5c"]) ) then
      return "Missing JWS information (PrivateKey+Certificates) in config"
   end
   if (not config["jws"]) or (not config["jws"]["identifier"]) then
      return "Missing local identifier information in jws config"
   end
   if (not config["satellite"]) or (not config["satellite"]["identifier"]) then
      return "Missing identifier information in Satellite config"
   end
   if not config["satellite"]["host"] then
      return "Missing Satellite host information in config"
   end
   local satellite_token_url = config["satellite"]["token_endpoint"]
   local satellite_trusted_list_url = config["satellite"]["trusted_list_endpoint"]
   if not satellite_token_url then
      return "Missing Satellite /token endpoint information in config"
   end
   if not satellite_trusted_list_url then
      return "Missing Satellite /trusted_list endpoint information in config"
   end
   
end

-- Get access token from AR (or other iSHARE participant)
function _M.get_token(config, token_url, iss, sub, aud)
   if _M.is_kong_debug then
      print("Getting access token at: ", token_url)
   end
   
   -- Get certificates and key
   local private_key = config["jws"]["private_key"]
   local x5c_certs = get_x5c_table(config["jws"]["x5c"])
   if not x5c_certs then
      return nil, "Error when parsing x5c certificate chain of local authority"
   end
   
   -- Build JWT Header
   local header = {
      typ = "JWT",
      alg = "RS256",
      x5c = x5c_certs
   }
   
   -- Build JWT Payload
   local now = os.time()
   local payload = {
      iss = iss,
      sub = sub,
      aud = aud,
      jti = random_string(32), 
      exp = now+30, 
      iat = now
   }
   
   print("Token request")
   print(token_url)
   print(payload)
   

   -- Sign JWS
   local unsigned_jwt = {
      header = header,
      payload = payload
   }
   if _M.is_kong_debug then
      print("Signing iSHARE JWT...")
   end
   local signed_jwt = jwt:sign(private_key, unsigned_jwt)

   -- Send request to token_url
   local ssl = false
   local tquery = "grant_type=client_credentials&scope=iSHARE&client_id="..iss.."&client_assertion_type=urn:ietf:params:oauth:client-assertion-type:jwt-bearer&client_assertion="..signed_jwt
   local headers = {}
   headers["Content-Type"] = "application/x-www-form-urlencoded"
   headers["Content-Length"] = string.len(tquery)
   local options = {
      method = "POST",
      body = tquery,
      headers = headers,
      ssl_verify = ssl,
   } -- query = tquery
   local res, err = request(token_url, options)
   if err then
      return nil, "Error when retrieving token: "..err
   end
   
   -- Get token from response
   local res_body = cjson.decode(res.body)
   local access_token = res_body["access_token"]
   if not access_token then
      return nil, "access_token not found in response: "..res_body
   end
   print(access_token)
   return access_token, nil
   
end

-- Get delegation evidence from iSHARE AR using valid access_token
-- prev_steps is optional
function _M.get_delegation_evidence(issuer, target, policies, delegation_url, access_token, prev_steps)

   if _M.is_kong_debug then
      print("Getting delegationEvidence from AR...")
   end

   -- Build payload body of request
   local payload = {
      delegationRequest = {
	       policyIssuer = issuer,
	       target = {
	          accessSubject = target
	       },
	       policySets = {}
      }
   }
   if prev_steps then
      payload["previous_steps"] = {}
      table.insert(payload["previous_steps"], prev_steps)
   end
   table.insert(payload.delegationRequest.policySets, {})
   payload.delegationRequest.policySets[1] = {
      policies = policies
   }

   -- Build header of request
   local headers = {}
   headers["Content-Type"] = "application/json"
   headers["Authorization"] = "Bearer "..access_token
   
   -- Send request to /delegation endpoint of AR at delegation_url
   local ssl = false
   local options = {
      method = "POST",
      body = cjson.encode(payload),
      headers = headers,
      ssl_verify = ssl,
   }
   if _M.is_kong_debug then
      print("Sending delegationRequest to: ", delegation_url)
      print(options.body)
   end
   local res, err = request(delegation_url, options)
   if err then
      return nil, "Error when retrieving delegation evidence: "..err
   end

   -- Get delegation_token from response
   local res_body = cjson.decode(res.body)
   local delegation_token = res_body["delegation_token"]
   
   if not delegation_token then
      return nil, "delegation_token not found in response: "..res_body
   end

   -- Decode delegation_token
   local decoded_token = jwt:load_jwt(delegation_token)
   if not decoded_token["valid"] then
      return nil, "The received delegation JWT is not valid"
   end
   
   -- Get delegation evidence
   if not decoded_token["payload"] and not decoded_token["payload"]["delegationEvidence"] then
      return nil, "The received delegation JWT contains no delegationEvidence"
   end
   
   return decoded_token["payload"]["delegationEvidence"], nil
end

-- Get delegation evidence from external authorisation registry
function _M.get_delegation_evidence_ext(config, issuer, target, policies, token_url, ar_eori, delegation_url, prev_steps)
   local del_evi = {}

   -- Check config for AR
   local err = _M.check_config_ar(config)
   if err then
      return nil, err
   end

   -- Get token at external AR
   local local_eori = config["jws"]["identifier"]
   local token, err = _M.get_token(config, token_url, local_eori, local_eori, ar_eori)
   if err then
      return nil, err
   end

   -- Get delegation evidence from external AR
   del_evi, err = _M.get_delegation_evidence(issuer, target, policies, delegation_url, token, prev_steps)
   if err then
      return nil, err
   end

   return del_evi, nil
end

function _M.get_trusted_list(config)

   -- Get config parameters
   local local_eori = config["jws"]["identifier"]
   local satellite_eori = config["satellite"]["identifier"]
   local satellite_token_url = config["satellite"]["token_endpoint"]
   local satellite_trusted_list_url = config["satellite"]["trusted_list_endpoint"]

   if _M.is_kong_debug then
      print("Getting trusted list from satellite at: ", satellite_trusted_list_url)
   end

   -- Get token at Satellite
   local token, err = _M.get_token(config, satellite_token_url, local_eori, local_eori, satellite_eori)
   if err then
      return nil, err
   end

   -- Build header of request
   local headers = {}
   headers["Authorization"] = "Bearer "..token
   
   -- Send request to /delegation endpoint of AR at delegation_url
   local ssl = false
   local options = {
      method = "GET",
      headers = headers,
      ssl_verify = ssl,
   }
   local res, err = request(satellite_trusted_list_url, options)
   if err then
      return nil, "Error when retrieving trusted list from Satellite: "..err
   end

   -- Get trusted_list_token from response
   if _M.is_kong_debug then
      print("Received response: ", res.body)
   end
   local res_body = cjson.decode(res.body)
   local trusted_list_token = res_body["trusted_list_token"]
   
   if not trusted_list_token then
      return nil, "trusted_list_token not found in response: "..res_body
   end

   -- Decode trusted_list_token
   local decoded_token = jwt:load_jwt(trusted_list_token)
   if not decoded_token["valid"] then
      return nil, "The received trusted_list JWT is not valid"
   end

   -- Get trusted_list
   if not decoded_token["payload"] and not decoded_token["payload"]["trusted_list"] then
      return nil, "The received trusted list JWT contains no element trusted_list"
   end

   return decoded_token["payload"]["trusted_list"]
   
end

local function check_ca_fingerprint(config, ca_fingerprint)

   if _M.is_kong_debug then
      print("Checking CA fingerprint...")
   end
   
   -- Get trusted list from satellite
   local trusted_list, err = _M.get_trusted_list(config)
   if err then
      return err
   end

   -- Iterate over trusted list and compare to CA fingerprint
   for index, value in pairs(trusted_list) do
      if trusted_list[index] then
	 if trusted_list[index]["certificate_fingerprint"] then
	    if string.upper(trusted_list[index]["certificate_fingerprint"]) == string.upper(ca_fingerprint) then
	       return nil
	    end
	 end
      end
   end

   return "No matching certificate fingerprint in trusted list found"
end

-- Validate, verify and decode iSHARE JWT
function _M.validate_ishare_jwt(config, token)

   if _M.is_kong_debug then
      print("Validate iSHARE JWT: ", token)
   end

   -- Empty token?
   if (not token) or (string.len(token) < 1) then
      return nil, "Empty token provided"
   end
   
   -- Decode JWT without validation to extract header params first
   local decoded_token = jwt:load_jwt(token)
   local header = decoded_token["header"]

   -- Check for RS256 header to be iSHARE compliant
   if header["alg"] ~= "RS256" then
      return nil, "RS256 algorithm must be used and specified in JWT header"
   end

   -- Check for x5c header
   if not header["x5c"] then
      return nil, "JWT must contain x5c header parameter"
   end
   
   -- Get first certificate
   local cert = header["x5c"][1]
   local pub_key = "-----BEGIN CERTIFICATE-----\n"..cert.."\n-----END CERTIFICATE-----\n"
   
   -- Compare policy issuer with certificate subject
   local cr, err = x509.new(pub_key)
   if not err then
      local subname, err = cr:get_subject_name()
      if err then
	       return nil, "Error when retrieving subject name from certificate: "..err
      end
      local serialnumber, pos, err = subname:find("serialNumber")
      if err then
	       return nil, "Error when retrieving serial number from certificate: "..err
      end
      if not serialnumber then
	       return nil, "Empty serial number in certificate"
      end
      local certsub = serialnumber.blob
      local payload = decoded_token["payload"]
      local issuer = payload['iss']
      if certsub ~= issuer then
	       return nil, "Certificate serial number "..certsub.." does not equal policy issuer "..issuer
      end
   else
      return nil, "Error when loading certificate: "..err
   end

   -- Check for exp and iat in payload
   local now = os.time()
   local payload = decoded_token["payload"]
   local exp = payload['exp']
   local iat = payload['iat']
   if exp < now or iat > now then
      return nil, "JWT has expired or was issued in the future"
   end

   -- Check aud claim to equal local EORI
   local local_eori = config["jws"]["identifier"]
   local aud = payload['aud']
   if local_eori ~= aud then
      return nil, "JWT aud claim does not match local EORI"
   end
   
   -- Verify signature
   local jwt_obj = nil
   if not _M.root_ca_set then
      -- Verify fingerprint of x5c root CA against trusted_list of satellite
      local root_cert = header["x5c"][#header["x5c"]]
      root_cert = "-----BEGIN CERTIFICATE-----\n"..root_cert.."\n-----END CERTIFICATE-----\n"
      local root_x509, root_err = x509.new(root_cert)
      if root_err then
	 return nil, "Error when loading x5c root CA: "..root_err
      end
      
      local dig = root_x509:digest("sha256")
      local ca_fingerprint = tohex(dig)
      err = check_ca_fingerprint(config, ca_fingerprint)
      if err then
	 return nil, "Verification of x5c root CA failed: "..err
      end
      
      -- Verify JWT against x5c certificate chain / root CA and intermediate certs
      local cert_chain = ""
      for index, value in ipairs(header["x5c"]) do
	 --if index ~= 1 then
	 cert_chain = cert_chain.."-----BEGIN CERTIFICATE-----\n"..value.."\n-----END CERTIFICATE-----\n"
	 --end
      end
      --jwt_obj = jwt:verify(pub_key, token)
      jwt_obj = jwt:verify(cert_chain, token)
   else
      -- Root CA file is set
      -- Verify JWT against provided root CA
      jwt_obj = jwt:verify(nil, token)
   end
   if not jwt_obj["valid"] then
      return nil, "Authorization JWT from sender is not valid"
   end
   if not jwt_obj["verified"] then
      return nil, "Verification failed: "..jwt_obj["reason"]
   end

   return decoded_token, nil
end

-- Compare issued/user policies with required policies
-- Returns all matching issued policies
-- Returns error, if there is no issued policy for any of the required policies
function _M.compare_policies(user_policies, req_policies, user_policy_target, req_policy_target)

   if _M.is_kong_debug then
      print("Comparing issued with required policies...")
   end

   -- Check if user IDs are equal
   if user_policy_target ~= req_policy_target then
      return nil, "Target subject IDs do not match: "..user_policy_target.." != "..req_policy_target
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
	             actions_ok = false
	          end
	       end
	       
	       -- Compare policy parameter: attributes
	       local user_attrs = user_policy.target.resource.attributes
	       local req_attrs = req_policy.target.resource.attributes
	       for index, value in ipairs(req_attrs) do
		  if (not has_value(user_attrs, "*")) and (not has_value(user_attrs, value)) then
	             -- Missing required attribute
	             attrs_ok = false
	          end
	       end
	       
	       -- Compare policy parameter: type
	       local user_type = user_policy.target.resource.type
	       local req_type = req_policy.target.resource.type
	       if user_type ~= req_type then
	          -- Wrong resource/entity type
	          type_ok = false
	       end
	       
	       -- Compare policy parameter: identifier
	       local user_ids = user_policy.target.resource.identifiers
	       local req_ids = req_policy.target.resource.identifiers
	       -- Check for exact entity IDs
	       for index, value in ipairs(req_ids) do
		  if (not has_value(user_ids, "*")) and (not has_value(user_ids, value)) then
	             -- Missing required identifier
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
	       return nil, "None of the delivered policies matched a required policy for this action"
      end

   end -- End required policy iteration

   --return nil, "None of the user policies matched required policy for this action"
   return matching_policies, nil
end

-- Check for expiration and "Permit" rule in required user/org policies
function _M.check_permit_policies(policies, notBefore, notAfter)

   if _M.is_kong_debug then
      print("Checking for expiration and Permit rule in policies...")
   end

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


return _M

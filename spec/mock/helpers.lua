local ngsi = require "fiware.ngsi.ngsi_helper"
local ishare = require "fiware.ishare.ishare_helper"
local ishare_handler = require "fiware.ishare.ishare_handler"

local certs = require('spec.mock.certs')
local policies = require('spec.mock.policies')

local jwt = require "resty.jwt"
local cjson = require "cjson"


local _M = {}

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

function _M.generate_client_token(private_key, x5c, iss, sub, aud, delegation_evidence)
   -- Build JWT Header
   local header = {
      typ = "JWT",
      alg = "RS256",
      x5c = x5c
   }
   
   -- Build JWT Payload
   local now = os.time()
   local payload = {
      iss = iss,
      sub = sub,
      aud = full_aud,
      jti = random_string(32), 
      exp = now+30, 
      iat = now
   }

   -- Add delegation evidence
   if delegation_evidence then
      payload.delegationEvidence = delegation_evidence
   end

   -- Add aud
   if aud then
      payload.aud = aud
   end
   
   -- Sign JWS
   local unsigned_jwt = {
      header = header,
      payload = payload
   }
   return jwt:sign(private_key, unsigned_jwt)
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

-- Compare two tables
function _M.deepcompare(t1, t2, ignore_mt)
   local ty1 = type(t1)
   local ty2 = type(t2)
   if ty1 ~= ty2 then
      return false
   end
   -- non-table types can be directly compared
   if ty1 ~= 'table' and ty2 ~= 'table' then
      return t1 == t2
   end
   -- as well as tables which have the metamethod __eq
   local mt = getmetatable(t1)
   if not ignore_mt and mt and mt.__eq then
      return t1 == t2
   end
   for k1,v1 in pairs(t1) do
      local v2 = t2[k1]
      if v2 == nil or not _M.deepcompare(v1,v2) then
	 return false
      end
   end
   for k2,v2 in pairs(t2) do
      local v1 = t1[k2]
      if v1 == nil or not _M.deepcompare(v1,v2) then
	 return false
      end
   end
   return true
end

-- Compare two arrays
function _M.arrayEqual(a, b)
  -- Check length, or else the loop isn't valid.
  if #a ~= #b then
    return false
  end

  -- Check each element.
  for ia, va in ipairs(a) do 
     if not has_value(b, va) then
	return false
     end
  end
  
  -- We've checked everything.
  return true
end

-- Mock for ishare_helper.get_trusted_list()
function _M.get_trusted_list_mock(config)
   return certs.trusted_list
end



return _M

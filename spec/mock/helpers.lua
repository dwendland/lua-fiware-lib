local ngsi = require "fiware.ngsi.ngsi_helper"

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

return _M

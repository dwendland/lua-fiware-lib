local certs = require('spec.mock.certs')

local _M = {}

-- Delegation Evidence mocks
_M.get_delegation_evidence = {}
_M.get_delegation_evidence.server = {}
_M.get_delegation_evidence.user = {}

-- Policies
_M.server = {}
_M.user = {}

-- Server policy - All actions and IDs, certain attrs
_M.server.all_attrs = {
   notBefore = 1649938121,
   notOnOrAfter = 1870862921,
   policyIssuer = certs.server.identifier,
   target = {
      accessSubject = certs.client.identifier
   },
   policySets = {
      {
	 policies = {
	    {
	       target = {
		  resource = {
		     --type = "DELIVERYORDER",
		     identifiers = {
			"*"
		     },
		     attributes = {
			"pta", "pda", "deliveryAddress"
		     }
		  },
		  actions = {
		     "PATCH", "GET", "POST", "DELETE"
		  }
	       },
	       rules = {
		  {
		     effect = "Permit"
		  }
	       }
	    }
	 }
      }
   }
}
_M.server.all_attrs.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"

-- Server policy - All actions and IDs, certain attrs, expired
_M.server.all_attrs_expired = {
   notBefore = 1649938121,
   notOnOrAfter = 1649939428,
   policyIssuer = certs.server.identifier,
   target = {
      accessSubject = certs.client.identifier
   },
   policySets = {
      {
	 policies = {
	    {
	       target = {
		  resource = {
		     --type = "DELIVERYORDER",
		     identifiers = {
			"*"
		     },
		     attributes = {
			"pta", "pda", "deliveryAddress"
		     }
		  },
		  actions = {
		     "PATCH", "GET", "POST", "DELETE"
		  }
	       },
	       rules = {
		  {
		     effect = "Permit"
		  }
	       }
	    }
	 }
      }
   }
}
_M.server.all_attrs.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"





return _M

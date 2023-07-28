local certs = require('spec.mock.certs')

local _M = {}

-- Timestamps
local valid_from = 1649938121
local valid_until = 1870862921

-- Delegation Evidence mocks
_M.get_delegation_evidence = {}
_M.get_delegation_evidence.server = {}
_M.get_delegation_evidence.user = {}

-- Policies
_M.server = {}
_M.user = {}

-- Server policy - All actions and IDs, all attrs
_M.server.all_attrs = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
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
			"*"
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

-- Server policy - All actions and all attrs, single ID
_M.server.all_attrs_single_id = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
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
			"urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
		     },
		     attributes = {
			"*"
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
_M.server.all_attrs_single_id.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"

-- Server policy - All actions and IDs, certain attrs
_M.server.some_attrs = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
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
_M.server.some_attrs.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"

-- Server policy - All actions and IDs, certain attrs, expired
_M.server.some_attrs_expired = {
   notBefore = valid_from,
   notOnOrAfter = valid_from+1,
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
_M.server.some_attrs_expired.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"

-- Server policy - EndpointConfig, only POST
_M.server.post_endpoint_config = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
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
			"*"
		     }
		  },
		  actions = {
		     "POST"
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
_M.server.post_endpoint_config.policySets[1].policies[1].target.resource.type = "EndpointConfig"

-- Server policy - EndpointConfig, only POST, alternative issuer
_M.server.post_endpoint_config_alt_issuer = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
   policyIssuer = certs.server.identifier_alt,
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
			"*"
		     }
		  },
		  actions = {
		     "POST"
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
_M.server.post_endpoint_config_alt_issuer.policySets[1].policies[1].target.resource.type = "EndpointConfig"

-- Server policy - EndpointConfig, only POST, expired
_M.server.post_endpoint_config_expired = {
   notBefore = valid_from,
   notOnOrAfter = valid_from+1,
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
			"*"
		     }
		  },
		  actions = {
		     "POST"
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
_M.server.post_endpoint_config_expired.policySets[1].policies[1].target.resource.type = "EndpointConfig"

-- Server policy - EndpointConfig, only GET, all configs
_M.server.get_endpoint_config_all = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
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
			"*"
		     }
		  },
		  actions = {
		     "GET"
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
_M.server.get_endpoint_config_all.policySets[1].policies[1].target.resource.type = "EndpointConfig"

-- User policy - All actions and IDs, all attrs
_M.user.all_attrs = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
   policyIssuer = certs.client.identifier,
   target = {
      accessSubject = certs.user.identifier
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
			"*"
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
_M.user.all_attrs.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"

-- User policy - All actions and IDs, certain attrs
_M.user.some_attrs = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
   policyIssuer = certs.client.identifier,
   target = {
      accessSubject = certs.user.identifier
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
			"pta", "pda"
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
_M.user.some_attrs.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"

-- User policy - All IDs, only POST, certain attrs
_M.user.some_attrs_post = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
   policyIssuer = certs.client.identifier,
   target = {
      accessSubject = certs.user.identifier
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
			"pta", "pda"
		     }
		  },
		  actions = {
		     "POST"
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
_M.user.some_attrs_post.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"

-- User policy - All actions, single ID, certain attrs
_M.user.some_attrs_single_id = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
   policyIssuer = certs.client.identifier,
   target = {
      accessSubject = certs.user.identifier
   },
   policySets = {
      {
	 policies = {
	    {
	       target = {
		  resource = {
		     --type = "DELIVERYORDER",
		     identifiers = {
			"urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
		     },
		     attributes = {
			"pta", "pda"
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
_M.user.some_attrs_single_id.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"

-- User policy - All actions, single ID, all attrs
_M.user.all_attrs_single_id = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
   policyIssuer = certs.client.identifier,
   target = {
      accessSubject = certs.user.identifier
   },
   policySets = {
      {
	 policies = {
	    {
	       target = {
		  resource = {
		     --type = "DELIVERYORDER",
		     identifiers = {
			"urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
		     },
		     attributes = {
			"*"
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
_M.user.all_attrs_single_id.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"

-- User policy - All actions, all attrs, fake issuer
_M.user.all_attrs_fake_iss = {
   notBefore = valid_from,
   notOnOrAfter = valid_until,
   policyIssuer = certs.client.identifier_alt,
   target = {
      accessSubject = certs.user.identifier
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
			"*"
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
_M.user.all_attrs_fake_iss.policySets[1].policies[1].target.resource.type = "DELIVERYORDER"

return _M

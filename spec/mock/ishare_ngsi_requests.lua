local certs = require('spec.mock.certs')

local _M = {}

-- Default config object
local default_config = {
   jws = {
      identifier = certs.server.identifier,
      private_key = certs.server.private_key,
      x5c = certs.server.x5c,
      root_ca_file = nil
   },
   authorisation_registry = {
      identifier = certs.server.identifier,
      host = "HOSTAR",
      token_endpoint = "TOKENURI",
      delegation_endpoint = "DELURI"
   },
   satellite = {
      identifier = "EORI_SAT",
      host = "HOSTSAT",
      token_endpoint = "TOKENURI",
      trusted_list_endpoint = "TRUSTURI"
   }
}

-- Get single entity
_M["get_1"] = {}
_M.get_1.config = default_config
_M.get_1.dict = {
   token = "",
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = nil
}

-- Get single entity, certain attrs pta&pda
_M["get_1_pta_pda"] = {}
_M.get_1_pta_pda.config = default_config
_M.get_1_pta_pda.dict = {
   token = "",
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = {
      attrs = "pta,pda"
   }
}

-- Get single entity, attr eta
_M["get_1_eta"] = {}
_M.get_1_eta.config = default_config
_M.get_1_eta.dict = {
   token = "",
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = {
      attrs = "eta"
   }
}

-- Get all entities of type DELIVERYORDER
_M["get_all"] = {}
_M.get_all.config = default_config
_M.get_all.dict = {
   token = "",
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = {}
}
_M.get_all.dict.uri_args.type = "DELIVERYORDER"

-- Get all entities of type DELIVERYORDER, only attrs pta&pda
_M["get_all_pta_pda"] = {}
_M.get_all_pta_pda.config = default_config
_M.get_all_pta_pda.dict = {
   token = "",
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = {
      attrs = "pta,pda"
   }
}
_M.get_all_pta_pda.dict.uri_args.type = "DELIVERYORDER"

-- Get all entities of type DELIVERYORDER, only attr eta
_M["get_all_eta"] = {}
_M.get_all_eta.config = default_config
_M.get_all_eta.dict = {
   token = "",
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = {
      attrs = "eta"
   }
}
_M.get_all_eta.dict.uri_args.type = "DELIVERYORDER"

-- Get all entities with certain IDs
_M["get_all_ids"] = {}
_M.get_all_ids.config = default_config
_M.get_all_ids.dict = {
   token = "",
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = {
      id = "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001,urn:ngsi-ld:DELIVERYORDER:HAPPYPETS002"
   }
}
_M.get_all_ids.dict.uri_args.type = "DELIVERYORDER"

-- Get all entities with certain IDs, only attrs pta&pda
_M["get_all_ids_pta_pda"] = {}
_M.get_all_ids_pta_pda.config = default_config
_M.get_all_ids_pta_pda.dict = {
   token = "",
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = {
      attrs = "pta,pda",
      id = "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001,urn:ngsi-ld:DELIVERYORDER:HAPPYPETS002"
   }
}
_M.get_all_ids_pta_pda.dict.uri_args.type = "DELIVERYORDER"

-- Patch single attr pta
_M["patch_pta"] = {}
_M.patch_pta.config = default_config
_M.patch_pta.dict = {
   token = "",
   method = "PATCH",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/attrs/pta",
   request_headers = nil,
   body_data = [[
{
  "value": "16:00:00",
  "type": "Property"
}
]],
   post_args = nil,
   uri_args = nil
}

-- Patch single attr eta
_M["patch_pta"] = {}
_M.patch_pta.config = default_config
_M.patch_pta.dict = {
   token = "",
   method = "PATCH",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/attrs/eta",
   request_headers = {},
   body_data = [[
{
  "value": "18:00:00",
  "type": "Property"
}
]],
   post_args = nil,
   uri_args = nil
}
_M.patch_pta.dict.request_headers["Content-Type"] = "application/json"

-- Patch attrs pta&pda
_M["patch_pta_pda"] = {}
_M.patch_pta_pda.config = default_config
_M.patch_pta_pda.dict = {
   token = "",
   method = "PATCH",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/attrs/",
   request_headers = {},
   body_data = [[
{
  "pta": {
    "value": "16:00:00",
    "type": "Property"
  },
  "pda": {
    "value": "2022-10-05",
    "type": "Property"
  }
}
]],
   post_args = nil,
   uri_args = nil
}
_M.patch_pta_pda.dict.request_headers["Content-Type"] = "application/json"

-- Patch attrs pta&eta
_M["patch_pta_eta"] = {}
_M.patch_pta_eta.config = default_config
_M.patch_pta_eta.dict = {
   token = "",
   method = "PATCH",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/attrs/",
   request_headers = {},
   body_data = [[
{
  "pta": {
    "value": "16:00:00",
    "type": "Property"
  },
  "eta": {
    "value": "2022-11-08",
    "type": "Property"
  }
}
]],
   post_args = nil,
   uri_args = nil
}
_M.patch_pta_eta.dict.request_headers["Content-Type"] = "application/json"


return _M

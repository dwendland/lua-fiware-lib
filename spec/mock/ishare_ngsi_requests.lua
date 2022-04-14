local certs = require('spec.mock.certs')

local _M = {}

_M["get_1"] = {}
_M.get_1.config = {
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
_M.get_1.dict = {
   token = "",
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = nil
}

return _M

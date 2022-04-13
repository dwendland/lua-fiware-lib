local _M = {}

-- Entity for single GET
_M["entity_get_1"] = {}
_M.entity_get_1.dict = {
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = nil
}
_M.entity_get_1.parameters = {
   method = "GET",
   operation_type = "ENTITY",
   entity_type = "DELIVERYORDER",
   identifier = { "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001" },
   attributes = { "*" }
}

-- Entity for single GET on attrs
_M["entity_get_attrs"] = {}
_M.entity_get_attrs.dict = {
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = {
      attrs = "pda,pta"
   }
}
_M.entity_get_attrs.parameters = {
   method = "GET",
   operation_type = "ENTITY",
   entity_type = "DELIVERYORDER",
   identifier = { "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001" },
   attributes = { "pda", "pta" }
}

-- Entity for GET all
_M["entity_get_all"] = {}
_M.entity_get_all.dict = {
   method = "GET",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = {
      ["type"] = "DELIVERYORDER"
   }
}
_M.entity_get_all.parameters = {
   method = "GET",
   operation_type = "ENTITY",
   entity_type = "DELIVERYORDER",
   identifier = { "*" },
   attributes = { "*" }
}

-- Entity for POST new entity
_M["entity_post_1"] = {}
_M.entity_post_1.dict = {
   method = "POST",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities",
   request_headers = nil,
   body_data = [[
{
    "id": "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001",
    "type": "DELIVERYORDER",
    "issuer": {
        "type": "Property",
        "value": "Happy Pets"
    },
    "destinee": {
        "type": "Property",
        "value": "Happy Pets customer"
    },
    "deliveryAddress": {
        "type": "Property",
        "value": {
            "addressCountry": "DE",
            "addressRegion": "Berlin",
            "addressLocality": "Berlin",
            "postalCode": "12345",
            "streetAddress": "Customer Strasse 23"
        }
    },
    "originAddress": {
        "type": "Property",
        "value": {
            "addressCountry": "DE",
            "addressRegion": "Berlin",
            "addressLocality": "Berlin",
            "postalCode": "12345",
            "streetAddress": "HappyPets Strasse 15"
        }
    },
    "pda": {
        "type": "Property",
        "value": "2021-10-03"
    },
    "pta": {
        "type": "Property",
        "value": "14:00:00"
    },
    "eda": {
        "type": "Property",
        "value": "2021-10-02"
    },
    "eta": {
        "type": "Property",
        "value": "14:00:00"
    },
    "@context": [
        "https://schema.lab.fiware.org/ld/context",
        "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld"
    ]
}
   ]],
   post_args = nil,
   uri_args = nil
}
_M.entity_post_1.parameters = {
   method = "POST",
   operation_type = "ENTITY",
   entity_type = "DELIVERYORDER",
   identifier = { "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001" },
   attributes = { "*" }
}

-- Entity for POST new attrs
_M["entity_post_attrs"] = {}
_M.entity_post_attrs.dict = {
   method = "POST",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/attrs",
   request_headers = nil,
   body_data = [[
{
    "pda": {
        "type": "Property",
        "value": "2021-10-03"
    },
    "pta": {
        "type": "Property",
        "value": "14:00:00"
    }
}
   ]],
   post_args = nil,
   uri_args = nil
}
_M.entity_post_attrs.parameters = {
   method = "POST",
   operation_type = "ENTITY",
   entity_type = "DELIVERYORDER",
   identifier = { "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001" },
   attributes = { "pta", "pda" }
}

-- Entity for PATCH single attr
_M["entity_patch_1"] = {}
_M.entity_patch_1.dict = {
   method = "PATCH",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/attrs/eda",
   request_headers = nil,
   body_data = [[
{
    "type": "Property",
    "value": "2021-10-02"
}
   ]],
   post_args = nil,
   uri_args = nil
}
_M.entity_patch_1.parameters = {
   method = "PATCH",
   operation_type = "ENTITY",
   entity_type = "DELIVERYORDER",
   identifier = { "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001" },
   attributes = { "eda" }
}

-- Entity for PATCH multiple attrs
_M["entity_patch_multi"] = {}
_M.entity_patch_multi.dict = {
   method = "PATCH",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/attrs",
   request_headers = nil,
   body_data = [[
{
    "pda": {
        "type": "Property",
        "value": "2021-10-03"
    },
    "pta": {
        "type": "Property",
        "value": "14:00:00"
    }
}
   ]],
   post_args = nil,
   uri_args = nil
}
_M.entity_patch_multi.parameters = {
   method = "PATCH",
   operation_type = "ENTITY",
   entity_type = "DELIVERYORDER",
   identifier = { "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001" },
   attributes = { "pta", "pda" }
}

-- Entity for single DELETE
_M["entity_delete_1"] = {}
_M.entity_delete_1.dict = {
   method = "DELETE",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = nil
}
_M.entity_delete_1.parameters = {
   method = "DELETE",
   operation_type = "ENTITY",
   entity_type = "DELIVERYORDER",
   identifier = { "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001" },
   attributes = { "*" }
}

-- Entity for single DELETE of attr
_M["entity_delete_attr"] = {}
_M.entity_delete_attr.dict = {
   method = "DELETE",
   request_uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/attrs/eta",
   request_headers = nil,
   body_data = nil,
   post_args = nil,
   uri_args = nil
}
_M.entity_delete_attr.parameters = {
   method = "DELETE",
   operation_type = "ENTITY",
   entity_type = "DELIVERYORDER",
   identifier = { "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001" },
   attributes = { "eta" }
}

return _M

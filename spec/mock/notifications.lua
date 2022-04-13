local _M = {}

-- Notification
_M["delivery_order"] = {}
_M.delivery_order.notification = [[
{
    "id": "urn:ngsi-ld:Notification:5fd0fa684eb81930c97005f3",
    "type": "Notification",
    "subscriptionId": "urn:ngsi-ld:Subscription:5fd0f69b4eb81930c97005db",
    "notifiedAt": "2021-12-09T16:25:12.193Z",
    "data": [
        {
            "id": "urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001",
            "type": "DELIVERYORDER",
            "pda": {
                "type": "Property",
                "value": "2021-12-15"
            },
            "pta": {
                "type": "DELIVERYORDER",
                "value": "14:00:00"
            },
            "eda": {
                "type": "Property",
                "value": "2021-12-15"
            },
            "eta": {
                "type": "DELIVERYORDER",
                "value": "15:00:00"
            }
        }
    ]
}
]]
_M.delivery_order.parameters = {
   method = "POST",
   operation_type = "NOTIFICATION",
   entity_type = "DELIVERYORDER",
   identifier = { "urn:ngsi-ld:Subscription:5fd0f69b4eb81930c97005db" },
   attributes = { "pda", "pta", "eda", "eta" }
}

return _M

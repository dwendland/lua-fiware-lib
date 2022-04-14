require 'busted.runner'()

local ngsi = require "fiware.ngsi.ngsi_helper"
local deepcompare = require('spec.mock.helpers').deepcompare
local arrayEqual = require('spec.mock.helpers').arrayEqual

local function ngsi_parameters(dict, parameters)

   local result, err = ngsi.get_ngsi_parameters(dict)
   assert.is.falsy(err)
   assert.are.same(parameters.method, result[1].method)
   assert.are.same(parameters.entity_type, result[1].entity_type)
   assert.are.same(parameters.operation_type, result[1].operation_type)
   assert.is_true(arrayEqual(parameters.identifier, result[1].identifier))
   assert.is_true(arrayEqual(parameters.attributes, result[1].attributes))
   
end

-- Common public methods
describe("Tests for common public methods.", function()

  -- Check for NGSI-LD	    
  describe("Test function: is_ngsi_ld().", function()

    -- Should return true
    it("is NGSI-LD request", function()
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
	  assert.is_true(ngsi.is_ngsi_ld(uri))
    end)

    -- Should return false
    it("is NOT NGSI-LD request (1)", function()
	  local uri = "https://gateway.com/orion/v2/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
	  assert.is_false(ngsi.is_ngsi_ld(uri))
    end)
    it("is NOT NGSI-LD request (2)", function()
	  local uri = "https://gateway.com/orion/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
	  assert.is_false(ngsi.is_ngsi_ld(uri))
    end)
    it("is NOT NGSI-LD request (3)", function()
	  local uri = "https://gateway.com/orion/ngsi-ld/v2/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
	  assert.is_false(ngsi.is_ngsi_ld(uri))
    end)
  end)

  -- Check NGSI compliance
  describe("Test function: check_ngsi_compliance().", function()

    -- GET requests
    it("NGSI-compliant GET requests", function()
	  local method = "GET"
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/subscriptions/urn:ngsi-ld:Subscription:sub-001"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/sub/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
	  assert.is_false(ngsi.check_ngsi_compliance(method, uri))
    end)

    -- PATCH requests
    it("NGSI-compliant PATCH requests", function()
	  local method = "PATCH"
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/attrs/pta"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/"
	  assert.is_false(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/subscriptions/urn:ngsi-ld:Subscription:sub-001"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/subscriptions/"
	  assert.is_false(ngsi.check_ngsi_compliance(method, uri))
    end)

    -- DELETE requests
    it("NGSI-compliant DELETE requests", function()
	  local method = "DELETE"
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001/attrs/pta"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/subscriptions/urn:ngsi-ld:Subscription:sub-001"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/subscriptions/"
	  assert.is_false(ngsi.check_ngsi_compliance(method, uri))
    end)

    -- POST requests
    it("NGSI-compliant POST requests", function()
	  local method = "POST"
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/entities"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/subscriptions/urn:ngsi-ld:Subscription:sub-001"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/subscriptions/"
	  assert.is_true(ngsi.check_ngsi_compliance(method, uri))
    end)

    -- Other methods, not supported
    it("Not NGSI-compliant HTTP methods", function()
	  local uri = "https://gateway.com/orion/ngsi-ld/v1/entities/urn:ngsi-ld:DELIVERYORDER:HAPPYPETS001"
	  assert.is_false(ngsi.check_ngsi_compliance("PUT", uri))
	  assert.is_false(ngsi.check_ngsi_compliance("HEAD", uri))
	  assert.is_false(ngsi.check_ngsi_compliance("CONNECT", uri))
    end)
    
  end)

  -- Get NGSI notification parameters
  describe("Test function: get_notification_parameters().", function()

    -- Notification 1
    it("Notification parameters ok", function()
	  local notification = require('spec.mock.notifications').delivery_order.notification
	  local parameters = require('spec.mock.notifications').delivery_order.parameters
	  local result, err = ngsi.get_notification_parameters(parameters.method, notification)
	  assert.is.falsy(err)
	  assert.are.same(parameters.method, result[1].method)
	  assert.are.same(parameters.entity_type, result[1].entity_type)
	  assert.are.same(parameters.operation_type, result[1].operation_type)
	  assert.is_true(arrayEqual(parameters.identifier, result[1].identifier))
	  assert.is_true(arrayEqual(parameters.attributes, result[1].attributes))
    end)

    -- Notification 1: wrong method PUT
    it("Wrong method PUT", function()
	  local notification = require('spec.mock.notifications').delivery_order.notification
	  local parameters = require('spec.mock.notifications').delivery_order.parameters
	  local result, err = ngsi.get_notification_parameters("PUT", notification)
	  assert.is.truthy(err)
    end)

    -- Notification 1: wrong method GET
    it("Wrong method PUT", function()
	  local notification = require('spec.mock.notifications').delivery_order.notification
	  local parameters = require('spec.mock.notifications').delivery_order.parameters
	  local result, err = ngsi.get_notification_parameters("GET", notification)
	  assert.is.truthy(err)
    end)      
  end)

  -- Get NGSI notification parameters
  describe("Test function: get_notification_parameters().", function()

    it("GET single entity", function()
	  local dict = require('spec.mock.entities').entity_get_1.dict
	  local parameters = require('spec.mock.entities').entity_get_1.parameters
	  ngsi_parameters(dict, parameters)
    end)

    it("GET single entity attrs", function()
	  local dict = require('spec.mock.entities').entity_get_attrs.dict
	  local parameters = require('spec.mock.entities').entity_get_attrs.parameters
	  ngsi_parameters(dict, parameters)
    end)

    it("GET all entities", function()
	  local dict = require('spec.mock.entities').entity_get_all.dict
	  local parameters = require('spec.mock.entities').entity_get_all.parameters
	  ngsi_parameters(dict, parameters)
    end)

    it("POST new entity", function()
	  local dict = require('spec.mock.entities').entity_post_1.dict
	  local parameters = require('spec.mock.entities').entity_post_1.parameters
	  ngsi_parameters(dict, parameters)
    end)

    it("POST new entity attrs", function()
	  local dict = require('spec.mock.entities').entity_post_attrs.dict
	  local parameters = require('spec.mock.entities').entity_post_attrs.parameters
	  ngsi_parameters(dict, parameters)
    end)

    it("PATCH single attr", function()
	  local dict = require('spec.mock.entities').entity_patch_1.dict
	  local parameters = require('spec.mock.entities').entity_patch_1.parameters
	  ngsi_parameters(dict, parameters)
    end)

    it("PATCH multiple attrs", function()
	  local dict = require('spec.mock.entities').entity_patch_1.dict
	  local parameters = require('spec.mock.entities').entity_patch_1.parameters
	  ngsi_parameters(dict, parameters)
    end)

    it("DELETE single entity", function()
	  local dict = require('spec.mock.entities').entity_delete_1.dict
	  local parameters = require('spec.mock.entities').entity_delete_1.parameters
	  ngsi_parameters(dict, parameters)
    end)

    it("DELETE single entity attr", function()
	  local dict = require('spec.mock.entities').entity_delete_attr.dict
	  local parameters = require('spec.mock.entities').entity_delete_attr.parameters
	  ngsi_parameters(dict, parameters)
    end)
    
  end)
end)

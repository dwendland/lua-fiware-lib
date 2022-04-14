#! /bin/bash

cd /fiware

luarocks install busted
luarocks make

# Run tests
echo ""
echo "================="
echo " Running tests"
echo "================="
echo ""

echo "\nngsi_helper_spec"
echo "-------------------"
resty spec/ngsi_helper_spec.lua

echo "\nishare_handler_spec"
echo "-------------------"
resty spec/ishare_handler_spec.lua

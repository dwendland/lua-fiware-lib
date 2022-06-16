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

echo ""
echo "ngsi_helper_spec"
echo "-------------------"
resty spec/ngsi_helper_spec.lua
CODE=$?

echo ""
echo "ishare_handler_spec"
echo "-------------------"
resty spec/ishare_handler_spec.lua
CODE=$?

echo ""
echo "sp_auth_endpoint_handler_spec.lua"
echo "-------------------"
resty spec/sp_auth_endpoint_handler_spec.lua
CODE=$?

# Check for errors
if [ $CODE -ne 0 ]; then
    echo ""
    echo "*************************************"
    echo " At least one of the tests failed"
    echo "*************************************"
    exit 1
fi

echo ""
echo "*************************************"
echo " All tests passed"
echo "*************************************"
exit 0

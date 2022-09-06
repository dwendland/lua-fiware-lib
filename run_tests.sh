#! /bin/bash

cd /fiware

luarocks install busted
luarocks make

# Run tests
ERROR=0
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
if [ $CODE -ne 0 ]; then
    ERROR=1
fi

echo ""
echo "ishare_handler_spec"
echo "-------------------"
resty spec/ishare_handler_spec.lua
CODE=$?
if [ $CODE -ne 0 ]; then
    ERROR=1
fi

echo ""
echo "sp_auth_endpoint_handler_spec.lua"
echo "-------------------"
resty spec/sp_auth_endpoint_handler_spec.lua
CODE=$?
if [ $CODE -ne 0 ]; then
    ERROR=1
fi

# Check for errors
if [ $ERROR -ne 0 ]; then
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

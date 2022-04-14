# lua-fiware-lib

This library provides several lua modules offering 
common functionalities required in FIWARE architectures

Requirements:
* `lua >= 5.1`
* `openresty >= 1.19.9`


## Installation

The Lua package manager [LuaRocks](https://luarocks.org/) is required. 

For installation of the library and all necessary dependencies run:
```shell
luarocks make
```




## Testing

The [busted](http://olivinelabs.com/busted/) framework is used. 

OpenResty provides a Docker image which can be used to run the tests 
without setting up a full environment.

To run the tests:
```shell
docker run --rm -it -v $PWD:/fiware openresty/openresty:1.19.9.1-10-alpine-fat \
	/bin/bash -c 'cd /fiware && ./run_tests.sh'
```

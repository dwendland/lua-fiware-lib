# lua-fiware-lib

[![](https://nexus.lab.fiware.org/repository/raw/public/badges/chapters/api-management.svg)](https://www.fiware.org/developers/catalogue/)
[![License badge](https://img.shields.io/github/license/FIWARE/lua-fiware-lib.svg)](https://opensource.org/licenses/MIT)
[![](https://img.shields.io/badge/tag-fiware-orange.svg?logo=stackoverflow)](http://stackoverflow.com/questions/tagged/fiware)
<br>
![Status](https://nexus.lab.fiware.org/static/badges/statuses/incubating.svg)

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



### Development

To test during development, run the container and install the busted framework:
```shell
docker run --rm -it -v $PWD:/fiware openresty/openresty:1.19.9.1-10-alpine-fat /bin/bash

> cd /fiware
> luarocks install busted
```

After code changes, compile the lib and run your tests:
```shell
> cd /fiware
> luarocks make

# E.g., run ngsi_helper.lua tests
> resty spec/ngsi_helper_spec.lua
```


FROM openresty/openresty:1.19.9.1-10-alpine-fat

COPY . /fiware

# Install dependency packages
RUN set -xe && \
        # Install busted
	luarocks install busted && \
	# Build lib
	cd /fiware && luarocks make

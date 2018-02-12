#!/bin/bash
#
# Contains the a dependency builder to iterate over all installed dependencies
# and cross compile them to the requested target platform.
#
# Usage: build_deps.sh <dependency folder> <configure arguments>
#
# Needed environment variables:
#   CC      - C cross compiler to use for the build
#   HOST    - Target platform to build (used to find the needed tool-chains)
#   PREFIX  - File-system path where to install the built binaries
set -e

# Remove any previous build leftovers, and copy a fresh working set (clean doesn't work for cross compiling)
rm -rf /deps-build && cp -r $1 /deps-build

# Build all the dependencies (no order for now)
for dep in `ls /deps-build`; do
    if [[ "$dep" == *"yara"* ]]; then
        if [ -f "/usr/local/lib/libyara.so" ] || [ -f "/usr/local/lib/libyara.a" ]; then
            echo "Removing previous stuff for dependency $dep for $HOST..."
            # (cd /deps-build/$dep && make uninstall)
            (rm -rf "/usr/local/include/yara")
            (rm -rf "/usr/local/include/yara.h")
            (rm -rf "/usr/local/lib/pkgconfig/yara.pc")
            (rm -rf "/usr/local/lib/libyara*")
            (rm -rf "/usr/local/bin/yara*")
        fi

        echo "Bootstaping dependency $dep for $HOST..."
        (cd /deps-build/$dep && ./bootstrap.sh)

        echo "Configuring dependency $dep for $HOST..."
        (cd /deps-build/$dep && ./configure --disable-shared --host=$HOST --disable-magic --disable-cuckoo --without-crypto --prefix=$PREFIX)

        echo "Building dependency $dep for $HOST..."
        (cd /deps-build/$dep && make && make install)

    else
        echo "Configuring dependency $dep for $HOST..."
        (cd /deps-build/$dep && ./configure --disable-shared --host=$HOST --prefix=$PREFIX --silent ${@:2})

        echo "Building dependency $dep for $HOST..."
        (cd /deps-build/$dep && make --silent -j install)
    fi
done

# Remove any build artifacts
rm -rf /deps-build

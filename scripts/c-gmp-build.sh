#!/usr/bin/env bash

# no longer able to build a working library, likely because I installed custom bintools,
# see: ls /usr/local/Cellar/binutils/2.32/bin/
# see and remove from: ls /usr/local/bin/

# https://stackoverflow.com/questions/52806532/gmp-error-cannot-determine-how-to-define-a-32-bit-word
# https://sourceware.org/bugzilla/show_bug.cgi?id=23728

# build gmp as a static library
# this script should be run from the GMP sources folder

set -euxo pipefail

VERSION_GMP="6.1.2"
VERSION_SDK="12.4"
VERSION_MIN="12.0"

# if it errs with "fatal error: 'stdio.h' file not found", then:
# xcode-select --install
# if it says already installed, then
# open /Library/Developer/CommandLineTools/Packages/macOS_SDK_headers_for_macOS_10.14.pkg

XCODE_DEV_PATH="/Applications/Xcode.app/Contents/Developer"
I_SYS_ROOT="$XCODE_DEV_PATH/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS$VERSION_SDK.sdk/"
CLANG_PATH="$XCODE_DEV_PATH/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"

rm -rf ./ios-build && mkdir -p ./ios-build

function do_build_for_target {
	PLATFORM="$1"  		# iPhoneOS or iPhoneSimulator
	ARCHITECTURE="$2"  	# arm64 or x86_64
	BUILD_PATH="./ios-build/libgmp-$VERSION_GMP-$PLATFORM-$ARCHITECTURE.a"
	SDK_PATH="$XCODE_DEV_PATH/Platforms/$PLATFORM.platform/Developer/SDKs/$PLATFORM$VERSION_SDK.sdk/"
	case "$ARCHITECTURE" in
		x86_64) 
			PARAM_BITCODE=""
			PARAM_ARCH="-target $ARCHITECTURE-apple-darwin"
			PARAM_ADD="--disable-assembly"
		;;
		*)
			PARAM_BITCODE="-fembed-bitcode"
			PARAM_ARCH="-target $ARCHITECTURE-apple-darwin"
			PARAM_ADD=" --host=none --enable-static --disable-shared"
		;;
	esac
	echo "--- do_build_for_target starting $ARCHITECTURE ---"

	make distclean || true
	./configure \
		CC="$CLANG_PATH" \
		CPP="$CLANG_PATH -E" \
		CPPFLAGS="$PARAM_ARCH -isysroot $SDK_PATH -miphoneos-version-min=$VERSION_MIN $PARAM_BITCODE" $PARAM_ADD
	make

	cp .libs/libgmp.a $BUILD_PATH
	echo "--- do_build_for_target done for $BUILD_PATH ---"
}

# do_build_for_target iPhoneSimulator x86_64
do_build_for_target iPhoneOS arm64

ls ./ios-build/

echo "built successfully in ./ios-build"

#!/bin/bash

CLANG=$(xcrun --sdk iphoneos --find clang)
BITCODE_FLAGS=" -fembed-bitcode"

function realpath() {
  [[ $1 = /* ]] && echo "$1" || echo "$PWD/${1#./}"
}

download() {
  local CURRENT=`pwd`
  local GMP_VERSION="6.2.1"

  if [ ! -d "${CURRENT}/gmp" ]; then
    echo "Downloading GMP ${GMP_VERSION}..."
    curl -L -o "${CURRENT}/gmp-${GMP_VERSION}.tar.bz2" http://ftp.gnu.org/gnu/gmp/gmp-${GMP_VERSION}.tar.bz2
    tar xfj "gmp-${GMP_VERSION}.tar.bz2"
    mv gmp-${GMP_VERSION} gmp
    rm "gmp-${GMP_VERSION}.tar.bz2" 
  else
    echo "GMP ${GMP_VERSION} is already downloaded."
  fi
}

build() {
  cd gmp

  build_for_ios
  build_for_simulator
}

build_for_ios() {
  echo "Building library for iOS..."

  local PREFIX=$(realpath "./lib/iphoneos")
  local ARCH='arm64'
  local SDK_DEVICE_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
  local MIN_VERSION='-miphoneos-version-min=15.0'

  build_scheme $PREFIX $ARCH $SDK_DEVICE_PATH $MIN_VERSION
}

build_for_simulator() {
  echo "Building library for iOS simulator..."
  local PREFIX=$(realpath "./lib/iphonesimulator-arm64")
  local SDK_SIMULATOR_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)
  local MIN_VERSION='-miphonesimulator-version-min=15.0'

  build_scheme $PREFIX 'arm64' $SDK_SIMULATOR_PATH $MIN_VERSION

  local PREFIX=$(realpath "./lib/iphonesimulator-x86_64")
  build_scheme $PREFIX 'x86_64' $SDK_SIMULATOR_PATH $MIN_VERSION
}

build_scheme() {
  clean

  local PREFIX="$1"
  local ARCH="$2"
  local SYS_ROOT="$3"
  local MIN_VERSION="$4"

  local EXTRAS="--target=${ARCH}-apple-darwin -arch ${ARCH} ${MIN_VERSION} -no-integrated-as"
  local CFLAGS=" ${EXTRAS} ${BITCODE_FLAGS} -isysroot ${SYS_ROOT} -Wno-error -Wno-implicit-function-declaration"

	if [ ! -e "${PREFIX}" ]; then
    mkdir -p "${PREFIX}"

    ./configure \
      --prefix="${PREFIX}" \
      CC="${CLANG}" \
      CPPFLAGS="${CFLAGS}" \
      --host=arm64-apple-darwin \
      --disable-assembly --enable-static --disable-shared --enable-cxx

    make
    make install
  fi
}

create_framework() {
  echo "Merging libraries in XCFramework..."

	local SIMULATOR_PATH="./lib/iphonesimulator"
  local BUILD_PATH="./build/GMP.xcframework"

  mkdir -p $SIMULATOR_PATH/lib

  lipo -create -output ${SIMULATOR_PATH}/lib/libgmp.a \
		-arch arm64 ${SIMULATOR_PATH}-arm64/lib/libgmp.a \
		-arch x86_64 ${SIMULATOR_PATH}-x86_64/lib/libgmp.a

	xcodebuild -create-xcframework \
		-library ./lib/iphoneos/lib/libgmp.a \
		-library ${SIMULATOR_PATH}/lib/libgmp.a \
		-output $BUILD_PATH

  echo "GMP.xcframework saved to 'build' folder"
}

clean() {
  make clean
  make distclean
}

download
build
create_framework
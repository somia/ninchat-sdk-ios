#!/bin/bash

echo "Will rebuild the low-level framework."

framework="NinchatLowLevelClient.framework"

mygopath="$GOPATH:`pwd`/go-sdk"
gocodedir="`pwd`/go-sdk/src/github.com/ninchat/ninchat-go/mobile/"
tmpframework="/tmp/$framework"
frameworkdir="Frameworks/$framework"

# Clean up previous builds
rm -rf "$tmpframework"

# Check that the go code dir exists
if [[ ! -d $gocodedir ]]
then
    echo "Could not find go code dir: $gocodedir"
    exit 1
fi

echo "Running gomobile tool.."
GOPATH=$mygopath gomobile bind -target ios -prefix NINLowLevel \
      -o $tmpframework github.com/ninchat/ninchat-go/mobile
if [ $? -ne 0 ]; then
    echo "gomobile cmd failed, aborting."
    exit 1
fi

# Copy the main header + the binary over to the framework dir
cp "$tmpframework/Headers/NINLowLevelClient.objc.h" "$frameworkdir/Headers/"
cp "$tmpframework/Client" "$frameworkdir/Versions/Current/NinchatLowLevelClient"

echo "Done."

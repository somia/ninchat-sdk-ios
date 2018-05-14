#!/bin/bash

echo "Rebuilding Go SDK framework.."

framework="Client.framework"

mygopath="$GOPATH:`pwd`/go-sdk"
gocodedir="go-sdk/src/github.com/ninchat/ninchat-go/mobile"
tmpframework="/tmp/$framework"
frameworkdir="Frameworks/$framework"

# Clean up previous builds
rm -rf "$tmpframework"

cd $gocodedir
if [ $? -ne 0 ]; then
    echo "Failed to find go code dir. Did you run this from the ios dir?"
    exit 1
fi

echo "Running gomobile tool.."
GOPATH=$mygopath gomobile bind -target ios -o $tmpframework github.com/ninchat/ninchat-go/mobile
if [ $? -ne 0 ]; then
    echo "gomobile cmd failed, aborting."
    exit 1
fi

# Return to the previous dir quietly
cd ~-
                      
echo "Replacing framework contents"
rm -rf $frameworkdir
cp -r $tmpframework $frameworkdir

echo "Done."

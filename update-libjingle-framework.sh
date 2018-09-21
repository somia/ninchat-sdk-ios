#!/bin/bash

echo "Will recreate the Libjingle framework."

framework="Frameworks/Libjingle.framework"
archive="https://s3.amazonaws.com/libjingle/11177/Release/0/libWebRTC.tar.bz2"
workdir=`mktemp -d -t libjingle`

echo "work dir: $workdir"

cd $workdir

echo "Fetching the libWebRTC archive over HTTP"
wget $archive -O libWebRTC.tar.bz2
if [ $? -ne 0 ]; then
    echo "Failed to wget the libWebRTC archive"
    exit 1
fi

echo "Extracting the libWebRTC archive"
bunzip2 libWebRTC.tar.bz2 && tar xf libWebRTC.tar
if [ $? -ne 0 ]; then
    echo "Failed to extract the libWebRTC archive"
    exit 1
fi

cd -

echo "Copying the extracted headers + binary into the framework structure"

cp $workdir/libjingle_peerconnection/Headers/* "$framework/Headers"
cp $workdir/libjingle_peerconnection/libWebRTC.a "$framework/Libjingle"

# Cleanup 
rm -r $workdir

echo "Done."

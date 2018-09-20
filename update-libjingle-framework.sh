#!/bin/bash

framework="Frameworks/Libjingle.framework"
archive="https://s3.amazonaws.com/libjingle/11177/Release/0/libWebRTC.tar.bz2"
work="`pwd`/libjingle-extraction-temp"

if [ -d $work ]
then 
    echo "Working directory $work already exists."
    echo "If it is not there for a purpose, delete it and try again."
    exit 1
fi

echo "Will (re)create the $framework from cocoapod."

mkdir -p $work
cd $work

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

cd ..

echo "Copying the extracted headers + binary into the framework structure"

cp "$work/libjingle_peerconnection/Headers/*" "$framework/Headers"
cp "$work/libjingle_peerconnection/libWebRTC.a" "$framework/Libjingle"

rm -r $work
echo "All done!"

#! /bin/sh

cd ~/
git clone https://github.com/FelixScat/Tracer.git
cd Tracer

# check if static link is needed
if [ -d "/Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/lib/swift_static/macosx" ];then
    swift build -c release -Xswiftc -static-stdlib
else
    swift build -c release
fi

cd .build/release
cp -f Tracer /usr/local/bin/Tracer
cd ~/
rm -rf Tracer
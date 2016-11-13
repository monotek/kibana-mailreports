#!/bin/bash
#
# build samba with glusterfs vfs module
#

apt-get install build-essential g++ flex bison gperf ruby perl libsqlite3-dev libfontconfig1-dev libicu-dev libfreetype6 libssl-dev libpng-dev libjpeg-dev python libx11-dev libxext-dev ttf-mscorefonts-installer

git clone git://github.com/ariya/phantomjs.git

cd phantomjs

git checkout 2.0

./build.sh --qt-config "-I /usr/local/include/ -L /usr/local/lib/"

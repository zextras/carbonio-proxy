#!/bin/sh

set -x

mkdir /tmp/build

cp -r /project/package/* /tmp/build/
cp -r /project/conf/nginx/errors/* /tmp/build/proxy/
cp -r /project/conf/nginx/templates/* /tmp/build/proxy/

yap build ubuntu-focal /tmp/build/

cp /artifacts/* /project/artifacts/

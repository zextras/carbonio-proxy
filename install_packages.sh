#!/usr/bin/env bash
HOST=$1

LAST_PACKAGE_PATH=$(ls artifacts/carbonio-proxy*.deb | tail -n 1)
PACKAGE_NAME=$(basename ${LAST_PACKAGE_PATH})

rsync -acz artifacts/${PACKAGE_NAME} root@${HOST}:/tmp/
ssh root@${HOST} "dpkg -i /tmp/${PACKAGE_NAME}"
ssh -t root@${HOST} "pending-setups -a"


#!/usr/bin/env bash
HOST=$1

LAST_PACKAGE_PATH=$(ls -t artifacts/carbonio-proxy*.deb | head -n 1)
PACKAGE_NAME=$(basename ${LAST_PACKAGE_PATH})

rsync -acz artifacts/${PACKAGE_NAME} root@${HOST}:/tmp/
ssh root@${HOST} "dpkg -i /tmp/${PACKAGE_NAME}"
ssh -t root@${HOST} "pending-setups -a"


#!/bin/bash
#
# SPDX-FileCopyrightText: 2023 Zextras <https://www.zextras.com>
#
# SPDX-License-Identifier: GPL-2.0-only
#
OS=${1:-"ubuntu-jammy"}

echo "Building for OS: $OS"

mkdir -p "$(pwd)/artifacts/${OS}"

docker run -it --rm \
  --entrypoint=bash \
  -v "$(pwd)/artifacts/${OS}":/artifacts \
  -v "$(pwd)":/tmp/build \
  "docker.io/m0rf30/yap-${OS}:2.0.1" \
  -c 'sudo yap build "${OS}" /tmp/build -sdc'

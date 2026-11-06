# syntax=docker/dockerfile:1.24

# Stage 0: the base image (also the one of the final stage), and the static
# configd binary.
FROM --platform=$TARGETPLATFORM registry.dev.zextras.com/dev/carbonio-mailbox:devel AS base-image
FROM --platform=$TARGETPLATFORM registry.dev.zextras.com/dev/carbonio-configd:main AS configd

# Stage 1: runs natively on BUILDPLATFORM (amd64 CI builder) — no QEMU.
# Downloads carbonio-nginx + runtime libs for TARGETARCH via apt-get download
# (no dep resolution, no postinst scripts, no service-discover/resolvconf).
# Also pre-generates the self-signed cert, the zmproxyconfgen wrapper and the
# zextras user/group files so the final stage needs zero RUN steps.
FROM --platform=$BUILDPLATFORM docker.io/library/ubuntu:jammy AS nginx-installer

ARG TARGETARCH
ARG BUILDARCH=amd64

# passwd/group of the final stage's base image: the zextras user is appended to
# them below. configd refuses to write the proxy configuration as root, it
# insists on the 'zextras' user (the Java generator did not care).
COPY --from=base-image /etc/passwd /base/passwd
COPY --from=base-image /etc/group /base/group

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates openssl \
 # Cross-arch setup when TARGETARCH != BUILDARCH
 && if [ "${TARGETARCH}" != "${BUILDARCH}" ]; then \
      dpkg --add-architecture ${TARGETARCH} \
      && sed -i 's|^deb |deb [arch='"${BUILDARCH}"'] |' /etc/apt/sources.list \
      && printf 'Types: deb\nURIs: http://ports.ubuntu.com/ubuntu-ports/\nSuites: jammy jammy-updates jammy-security\nComponents: main restricted universe multiverse\nArchitectures: %s\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\n' "${TARGETARCH}" \
         > /etc/apt/sources.list.d/ports-${TARGETARCH}.sources; \
    fi \
 && printf 'deb [arch=%s trusted=yes] https://repo.zextras.tools/repository/ubuntu-devel-jammy jammy main\n' "${TARGETARCH}" \
    > /etc/apt/sources.list.d/zextras.list \
 && apt-get update \
 # Download only the packages needed to run nginx — no dep resolution, no carbonio-core
 && mkdir -p /staging /tmp/debs && cd /tmp/debs \
 && apt-get download \
      carbonio-nginx:${TARGETARCH} \
      carbonio-openssl:${TARGETARCH} \
      carbonio-cyrus-sasl:${TARGETARCH} \
      libbrotli1:${TARGETARCH} \
      libcap2:${TARGETARCH} \
      libluajit-5.1-2:${TARGETARCH} \
      libpcre3:${TARGETARCH} \
      zlib1g:${TARGETARCH} \
 # Extract all debs with dpkg -x — no postinst scripts run
 && for deb in /tmp/debs/*.deb; do dpkg -x "$deb" /staging; done \
 && rm -rf /tmp/debs \
 # Collect arch-specific libs into /staging/usr/local/lib for arch-independent COPY
 && mkdir -p /staging/usr/local/lib \
 && find /staging/lib /staging/usr/lib -name '*.so*' -not -path '*/opt/*' \
    -exec cp -P {} /staging/usr/local/lib/ \; 2>/dev/null || true \
 # Pre-create directories needed at runtime
 && mkdir -p /staging/opt/zextras/conf/nginx/includes \
 && mkdir -p /staging/opt/zextras/data/tmp/nginx/client \
 && mkdir -p /staging/opt/zextras/common/conf \
 && touch /staging/opt/zextras/conf/nginx/includes/nginx.conf.main \
 # Generate self-signed cert (runs natively on BUILDPLATFORM)
 && openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 \
        -nodes -keyout /staging/opt/zextras/conf/nginx.key \
        -out /staging/opt/zextras/conf/nginx.crt -subj "/CN=example.com" \
        -addext "subjectAltName=DNS:example.com,DNS:*.example.com,IP:10.0.0.1" \
 # zmproxyconfgen wrapper: configd is the nginx configuration generator
 && mkdir -p /staging/usr/bin \
 && printf '#!/bin/sh\nexec /opt/zextras/bin/configd proxy gen "$@"\n' \
    > /staging/usr/bin/zmproxyconfgen \
 && chmod 755 /staging/usr/bin/zmproxyconfgen \
 # configd reads <base dir>/conf/localconfig.xml; the image keeps it (the
 # entrypoint fills in its placeholders) at /localconfig/localconfig.xml, the
 # path the mailbox tools (zmprov) read
 && ln -s /localconfig/localconfig.xml /staging/opt/zextras/conf/localconfig.xml \
 # zextras user and group (uid/gid 999), appended to the base image files
 && mkdir -p /staging/etc \
 && { cat /base/passwd; echo 'zextras:x:999:999:Carbonio:/opt/zextras:/usr/sbin/nologin'; } \
    > /staging/etc/passwd \
 && { cat /base/group; echo 'zextras:x:999:'; } > /staging/etc/group \
 && rm -rf /var/lib/apt/lists/*

# Stage 2: final image — TARGETPLATFORM, zero RUN steps (no QEMU needed).
FROM --platform=$TARGETPLATFORM base-image
USER root

COPY entrypoint.sh entrypoint.sh
COPY proxy/conf /opt/zextras/conf

ENV MEMCACHED_BIND_ADDRESS="memcached"
ENV MEMCACHED_BIND_PORT=11211
ENV CARBONIO_FILES_HOST="127.78.0.1:20000"
ENV CARBONIO_WSC_HOST="127.78.0.1:20001"
ENV CARBONIO_DOCS_CONNECTOR_HOST="127.78.0.1:20002"
ENV CARBONIO_DOCS_EDITOR_HOST="127.78.0.1:20003"
ENV CARBONIO_MESSAGE_DISPATCHER_HOST="127.78.0.1:20004"
ENV CARBONIO_MESSAGE_DISPATCHER_XMPP_HOST="127.78.0.1:20005"
ENV CARBONIO_ADDRESS_BOOK_HOST="127.78.0.1:20006"
ENV CARBONIO_TASKS_HOST="127.78.0.1:20007"
ENV CARBONIO_AUTH_HOST="127.78.0.1:20008"
ENV CARBONIO_STORAGES_HOST="127.78.0.1:20009"
ENV CARBONIO_NOTIFICATION_PUSH_HOST="127.78.0.1:20010"
ENV CARBONIO_CERTIFICATE_MANAGER_HOST="127.78.0.1:20011"
ENV CARBONIO_CATALOG_HOST="127.78.0.1:20012"
ENV CARBONIO_MEMCACHED_HOST="127.78.0.1:20014"

COPY --from=nginx-installer /staging/opt /opt
COPY --from=nginx-installer /staging/usr/local/lib /usr/local/lib/
COPY --from=nginx-installer /staging/usr/bin/zmproxyconfgen /usr/bin/zmproxyconfgen
COPY --from=nginx-installer /staging/etc/passwd /staging/etc/group /etc/
COPY --from=configd /opt/zextras/bin/configd /opt/zextras/bin/configd
# LDAP attribute schema configd reads (<base dir>/conf/attrs); the Java generator
# had it inside the mailbox jars
COPY --from=configd /opt/zextras/share/configd/conf/attrs /opt/zextras/conf/attrs
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

ENTRYPOINT ["./entrypoint.sh"]

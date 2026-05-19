# syntax=docker/dockerfile:1.4

# Stage 1: runs natively on BUILDPLATFORM (amd64 CI builder) — no QEMU.
# Downloads carbonio-nginx + runtime libs for TARGETARCH via apt-get download
# (no dep resolution, no postinst scripts, no service-discover/resolvconf).
# Also pre-generates the self-signed cert and zmproxyconfgen wrapper so the
# final stage needs zero RUN steps.
FROM --platform=$BUILDPLATFORM ubuntu:jammy AS nginx-installer

ARG TARGETARCH
ARG BUILDARCH=amd64
ARG PROXY_JAVA_ARGS="-Dfile.encoding=UTF-8 -server \
              -Dhttps.protocols=TLSv1.2,TLSv1.3 \
              -Djdk.tls.client.protocols=TLSv1.2,TLSv1.3 \
              -Djava.awt.headless=true -Djava.net.preferIPv4Stack=true \
              -Dsun.net.inetaddr.ttl=60 -Dorg.apache.jasper.compiler.disablejsr199=true \
              -XX:+UseG1GC -XX:SoftRefLRUPolicyMSPerMB=1 -XX:+UnlockExperimentalVMOptions \
              -XX:G1NewSizePercent=15 -XX:G1MaxNewSizePercent=45 -XX:-OmitStackTraceInFastThrow \
              -Djava.security.egd=file:/dev/./urandom \
              --add-opens java.base/java.lang=ALL-UNNAMED \
              -Xss256k -Dlog4j.configurationFile=/opt/zextras/conf/log4j.properties \
              -Xms1996m -Xmx1996m -Djava.io.tmpdir=/opt/zextras/mailboxd/work \
              -Djava.library.path=/opt/zextras/lib \
              -Dzimbra.config=/localconfig/localconfig.xml \
              -Dzimbra.native.required=false \
              -Dlog4j.configurationFile=/opt/zextras/conf/log4j.properties \
              -cp /opt/zextras/proxyconfgen/proxyconfgen.jar"

RUN apt-get update \
 && apt-get install -y --no-install-recommends ca-certificates openssl \
 # Cross-arch setup when TARGETARCH != BUILDARCH
 && if [ "${TARGETARCH}" != "${BUILDARCH}" ]; then \
      dpkg --add-architecture ${TARGETARCH} \
      && sed -i 's|^deb |deb [arch='"${BUILDARCH}"'] |' /etc/apt/sources.list \
      && printf 'Types: deb\nURIs: http://ports.ubuntu.com/ubuntu-ports/\nSuites: jammy jammy-updates jammy-security\nComponents: main restricted universe multiverse\nArchitectures: %s\nSigned-By: /usr/share/keyrings/ubuntu-archive-keyring.gpg\n' "${TARGETARCH}" \
         > /etc/apt/sources.list.d/ports-${TARGETARCH}.sources; \
    fi \
 && printf 'deb [arch=%s trusted=yes] https://repo.area51-zextras.com/devel/ubuntu jammy main\n' "${TARGETARCH}" \
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
 # Write zmproxyconfgen wrapper
 && mkdir -p /staging/usr/bin \
 && echo "java ${PROXY_JAVA_ARGS} com.zimbra.cs.util.proxyconfgen.ProxyConfGen \"\$@\"" \
    > /staging/usr/bin/zmproxyconfgen \
 && chmod +x /staging/usr/bin/zmproxyconfgen \
 && rm -rf /var/lib/apt/lists/*

# Stage 2: final image — TARGETPLATFORM, zero RUN steps (no QEMU needed).
FROM --platform=$TARGETPLATFORM registry.dev.zextras.com/dev/carbonio-mailbox:devel
USER root

COPY target/proxyconfgen.jar /opt/zextras/proxyconfgen/proxyconfgen.jar
COPY entrypoint.sh entrypoint.sh
COPY proxy/conf /opt/zextras/conf

ENV MEMCACHED_BIND_ADDRESS="memcached"
ENV MEMCACHED_BIND_PORT=11211
ENV CARBONIO_FILES_HOST="127.78.0.1:20000"
ENV CARBONIO_WSC_HOST="127.78.0.1:20001"
ENV CARBONIO_DOCS_CONNECTOR_HOST="127.78.0.1:20002"
ENV CARBONIO_DOCS_EDITOR_HOST="127.78.0.1:20003"
ENV CARBONIO_MESSAGE_DISPATCHER_HOST="127.78.0.1:20004"
ENV CARBONIO_TASKS_HOST="127.78.0.1:20007"
ENV CARBONIO_AUTH_HOST="127.78.0.1:20008"
ENV CARBONIO_STORAGES_HOST="127.78.0.1:20009"
ENV CARBONIO_NOTIFICATION_PUSH_HOST="127.78.0.1:20010"
ENV CARBONIO_CERTIFICATE_MANAGER_HOST="127.78.0.1:20011"
ENV CARBONIO_CATALOG_HOST="127.78.0.1:20012"

COPY --from=nginx-installer /staging/opt /opt
COPY --from=nginx-installer /staging/usr/local/lib /usr/local/lib/
COPY --from=nginx-installer /staging/usr/bin/zmproxyconfgen /usr/bin/zmproxyconfgen
ENV LD_LIBRARY_PATH=/usr/local/lib:${LD_LIBRARY_PATH}

ENTRYPOINT ["./entrypoint.sh"]

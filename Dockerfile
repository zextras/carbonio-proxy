FROM registry.dev.zextras.com/dev/carbonio-mailbox:devel
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


RUN apt update && apt install -y gnupg2 ca-certificates && apt clean \
&& apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 52FD40243E584A21 \
&& echo deb https://repo.zextras.io/release/ubuntu jammy main > /etc/apt/sources.list.d/zextras.list \
&& apt update && apt install -y carbonio-nginx openssl netcat curl && apt clean \
&& mkdir -p /opt/zextras/conf \
&& mkdir -p /opt/zextras/data/tmp/nginx/client \
&& mkdir -p /run/carbonio \
&& mkdir -p /opt/zextras/common/conf \
&& openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 \
-nodes -keyout /opt/zextras/conf/nginx.key \
-out /opt/zextras/conf/nginx.crt -subj "/CN=example.com" \
-addext "subjectAltName=DNS:example.com,DNS:*.example.com,IP:10.0.0.1" \
&& mkdir -p /opt/zextras/conf/nginx/includes && touch /opt/zextras/conf/nginx/includes/nginx.conf.main \
&& echo "java $PROXY_JAVA_ARGS com.zimbra.cs.util.proxyconfgen.ProxyConfGen \"\$@\"" > /usr/bin/zmproxyconfgen

ENTRYPOINT ["./entrypoint.sh"]

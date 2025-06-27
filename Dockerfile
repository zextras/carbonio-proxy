# TODO: use mailbox container image (be careful it is based on ubuntu noble but we need at least jammy)
FROM mailbox-local
USER root

RUN apt update && apt install -y gnupg2 ca-certificates && apt clean \
&& apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 52FD40243E584A21 \
&& echo deb https://repo.zextras.io/release/ubuntu jammy main > /etc/apt/sources.list.d/zextras.list \
&& apt update && apt install -y carbonio-nginx openssl netcat curl && apt clean

RUN mkdir -p /opt/zextras/conf
RUN mkdir -p /opt/zextras/data/tmp/nginx/client
RUN mkdir -p /run/carbonio
RUN mkdir -p /opt/zextras/common/conf

# TODO: is a self-signed certificate required?
RUN openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 \
-nodes -keyout /opt/zextras/conf/nginx-carbonio.key \
-out /opt/zextras/conf/nginx-carbonio.crt -subj "/CN=example.com" \
-addext "subjectAltName=DNS:example.com,DNS:*.example.com,IP:10.0.0.1"

COPY conf /opt/zextras/conf

COPY entrypoint.sh entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
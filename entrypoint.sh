#!/bin/bash

sed -i -e "s#LDAP_URL#${LDAP_URL}#g" /localconfig/localconfig.xml
sed -i -e "s/LDAP_ROOT_PASSWORD/${LDAP_ROOT_PASSWORD}/g" /localconfig/localconfig.xml
sed -i -e "s/LDAP_ADMIN_PASSWORD/${LDAP_ADMIN_PASSWORD}/g" /localconfig/localconfig.xml
sed -i -e "s/MARIADB_ROOT_PASSWORD/${MARIADB_ROOT_PASSWORD}/g" /localconfig/localconfig.xml
sed -i -e "s/MARIADB_URL/${MARIADB_URL}/g" /localconfig/localconfig.xml
sed -i -e "s/MARIADB_PORT/${MARIADB_PORT}/g" /localconfig/localconfig.xml
sed -i -e "s/SERVER_HOSTNAME/${HOSTNAME}/g" /localconfig/localconfig.xml

# Upstreams update
sed -i -e "s/127.78.0.1:20000/${CARBONIO_FILES_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template
sed -i -e "s/127.78.0.1:20001/${CARBONIO_WSC_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template
sed -i -e "s/127.78.0.1:20002/${CARBONIO_DOCS_CONNECTOR_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template
sed -i -e "s/127.78.0.1:20003/${CARBONIO_DOCS_EDITOR_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template
sed -i -e "s/127.78.0.1:20004/${CARBONIO_MESSAGE_DISPATCHER_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template
sed -i -e "s/127.78.0.1:20007/${CARBONIO_TASKS_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template
sed -i -e "s/127.78.0.1:20008/${CARBONIO_AUTH_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template
sed -i -e "s/127.78.0.1:20009/${CARBONIO_STORAGES_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template
sed -i -e "s/127.78.0.1:20010/${CARBONIO_NOTIFICATION_PUSH_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template
sed -i -e "s/127.78.0.1:20011/${CARBONIO_CERTIFICATE_MANAGER_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template
sed -i -e "s/127.78.0.1:20012/${CARBONIO_CATALOG_HOST}/g" /opt/zextras/conf/nginx/templates/nginx.conf.web.upstreams.template


SERVER_EXISTS=$(/usr/bin/zmprov -l gs "${HOSTNAME}" 2>&1)
if [[ $SERVER_EXISTS == *"account.NO_SUCH_SERVER"* ]]; then
  echo "Creating server ${HOSTNAME}"
  /usr/bin/zmprov -l cs "${HOSTNAME}" zimbraServiceInstalled proxy \
                                      zimbraServiceEnabled proxy \
                                      zimbraServiceInstalled memcached \
                                      zimbraServiceEnabled memcached \
                                      zimbraMemcachedBindAddress "${MEMCACHED_BIND_ADDRESS}" \
                                      zimbraMemcachedBindPort "${MEMCACHED_BIND_PORT}" \
                                      zimbraMailProxyPort 80 \
                                      zimbraMailSSLProxyPort 443 \
                                      zimbraReverseProxyStrictServerNameEnabled FALSE

  echo "Server ${HOSTNAME} created"
fi


chmod +x /usr/bin/zmproxyconfgen

/usr/bin/zmproxyconfgen

/opt/zextras/common/sbin/nginx -c /opt/zextras/conf/nginx.conf -g "daemon off;"
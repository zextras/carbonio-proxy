#!/bin/bash

sed -i -e "s#LDAP_URL#${LDAP_URL}#g" /localconfig/localconfig.xml
sed -i -e "s/LDAP_ROOT_PASSWORD/${LDAP_ROOT_PASSWORD}/g" /localconfig/localconfig.xml
sed -i -e "s/LDAP_ADMIN_PASSWORD/${LDAP_ADMIN_PASSWORD}/g" /localconfig/localconfig.xml
sed -i -e "s/MARIADB_ROOT_PASSWORD/${MARIADB_ROOT_PASSWORD}/g" /localconfig/localconfig.xml
sed -i -e "s/MARIADB_URL/${MARIADB_URL}/g" /localconfig/localconfig.xml
sed -i -e "s/MARIADB_PORT/${MARIADB_PORT}/g" /localconfig/localconfig.xml
sed -i -e "s/SERVER_HOSTNAME/${HOSTNAME}/g" /localconfig/localconfig.xml

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

echo "Testing Nginx configuration"
/opt/zextras/common/sbin/nginx -t
echo "Nginx configuration is ok!"

/opt/zextras/common/sbin/nginx -c /opt/zextras/conf/nginx.conf
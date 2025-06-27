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
  /usr/bin/zmprov -l cs "${HOSTNAME}" zimbraServiceInstalled proxy zimbraServiceEnabled proxy
  echo "Server ${HOSTNAME} created"
fi

# TODO: expose java base args from mailbox container
ARGS="-Dfile.encoding=UTF-8 -server \
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
              -cp /opt/zextras/mailbox/jars/mailbox.jar:/opt/zextras/mailbox/jars/*"

echo "java $ARGS com.zimbra.cs.util.proxyconfgen.ProxyConfGen \"\$@\"" > /usr/bin/zmproxyconfgen

chmod +x /usr/bin/zmproxyconfgen

/usr/bin/zmproxyconfgen

# TODO: nginx requires memcached
# WARN : No available nginx lookup handlers could be found
# INFO : Strict server name enforcement enabled? true
# ERROR: Error while expanding templates: No available memcached servers could be contacted
/opt/zextras/common/sbin/nginx -c /opt/zextras/conf/nginx.conf
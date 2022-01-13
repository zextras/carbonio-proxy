targets=(
  "centos"
  "ubuntu"
)
pkgname="carbonio-proxy"
pkgver="4.0.0"
pkgrel="1"
pkgdesc="An open-source, community-driven email server"
pkgdesclong=(
  "An open-source, community-driven email server"
)
maintainer="Zextras <packages@zextras.com>"
url="https://zextras.com"
section="mail"
priority="optional"
arch="amd64"
depends:apt=(
  "carbonio-core"
  "carbonio-memcached"
  "carbonio-nginx"
  "sqlite3"
)
depends:yum=(
  "carbonio-core"
  "carbonio-memcached"
  "carbonio-nginx"
  "sqlite"
)

package() {
  cd "${srcdir}"/..
  install -D sudoers/02_carbonio-proxy \
    "${pkgdir}/etc/sudoers.d/02_carbonio-proxy"
  mkdir -p "${pkgdir}/opt/zextras/conf/nginx/includes/"
  rsync -a conf/nginx/ \
    "${pkgdir}/opt/zextras/conf/nginx/templates/"
}

postinst() {
  grep -E -q '^%zextras[[:space:]]' /etc/sudoers

  if [ $? = 0 ]; then
    sudotmp=$(mktemp -t zsudoers.XXXXXX 2>/dev/null) || {
      echo "Failed to create tmpfile"
      exit 1
    }
    SUDOMODE=$(perl -e 'my $mode=(stat("/etc/sudoers"))[2];printf("%04o\n",$mode & 07777);')
    grep -E -v '^%zextras[[:space:]]' /etc/sudoers >$sudotmp
    mv -f $sudotmp /etc/sudoers
    chmod $SUDOMODE /etc/sudoers
  fi
  chmod 440 /etc/sudoers.d/02_carbonio-proxy
  chown root:root /etc/sudoers.d/02_carbonio-proxy
  chown -R zextras:zextras /opt/zextras/conf/nginx
}

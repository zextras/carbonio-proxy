DOMAIN=demo.zextras.io

sys-status:
	ssh root@${HOST}.${DOMAIN} "systemctl status carbonio-proxy"

sys-stop:
	ssh root@${HOST}.${DOMAIN} "systemctl stop carbonio-proxy"

sys-start:
	ssh root@${HOST}.${DOMAIN} "systemctl start carbonio-proxy"

sys-install:
	./build_packages.sh
	./install_packages.sh ${HOST}.${DOMAIN}

.PHONY: sys-status sys-stop sys-start sys-install


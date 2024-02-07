DOMAIN=demo.zextras.io

build:
	docker run --rm -it \
		-v $(shell pwd):/project \
		--entrypoint='/project/build_entrypoint.sh' \
		registry.dev.zextras.com/jenkins/pacur/ubuntu-20.04:v2

sys-status:
	ssh root@${HOST}.${DOMAIN} "systemctl status carbonio-proxy"

sys-stop:
	ssh root@${HOST}.${DOMAIN} "systemctl stop carbonio-proxy"

sys-start:
	ssh root@${HOST}.${DOMAIN} "systemctl start carbonio-proxy"

sys-install: build
	./install_packages.sh ${HOST}.${DOMAIN}

.PHONY: build sys-status sys-stop sys-start sys-install


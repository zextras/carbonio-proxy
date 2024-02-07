DOMAIN=demo.zextras.io

build:
	docker run --rm -it \
		-v $(shell pwd):/project \
		--entrypoint='/project/build_entrypoint.sh' \
		registry.dev.zextras.com/jenkins/pacur/ubuntu-20.04:v2

install:
	./install_packages.sh ${HOST}.${DOMAIN}

sys-status:
	@$(call execute_zextras_cmd, "zmproxyctl status")

sys-stop:
	@$(call execute_zextras_cmd, "zmproxyctl stop")

sys-start:
	@$(call execute_zextras_cmd, "zmproxyctl start")

sys-restart:
	@$(call execute_zextras_cmd, "zmproxyctl restart")

sys-install: build install sys-restart

.PHONY: build install sys-status sys-stop sys-start sys-restart sys-install

define execute_zextras_cmd
	ssh root@${HOST}.${DOMAIN} "su - zextras -c '$(1)'"
endef


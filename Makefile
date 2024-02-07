DOMAIN=demo.zextras.io

host-check:
	 @$(call check,$(HOST))

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

sys-install: host-check build install sys-restart

.PHONY: host-check build install sys-status sys-stop sys-start sys-restart sys-install

define execute_zextras_cmd
	ssh root@${HOST}.${DOMAIN} "su - zextras -c '$(1)'"
endef

define check 
  $(eval HOST := $(1))

  # COLOR CODES
  $(eval RED	:= \033[0;31m)
  $(eval GREEN	:= \033[0;32m)
  $(eval NC		:= \033[0m) # NO COLOR

  if [ -z "$(HOST)" ]; then \
    echo "$(RED)No HOST found$(NC). Please provide one."; \
    exit 1; \
  else \
	echo "$(GREEN)Using host: $(HOST)$(NC)"; \
  fi
endef

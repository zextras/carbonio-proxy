build:
	docker run --rm -it \
		--workdir /project \
		-v $(shell pwd):/project \
		docker.io/m0rf30/yap-ubuntu-focal:1.11 \
		build ubuntu-focal package -sdc

sys-install: host-check
	./install-packages.sh ${HOST}

sys-deploy: host-check build sys-install sys-restart

sys-status:
	@$(call execute_zextras_cmd, "zmproxyctl status")

sys-start:
	@$(call execute_zextras_cmd, "zmproxyctl start")

sys-stop:
	@$(call execute_zextras_cmd, "zmproxyctl stop")

sys-restart:
	@$(call execute_zextras_cmd, "zmproxyctl restart")

host-check:
	 @$(call check, HOST, $(HOST))

.PHONY: build sys-install sys-deploy sys-status sys-start sys-stop sys-restart host-check 

define execute_zextras_cmd
  @$(call check, HOST, $(HOST))
  ssh root@${HOST} "su - zextras -c '$(1)'"
endef

define check 
  $(eval VAR_NAME	:= $(1))
  $(eval VAR_VALUE	:= $(2))

  # COLOR CODES
  $(eval RED	:= \033[0;31m)
  $(eval GREEN	:= \033[0;32m)
  $(eval NC		:= \033[0m) # NO COLOR

  if [ -z "$(VAR_VALUE)" ]; then \
    echo "$(RED)No $(VAR_NAME) found$(NC). Please provide one."; \
    exit 1; \
  else \
    echo "$(GREEN)Using $(VAR_NAME): $(VAR_VALUE)$(NC)"; \
  fi
endef

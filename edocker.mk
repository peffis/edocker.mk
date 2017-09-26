DOCKER ?= docker
NAMESPACE = $(shell basename `pwd`)
LRM = erlang_linux_release_builder
MAKER_EXISTS = $(shell $(DOCKER) images -q $(LRM) 2> /dev/null)
ROOT_VOLUME = $(NAMESPACE)_root
ROOT_MOUNT_POINT = /$(NAMESPACE)
DEPS_VOLUME = $(NAMESPACE)_deps
DEPS_MOUNT_POINT = $(ROOT_MOUNT_POINT)/deps
REL_VOLUME = $(NAMESPACE)_rel
REL_MOUNT_POINT = $(ROOT_MOUNT_POINT)/_rel
EBIN_VOLUME = $(NAMESPACE)_ebin
EBIN_MOUNT_POINT = $(ROOT_MOUNT_POINT)/ebin
EDOCKER_REPO = https://github.com/peffis/edocker.mk.git
BINARIES_TO_INCLUDE ?=
EXTRA_PACKAGES ?=

define log_msg
	@printf "\033[1;37m===> "$(1)"\033[0m\n"
endef


volumes: $(ROOT_VOLUME) $(DEPS_VOLUME) $(REL_VOLUME) $(EBIN_VOLUME)


$(ROOT_VOLUME):
	$(call log_msg,"creating "$(ROOT_VOLUME)" volume")
	@if [ `$(DOCKER) volume inspect $(ROOT_VOLUME) 2> /dev/null | head -1` = "[]" ]; then \
		$(DOCKER) volume create $(ROOT_VOLUME); \
	fi
	@$(DOCKER) run --name tmp_builder -v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) bravissimolabs/alpine-git echo > /dev/null 2>&1
	@$(DOCKER) cp . tmp_builder:$(ROOT_MOUNT_POINT) > /dev/null 2>&1
	@$(DOCKER) stop tmp_builder > /dev/null 2>&1
	@$(DOCKER) rm tmp_builder > /dev/null 2>&1


$(DEPS_VOLUME):
	$(call log_msg,"creating "$(DEPS_VOLUME)" volume")
	@if [ `$(DOCKER) volume inspect $(DEPS_VOLUME) 2> /dev/null | head -1` = "[]" ]; then \
		$(DOCKER) volume create $(DEPS_VOLUME); \
	fi

$(REL_VOLUME):
	$(call log_msg,"creating "$(REL_VOLUME)" volume")
	@if [ `$(DOCKER) volume inspect $(REL_VOLUME) 2> /dev/null | head -1` = "[]" ]; then \
		$(DOCKER) volume create $(REL_VOLUME); \
	fi

$(EBIN_VOLUME):
	$(call log_msg,"creating "$(EBIN_VOLUME)" volume")
	@if [ `$(DOCKER) volume inspect $(EBIN_VOLUME) 2> /dev/null | head -1` = "[]" ]; then \
		$(DOCKER) volume create $(EBIN_VOLUME); \
	fi


linux_release_build_machine: volumes
	$(call log_msg,"making linux build machine...")
	@if [ `$(DOCKER) images -q $(LRM) 2> /dev/null`"abc" = "abc" ]; then \
		echo "rebuilding release machine"; \
		echo "cloning edocker repo"; \
		$(DOCKER) run --rm -v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) bravissimolabs/alpine-git \
			git clone --verbose --progress -b using_volumes $(EDOCKER_REPO) $(ROOT_MOUNT_POINT)/.edocker; \
		echo "copying Dockerfile.builder"; \
		$(DOCKER) run --rm -v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) bravissimolabs/alpine-git \
			cat $(ROOT_MOUNT_POINT)/.edocker/builder/Dockerfile.builder > .Dockerfile.builder; \
		echo "building docker image"; \
		$(DOCKER) build --build-arg EXTRA_PACKAGES="${EXTRA_PACKAGES}" -t $(LRM) -f .Dockerfile.builder .; \
		rm -f .Dockerfile.builder; \
	fi


linux_release: linux_release_build_machine
	$(call log_msg,"making linux release...")

	$(eval RELEASE_NAME := $(shell $(DOCKER) run --rm \
		-v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) \
		erlang $(ROOT_MOUNT_POINT)/.edocker/bin/release_name))

	$(eval ERTS_VERSION := $(shell $(DOCKER) run --rm \
		-v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) \
		erlang $(ROOT_MOUNT_POINT)/.edocker/bin/system_version))

	$(foreach binary,$(BINARIES_TO_INCLUDE),\
		$(DOCKER) run --rm \
			-v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) \
			-v $(REL_VOLUME):$(REL_MOUNT_POINT) \
			$(LRM) bash -c "cp \`which ${binary}\` ${REL_MOUNT_POINT}/${RELEASE_NAME}/bin/";)

	@$(DOCKER) run  --rm \
			-v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) \
			-v $(REL_VOLUME):$(REL_MOUNT_POINT) \
			-v $(DEPS_VOLUME):$(DEPS_MOUNT_POINT) \
			-v $(EBIN_VOLUME):$(EBIN_MOUNT_POINT) \
			$(LRM) bash -c "cd ${ROOT_MOUNT_POINT} && make && .edocker/bin/mkimage ${BINARIES_TO_INCLUDE}"

	@$(DOCKER) run  --rm \
			-v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) \
			-v $(REL_VOLUME):$(REL_MOUNT_POINT) \
			-v $(DEPS_VOLUME):$(DEPS_MOUNT_POINT) \
			-v $(EBIN_VOLUME):$(EBIN_MOUNT_POINT) \
			$(LRM) bash -c "gcc -DERTS_VERSION=\\\"${ERTS_VERSION}\\\" -DREL_NAME=\\\"${RELEASE_NAME}\\\" -o ${REL_MOUNT_POINT}/${RELEASE_NAME}/erts-${ERTS_VERSION}/bin/edocker_erlexec ${ROOT_MOUNT_POINT}/.edocker/src/edocker_erlexec.c"

	$(call log_msg,"a linux release of the project is now in volume ${REL_VOLUME}")



docker_image: linux_release
	$(call log_msg,"making docker image...")

	$(eval SYSTEM_VERSION := $(shell $(DOCKER) run --rm -v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) erlang \
		$(ROOT_MOUNT_POINT)/.edocker/bin/system_version))

	$(eval REL_VSN := $(shell $(DOCKER) run --rm \
		-v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) \
		-v $(EBIN_VOLUME):$(EBIN_MOUNT_POINT) \
		erlang $(ROOT_MOUNT_POINT)/.edocker/bin/version))

	@$(DOCKER) run \
		--name $(NAMESPACE)_$(LRM) \
		-v $(ROOT_VOLUME):$(ROOT_MOUNT_POINT) \
		-v $(REL_VOLUME):$(REL_MOUNT_POINT) \
		-v $(DEPS_VOLUME):$(DEPS_MOUNT_POINT) \
		-v $(EBIN_VOLUME):$(EBIN_MOUNT_POINT) \
		$(LRM) bash -c \
		"mkdir -p $(REL_MOUNT_POINT)/$(RELEASE_NAME)/etc && echo \"{lookup, [file, dns]}.\" > $(REL_MOUNT_POINT)/$(RELEASE_NAME)/etc/erl_inetrc"

	@rm -rf .context
	@mkdir .context

	@$(DOCKER) cp $(NAMESPACE)_$(LRM):$(REL_MOUNT_POINT) .context/
	@$(DOCKER) cp $(NAMESPACE)_$(LRM):$(ROOT_MOUNT_POINT)/.edocker/builder/Dockerfile.release .context/
	@$(DOCKER) stop $(NAMESPACE)_$(LRM)
	@$(DOCKER) rm $(NAMESPACE)_$(LRM)

	@$(DOCKER) build \
		--build-arg REL_NAME=$(RELEASE_NAME) \
		--build-arg ERTS_VSN=$(SYSTEM_VERSION) \
		--pull=true \
		--no-cache=true \
		--force-rm=true \
	  	-f .context/Dockerfile.release \
		-t $(RELEASE_NAME):$(REL_VSN) .context

	$(call log_msg,"docker image "$(RELEASE_NAME):$(REL_VSN)" was created")


cleanup:
	$(foreach c, $(shell $(DOCKER) ps -a -q -f status=exited), \
		$(DOCKER) rm -f $(c);)

ifneq ($(strip $(MAKER_EXISTS)),)
	@$(DOCKER) rmi -f $(LRM) || true
endif
	@$(DOCKER) volume inspect $(ROOT_VOLUME) >/dev/null 2>&1 && $(DOCKER) volume remove $(ROOT_VOLUME) || true
	@$(DOCKER) volume inspect $(DEPS_VOLUME) >/dev/null 2>&1 && $(DOCKER) volume remove $(DEPS_VOLUME) || true
	@$(DOCKER) volume inspect $(REL_VOLUME) >/dev/null 2>&1 && $(DOCKER) volume remove $(REL_VOLUME) || true
	@$(DOCKER) volume inspect $(EBIN_VOLUME) >/dev/null 2>&1 && $(DOCKER) volume remove $(EBIN_VOLUME) || true

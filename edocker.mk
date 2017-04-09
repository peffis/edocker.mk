DOCKER ?= docker
LRM = erlang_linux_release_builder
MAKER_EXISTS = $(shell $(DOCKER) images -q $(LRM) 2> /dev/null)
EDOCKER_ROOT = .edocker.mk
BASE_URL = https://raw.githubusercontent.com/peffis/edocker.mk/master/
BUILD_SCRIPTS = $(EDOCKER_ROOT)/bin/app $(EDOCKER_ROOT)/bin/mkimage \
	$(EDOCKER_ROOT)/bin/release_name $(EDOCKER_ROOT)/bin/release_version \
	$(EDOCKER_ROOT)/bin/system_version $(EDOCKER_ROOT)/bin/version $(EDOCKER_ROOT)/src/edocker_erlexec.c
DOCKER_FILES = $(EDOCKER_ROOT)/builder/Dockerfile.builder \
	$(EDOCKER_ROOT)/builder/Dockerfile.release
BINARIES_TO_INCLUDE ?= 
EXTRA_PACKAGES ?= 


define log_msg
	@printf "\033[1;37m===> "$(1)"\033[0m\n"
endef

edocker_boot: 	| $(DOCKER_FILES) $(BUILD_SCRIPTS)

$(EDOCKER_ROOT):	
	@mkdir -p $(EDOCKER_ROOT)

$(EDOCKER_ROOT)/builder: | $(EDOCKER_ROOT)
	@mkdir -p $(EDOCKER_ROOT)/builder

$(EDOCKER_ROOT)/builder/%: | $(EDOCKER_ROOT)/builder
	@echo "GET "$(BASE_URL)$(@:$(EDOCKER_ROOT)/%=%)
	@curl -s -o $@ $(BASE_URL)$(@:$(EDOCKER_ROOT)/%=%)

build_scripts: $(BUILD_SCRIPTS)

docker_files: $(DOCKER_FILES)

$(EDOCKER_ROOT)/bin: | $(EDOCKER_ROOT)
	@mkdir -p $(EDOCKER_ROOT)/bin

$(EDOCKER_ROOT)/src: | $(EDOCKER_ROOT)
	@mkdir -p $(EDOCKER_ROOT)/src

$(EDOCKER_ROOT)/bin/%: | $(EDOCKER_ROOT)/bin
	@echo "GET "$(BASE_URL)$(@:$(EDOCKER_ROOT)/%=%)
	@curl -s -o $@ $(BASE_URL)$(@:$(EDOCKER_ROOT)/%=%)
	@chmod a+x $@

$(EDOCKER_ROOT)/src/%: | $(EDOCKER_ROOT)/src
	@echo "GET "$(BASE_URL)$(@:$(EDOCKER_ROOT)/%=%)
	@curl -s -o $@ $(BASE_URL)$(@:$(EDOCKER_ROOT)/%=%)

linux_release_build_machine: | edocker_boot
ifeq ($(strip $(MAKER_EXISTS)),)
	$(call log_msg,"making linux erlang release builder...")
	$(DOCKER) build --build-arg EXTRA_PACKAGES="${EXTRA_PACKAGES}" -t $(LRM)  \
		-f $(EDOCKER_ROOT)/builder/Dockerfile.builder $(EDOCKER_ROOT)/builder
	$(call log_msg,"done")
endif

linux_release: linux_release_build_machine 
	$(call log_msg,"making linux release...")
	@mkdir -p $(EDOCKER_ROOT)/linux_deps
	@mkdir -p $(EDOCKER_ROOT)/linux_ebin
	@mkdir -p $(EDOCKER_ROOT)/linux_rel
	$(eval RELEASE_NAME := $(shell $(EDOCKER_ROOT)/bin/release_name))
	$(eval ERTS_VERSION := $(shell $(DOCKER) run -v `pwd`:/$(RELEASE_NAME) erlang /$(RELEASE_NAME)/$(EDOCKER_ROOT)/bin/system_version))

	$(foreach binary,$(BINARIES_TO_INCLUDE), @$(DOCKER) run -v `pwd`:/$(RELEASE_NAME) \
		-v `pwd`/$(EDOCKER_ROOT)/linux_deps:/$(RELEASE_NAME)/deps \
		-v `pwd`/$(EDOCKER_ROOT)/linux_ebin:/$(RELEASE_NAME)/ebin \
		-v `pwd`/$(EDOCKER_ROOT)/linux_rel:/$(RELEASE_NAME)/_rel \
		-it $(LRM) bash -c "cp \`which ${binary}\` /${RELEASE_NAME}/_rel/${RELEASE_NAME}/bin/";)

	@$(DOCKER) run -v `pwd`:/$(RELEASE_NAME) \
		-v `pwd`/$(EDOCKER_ROOT)/linux_deps:/$(RELEASE_NAME)/deps \
		-v `pwd`/$(EDOCKER_ROOT)/linux_ebin:/$(RELEASE_NAME)/ebin \
		-v `pwd`/$(EDOCKER_ROOT)/linux_rel:/$(RELEASE_NAME)/_rel \
		-it $(LRM) bash -c \
		"cd /${RELEASE_NAME} && make && ${EDOCKER_ROOT}/bin/mkimage ${BINARIES_TO_INCLUDE}"

	@$(DOCKER) run -v `pwd`:/$(RELEASE_NAME) \
		-v `pwd`/$(EDOCKER_ROOT)/linux_deps:/$(RELEASE_NAME)/deps \
		-v `pwd`/$(EDOCKER_ROOT)/linux_ebin:/$(RELEASE_NAME)/ebin \
		-v `pwd`/$(EDOCKER_ROOT)/linux_rel:/$(RELEASE_NAME)/_rel \
		-it $(LRM) bash -c \
		"cd /${RELEASE_NAME} && gcc -DERTS_VERSION=\\\"${ERTS_VERSION}\\\" -DREL_NAME=\\\"${RELEASE_NAME}\\\" -o _rel/${RELEASE_NAME}/erts-${ERTS_VERSION}/bin/edocker_erlexec /${RELEASE_NAME}/${EDOCKER_ROOT}/src/edocker_erlexec.c"

	$(call log_msg,"a linux release of the project is now in ${EDOCKER_ROOT}/linux_rel")

docker_image: linux_release
	$(call log_msg,"making docker image...")
	$(eval SYSTEM_VERSION := $(shell $(DOCKER) run -v `pwd`:/$(RELEASE_NAME) erlang /$(RELEASE_NAME)/$(EDOCKER_ROOT)/bin/system_version))
	$(eval REL_VSN := $(shell $(DOCKER) run -v `pwd`:/$(RELEASE_NAME) \
		-v `pwd`/$(EDOCKER_ROOT)/linux_deps:/$(RELEASE_NAME)/deps \
		-v `pwd`/$(EDOCKER_ROOT)/linux_ebin:/$(RELEASE_NAME)/ebin \
		-v `pwd`/$(EDOCKER_ROOT)/linux_rel:/$(RELEASE_NAME)/_rel \
		-it $(LRM) bash -c \
		"cd /${RELEASE_NAME} && ${EDOCKER_ROOT}/bin/version")) 
	@$(DOCKER) build \
		--build-arg REL_NAME=$(RELEASE_NAME) \
		--build-arg ERTS_VSN=$(SYSTEM_VERSION) \
		--pull=true \
		--no-cache=true \
		--force-rm=true \
	  	-f $(EDOCKER_ROOT)/builder/Dockerfile.release \
		-t $(RELEASE_NAME):$(REL_VSN) .
	$(call log_msg,"docker image "$(RELEASE_NAME):$(REL_VSN)" was created")

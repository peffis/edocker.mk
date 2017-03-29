DOCKER ?= docker
LRM = erlang_linux_release_builder
MAKER_EXISTS = $(shell $(DOCKER) images -q $(LRM) 2> /dev/null)
EDOCKER_ROOT = .edocker.mk
BASE_URL = https://raw.githubusercontent.com/peffis/edocker.mk/master/
BUILD_SCRIPTS = $(EDOCKER_ROOT)/bin/app $(EDOCKER_ROOT)/bin/mkimage \
	$(EDOCKER_ROOT)/bin/release_name $(EDOCKER_ROOT)/bin/release_version \
	$(EDOCKER_ROOT)/bin/system_version $(EDOCKER_ROOT)/bin/version 
DOCKER_FILES = $(EDOCKER_ROOT)/builder/Dockerfile.builder \
	$(EDOCKER_ROOT)/builder/Dockerfile.release


root:	
	@mkdir -p $(EDOCKER_ROOT)

builder: root
	@mkdir -p $(EDOCKER_ROOT)/builder

$(EDOCKER_ROOT)/builder/%: builder
	@curl -s -o $@ $(BASE_URL)/$(@:$(EDOCKER_ROOT)/%=%)

build_scripts: $(BUILD_SCRIPTS)

docker_files: $(DOCKER_FILES)

bin: root
	@mkdir -p $(EDOCKER_ROOT)/bin

$(EDOCKER_ROOT)/bin/%: bin
	@curl -s -o $@ $(BASE_URL)$(@:$(EDOCKER_ROOT)/%=%)
	@chmod a+x $@

linux_release_build_machine: $(DOCKER_FILES)
ifeq ($(strip $(MAKER_EXISTS)),)
	@echo "making linux erlang release builder..."
	@$(DOCKER) build -t $(LRM) -f $(EDOCKER_ROOT)/builder/Dockerfile.builder $(EDOCKER_ROOT)/builder
	@echo "done."
else
	@echo "linux erlang release builder already exists"
endif

linux_release: linux_release_build_machine build_scripts
	@echo "making linux release..."
	@mkdir -p $(EDOCKER_ROOT)/linux_deps
	@mkdir -p $(EDOCKER_ROOT)/linux_ebin
	@mkdir -p $(EDOCKER_ROOT)/linux_rel
	$(eval RELEASE_NAME := $(shell $(EDOCKER_ROOT)/bin/release_name))
	$(eval SYSTEM_VERSION := $(shell $(DOCKER) run -v `pwd`:/$(RELEASE_NAME) erlang /$(RELEASE_NAME)/$(EDOCKER_ROOT)/bin/system_version))

	@$(DOCKER) run -v `pwd`:/$(RELEASE_NAME) \
		-v `pwd`/$(EDOCKER_ROOT)/linux_deps:/$(RELEASE_NAME)/deps \
		-v `pwd`/$(EDOCKER_ROOT)/linux_ebin:/$(RELEASE_NAME)/ebin \
		-v `pwd`/$(EDOCKER_ROOT)/linux_rel:/$(RELEASE_NAME)/_rel \
		-it $(LRM) bash -c \
		"cd /${RELEASE_NAME} && make && ${EDOCKER_ROOT}/bin/mkimage"
	@echo "a linux release of the project is now in ${EDOCKER_ROOT}/linux_rel"

docker_image: linux_release $(DOCKER_FILES)
	@echo "making docker image..."
	$(eval version := $(shell $(DOCKER) run -v `pwd`:/$(RELEASE_NAME) \
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
		-t $(RELEASE_NAME):$(version) .
	@echo "a docker image" $(RELEASE_NAME):$(version) "was created"

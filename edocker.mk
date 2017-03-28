DOCKER ?= docker
LRM = erlang_linux_release_builder
MAKER_EXISTS = $(shell $(DOCKER) images -q $(LRM) 2> /dev/null)
RELEASE_NAME = $(shell bin/release_name)
SYSTEM_VERSION = $(shell $(DOCKER) run -v `pwd`:/$(RELEASE_NAME) erlang /$(RELEASE_NAME)/bin/system_version)

linux_release_build_machine:
ifeq ($(strip $(MAKER_EXISTS)),)
	@echo "making linux erlang release builder..."
	@$(DOCKER) build -t $(LRM) -f builder/Dockerfile.builder builder
	@echo "done."
else
	@echo "linux erlang release builder already exists"
endif

linux_release: linux_release_build_machine
	@mkdir -p .linux_deps
	@mkdir -p .linux_ebin
	@mkdir -p .linux_rel
	@$(DOCKER) run -v `pwd`:/$(RELEASE_NAME) \
		-v `pwd`/.linux_deps:/$(RELEASE_NAME)/deps \
		-v `pwd`/.linux_ebin:/$(RELEASE_NAME)/ebin \
		-v `pwd`/.linux_rel:/$(RELEASE_NAME)/_rel \
		-it $(LRM) bash -c \
		"cd /${RELEASE_NAME} && make && ./bin/mkimage"
	@echo "release is now in .linux_rel"

docker_image: linux_release
	$(eval version := $(shell $(DOCKER) run -v `pwd`:/$(RELEASE_NAME) \
		-v `pwd`/.linux_deps:/$(RELEASE_NAME)/deps \
		-v `pwd`/.linux_ebin:/$(RELEASE_NAME)/ebin \
		-v `pwd`/.linux_rel:/$(RELEASE_NAME)/_rel \
		-it $(LRM) bash -c \
		"cd /${RELEASE_NAME} && ./bin/version")) 
	@$(DOCKER) build \
		--build-arg REL_NAME=$(RELEASE_NAME) \
		--build-arg ERTS_VSN=$(SYSTEM_VERSION) \
		--pull=true \
		--no-cache=true \
		--force-rm=true \
	  	-f builder/Dockerfile.release \
		-t $(RELEASE_NAME):$(version) .	

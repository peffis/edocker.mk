lrm = erlang_linux_release_builder
maker_exists = $(shell docker images -q $(lrm) 2> /dev/null)
release_name = $(shell bin/release_name)
system_version = $(shell docker run -v `pwd`:/$(release_name) erlang /$(release_name)/bin/system_version)

linux_release_build_machine:
ifeq ($(strip $(maker_exists)),)
	@echo "making linux erlang release builder..."
	@docker build -t $(lrm) -f builder/Dockerfile.builder builder
	@echo "done."
else
	@echo "linux erlang release builder already exists"
endif

linux_release: linux_release_build_machine
	@mkdir -p .linux_deps
	@mkdir -p .linux_ebin
	@mkdir -p .linux_rel
	@docker run -v `pwd`:/$(release_name) \
		-v `pwd`/.linux_deps:/$(release_name)/deps \
		-v `pwd`/.linux_ebin:/$(release_name)/ebin \
		-v `pwd`/.linux_rel:/$(release_name)/_rel \
		-it $(lrm) bash -c \
		"cd /${release_name} && make && ./bin/mkimage"
	@echo "release is now in .linux_rel"

docker_image: linux_release
	$(eval version := $(shell docker run -v `pwd`:/$(release_name) \
		-v `pwd`/.linux_deps:/$(release_name)/deps \
		-v `pwd`/.linux_ebin:/$(release_name)/ebin \
		-v `pwd`/.linux_rel:/$(release_name)/_rel \
		-it $(lrm) bash -c \
		"cd /${release_name} && ./bin/version")) 
	@docker build \
		--build-arg REL_NAME=$(release_name) \
		--build-arg ERTS_VSN=$(system_version) \
		--pull=true \
		--no-cache=true \
		--force-rm=true \
	  	-f builder/Dockerfile.release \
		-t $(release_name):$(version) .	

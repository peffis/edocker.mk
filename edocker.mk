PROJECT_NAME = $(shell basename `pwd`)
TAG ?= 1.0

# The docker binary you have in your system, if you require "sudo docker"
# then do "DOCKER=sudo docker"
DOCKER ?= docker

# The erlang version you want to build your release in. The number should match
# an existing public tag for the erlang docker image
ERLANG_VERSION ?= 26

# A list of binaries that will be copied from the erlang docker image to the /bin folder
# of the release image. So if you require "ffmpeg" and "bash" binary for instance, you should
# list that here as BINARIES_TO_INCLUDE = ffmpeg bash
BINARIES_TO_INCLUDE ?=

# If you want to add some apt repositories (PPAs) to install before building (and perhaps
# add binaries from to the BINARIES_TO_INCLUDE above) you should list them here and then
# add the specific package you want installed to the EXTRA_PACKAGES below
EXTRA_PPAS ?=

# If you want to add a line to the /etc/apt/soruces.list before building
# you can add that line here and add the specific package you want installed to the
# EXTRA_PACKAGES below
SOURCES_LIST_APPEND ?=

# If you want to install some extra package to perhaps add a binary from that package
# to BINARIES_TO_INCLUDE, you can add that package name to the EXTRA_PACKAGES list
EXTRA_PACKAGES ?=

# rule to extract the build scripts and the source code for the resulting edocker_erlexec.c
# this is extracting a tar file that is generated from tarring up the .ed folder in the git
# repository
ed_helper_files:
	@ echo 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 | base64 -d | tar xzf -


define make_builder
$(DOCKER) build -t "builder_${PROJECT_NAME}:${TAG}" . -f - <<EOF
FROM erlang:$(ERLANG_VERSION)
WORKDIR /$(PROJECT_NAME)
RUN apt-get update && apt-get -y --force-yes install software-properties-common
RUN for r in ${EXTRA_PPAS}; do add-apt-repository -y $r; done
RUN if [ ! -z "${SOURCES_LIST_APPEND}" ]; then printf "${SOURCES_LIST_APPEND}" >> /etc/apt/sources.list; fi
RUN apt-get update && apt-get -y --force-yes install ${EXTRA_PACKAGES} erlang-dev

COPY . .
RUN make RELX_TAR=0
RUN make extract
RUN .ed/bin/mkimage ${BINARIES_TO_INCLUDE}
EOF
endef
export make_builder

define make_release_image
${DOCKER} build -t ${REL_NAME}:${TAG} . -f - <<EOF
FROM scratch
MAINTAINER Stefan Hellkvist <hellkvist@gmail.com>
ENV BOOT /releases/${REL_VSN}/start
ENV BINDIR /erts-${ERTS_VSN}/bin
ENV CONFIG /releases/${REL_VSN}/sys.config
ENV ARGS_FILE /releases/${REL_VSN}/vm.args
ENV EDOCKER_COOKIE edocker_default_cookie
ENV EDOCKER_NAME edocker_default_name
ENV EDOCKER_HOST 127.0.0.1
ENV ERL_INETRC /etc/erl_inetrc
ENV TZ=GMT
ENTRYPOINT exec ${BINDIR}/edocker_erlexec
COPY --from="builder_${PROJECT_NAME}:${TAG}" /${PROJECT_NAME}/_rel/${REL_NAME}/ /
EOF
endef
export make_release_image

extract: ed_helper_files

ebuilder:
	@ eval "$$make_builder"

erelease_image: ebuilder
	$(eval REL_NAME := $(shell ${DOCKER} run --rm "builder_${PROJECT_NAME}:${TAG}" .ed/bin/release_name))
	$(eval REL_VSN := $(shell ${DOCKER} run --rm "builder_${PROJECT_NAME}:${TAG}" .ed/bin/release_version))
	$(eval ERTS_VSN := $(shell ${DOCKER} run --rm "builder_${PROJECT_NAME}:${TAG}" .ed/bin/system_version))
	$(eval BINDIR := /erts-${ERTS_VSN}/bin)
	@ eval "$$make_release_image"

docker: erelease_image

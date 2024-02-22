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

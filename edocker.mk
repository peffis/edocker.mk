# APP_NAME is the name of the app. Unfortunately erlang.mk currently requires the top folder
# name to be the same as the APP_NAME. Therefore you can either specify the app name as an
# argument to the make command or the script will try to figure it out by looking into any
# ebin/*.app or src/*.app.src it might find
APP_NAME ?= $(shell cat ebin/*.app src/*.app.src 2>/dev/null | sed -n 's/\s*{\s*application\s*,[ \t\n]*\([^ ^\t^\n][^,]*\),.*\s*/\1/p' | head -1)
APP_NAME ?= $(shell basename `pwd`)

# This is the version tag of the resulting docker image
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
$(DOCKER) build -t "builder_${APP_NAME}:${TAG}" . -f - <<EOF
FROM erlang:$(ERLANG_VERSION)
WORKDIR /$(APP_NAME)
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
COPY --from="builder_${APP_NAME}:${TAG}" /${APP_NAME}/_rel/${REL_NAME}/ /
EOF
endef
export make_release_image

extract: ed_helper_files

ebuilder:
	@ eval "$$make_builder"

erelease_image: ebuilder
	$(eval REL_NAME := $(shell ${DOCKER} run --rm "builder_${APP_NAME}:${TAG}" .ed/bin/release_name))
	$(eval REL_VSN := $(shell ${DOCKER} run --rm "builder_${APP_NAME}:${TAG}" .ed/bin/release_version))
	$(eval ERTS_VSN := $(shell ${DOCKER} run --rm "builder_${APP_NAME}:${TAG}" .ed/bin/system_version))
	$(eval BINDIR := /erts-${ERTS_VSN}/bin)
	@ eval "$$make_release_image"

docker_image: erelease_image

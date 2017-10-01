FROM erlang:19

ARG EXTRA_PPAS=
ARG EXTRA_PACKAGES=
ARG SOURCES_LIST_APPEND=
WORKDIR /workdir

RUN apt-get update && apt-get -y install software-properties-common
RUN for r in $EXTRA_PPAS; do add-apt-repository -y $r; done
RUN printf "${SOURCES_LIST_APPEND}" >> /etc/apt/sources.list
RUN apt-get update && apt-get -y install $EXTRA_PACKAGES erlang-dev
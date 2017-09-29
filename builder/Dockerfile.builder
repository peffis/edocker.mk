FROM erlang:19

ARG EXTRA_REPOSITORIES=
ARG EXTRA_PACKAGES=
WORKDIR /workdir

RUN apt-get update && apt-get -y install software-properties-common
RUN for r in $EXTRA_REPOSITORIES; do add-apt-repository -y $r; done
RUN apt-get update && apt-get -y install $EXTRA_PACKAGES erlang-dev
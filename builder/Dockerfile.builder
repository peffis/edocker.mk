FROM erlang:19

ARG EXTRA_PACKAGES=
WORKDIR /workdir

RUN apt-get update && apt-get -y install $EXTRA_PACKAGES erlang-dev
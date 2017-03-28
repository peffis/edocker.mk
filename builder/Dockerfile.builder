FROM erlang

WORKDIR /workdir

RUN apt-get update && apt-get -y install libpam-dev erlang-dev
# edocker.mk
An erlang linux release/docker image builder 

# inspiration
The origin of the build scripts in the bin folder and the inspiration comes from Peter Morgan's [Erlang in Docker From Scratch repo](https://github.com/shortishly/erlang-in-docker-from-scratch). The work in this
repo is to integrate that way of building of erlang docker images nicely with
erlang.mk in a reusable manner.

# documentation

## requirements
It is assumed you have docker installed on your machine (such as Docker for Mac
or docker-machine). 

## bootstrapping
Assume you have an [erlang.mk](https://erlang.mk) project with a Makefile
```
PROJECT = my_project
PROJECT_DESCRIPTION = Some project
PROJECT_VERSION = 0.1.0

include erlang.mk
```

1. Download edocker.mk
```
$ curl -O https://raw.githubusercontent.com/peffis/edocker.mk/master/edocker.mk
```

2. Add edocker.mk to your Makefile
```
PROJECT = my_project
PROJECT_DESCRIPTION = Some project
PROJECT_VERSION = 0.1.0

include erlang.mk
include edocker.mk
```

## using
### building a linux erlang release of your project (such as if you are on a Mac)
```
$ make linux_release
```

### building a docker image of your linux release
```
$ make docker_image
```


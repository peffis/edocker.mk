# edocker.mk
An erlang linux release/docker image builder 

## Inspiration
The origin of the build scripts in the bin folder and the inspiration comes from 
Peter Morgan's [Erlang in Docker From Scratch](https://github.com/shortishly/erlang-in-docker-from-scratch) 
repository. The purpose of the work in this repository is to integrate Peter's way of building erlang docker 
images with erlang.mk in a reusable manner. 

You can use this project to build erlang releases even if you do not have
erlang installed on your machine and make a minimal erlang docker image
of your release. It uses a docker container as build machine so you can
build a *linux release* and *docker image* even if you are on a Mac or
if you do not have the erlang runtime installed on your Linux machine. 

## Requirements
It is assumed you have docker installed on your machine (such as Docker for Mac
or docker-machine). If you run docker with sudo you should set the environment 
variable DOCKER to *sudo docker*.

## Bootstrapping
Assume you have an [erlang.mk](https://erlang.mk) project with a *Makefile*
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

## Building a linux erlang release of your project
```
$ make linux_release
```

## Building a docker image of your linux release
```
$ make docker_image
```

# edocker.mk
An erlang linux release/docker image builder 

## Inspiration
The build scripts in the *bin* folder are derived from Peter Morgan's [Erlang in Docker From Scratch](https://github.com/shortishly/erlang-in-docker-from-scratch). The purpose of the work in this repository 
is to integrate Peter's way of building erlang docker images with erlang.mk in a reusable manner, making it 
more of a stand-alone build tool and, also, making it possible to build erlang releases and docker images
also from a machine that does not have a Linux Erlang runtime.

You can use this project to build *Linux Erlang releases* and make small *Erlang Docker images*
of your Erlang project. Like in Peter's repo, the docker image is based on *scratch* and contains only the 
bare Erlang release, no Ubuntu, Alpine or Debian OS. *edocker.mk* uses a Docker container as *build machine* so you can
build a *Linux release* and a *Docker image* even if you are on a Mac or
if you do not have the Erlang runtime installed on your Linux machine. You will need *Docker* though, 
obviously. 

## Requirements
It is assumed you have *Docker* installed on your machine (such as *Docker for Mac*
or *docker-machine*). If you run Docker with *sudo* you should set the environment 
variable *DOCKER* to *sudo docker* (for instance *make DOCKER="sudo docker"*, or add 
export DOCKER="sudo docker" to your .bashrc/.bash_profile)

## Bootstrapping
Let us assume you have an [erlang.mk](https://erlang.mk) project with a *Makefile*, something like...
```
PROJECT = my_project
PROJECT_DESCRIPTION = Some project
PROJECT_VERSION = 0.1.0

include erlang.mk
```
Then...
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

## Build a linux erlang release of your project
```
$ make linux_release
```

## Build a docker image of your linux release
```
$ make docker_image
```

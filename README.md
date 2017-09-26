# edocker.mk
An erlang linux release/docker image builder

## Inspiration
The build scripts in the *bin* folder are derived from Peter Morgan's [Erlang in Docker From Scratch](https://github.com/shortishly/erlang-in-docker-from-scratch). The purpose of the work in this repository
is to integrate Peter's way of building erlang docker images with erlang.mk in a reusable manner, making it
more of a stand-alone build tool and, also, making it possible to build erlang releases and docker images
also from a machine that does not have a Linux Erlang runtime (I have
mostly used this on my Macbook but other cases could be a build/ci
server that knows docker but does not know erlang).

You can use this project to build *Linux Erlang releases* and make small *Erlang Docker images*
of your Erlang project. Like in Peter's repo, the docker image is based on the *scratch image* and contains only the
bare Erlang release, no Ubuntu, Alpine or Debian OS.

*edocker.mk* make use of a Docker container as *build machine* so you can
build a *Linux release* and a *Docker image* of your project even if you are on a Mac or
if you do not have the Erlang runtime installed on your machine. You will need *Docker* though,
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
The linux release, if the build is successful, will be placed inside a docker
volume named &lt;proj&gt;_rel, where &lt;proj&gt; is the folder name of your
project. If you want to extract it you could for instance copy it to
a folder, say _release_, on your host machine, by doing:
```
$ docker run --name busybox -v <proj>_rel:/release busybox
$ docker cp busybox:/release .
$ docker rm busybox
```


## Build a docker image of your linux release
```
$ make docker_image
```

## Adding extra packages to the build machine
Suppose you know that your erlang build will require some extra deb-package. In order to add this extra package to the build machine you include it with the EXTRA_PACKAGES variable. Example:
```
$ EXTRA_PACKAGES=libpam0g-dev make docker_image
```

## cleaning up
If you are done working on your project and want to get rid of the
docker volumes the build system has created you can invoke
```
$ make cleanup
```

## edocker_erlexec
This repository also includes an alternative binary for bootstrapping
the erlang vm - edocker_erlexec. It does the same as erlexec but it
adds the possibility to override values such as the cookie, the node
name and the host with environment variables which is conveniant in a
docker/kubernetes playground. As can be seen in the [docker file for
the
release](https://github.com/peffis/edocker.mk/blob/master/builder/Dockerfile.release)
you can override the following environment variables.
```
ENV EDOCKER_COOKIE edocker_default_cookie
ENV EDOCKER_NAME edocker_default_name
ENV EDOCKER_HOST 127.0.0.1
```

This means that you can for instance do
```bash
docker run -e EDOCKER_COOKIE=some_cookie -e EDOCKER_NAME=clarence yourrelease
```
if you want to start _yourrelease_ with the cookie _some_cookie_ and with the node name of _clarence_.

Or if you want to do the equivalent inside a kubernetes deployment.yaml where you might want to pass the pod IP as the EDOCKER_HOST:
```yaml
...snip...
        env:
        - name: EDOCKER_NAME
          value: edocker
        - name: EDOCKER_HOST
          valueFrom:
             fieldRef:
                 fieldPath: status.podIP
        - name: EDOCKER_COOKIE
          value: thecookiethatweallgonnause
...snip...
```

# edocker.mk
An erlang linux release/docker image builder

## Overview
Some people have a need to shrink the sizes of their Docker images. If
you, instead of packaging an Erlang release into some Ubuntu or Alpine
image, add the release to the scratch image, you reduce the
size from several hundred MB (or even above GB depending on what image
you start with) down to perhaps 20-50MB (depending on the size of your
erlang release). The tools in this repository help you to create a
docker image that only contains the erlang release and some optional
binaries of your choice.

When running erlang releases inside docker you might also want a more
flexible way of controlling erlang arguments such as cookie and node
names through environment variables rather than through scripts and
command line arguments as is normally used in erlang. For this purpose
this repository also contains a wrapper program around erlexec that
reads environment variables and translates them to command line
arguments.


## Inspiration
The build scripts in the *bin* folder are derived from Peter Morgan's
[Erlang in Docker From
Scratch](https://github.com/shortishly/erlang-in-docker-from-scratch). The
purpose of the work in this repository is to integrate Peter's way of
building erlang docker images with erlang.mk in a reusable manner,
making it more of a stand-alone build tool and, also, making it
possible to build erlang releases and docker images also from a
machine that does not have a Linux Erlang runtime (I have mostly used
this on my Macbook but other cases could be a build/ci server that
knows docker but does not know erlang).

You can use this project to build *Linux Erlang releases* and make
small *Erlang Docker images* of your Erlang project. Like in Peter's
repo, the docker image is based on the *scratch image* and contains
only the bare Erlang release, no Ubuntu, Alpine or Debian OS.

*edocker.mk* make use of a Docker container as *build machine* so you
can build a *Linux release* and a *Docker image* of your project even
if you are on a Mac or if you do not have the Erlang runtime installed
on your machine. You will need *Docker* though, obviously.

## Requirements
It is assumed you have *Docker* installed on your machine (such as
*Docker for Mac* or *docker-machine*). If you run Docker with *sudo*
you should set the environment variable *DOCKER* to *sudo docker* (for
instance *make DOCKER="sudo docker"*, or add export DOCKER="sudo
docker" to your .bashrc/.bash_profile)

## Bootstrapping
Let us assume you have an [erlang.mk](https://erlang.mk) project with
a *Makefile* (this could possibly work also with rebar with some minor
modifications to the line that currently reads "RUN make RELX_TAR=0"
which is the line that builds the release with erlang.mk), something like...
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
PROJECT = hello_joe
PROJECT_DESCRIPTION = Hello Joe
PROJECT_VERSION = 0.1.0
BUILD_DEPS += relx

include erlang.mk
include edocker.mk
```

## Build a docker container
```
$ make docker
```
The resulting docker image, if the build is successful, will be named
&lt;proj&gt;, where &lt;proj&gt; is how you named your release in your
relx.config.

## Configuring the erlang linux build machine
At the time of writing the [erlang docker
image](https://hub.docker.com/_/erlang/) is based on Debian. If
your build process has dependencies to additional ppa:s, additional
lines in /etc/apt/sources.list or if you just need to apt-get a few
more extra packages to be able to build your erlang release this is
all configurable.

### Adding additional PPA:s
Add PPA:s by setting the environment variable EXTRA_PPAS in your
makefile

Example:
```Makefile
EXTRA_PPAS = ppa:some/ppa
```

### Additions to /etc/apt/sources.list
You can also add repositories to /etc/apt/sources.list by specifying
what to append to the file with the variable SOURCES_LIST_APPEND

Example:
```Makefile
SOURCES_LIST_APPEND = deb http://ftp.uk.debian.org/debian jessie-backports main\ndeb http://www.deb-multimedia.org jessie main non-free
```

### Installing additional software on the build machine
Suppose you know that your erlang build will require some extra
deb-package. In order to add this extra package (assuming that you
have added additional ppa:s or lines to sources.list above if that is
needed) to the build machine you include it with the EXTRA_PACKAGES
variable in your Makefile.

Example:
```Makefile
EXTRA_PACKAGES = deb-multimedia-keyring libpam0g-dev ffmpeg x264
```

## Adding binaries to the runtime
If your erlang release will call other binaries (such as
os:cmd("ffmpeg")) you want to copy those binaries from the build
machine to the final docker image. You do that by setting the
BINARIES_TO_INCLUDE environment variable in the Makefile and they will
then be copied to the _release_/bin folder (any shared object that the
binary is depending on will be copied to the lib folder so that the
binary can be loaded when later run). There could be binaries that
have other dependencies (such as data stored in various folders -
_emacs_ is one such application that will complain if it cannot find
certain data folders in the file system) and those will be broken with
this solution unless some future release allow you to also specify
certain folders that should also be copied from the build machine when
building the release image - the script will currently only deduce the
linker dependencies, nothing else.

Example
```Makefile
BINARIES_TO_INCLUDE = ffmpeg ls bash
```

## edocker_erlexec
This repository also includes an alternative binary for bootstrapping
the erlang vm - edocker_erlexec. It does the same as erlexec (and will
in fact eventually do an exec on erlexec) but it adds the possibility to
override values such as the cookie, the node name and the host with
environment variables which is conveniant in a docker/kubernetes
playground. You can override the following environment variables:
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

## Rebuilding the edocker.mk file
If you make changes to any of the scripts in the .ed folder you should
rebuild the edocker.mk that you use so that your changes gets included
in the embedded tar file in edocker.mk. Do this by invoking make in
the cloned copy of this repo:
```
make
```
# build and tag me:
# docker build -t debuglevel/mono:latest . && docker tag debuglevel/mono:latest debuglevel/mono:$(date +%Y-%m-%d)

# the image we want to base our image on
# we use debian, as this works pretty well and does not consume too much space.
# ubuntu was also tested and is working - but we should not move to ubuntu unless there is a good reason.
FROM debian:latest

MAINTAINER Marc Kohaupt <debuglevel@gmail.com>

# set up the environment needed to execute mono executables
ENV MONO_PREFIX=/local/mono
ENV DYLD_FALLBACK_LIBRARY_PATH=$MONO_PREFIX/lib:$DYLD_LIBRARY_FALLBACK_PATH
ENV LD_LIBRARY_PATH=$MONO_PREFIX/lib:$LD_LIBRARY_PATH
ENV C_INCLUDE_PATH=$MONO_PREFIX/include
ENV ACLOCAL_PATH=$MONO_PREFIX/share/aclocal
ENV PKG_CONFIG_PATH=$MONO_PREFIX/lib/pkgconfig
ENV PATH=$MONO_PREFIX/bin:$PATH

# setting LC_ALL should avaoid problems in System.Text.EncodingHelper.GetDefaultEncoding ()
ENV LC_ALL="C"

# override the git:// based connection and use https://. some firewalls deny access otherwise.
COPY additional-gitconfig /tmp/

# shell script wrapper for nuget as binfmt does not work in docker (you cannot execute "./something.exe" but must use "mono something.exe")
COPY nuget /local/mono/bin/nuget

# RUN executes a command in the container.
# for each RUN, docker creates a new layered image on top of the image created by the previous RUN.
# we use one big RUN so that we can delete our temporary files at the end. this way the image remains as small as possible.

RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
	# install packages needed to compile mono
		autoconf \
		automake \
		build-essential \
		git \
		gettext \
		libtool \
	# install packages needed to run mono and other tools
		ca-certificates \
		wget \
		
	&& rm -rf /var/lib/apt/lists/* \
	
	# fetch latest mono sources (only the debuglevel_patches branch without any history)
	&& mkdir -p /local/mono-compile \
	&& cd /local/mono-compile \
	&& git clone -v --progress --depth 1 --branch debuglevel_patches --single-branch https://github.com/debuglevel/mono.git \
	&& cd /local/mono-compile/mono \
    
	&& cat /tmp/additional-gitconfig >> ~/.gitconfig \
	&& rm /tmp/additional-gitconfig \
	
	# initialize and fetch the submodules
	&& git submodule update --init --recursive \
	
	# do autogen
	&& ./autogen.sh --prefix=$MONO_PREFIX \

	# fetch the basic mono standalone executable (mono is needed to compile mono)
	&& make get-monolite-latest \
	
	# make (using monolite)
&& locale \ && locale -a && locale -m \
	&& make EXTERNAL_MCS="${PWD}/mcs/class/lib/monolite/basic.exe" \
	
	# install to $MONO_PREFIX
	&& make install \
	
	# remove source files
	&& rm -rf /local/mono-compile/mono \
	
	# install nuget
	&& cd /local/mono/bin \
	&& wget http://nuget.org/nuget.exe \
	&& chmod +x nuget.exe \
	&& chmod +x nuget \
	
	# import SSL certs (needed by NuGet)
	&& mozroots --import --machine --sync \
	&& yes | certmgr -ssl -m https://go.microsoft.com \
	&& yes | certmgr -ssl -m https://nugetgallery.blob.core.windows.net \
	&& yes | certmgr -ssl -m https://nuget.org \

	# remove packages which were used to compile mono but are not needed anymore
	&& apt-get remove -y \
		autoconf \
		automake \
		build-essential \
		git \
		gettext \
		libtool \
	&& apt-get autoremove -y \
	&& apt-get clean

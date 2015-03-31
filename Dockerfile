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
	
	# fetch latest mono sources
	&& mkdir -p /local/mono-compile \
	&& cd /local/mono-compile \

	&& git clone -v --progress https://github.com/mono/mono.git \
	&& cd /local/mono-compile/mono \
	
	#113 (works)
	#&& git reset --hard dfebf124e54e11ef4de85addffd8d9df102e859b \
    
	#114 (fails)
	&& git reset --hard 519ddb9895af5639de5ba0361af54a8d585c4070  \
    
	# initialize and fetch the submodules
	&& git submodule update --init --recursive \
	
	# do autogen
	&& ./autogen.sh --prefix=$MONO_PREFIX \

	# fetch the basic mono standalone executable (mono is needed to compile mono)
	&& make get-monolite-latest \
	&& cd /local/mono-compile/mono \
	
	# make (using monolite)
	&& make EXTERNAL_MCS="${PWD}/mcs/class/lib/monolite/basic.exe" \
	
	# install to $MONO_PREFIX
	&& make install

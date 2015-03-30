FROM debian:wheezy

# The versions (github branches) that should be pulled and compiled
ENV MONO_VERSION=mono-3.12.0.76

# The dependencies needed for the compilation process, they will be deleted once the docker image is baked
ENV SETUP_TOOLS="git autoconf libtool automake build-essential mono-devel gettext python"
WORKDIR /deploy

RUN apt-get update \
    && apt-get install -y curl unzip s3cmd $SETUP_TOOLS \
    && cd /deploy \
    && git clone git://github.com/mono/mono   \
    && cd /deploy/mono \
    && bash ./autogen.sh  \
    && make get-monolite-latest \
    && make \
    && make install \
    && apt-get remove -y --purge $SETUP_TOOLS \
    && apt-get autoremove -y \
    && rm -rf /deploy \
    && mkdir /app

WORKDIR /app
FROM debian:stable-20201117-slim AS common

ENV DEBIAN_FRONTEND=noninteractive

ARG REPOSITORY_URL=https://github.com/innovaker/zmk-docker
LABEL org.opencontainers.image.source ${REPOSITORY_URL}

ARG ZEPHYR_VERSION
ENV ZEPHYR_VERSION=${ZEPHYR_VERSION}
RUN \
  apt-get -y update \
  && apt-get -y install --no-install-recommends \
  ccache \
  device-tree-compiler \
  file \
  gcc \
  gcc-multilib \
  git \
  gperf \
  make \
  ninja-build \
  python \
  python3-pip \
  python3-setuptools \
  python3-wheel \
  && echo deb http://deb.debian.org/debian buster-backports main >> /etc/apt/sources.list \
  && apt-get -y update \
  && apt-get -y -t buster-backports install --no-install-recommends \
  cmake \
  && pip3 install \
  -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/v${ZEPHYR_VERSION}/scripts/requirements-base.txt \
  && apt-get remove -y \
  python3-pip \
  python3-setuptools \
  python3-wheel \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && cmake --version

CMD ["/bin/bash"]

#------------------------------------------------------------------------------

FROM common AS build

ARG ZEPHYR_TOOLCHAIN_PLATFORM
ARG ZEPHYR_TOOLCHAIN_VERSION
ARG ZEPHYR_TOOLCHAIN_SETUP_FILENAME=zephyr-toolchain-${ZEPHYR_TOOLCHAIN_PLATFORM}-${ZEPHYR_TOOLCHAIN_VERSION}-setup.run
ENV ZEPHYR_SDK_INSTALL_DIR=/opt/zephyr-${ZEPHYR_TOOLCHAIN_PLATFORM}-${ZEPHYR_TOOLCHAIN_VERSION}
ENV ZEPHYR_TOOLCHAIN_VERSION=${ZEPHYR_TOOLCHAIN_VERSION}
RUN \
  apt-get -y update \
  && apt-get -y install --no-install-recommends \
  bzip2 \
  wget \
  xz-utils \
  && wget -q "https://github.com/zephyrproject-rtos/sdk-ng/releases/download/v${ZEPHYR_TOOLCHAIN_VERSION}/${ZEPHYR_TOOLCHAIN_SETUP_FILENAME}" \
  && sh ${ZEPHYR_TOOLCHAIN_SETUP_FILENAME} --quiet -- -d ${ZEPHYR_SDK_INSTALL_DIR} \
  && rm ${ZEPHYR_TOOLCHAIN_SETUP_FILENAME} \
  && apt-get remove -y \
  bzip2 \
  wget \
  xz-utils \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

#------------------------------------------------------------------------------

FROM build AS dev

RUN \
  apt-get -y update \
  && apt-get -y install --no-install-recommends \
  clang \
  curl \
  && curl -sL https://deb.nodesource.com/setup_12.x | bash - \
  && apt-get -y update \
  && apt-get -y install --no-install-recommends \
  dfu-util \
  g++-multilib \
  gpg-agent \
  libsdl2-dev \
  nano \
  nodejs \
  python \
  python3-dev \
  python3-pip \
  python3-setuptools \
  python3-tk \
  python3-wheel \
  wget \
  xz-utils \
  && pip3 install \
  -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/v${ZEPHYR_VERSION}/scripts/requirements-build-test.txt \
  -r https://raw.githubusercontent.com/zephyrproject-rtos/zephyr/v${ZEPHYR_VERSION}/scripts/requirements-run-test.txt \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* \
  && node --version

ENV DEBIAN_FRONTEND=
FROM ubuntu

# Install Ruby and Rails dependencies
RUN apt update && apt install -y \
  build-essential \
  bash-completion \
  screen \
  man-db \
  pkg-config-aarch64-linux-gnu \
  gcc-aarch64-linux-gnu \
  g++-aarch64-linux-gnu \
	cpp-aarch64-linux-gnu \
	binutils-aarch64-linux-gnu \
	flex \
	bison \
	automake \
	libtool \
  git \
  vim \
  bc \
  python \
  libfdt-dev \
  sudo \
  libncurses5-dev \
  dialog \
  android-tools-adb \
  android-tools-fastboot

ADD osp.sh /etc/profile.d/

WORKDIR /opt/osp/var/build

ENTRYPOINT ["/bin/bash", "-l"]

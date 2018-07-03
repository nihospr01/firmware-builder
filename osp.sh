# setup development environment for osp
OSP_ROOT=/opt/osp
OSP_BUILD=$OSP_ROOT/var/build
KERNEL_DIR=$OSP_ROOT/src/kernel

mkdir -p $OSP_BUILD

NTHREADS=$(expr $(grep -c ^processor /proc/cpuinfo) + 1)
export NTHREADS

PATH=/opt/osp/bin:/opt/skales:$PATH
export PATH

ARCH=arm64
export ARCH

CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE

buildKernel() {
  pushd $KERNEL_DIR
  if ! [ -f .config ]; then
      make ospboard_defconfig KERNELRELEASE=4.9.56-linaro-lt-qcom
  fi
  make -j$NTHREADS Image.gz dtbs KERNELRELEASE=4.9.56-linaro-lt-qcom $1
  dtbTool -o $OSP_BUILD/dt.img -s 2048 arch/arm64/boot/dts/qcom/
  mkbootimg --kernel arch/arm64/boot/Image.gz \
            --ramdisk $OSP_ROOT/share/initrd.img-4.9.56-linaro-lt-qcom \
            --output $OSP_BUILD/boot-carrier.img \
            --dt $OSP_BUILD/dt.img \
            --pagesize 2048 \
            --base 0x80000000 \
            --cmdline "root=/dev/disk/by-partlabel/rootfs rw rootwait console=ttyMSM0,115200n8"

  popd &> /dev/null
  echo 'Done!'
}

flashImage() {
    sudo fastboot flash boot $OSP_BUILD/boot-carrier.img
    sudo fastboot reboot
}

buildHelp() {
    echo 'Available Commands:'
    echo '  buildKernel -- builds the kernel and creates image'
    echo '  flashImage  -- flashes the image to the board, sudo required'
    echo '  buildHelp   -- print this help summary'
}

buildHelp

# vim: set filetype=sh tabstop=2 shiftwidth=2 softtabstop=2 expandtab :

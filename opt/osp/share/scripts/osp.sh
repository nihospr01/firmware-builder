# setup development environment for osp
OSP_ROOT=/opt/osp
OSP_BUILD=$OSP_ROOT/var/build
KERNEL_DIR=$OSP_ROOT/src/kernel
OSP_PROCESS=$OSP_ROOT/src/osp_process
ROOTFS_DIR=$OSP_ROOT/rootfs
REDIRECT=/dev/stderr

mkdir -p $OSP_BUILD

if [ ! -f /opt/osp/share/rootfs.img ]; then
	echo "*** Extracting rootfs, this may take a minute but occurs only on first launch ***"
	pushd /opt/osp/share &>> $REDIRECT
	simg2img rootfs.simg rootfs.img
	popd &>> $REDIRECT
fi
mount -t ext4 -o rw,loop,auto /opt/osp/share/rootfs.img /opt/osp/rootfs


NTHREADS=$(expr $(grep -c ^processor /proc/cpuinfo) + 1)
export NTHREADS

PATH=/opt/osp/bin:$PATH
export PATH

ARCH=arm64
export ARCH

CROSS_COMPILE=aarch64-linux-gnu-
export CROSS_COMPILE

updateRootfs() {
  printf "$1Updating Rootfs.......................... "
  pushd /opt/osp/share &>> $REDIRECT
  umount /opt/osp/rootfs
  img2simg rootfs.img rootfs.simg &>> $REDIRECT
  mount -t ext4 -o rw,loop,auto /opt/osp/share/rootfs.img /opt/osp/rootfs
  popd &>> $REDIRECT
  printf "DONE\n"
}

buildKernel() {
  echo "Linux Kernel Build Tasks:"
  pushd $KERNEL_DIR &>> $REDIRECT
  if ! [ -f .config ]; then
      make ospboard_defconfig KERNELRELEASE=4.14.15-qcomlt-arm64 &>> $REDIRECT
    fi
  printf "  Building executable, dtbs, and modules... "
  make -j$NTHREADS Image.gz dtbs modules KERNELRELEASE=4.14.15-qcomlt-arm64 &>> $REDIRECT
  printf "DONE\n"
  printf "  Installing modules....................... "
  make modules_install KERNELRELEASE=4.14.15-qcomlt-arm64 INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=$ROOTFS_DIR &>> $REDIRECT
  printf "DONE\n"
  printf "  Building boot image...................... "
  cat arch/arm64/boot/Image.gz arch/arm64/boot/dts/qcom/apq8016-sbc.dtb > $OSP_BUILD/Image.gz+dtb
  mkbootimg --kernel $OSP_BUILD/Image.gz+dtb \
            --ramdisk $OSP_ROOT/share/initrd.img \
            --output $OSP_BUILD/boot.img \
            --pagesize 2048 \
            --base 0x80000000 \
            --cmdline "root=/dev/disk/by-partlabel/rootfs rw rootwait console=ttyMSM0,115200n8"
  rm -f $OSP_BUILD/Image.gz+dtb &>> $REDIRECT
  printf "DONE\n"

  popd &>> $REDIRECT

  if [ -z "$1" ] || [ "$1" != "skip" ]; then
    updateRootfs "  "
  fi
}

buildOSP() {
  echo "OSP Build Tasks:"
  pushd $OSP_BUILD &>> $REDIRECT
  cmake -DCMAKE_TOOLCHAIN_FILE=/opt/osp/src/CMakeToolchain /opt/osp/src/osp-process
  make
  cp osp_clion /opt/osp/rootfs/usr/local/bin/osp_process
  popd &>> $REDIRECT

  if [ -z "$1" ] || [ "$1" != "skip" ]; then
    updateRootfs "  "
  fi
}

buildAll() {
  buildLK
  buildKernel skip
  buildOSP skip
  updateRootfs
}

buildLK() {
  echo "OSP Build Tasks: NOT IMPLEMENTED YET"
}

setOutput() {
  if [ "$1" = "verbose" ]; then
    REDIRECT=/dev/stderr
  elif [ "$1" = "quiet" ]; then
    REDIRECT=/dev/null
  elif [ "$1" = "log" ]; then
    REDIRECT=$OSP_BUILD/output.log
  fi
}

buildHelp() {
    echo 'Available Commands:'
    echo '  updateRootfs -- updates the rootfs image with changes to "/opt/osp/rootfs"'
    echo '  buildKernel  -- builds the kernel and creates image'
    echo '  buildLK      -- builds the Little Kernel bootloader image'
    echo '  buildOSP     -- builds OSP process and installs in rootfs image'
    echo '  buildAll     -- builds all and updates rootfs image'
    echo '  setOutput    -- sets the output to "quiet (default), verbose, or log"'
    echo '  buildHelp    -- print this help summary'
}

buildHelp

# vim: set filetype=sh tabstop=2 shiftwidth=2 softtabstop=2 expandtab :

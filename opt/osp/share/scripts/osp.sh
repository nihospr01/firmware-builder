# setup development environment for osp
OSP_ROOT=/opt/osp
OSP_BUILD=$OSP_ROOT/var/build
KERNEL_DIR=$OSP_ROOT/src/kernel
KERNEL_MAKE_V=2
OSP_PROCESS=$OSP_ROOT/src/osp_process
ROOTFS_DIR=$OSP_ROOT/rootfs
REDIRECT=/dev/stderr

mkdir -p $OSP_BUILD
mkdir -p $ROOTFS_DIR

if [ ! -f /opt/osp/share/rootfs.simg ]; then
	echo "*** Decompressing rootfs, this may take a minute but occurs only on first launch ***"
	pushd /opt/osp/share &>> /dev/null
	7z e -bd rootfs.simg.7z &>> /dev/null
	popd &>> /dev/null
fi

if [ ! -f /opt/osp/share/rootfs.img ]; then
	echo "*** Extracting rootfs, this may take a minute but occurs only on first launch ***"
	pushd /opt/osp/share &>> /dev/null
	simg2img rootfs.simg rootfs.img &>> /dev/null
	popd &>> /dev/null
fi
mount -t ext4 -o rw,loop,auto /opt/osp/share/rootfs.img /opt/osp/rootfs


NTHREADS=$(expr $(grep -c ^processor /proc/cpuinfo) + 1)
export NTHREADS

PATH=/opt/osp/bin:$PATH
export PATH

ARCH=arm64
export ARCH

CROSS_COMPILE="ccache aarch64-linux-gnu-"
export CROSS_COMPILE

updateRootfs() {
  printf "$1Updating Rootfs.......................... "
  pushd /opt/osp/share &>> /dev/null
  umount /opt/osp/rootfs &>> /dev/null
  img2simg rootfs.img rootfs.simg &>> /dev/null
  mount -t ext4 -o rw,loop,auto /opt/osp/share/rootfs.img /opt/osp/rootfs &>> /dev/null
  popd &>> /dev/null
  printf "DONE\n"
}

compressRootfs() {
  printf "$1Compressing Rootfs.......................... "
  pushd /opt/osp/share &>> /dev/null
  rm -f rootfs.simg.7z &>> /dev/null
  7z a -bd rootfs.simg.7z rootfs.simg  &>> /dev/null
  popd &>> /dev/null
  printf "DONE\n"
}

buildKernel() {
  echo "Linux Kernel Build Tasks:"
  pushd $KERNEL_DIR &>> /dev/null
  if ! [ -f .config ]; then
      make ospboard_defconfig KERNELRELEASE=4.14.0-qcomlt-arm64 V=$KERNEL_MAKE_V &>> $REDIRECT
  fi
  printf "  Building Image.gz......................... "
  make -j$NTHREADS Image.gz KERNELRELEASE=4.14.0-qcomlt-arm64 V=$KERNEL_MAKE_V &>> $REDIRECT
  printf "DONE\n"
  printf "  Building modules.......................... "
  make -j$NTHREADS modules KERNELRELEASE=4.14.0-qcomlt-arm64 V=$KERNEL_MAKE_V &>> $REDIRECT
  printf "DONE\n"
  printf "  Building dtbs............................. "
  make -j$NTHREADS dtbs KERNELRELEASE=4.14.0-qcomlt-arm64 V=$KERNEL_MAKE_V &>> $REDIRECT
  printf "DONE\n"
  printf "  Installing modules....................... "
  make modules_install KERNELRELEASE=4.14.0-qcomlt-arm64 INSTALL_MOD_STRIP=1 INSTALL_MOD_PATH=$ROOTFS_DIR V=$KERNEL_MAKE_V &>> $REDIRECT
  printf "DONE\n"
  printf "  Building boot image...................... "
  cat arch/arm64/boot/Image.gz arch/arm64/boot/dts/qcom/apq8016-sbc.dtb > $OSP_BUILD/Image.gz+dtb
  mkbootimg --kernel $OSP_BUILD/Image.gz+dtb \
            --ramdisk $OSP_ROOT/share/initrd.img \
            --output $OSP_BUILD/boot.img \
            --pagesize 2048 \
            --base 0x80000000 \
            --cmdline "root=/dev/disk/by-partlabel/rootfs rw rootwait console=ttyMSM0,115200n8"
  rm -f $OSP_BUILD/Image.gz+dtb &>> /dev/null
  printf "DONE\n"

  popd &>> /dev/null

  if [ -z "$1" ] || [ "$1" != "skip" ]; then
    updateRootfs "  "
  fi
}

buildOSP() {
  echo "OSP Build Tasks:"
  pushd $OSP_BUILD &>> /dev/null
  cmake -DCMAKE_TOOLCHAIN_FILE=/opt/osp/src/CMakeToolchain /opt/osp/src/osp-process
  make
  cp osp_clion /opt/osp/rootfs/usr/local/bin/osp_process
  popd &>> /dev/null

  if [ -z "$1" ] || [ "$1" != "skip" ]; then
    updateRootfs "  "
  fi
}

buildAll() {
  buildLK
  buildKernel skip
  buildOSP skip
  updateRootfs
  compressRootfs
}

buildLK() {
  echo "OSP Build Tasks: NOT IMPLEMENTED YET"
}

setOutput() {
  if [ "$1" = "verbose" ]; then
    REDIRECT=/dev/stderr
		KERNEL_MAKE_V=2
  elif [ "$1" = "quiet" ]; then
    REDIRECT=/dev/null
		KERNEL_MAKE_V=0
  elif [ "$1" = "log" ]; then
    REDIRECT=$OSP_BUILD/output.log
		KERNEL_MAKE_V=1
  fi
}

buildHelp() {
    echo 'Available Commands:'
    echo '  updateRootfs   -- updates rootfs.simg with changes to "/opt/osp/rootfs"'
    echo '  compressRootfs -- updates rootfs.simg.gz with latest rootfs.simg'
    echo '  buildKernel    -- builds the kernel and creates image'
    echo '  buildLK        -- builds the Little Kernel bootloader image'
    echo '  buildOSP       -- builds OSP process and installs in rootfs image'
    echo '  buildAll       -- builds all and updates rootfs image'
    echo '  setOutput      -- sets the output to "quiet, verbose (default), or log"'
    echo '  buildHelp      -- print this help summary'
}

if ! [ -f /usr/local/bash-git-prompt/gitprompt.sh ]; then
	pushd /usr/local &> /dev/null
	git clone --branch=2.7.1 https://github.com/magicmonty/bash-git-prompt.git &> /dev/null
	popd &> /dev/null
fi
source /usr/local/bash-git-prompt/gitprompt.sh

complete -W "quiet verbose log" setOutput
buildHelp

# vim: set filetype=sh tabstop=2 shiftwidth=2 softtabstop=2 expandtab :

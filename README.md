# Setup OSPBoard Development Environment

## Get Repositories

⚠️ Install Git LFS before continuing

```bash
git clone --recurse-submodules git@bitbucket.org:openspeechplatform/ospboard.git
```


## Initialize environment

⚠️ Install Docker before continuing

```bash
cd ospboard
./initialize
```

## Start Build environment

```bash
./start
```

## Build Kernel and Upload to OSPBoard

⚠️ Install `fastboot` on host machine before continuing

```bash
buildKernel
```

On the host system goto `ospboard/opt/osp/var/build` directory and execute the commands below to update OSPBoard's firmware:

```bash
sudo fastboot flash boot boot-carrier.img
sudo fastboot reboot
```

# [Notes for Installing Git LFS](https://git-lfs.github.com)
# [Notes for Installing Docker](https://bitbucket.org/openspeechplatform/ospboard/wiki/Installing%20Docker)

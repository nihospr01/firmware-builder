# Setup OSPBoard Development Environment

## Get Repositories

```bash
git clone --recurse-submodules git@bitbucket.org:openspeechplatform/ospboard.git
```


## Initialize environment
<style>
.warnbox { /*next paragraph after <div class="note"></div>*/
    width: fit-content;
    padding: 8pt 8pt 8pt 8pt;
    border-radius: 4pt;
    color: yellow;
    background-color: blue;
    display: flex;
    flex-wrap: nowrap;
}

.warnmsg { /*aditionally prepend `⚠ Note:` to message: */
  height: 20pt;
  line-height: 20pt;
  font-size: 15pt;
  text-align: center;
}

.warnsign { /*aditionally prepend `⚠ Note:` to message: */
  line-height: 20pt;
  padding-right: 8pt;
  font-size: 20pt;
  text-align: center;
}
</style>

<div class="warnbox">
  <div class="warnsign">
    ⚠️
  </div>
  <div class="warnmsg">
    Install Docker before continuing
  </div>
</div>



```bash
cd ospboard
./initialize
```

## Start Build environment

```bash
./start
```

## Build Kernel and Upload to OSPBoard

```bash
buildKernel
```

On the host system goto `ospboard/opt/osp/var/build` directory and run fastboot to upload new image

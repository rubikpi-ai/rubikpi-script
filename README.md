RUBIK Pi Qualcomm Linux Yocto project Linux kernel separate compilation and flashing script.

# Usage

This repository has been used as a sub-repository of [linux](https://github.com/rubikpi-ai/linux).
The following commands need to be executed in the root directory of the [linux](https://github.com/rubikpi-ai/linux) repository.

**build:**
```shell
./rubikpi_build.sh -a
```

**Package the compilation results into an image：**
```shell
./rubikpi_build.sh -ip -dp
```

**flash:**
```shell
adb shell reboot bootloader
./rubikpi_flash.sh -i -d -r
```

# README

Helps you quickly enable RUBIK Pi's peripheral functions. (CAM, AI, Audio, etc.)

## Usage

Execute the following command on the RUBIK Pi 3 terminal:

### Prerequisites:

```bash
git clone -b linux_distro_dev --single-branch https://github.com/rubikpi-ai/rubikpi-script.git
cd rubikpi-script
```

### Run scripts:

```bash
./install_ppa_pkgs.sh
```

More complicated usage can be found by -h or --help:
```bash
./install_ppa_pkgs.sh --help
```

### More Examples:
```bash
./install_ppa_pkgs.sh --hostname=mypi          # Install all pkgs, and set hostname
./install_ppa_pkgs.sh --reboot                 # Install all pkgs, and reboot
./install_ppa_pkgs.sh --reboot --hostname=mypi # Install all pkgs, set hostname, and reboot
./install_ppa_pkgs.sh --uninstall --reboot     # Uninstall all pkgs, and reboot
```

### Speed up by using region mirrors for ubuntu-ports:

Just pick one mirror below based on your region, if default ubuntu-ports is slow.
Mirror setting will be saved to the source list below:
* /etc/apt/sources.list.d/ports-mirror.sources

For APAC
```bash
./install_ppa_pkgs.sh --mirror=https://ftp.tsukuba.wide.ad.jp/Linux/ubuntu-ports      # Japan mirror
./install_ppa_pkgs.sh --mirror=https://in.mirror.coganng.com/ubuntu-ports             # India mirror
./install_ppa_pkgs.sh --mirror=https://mirror.hashy0917.net/ubuntu-ports              # Japan mirror
./install_ppa_pkgs.sh --mirror=https://mirror.twds.com.tw/ubuntu-ports                # Taiwan mirror
./install_ppa_pkgs.sh --mirror=https://mirrors.tuna.tsinghua.edu.cn/ubuntu-ports      # China mirror
./install_ppa_pkgs.sh --mirror=https://mirrors.ustc.edu.cn/ubuntu-ports               # China mirror
```

For EU
```bash
./install_ppa_pkgs.sh --mirror=https://mirror.dogado.de/ubuntu-ports                  # Germany mirror
./install_ppa_pkgs.sh --mirror=https://mirror.kumi.systems/ubuntu-ports               # Austria mirror
```

For North America
```bash
./install_ppa_pkgs.sh --mirror=https://mirror.csclub.uwaterloo.ca/ubuntu-ports        # Canada mirror
./install_ppa_pkgs.sh --mirror=https://mirrors.mit.edu/ubuntu-ports                   # US/East mirror
./install_ppa_pkgs.sh --mirror=https://mirrors.ocf.berkeley.edu/ubuntu-ports          # US/West mirror
```

## Get script version when report issues:

Inform us the script version from git describe command below when you report issues.

```bash
cd rubikpi-script
git describe --always
```

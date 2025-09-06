# initial.sh

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

### Get script version when report issues:

Inform us the script version from git describe command below when you report issues.

```bash
cd rubikpi-script
git describe --always
```

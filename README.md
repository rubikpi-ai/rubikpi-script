# initial.sh

Helps you quickly enable RUBIK Pi's peripheral functions. (CAM, AI, Audio, etc.)

## Usage

Execute the following command on the RUBIK Pi 3 terminal:

### Prerequisites:

```bash
sudo apt install git
git clone -b linux_distro https://github.com/rubikpi-ai/rubikpi-script.git
cd rubikpi-script
```
### Run all scripts in sequence:

```bash
bash ./initial.sh
```

### Only download packages:

```bash
bash ./initial.sh --dloadpkgs
```

### Only run IDE installation:

```bash
bash ./initial.sh --ide-install
```

### Only set hostname:
```bash
bash ./initial.sh --sethostname=rubikpi
```

### Run IDE installation with reboot:
```bash
bash ./initial.sh --ide-install --reboot
```

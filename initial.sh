#!/bin/sh
# Parameter-based dispatcher for UbunInitScripts
# Helps you quickly enable RUBIK Pi's peripheral functions (CAM, AI, Audio, etc.)

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
UBUN_SCRIPTS_DIR="$SCRIPT_DIR/UbunInitScripts"

# Usage function with colored output
usage() {
	printf "\033[1;37mUsage:\033[0m\n"
	printf "  bash %s [options]\n" "$0"
	printf "\n"
	printf "\033[1;37mDescription:\033[0m\n"
	printf "  Dispatcher script that calls specific scripts from UbunInitScripts directory\n"
	printf "  Helps you quickly enable RUBIK Pi's peripheral functions (CAM, AI, Audio, etc.)\n"
	printf "\n"
	printf "\033[1;37mOptions:\033[0m\n"
	printf "\033[1;37m  -h, --help\033[0m              display this help message\n"
	printf "\033[1;37m  --dloadpkgs\033[0m             download and install QNN/SNPE packages and Edge Impulse\n"
	printf "\033[1;37m  --ide-install\033[0m           run comprehensive IDE installation script\n"
	printf "\033[1;37m  --sethostname=<name>\033[0m    set system hostname to specified name\n"
	printf "\033[1;37m  --reboot\033[0m                pass --reboot flag to ide-install script\n"
	printf "\n"
	printf "\033[1;37mExamples:\033[0m\n"
	printf "  bash %s                          # Run all scripts in sequence\n" "$0"
	printf "  bash %s --dloadpkgs               # Only download packages\n" "$0"
	printf "  bash %s --ide-install            # Only run IDE installation\n" "$0"
	printf "  bash %s --sethostname=mypi       # Only set hostname\n" "$0"
	printf "  bash %s --ide-install --reboot   # Run IDE install with reboot\n" "$0"
	printf "\n"
	printf "\033[1;37mAvailable Scripts:\033[0m\n"
	printf "  dloadpkgs.sh    - Downloads QNN, SNPE packages and Edge Impulse setup\n"
	printf "  ide_install.sh  - Comprehensive installation of repositories, packages, and configuration\n"
	printf "  sethostname.sh  - Sets system hostname\n"
	printf "\n"
}

# Check if UbunInitScripts directory exists
check_scripts_dir() {
	if [ ! -d "$UBUN_SCRIPTS_DIR" ]; then
		echo "Error: UbunInitScripts directory not found at: $UBUN_SCRIPTS_DIR"
		exit 1
	fi
}

# Execute a script from UbunInitScripts directory
execute_script() {
	local script_name="$1"
	shift
	local script_path="$UBUN_SCRIPTS_DIR/$script_name"
	
	if [ ! -f "$script_path" ]; then
		echo "Error: Script not found: $script_path"
		exit 1
	fi
	
	if [ ! -x "$script_path" ]; then
		chmod +x "$script_path"
	fi
	
	echo "Executing: $script_name $*"
	cd "$UBUN_SCRIPTS_DIR"
	"./$script_name" "$@"
	cd "$SCRIPT_DIR"
}

# Main execution logic
main() {
	echo "RUBIK Pi 3 Initial Setup Script Dispatcher"
	echo "=========================================="
	
	check_scripts_dir
	
	# If no arguments provided, run all scripts in sequence
	if [ "$#" -eq 0 ]; then
		echo "No specific options provided. Running all scripts in sequence..."
		execute_script "ide_install.sh"
		execute_script "dloadpkgs.sh"
		return
	fi
	
	# Parse arguments and execute accordingly
	local run_dloadpkgs=0
	local run_ide_install=0
	local hostname=""
	local ide_install_args=""
	
	while [ "$#" -gt 0 ]; do
		case "$1" in
			-h|--help)
				usage
				exit 0
				;;
			--dloadpkgs)
				run_dloadpkgs=1
				;;
			--ide-install)
				run_ide_install=1
				;;
			--sethostname=*)
				hostname="${1#*=}"
				if [ -z "$hostname" ]; then
					echo "Error: hostname cannot be empty"
					exit 1
				fi
				;;
			--reboot)
				ide_install_args="$ide_install_args --reboot"
				;;
			*)
				echo "Unknown option: $1"
				echo "Use --help for usage information"
				exit 1
				;;
		esac
		shift
	done
	
	# Execute based on parsed arguments
	if [ -n "$hostname" ]; then
		execute_script "sethostname.sh" "$hostname"
	fi
	
	if [ "$run_ide_install" -eq 1 ]; then
		if [ -n "$hostname" ]; then
			execute_script "ide_install.sh" "--hostname=$hostname" $ide_install_args
		else
			execute_script "ide_install.sh" $ide_install_args
		fi
	fi
	
	if [ "$run_dloadpkgs" -eq 1 ]; then
		execute_script "dloadpkgs.sh"
	fi
	
	echo "Script execution completed successfully!"
}

# Start the script
main "$@"

#!/bin/bash
# Path and file name
#  - /usr/local/bin/usb-autostart-script-detection.sh (755) - coded in utf-8
#
# Acoustic signal output true/false
#  - sudo sed -i 's/signal=".*"/signal="true"/g' /usr/local/bin/usb-autostart-script-detection.sh
#
#                autostart für externe Datenträger
#
#                  Developed by tommes (toafez)
#              MIT License https://mit-license.org/
#        Member of the German UGREEN Forum - DACH Community
#
#       Dieses Script wurde speziell für die Verwendung auf
#            UGREEN-NAS Systemen entwickelt die das
#              Betriebsystem UGOS Pro verwenden.

# --------------------------------------------------------------
# Define Enviroment
# --------------------------------------------------------------

# Securing the Internal Field Separator (IFS) as well as the separation
if [ -z "${backupIFS}" ]; then
	backupIFS="${IFS}"
	readonly backupIFS
fi

# Set timestamp
timestamp() {
	date +"%Y-%m-%d %H:%M:%S"
}

# Acoustic signal output
signal="true"

function signal_start()
{
	# Short beep
	echo one > /proc/nas/beeper
	sleep 1
}

function signal_stop()
{
	# Short beep
	echo one > /proc/nas/beeper
	sleep 1
}

function signal_warning()
{
	# Short beep
	echo one > /proc/nas/beeper
	sleep 1
	# Short beep
	echo one > /proc/nas/beeper
	sleep 1
	# Short beep
	echo one > /proc/nas/beeper
}
# --------------------------------------------------------------
# Take parameter %k (device name) from the udev rule
# --------------------------------------------------------------
par=$(echo "${1}")

# --------------------------------------------------------------
# Determine the mount point of the device ${par}
# --------------------------------------------------------------
if [ -z "${par}" ]; then
	exit 1
else
	# If ${par} starts with /dev/, then delete /dev/
	par=$(echo "${par}" | sed 's:^/dev/::')

	# Remove the number from the partition to identify the disk itself, e.g. partition is sda1 --> disk is sda
	disk=$(echo "${par}" | sed 's/[0-9]\+$//')

	# Set device path to determine the mountpoint
	device="/dev/${par}"

	# Searching for mountpoints
	mountpoint=""

	# Set maximum time (duration) for loop in seconds.
	loopMaxSecs=30

	# Calculate end time of loop.
	loopEndTime=$(( $(date +%s) + loopMaxSecs ))

	# Loop until mountpoint found or reached maximum duration time.
	while [ -z "${mountpoint}" ] && [ $(date +%s) -lt $loopEndTime ]; do
		# The mountpoint should look something like this /mnt/@usb/sdc1
		mountpoint=$(mount -l | grep "$device" | awk '{print $3}')
	done
fi

# --------------------------------------------------------------
# If the autostart file is in the root directory, run the script
# --------------------------------------------------------------
if [ -n "${mountpoint}" ] && [ -f "${mountpoint}/autostart.sh" ]; then
	scriptfile="${mountpoint}/autostart.sh"
	logfile="${mountpoint}/autostart.log"
	[ -f "${logfile}" ] && rm -f "${logfile}"
	[ ! -f "${logfile}" ] && install -m 777 /dev/null "${logfile}"

	echo "" > "${logfile}"
	echo "------------------------------------------------------------" | tee -a "${logfile}"
	echo "autostart für externe Datenträger" | tee -a "${logfile}"
	echo " - Skript Version 0.1-000" | tee -a "${logfile}"
	echo " - Disk: ${disk}" | tee -a "${logfile}"
	echo " - Device: ${device}" | tee -a "${logfile}"
	echo " - Mountpoint: ${mountpoint}" | tee -a "${logfile}"
	echo " - Auszuführendes autostart Skript: ${scriptfile}" | tee -a "${logfile}"
	echo "------------------------------------------------------------" | tee -a "${logfile}"
	echo "" | tee -a "${logfile}"

    # ----------------------------------------------------------
	# Run the autostart script
	# ----------------------------------------------------------
	timestamp_start=$(date +%s)
	[[ "${signal}" == "true" ]] && signal_start

	IFS="
	"
	sudo ${scriptfile} "${logfile}" "${mountpoint}"
	exit_script=${?}
	IFS="${backupIFS}"

	duration="$(($(date +%s) - timestamp_start))"
	[[ "${signal}" == "true" && "${exit_script}" -eq 0 ]] && signal_stop
	[[ "${signal}" == "true" && "${exit_script}" -ne 0 ]] && signal_warning

    # ----------------------------------------------------------
	# Stop the autostart script
	# ----------------------------------------------------------
	echo "" | tee -a "${logfile}"
	echo "------------------------------------------------------------" | tee -a "${logfile}"
	echo "Das autostart Skript wurde beendet! " | tee -a "${logfile}"
	echo "Ausgegebener Rückgabewert (Exit-Code): ${exit_script}" | tee -a "${logfile}"
	echo "Dauer der Skriptausführung: "$(printf '%dh:%dm:%ds\n' $((duration/3600)) $((duration%3600/60)) $((duration%60)))"" | tee -a "${logfile}"
	echo "------------------------------------------------------------" | tee -a "${logfile}"
fi
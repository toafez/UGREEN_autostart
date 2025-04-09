#!/bin/bash
# Path and file name 
#  - /usr/local/bin/usb-autostart-script-detection.sh (755) - coded in utf-8

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
	echo "------------------------------------------------------------" >> "${logfile}"
	echo "autostart für externe Datenträger" >> "${logfile}"
	echo " - Skript Version 0.1-000" >> "${logfile}"
	echo " - Disk: ${disk}" >> "${logfile}"
	echo " - Device: ${device}" >> "${logfile}"
	echo " - Mountpoint: ${mountpoint}" >> "${logfile}"
	echo " - Auszuführendes autostart Skript: ${scriptfile}" >> "${logfile}"
	echo "------------------------------------------------------------" >> "${logfile}"
	echo "" >> "${logfile}"

    # ----------------------------------------------------------
	# Run the autostart script
	# ----------------------------------------------------------
	timestamp_start=$(date +%s)
	IFS="
	"
	sudo ${scriptfile} "${logfile}" "${mountpoint}"
	exit_script=${?}
	IFS="${backupIFS}"

    # ----------------------------------------------------------
	# Stop the autostart script
	# ----------------------------------------------------------
	echo "" >> "${logfile}"
	echo "------------------------------------------------------------" >> "${logfile}"
	duration="$(($(date +%s) - timestamp_start))"
	echo "Das autostart Skript wurde beendet! " >> "${logfile}"
	echo "Ausgegebener Rückgabewert (Exit-Code): ${exit_script}" >> "${logfile}"
	echo "Dauer der Skriptausführung: "$(printf '%dh:%dm:%ds\n' $((duration/3600)) $((duration%3600/60)) $((duration%60)))"" >> "$logfile"
	echo "------------------------------------------------------------" >> "${logfile}"
fi

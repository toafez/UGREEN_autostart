#!/bin/bash
logfile="${1}"
mountpoint="${2}"
# Path and file name
#  - ${mountpoint}/autostart.sh - coded in utf-8

#                autostart für externe Datenträger
#
#                  Developed by tommes (toafez)
#              MIT License https://mit-license.org/
#        Member of the German UGREEN Forum - DACH Community
#
#       Dieses Script wurde speziell für die Verwendung auf 
#            UGREEN-NAS Systemen entwickelt die das
#              Betriebsystem UGOS Pro verwenden.


#---------------------------------------------------------------------
#                   !!! BENUTZEREINGABEN !!!
#---------------------------------------------------------------------

# Zielverzeichnis
#---------------------------------------------------------------------
# Syntaxmuster: target="/[VOLUME]/[SHARE]/[FOLDER]"
#---------------------------------------------------------------------
# Dem Pfad zum Zielverzeichnis muss in jedem Fall die Variable 
# ${mountpoint} vorangestellt werden. Weitere Unterverzeichnisse sind
# möglich. Wenn das Zielverzeichnis nicht existiert, wird es bei der 
# ersten Datensicherung angelegt. Ungültige Zeichen in Datei- und 
# Verzeichnisnamen sind ~ " # % & * : < > ? / \ { | }
#---------------------------------------------------------------------
target="${mountpoint}/UGOS-Backup"

# Datensicherungsquelle(n)
#---------------------------------------------------------------------
# Syntaxmuster: sources="/[SHARE1]/[FOLDER1] & /[SHARE2]/[FOLDER2]"
#---------------------------------------------------------------------
# Es muss der vollständige Pfad zum Quellverzeichnis angegeben werden.
# Wenn mehr als ein Quellverzeichnis angegeben wird, müssen die Pfade
# durch das Symbol & getrennt werden, z. B. 
# "/volume1/photo & /volume1/music/compilation & /volume1/video/series" 
# Ungültige Zeichen in Datei- und Verzeichnisnamen sind
# ~ " # % & * : < > ? / \ { | }
#---------------------------------------------------------------------
sources="/volume1/Downloads & /volume1/docker/it-tools & /volume1/docker/stirling-pdf"

# Inhalt des Papierkorbs /@recycle löschen, der älter ist als...
#---------------------------------------------------------------------
# Syntaxmuster: recycle="false", "30" (Standardauswahl) oder "true"
#---------------------------------------------------------------------
# Wird für recycle= der Wert "false" angegeben, so werden alle
# zwischenzeitlich gelöschten Daten der Sicherungsquelle(n) auch im
#  Sicherungsziel unwiderruflich gelöscht. Wird für recycle= ein
# numerischer Wert von mindestens 1 angegeben, so werden
# zwischenzeitlich gelöschte Daten der Sicherungsquelle(n) für die
# angegebene Zeit in Tagen in den Papierkorb unter /@recycle des
# Zielordners verschoben, bevor sie unwiderruflich gelöscht werden.
# Wird für recycle= der Wert "true" angegeben, so werden
# zwischenzeitlich gelöschte Daten der Sicherungsquelle(n) immer in
# den Papierkorb unter /@recycle des Zielordners verschoben, ohne dass
# sie zukünftig gelöscht werden. 
#---------------------------------------------------------------------
recycle="30"

# rsync Optionen
#---------------------------------------------------------------------
# Syntaxmuster: syncopt="-ah" (Standardauswahl)
#---------------------------------------------------------------------
syncopt="-ah"

# Ausschließen von Dateien und Verzeichnissen
#---------------------------------------------------------------------
# Syntaxmuster: exclude="--delete-excluded --exclude=[DATEI-ODER-VERZEICHNIS]"
#---------------------------------------------------------------------
exclude="--delete-excluded --exclude=@eaDir/*** --exclude=@Logfiles/*** --exclude=#recycle/*** --exclude=#snapshot/*** --exclude=.DS_Store/***"


#---------------------------------------------------------------------
#          !!! AB HIER BITTE NICHTS MEHR ÄNDERN !!!
#---------------------------------------------------------------------

# --------------------------------------------------------------
#  Set environment variables
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

	# Set the current date and time
	datetime=$(date "+%Y-%m-%d_%Hh-%Mm-%Ss")

	# Reset exit code
	exit_code=

# --------------------------------------------------------------
# Create target folder on the external device
# --------------------------------------------------------------

	# Make sure that the target path ends with a slash
	if [[ "${target:${#target}-1:1}" != "/" ]]; then
		target="${target}/"
	fi

	# Create target path
	if [ ! -d "${target}" ]; then
		mkdir -p "${target}"
		exit_mkdir=${?}
	fi

	# If the target folder could not be created
	if [[ "${exit_mkdir}" -ne 0 ]]; then
		echo "# $(timestamp) Starte synchrone rsync Datensicherung auf einen externen Datenträger..." >> "${logfile}"
		echo " - Warnung: Der Zielordner konnte nicht erstellt werden." >> "${logfile}"
		exit_code=1
	else
		echo "# $(timestamp) Starte synchrone rsync Datensicherung auf einen externen Datenträger..." >> "${logfile}"
		exit_code=0

	fi

# --------------------------------------------------------------
# Configure @recycle bin
# --------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	# If the number of days in the recycle bin is a number and not 0 or true, create a restore point.
	is_number="^[0-9]+$"
	if [ -n "${recycle}" ] && [[ "${recycle}" -ne 0 ]] && [[ "${recycle}" =~ ${is_number} ]]; then
		backup="--backup --backup-dir=@recycle/${datetime}"
	elif [ -n "${recycle}" ] && [[ "${recycle}" == "true" ]]; then
		backup="--backup --backup-dir=@recycle/${datetime}"
	fi
fi

# --------------------------------------------------------------
# Configure ionice
# --------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	# If the ionice program is installed, use it, otherwise use the rsync bandwidth limitation
	if command -v ionice 2>&1 >/dev/null; then
		echo " - Das Programm [ ionice ] optimiert die Lese- und Schreibgeschwindigkeit des rsync-Prozesses" >> "${logfile}"
		echo "   um die Verfügbarkeit des Systems während der Datensicherung zu gewährleisten!" >> "${logfile}"
		ionice="ionice -c 3"
	fi
fi

# --------------------------------------------------------------
# Read in the sources and pass them to the rsync script
# --------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	IFS='&'
	read -r -a all_sources <<< "${sources}"
	IFS="${backupIFS}"
	for source in "${all_sources[@]}"; do
		source=$(echo "${source}" | sed 's/^[ \t]*//;s/[ \t]*$//')

		# ------------------------------------------------------
		# Beginn rsync loop
		# ------------------------------------------------------
		echo "" >> "${logfile}"
		echo "# $(timestamp) Schreibe rsync-Protokoll..." >> "${logfile}"
		echo " - Quellverzeichnis: ${source}" >> "${logfile}"
		echo " - Zielverzeichnis: ${target}${source##*/}" >> "${logfile}"
		${ionice} \
		rsync \
		${syncopt} \
		--stats \
		--delete \
		${backup} \
		${exclude} \
		"${source}" "${target}" >> "${logfile}"
		rsync_exit_code=${?}
		
		# ------------------------------------------------------
		# rsync error analysis after rsync run...
		# ------------------------------------------------------
		if [[ "${rsync_exit_code}" -ne 0 ]]; then
			echo "" >> "${logfile}"
			echo "Warnung: Rsync meldet Fehlercode ${rsync_exit_code}!" >> "${logfile}"
			echo " - Prüfe das Protokoll für weitere Informationen." >> "${logfile}"
			echo "" >> "${logfile}"
			exit_code=1
		else
			exit_code=0
		fi
	done
	echo "" >> "${logfile}"
	echo "# $(timestamp) Der Auftrag wird abgeschlossen..." >> "${logfile}"
fi

# --------------------------------------------------------------
# Rotation cycle for deleting /@recycle
# --------------------------------------------------------------
if [[ ${exit_code} -eq 0 ]]; then
	if [ -n "${recycle}" ] && [[ "${recycle}" -ne 0 ]] && [[ "${recycle}" =~ ${is_number} ]]; then
		echo " - Zwischenzeitlich gelöschte Daten der Sicherungsquelle(n) werden in den" >> "${logfile}"
		echo "   Ordner /@recycle, des Sicherungsziels verschoben." >> "${logfile}"
		if [ -d "${target%/*}/@recycle" ]; then
			find "${target%/*}/@recycle/"* -maxdepth 0 -type d -mtime +${recycle} -print0 | xargs -0 rm -r 2>/dev/null
			if [[ ${?} -eq 0 ]]; then
				echo " - Daten aus dem Ordner /@recycle, die älter als ${recycle} Tage waren, wurden gelöscht." >> "${logfile}"
			fi
		fi
	fi
fi

# ------------------------------------------------------------------------
# Notification of success or failure and exit script
# ------------------------------------------------------------------------
if [[ "${exit_code}" -eq 0 ]]; then
	# Notification that the backup job was successfully executed
	echo " - Der Sicherungsauftrag wurde erfolgreich ausgeführt." >> "${logfile}"
	exit 0
else
	# Notification that the backup job contained errors
	echo " - Warnung: Der Sicherungsauftrag ist fehlgeschlagen oder wurde abgebrochen." >> "${logfile}"
	exit 1
fi

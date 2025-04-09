# autostart für externe Datenträger

**autostart** ermöglicht das **Ausführen von beliebigen Shellscript Anweisungen**, die **nach** dem **Anschluss eines externen USB Datenträgers** an deine **UGREEN-NAS** automatisch ausgeführt werden. 

## Wie funktioniert autostart
Wird ein externer USB Datenträger an das **UGREEN-NAS** angeschlossen, wird dieser zunächst von **UGOS Pro** erkannt und in das System eingebunden (gemounted). Anschließend prüft **autostart**, ob sich im Wurzelverzeichnis des externen USB Datenträgers bzw. auf den eingebundenen Partitionen eine Shell-Skript-Datei mit dem Namen autostart.sh befindet. Ist dies der Fall, wird der Inhalt der Shell-Skript-Datei ausgeführt, andernfalls wird die Überwachung für diesen Datenträger beendet. Nach der Ausführung der Shell-Skript-Datei wird eine Protokolldatei mit dem Namen autostart.log im Wurzelverzeichnis des externen USB Datenträgers abgelegt.

## Sicherheitshinweise
Nach der Einrichtung von **autostart** wird der Inhalt der Datei **autostart.sh** nach jedem Einstecken eines externen USB Datenträgers mit **root-Rechten** ausgeführt. Dies gibt dem Benutzer einerseits große Freiheiten, andererseits aber auch ein hohes Maß an Verantwortung. Neben unbeabsichtigten oder nicht vorhersehbaren Fehlern im Skript selbst, die zum Teil erheblichen Schaden anrichten können, kann es auch zu absichtlichen Versuchen der Kompromittierung durch Dritte kommen, wenn diese Kenntnis von der Existenz von autostart auf deinem UGREEN-NAS haben.

Da **autostart** derzeit noch nicht als App in **UGOS Pro** eingebunden werden kann, gibt es auch keine erweiterten Konfigurationsmöglichkeiten, wie z.B. einen Schalter zum temporären Deaktivieren der autostart Funktion oder das Auslagern der Shell-Skript-Datei auf ein internes Volume des UGREEN-NAS und das Koppeln an die UUID des externen USB Datenträgers, wie es meine für Synology geschriebene App [AutoPilot](https://github.com/toafez/AutoPilot) ermöglicht.

Aufgrund der bestehenden Sicherheitsmängel füge ich am Ende daher noch eine Anleitung bei, wie man **autostart** über die Kommandozeile ggf. deinstallieren kann.

## Installationshinweise
Für die Ersteinrichtung von autostart ist es notwendig, sich über SSH mit der Kommandozeile deines UGREEN-NAS zu verbinden. Dazu wird ein Terminalprogramm wie z.B. PuTTy, Windows PowerShell, MAC Terminal oder eines der zahlreichen Terminalprogramme unter Linux benötigt. Später wird die Kommandozeile jedoch nicht mehr benötigt, da die Shell-Skript-Datei autostart.sh mit der von UGREEN bereitgestellten App **TextEdit** bearbeitet werden kann.

## SSH Dienst aktivieren
Um eine SSH-Verbindung zu deinem UGREEN-NAS herzustellen, musst du zuerst den SSH-Dienst in UGOS Pro aktivieren. Dazu meldest du dich am UGOS Pro deines UGREEN-NAS mit einem Administratorkonto an. Anschließend navigierst du zu Meine-Apps > Systemsteuerung > Terminal und aktivierst das Kontrollkästchen SSH aktivieren. Direkt darunter kannst du bei Bedarf den Port anpassen, den der SSH-Dienst verwenden soll. Durch Anklicken der Schaltfläche Übernehmen werden deine Einstellungen gespeichert. 

## Verbindung herstellen
- Starte dein bevorzugtes Terminalprogramm.
- Im folgenden Beispiel lautet der Name des UGOS Pro Administratorkontos MyAdmin. Das UGREEN-NAS selbst ist in diesem Beispiel über die IPv4 Adresse 172.16.1.12 erreichbar und trägt den Namen UGREEN-NAS. Ersetze daher im folgenden Befehl die Platzhalter für [PORT], [BENUTZERNAME] und [IP-ADRESSE] durch deine eigenen Daten. Führe dann den folgenden Befehl aus.

  **Hinweis:** Text in Großbuchstaben innerhalb eckiger Klammern dient als Platzhalter und muss einschließlich der eckigen Klammern durch eigene Angaben ersetzt werden.

  **Syntax:**

  		ssh -p [PORT] [BENUTZERNAME]@[IP-ADRESSE]
    
  **Beispiel:** Befehlseingabe in der Windows PowerShell

  		PS C:\Users\MyUser> ssh -p 22 MyAdmin@172.16.1.12
    
- Nach der Ausführung des Verbindungsbefehls durch Drücken der Eingabetaste wirst du aufgefordert, das Passwort des Administratorkontos einzugeben, mit dem du dich an der Konsole deines UGREEN-NAS anmelden möchtest.
	
		MyAdmin@172.16.1.12's password:

- Nach erfolgreicher Passworteingabe und anschließendem Drücken der Eingabetaste sollte nach einer kurzen Begrüßung und ggf. weiteren Informationen die Eingabeaufforderung bzw. der Prompt erscheinen.

		MyAdmin@UGREEN-NAS:~$

## Scriptdateien downloaden und Rechte einstellen.
Nun musst du eine UDEV-Regel-Datei und eine weitere Shell-Skript-Datei von diesem GitHub-Repository auf dein UGREEN-NAS herunterladen. Beginne mit dem UDEV-Regel-Datei, kopiere die folgende Befehlszeile in dein geöffnetes Terminalfenster und führe den Befehl aus.

	sudo curl -O https://raw.githubusercontent.com/toafez/UGREEN_autostart/refs/heads/main/scripts/99-usb-device-detection.rules -o /usr/lib/udev/rules.d/99-usb-device-detection.rules

Da der Befehl als Systembenutzer root ausgeführt werden muss (erkennbar am vorangestellten sudo-Befehl), wirst du ein weiteres Mal nach einem Passwort gefragt. Hier gibst du das gleiche Passwort ein, das du bereits für die Anmeldung als Administrator verwendet hast.

Fahre nun mit der Shell-Skript-Datei fort, kopiere die folgende Befehlszeile in dein geöffnetes Terminalfenster und führe den Befehl ebenfalls aus.

	sudo curl -O https://raw.githubusercontent.com/toafez/UGREEN_autostart/refs/heads/main/scripts/usb-autostart-script-detection.sh -o /usr/local/bin/usb-autostart-script-detection.sh

Da du dich zuvor bereits als root angemeldet hast, musst du das Passwort nicht noch einmal eingeben.

Für diese Shell-Skript-Datei müssen noch bestimmte Zugriffsrechte vergeben werden. Daher bitte auch folgenden Befehl eingeben

	sudo chmod +x /usr/local/bin/usb-autostart-script-detection.sh
	
Damit ist die Installation zunächst abgeschlossen. Die Überwachung der externen USB Datenträger ist nun aktiv und die Terminalverbindung kann durch Eingabe des Befehls exit beendet werden.
	
## autostart.sh erstellen und mit Inhalten füllen
Wie bereits eingangs erwähnt, überwacht autostart ab sofort, ob ein externes USB Laufwerk an das UGREEN-NAS angeschlossen wurde und prüft, ob sich im Wurzelverzeichnis dieses externen Laufwerks bzw. auf den eingebundenen Partitionen eine Shell-Skript-Datei mit dem Namen autostart.sh befindet. Ist dies der Fall, wird der Inhalt der Shell-Skript-Datei ausgeführt, andernfalls wird die Überwachung beendet. An dieser Stelle bleibt es jedem selbst überlassen, welche Shell-Skripte er darüber ausführen möchte und welche Aufgaben damit verbunden sein sollen. Es gibt auch keine großen Anforderungen wie die Vergabe von Zugriffsrechten auf diese Datei, wichtig ist nur, dass der Name der Datei autostart.sh lautet.

## Beispiel: synchrone rsync Datensicherung auf einen externen Datenträger
Zur Veranschaulichung wird im Folgenden ein rsync-Skript zur synchronen Datensicherung interner Datenbestände auf einen externen Datenträger ausgeführt. 

- Schließe einen externen USB Datenträger an dein UGREEN-NAS an.
- Erstelle mit Hilfe der App TextEdit, die über das UGOS Pro App Center installiert werden kann, eine neue leere Datei mit dem Namen autostart.sh und speichere sie im Wurzelverzeichnis des externen Laufwerks bzw. auf einer dort eingebundenen Partition ab. 
- Öffne dieses GitHub-Repository in einem Browser deiner Wahl und wechsle in das Verzeichnis /scripts 

    ![10_UGREEN_autostart_raw](/images/10_UGREEN_autostart_raw.png)

- Klicke auf die Shell-Skript-Datei autostart.sh, um sich den Inhalt der Datei anzuzeigen zu lassen.

    ![11_UGREEN_autostart_raw](/images/11_UGREEN_autostart_raw.png)

- Klicke dann auf die Schaltfläche Raw in der Menüleiste oben rechts.

    ![12_UGREEN_autostart_raw](/images/12_UGREEN_autostart_raw.png)

- Klicke mit der rechten Maustaste in das Fenster und wähle aus dem sich öffnenden Kontextmenü "Alles auswählen" bzw. "Alles markieren". Klicke erneut mit der rechten Maustaste in das Fenster und wähle aus dem sich öffnenden Kontextmenü "Kopieren" und füge den kopierten Inhalt in die geöffnete Datei autostart.sh der App TextEdit ein.

    ![13_UGREEN_autostart_raw](/images/13_UGREEN_autostart_raw.png)

- Schau dir den Inhalt der Datei autostart.sh an, beachte dabei die Hilfetexte im Abschnitt Benutzereingaben und passe die Variablen für das Zielverzeichnis, die Datensicherungsquelle(n) usw. deinen Bedürfnissen an.

    ![14_UGREEN_autostart_raw](/images/14_UGREEN_autostart_raw.png)

- Speicher die Datei erneut ab und schließe sie.
- Entferne anschließend den externen Datenträger und steck ihn erneut ein. Das Datensicherungs-Skript sollte nun ausgeführt werden.

## Deinstallationshinweise
Aufgrund der oben genannten Sicherheitsmängel kann autostart bei Bedarf relativ einfach über die Kommandozeile deinstalliert werden. In erster Linie reicht es aus, die UDEV-Regel-Datei zu löschen, da dadurch die Überwachung beendet wird. Alternativ kann auch die Shell-Skript-Datei, die autostart.sh auf dem externen Datenträger ausführt, gelöscht werden.

**Löschen der UDEV-Regel-Datei**
	
	sudo rm /usr/lib/udev/rules.d/99-usb-device-detection.rules

**Löschen der Shell-Skript-Datei**
	
	sudo rm /usr/local/bin/usb-autostart-script-detection.sh



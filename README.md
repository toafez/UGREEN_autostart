# autostart für externe Datenträger

**autostart** ermöglicht das **Ausführen von beliebigen Shell-Skript-Anweisungen**, die **nach** dem **Anschluss eines externen USB Datenträgers** an deine **UGREEN-NAS** automatisch ausgeführt werden. 

## Wie funktioniert autostart
Wird ein externer USB Datenträger an das **UGREEN-NAS** angeschlossen, wird dieser zunächst von **UGOS Pro** erkannt und in das System eingebunden (gemounted). Anschließend prüft **autostart**, ob sich im Wurzelverzeichnis des externen USB Datenträgers bzw. auf den eingebundenen Partitionen eine Shell-Skript-Datei mit dem Namen **autostart.sh** befindet. Ist dies der Fall, wird der Inhalt der Shell-Skript-Datei ausgeführt, andernfalls wird die Überwachung für diesen Datenträger beendet. Nach der Ausführung der Shell-Skript-Datei wird eine Protokolldatei mit dem Namen **autostart.log** im Wurzelverzeichnis des externen USB Datenträgers abgelegt.

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

## Skriptdateien downloaden und Rechte einstellen.
Nun musst du eine UDEV-Regeldatei, ein Überwachungsskript und ein Ausführungsskript von diesem GitHub-Repository auf dein UGREEN-NAS herunterladen.

- ### Die UDEV-Regeldatei

  Beginne mit der UDEV-Regel-Datei **99-usb-device-detection.rules**, kopiere die folgende Befehlszeile in dein geöffnetes Terminalfenster und führe den Befehl aus.

	  sudo curl -L https://raw.githubusercontent.com/toafez/UGREEN_autostart/refs/heads/main/scripts/99-usb-device-detection.rules -o /usr/lib/udev/rules.d/99-usb-device-detection.rules

  Da der Befehl als Systembenutzer root ausgeführt werden muss (erkennbar am vorangestellten sudo-Befehl), wirst du ein weiteres Mal nach einem Passwort gefragt. Hier gibst du das gleiche Passwort ein, das du bereits für die Anmeldung als Administrator verwendet hast.

- ### Das Überwachungsskript

  Fahre nun mit dem Überwachungsskript bzw. der Shell-Skriptdatei **usb-autostart-script-detection.sh** fort, kopiere die folgende Befehlszeile in dein geöffnetes Terminalfenster und führe den Befehl ebenfalls aus.

	  sudo curl -L https://raw.githubusercontent.com/toafez/UGREEN_autostart/refs/heads/main/scripts/usb-autostart-script-detection.sh -o /usr/local/bin/usb-autostart-script-detection.sh

  Da du dich zuvor bereits als root angemeldet hast, musst du das Passwort nicht noch einmal eingeben.

  Für das Überwachungsskript müssen noch bestimmte Zugriffsrechte vergeben werden. Daher bitte auch folgenden Befehl eingeben

	  sudo chmod +x /usr/local/bin/usb-autostart-script-detection.sh
	
  - #### Akustische Signalausgabe ein- bzw. ausschalten
    
    Standardmäßig ist die akustische Signalausgabe nach der Installation aktiviert. Dadurch erhältst du eine akustische Rückmeldung über den Status der aktuell ausgeführten Shell-Skriptdatei über den Lautsprecher deines UGREEN-NAS. Vor Beginn der Ausführung ertönt ein Signalton. Nach der Ausführung ertönt ein weiterer Signalton. Traten während der Ausführung Probleme auf, ertönt als Rückmeldung ein dreifacher Signalton.
    - **Ausschalten der akustischen Signalausgabe**
      
           sudo sed -i 's/signal="true"/signal="false"/g' /usr/local/bin/usb-autostart-script-detection.sh

    - **Einschalten der akustischen Signalausgabe**
   
           sudo sed -i 's/signal="true"/signal="true"/g' /usr/local/bin/usb-autostart-script-detection.sh

  Wie bereits eingangs erwähnt, überwacht autostart ab sofort, ob ein externer USB Datenträger an das UGREEN-NAS angeschlossen wurde und prüft, ob sich im Wurzelverzeichnis dieses externen Datenträgers bzw. auf den eingebundenen Partitionen ein Ausführungsskript mit dem Namen **autostart.sh** befindet. Derzeit sollte noch kein Ausführungsskript mit diesem Dateinamen existieren, daher wird es nachfolgend erstellt. 

- ### Das Ausführungsskript (autostart.sh)
  Im weiteren Verlauf bleibt es jedem selbst überlassen, welche Shellskripte durch das Ausführungsskript ausgeführt werden und welche Aufgaben damit verbunden sein sollen. Es gibt auch keine großen Anforderungen wie die Vergabe von Zugriffsrechten auf diese Datei, wichtig ist nur, dass der Name der Datei immer **autostart.sh** lautet. 

  Da wir uns bereits auf der Konsole bzw. Kommandozeile befinden, ist es am sinnvollsten, das Ausführungsskript direkt über diesen Weg zu erstellen. Damit das Ausführungsskript am Ende auch an der richtigen Stelle landet, schließt man zunächst den gewünschten externen USB-Datenträger an das UGREEN-NAS an und wechselt kurz zu UGOS Pro.
  
  Nach der Anmeldung an UGOS Pro öffnet man die Dateien App (1) und klickt auf das Dreieck bzw. den Pfeil vor dem Menüpunkt "Externes Gerät" (2) auf der linken Seite, um das Menü nach unten aufklappen zu lassen. Es erscheint ein weiterer Menüpunkt (im Beispiel "Externer Speicher 1") und man klickt erneut auf das Dreieck bzw. den Pfeil vor dem Menüpunkt "Externer Speicher 1" (3), woraufhin sich ein weiterer Menüpunkt öffnet, der den Namen des angeschlossenen USB-Datenträgers trägt (in diesem Beispiel "USB-STICK"). Ein Klick mit der rechten Maustaste (4) öffnet ein Kontextmenü. Klicke auf Eigenschaften.

   ![20_UGREEN_autostart_create](/images/20_UGREEN_autostart_create.png)
 
  Es öffnet sich ein Popup-Fenster mit allgemeinen Informationen zum Datenträger sowie dem Speicherort, d.h. dem Pfad bzw. Einhängepunkt (Mountpoint) des externen Datenträgers (in diesem Beispiel lautet der Pfad /mnt/@usb/sdc1). Klicke auf das Kopieren-Symbol (1) rechts neben dem angezeigten Pfad, um diesen in die Zwischenablage zu kopieren.

  ![21_UGREEN_autostart_create](/images/21_UGREEN_autostart_create.png)

  Wechsle zurück zur Konsole bzw. Kommandozeile und gib den Befehl `cd` mit anschließendem Leerzeichen ein, **ohne** die Eingabetaste zu drücken. Klicke nun mit der rechten Maustaste hinter den Befehl `cd` und wähle aus dem Kontextmenü **Einfügen**, um den Pfad aus der Zwischenablage an dieser Stelle einzufügen. Das Ergebnis sollte wie folgt aussehen

      cd /mnt/@usb/sdc1

  Wenn du jetzt die Eingabetaste drückst, solltest du in das entsprechende Verzeichnis wechseln. Der Prompt sollte nun etwa so aussehen

      MyAdmin@UGREEN-NAS:/mnt/@usb/sdc1$

  Um ganz sicherzugehen, kannst du den Befehl `pwd` (Print Working Directory) eingeben, um dir das aktuelle Verzeichnis anzeigen zu lassen.

      MyAdmin@UGREEN-NAS:/mnt/@usb/sdc1$ pwd
      /mnt/@usb/sdc1

  Du befindest dich nun im Wurzelverzeichnis deines USB-Datenträgers. Hier hast du zwei Möglichkeiten: Entweder du erstellst eine leere Skriptdatei mit dem Namen **autostart.sh** und füllst sie mit eigenen Inhalten. Oder du lädst mein nachfolgendes Beispielskript von GitHub herunter, um eine **Synchrone Datensicherung mit optionalem Löschschutz auf einen externen Datenträger** durchzuführen. Dazu kannst du folgenden Befehl ausführen:

      curl -L -O https://raw.githubusercontent.com/toafez/UGREEN_autostart/refs/heads/main/scripts/autostart.sh

  Damit ist die Installation abgeschlossen. Die Überwachung der externen USB Datenträger ist nun aktiv und die Terminalverbindung kann durch Eingabe des Befehls `exit` beendet werden.

      MyAdmin@UGREEN-NAS:/mnt/@usb/sdc1$ exit

  Den Inhalt der Skriptdatei **autostart.sh** kann man sich nun mit der **TextEdit** App bearbeitet werden, die über das **UGOS Pro App Center** installiert werden kann. Beachte dabei in jedem Fall die **Hilfetexte** im Abschnitt Benutzereingaben und passe die Variablen für das Zielverzeichnis, die Datensicherungsquelle(n) usw. deinen Bedürfnissen an.

  ![14_UGREEN_autostart_raw](/images/14_UGREEN_autostart_raw.png)

  Nachdem du alle Anpassungen ausgeführt hast, speichere die Datei ab und schließe die TextEdit-App.

   Entferne anschließend den externen Datenträger, indem du in der **Dateien**-App einen Rechtsklick auf den Menüeintrag **Externer Speicher 1** (gemäß diesem Beispiel) ausführst. Wähle im sich öffnenden Kontextmenü den einzigen auswählbaren Punkt **Entfernen** aus und ziehe den USB-Datenträger von deinem UGREEN-NAS ab. Stecke ihn anschließend erneut ein. Das Datensicherungs-Skript sollte nun ausgeführt werden. Beachte dabei das mitlaufende Protokoll **autostart.log**, das während der Datensicherung im Wurzelverzeichnis des externen USB-Datenträgers angelegt wird.

## Deinstallationshinweise
Aufgrund der oben genannten Sicherheitsmängel kann autostart bei Bedarf relativ einfach über die Kommandozeile deinstalliert werden. In erster Linie reicht es aus, die UDEV-Regel-Datei zu löschen, da dadurch die Überwachung beendet wird. Alternativ kann auch die Shell-Skript-Datei, die autostart.sh auf dem externen Datenträger ausführt, gelöscht werden.

**Löschen der UDEV-Regel-Datei**
	
	sudo rm /usr/lib/udev/rules.d/99-usb-device-detection.rules

**Löschen der Shell-Skript-Datei**
	
	sudo rm /usr/local/bin/usb-autostart-script-detection.sh



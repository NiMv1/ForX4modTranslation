Deutsch (English below):

Mit dieser Mod werden Bergbau-, Gas Sammel- und Rohschrott Konverterstationen dem Spiel hinzugefügt. Sie sind bei fast allen Völkern erhältlich.
Um den großen Bedarf an Energiezellen zu befriedigen, habe ich mit Version 1.6 zusätzliche Stationen hinzugefügt, die ebendiese produzieren.
Seit Version 1.7 existieren die Rohschrott Konverterstationen und die großen Bergbaustationen produzieren nun wesentlich mehr.

===================================
Credits und besonderer Dank an:
===================================

- iforgotmysocks, Egosoft-Forum und Nexusmods: Update- und Benachrichtigungsroutine. Danke, dass ich sie mir abkupfern durfte.
- kuertee, Egosoft-Forum und Nexusmods: Optionen für Mods innerhalb des Spiels (Erweiterungsoptionen). Gleicher Grund. Danke schön!
- aladinaleks, Steam: Russische Übersetzung und allgemeine Unterstützung
- cyno op, Steam: Chinesische Übersetzung

===================================
Änderungsmöglichkeiten vom Spieler:
===================================

Wer die Mod ändern möchte, sollte den Dropbox-Download verwenden, dann entfällt das Entpacken mit dem XRCatTool 
Und das deabbonieren der Mod bei Steam und löschen der alten cat/dat-Dateien im Mod-Ordner, damit die richtigen Daten vom Spiel geladen werden.

Allgmeine Hinweise:
- Ich habe versucht, die wichtigste Datei, wares.xml, soviel wie möglich zu kommentieren, damit Änderungen für euch einfacher sind.
- Kommentare/Hinweise fangen mit einem "<!--" an und enden mit einem "-->". Alles davon eingeschlossen wird nicht vom Spiel verarbeitet.

A: Wer allgemein Änderungen an den Produktionsraten oder den Preisen der Stationen durchführen möchte:
1. ins Verzeichnis extensions\mining_station\libraries gehen
2. Die Datei "wares.xml" mit Editor, Notepad++ oder ähnlichem öffnen
3. Die zu ändernden Stellen nach belieben ändern. Wenn etwas nicht genügend beschrieben wurde, einfach bei Steam oder im Egosoft-Forum Bescheid geben.
4. Datei speichern, spielen und Spaß haben.

B: Wer Änderungen an dem Einfluss der Arbeitskraft durchführen möchte:
1. ins Verzeichnis extensions\mining_station\libraries gehen
2. Die Datei "wares.xml" mit Editor, Notepad++ oder ähnlichem öffnen
3. Bei der Produktionsmethode im folgenden Abschnitt den Wert von "product" anpassen. Der Wert gibt prozentual die Produktionssteigerung durch Arbeitskräfte an.

			<effects>
				<effect type="work" product="0.05"/>
			</effects>

4. ins Verzeichnis extensions\mining_station\assets\structures\production\macros gehen
5. Von der Station, die geändert werden soll, das dazugehörige *_macro.xml mit Editor, Notepad++ oder ähnlichem öffnen 
6. in der folgenden Zeile den Wert ändern. Der Wert steht für die benötigten Arbeitskräfte zur Produktionssteigerung.

			<workforce max="10" />

7. Datei speichern, spielen und Spaß haben.
______________________________________________________________________________________________________________________

English

This mod adds mining, gas collector and rawscrap converter stations to the game. They are buyable at nearly all factions.
In order to satisfy the great demand for energy cells, with version 1.6 I added additional stations that produce enery cells.
Since version 1.7, the raw scrap converter stations exist and the large mining stations now produce much more.

===================================
Credits and special thanks to:
===================================

- iforgotmysocks, Egosoft-forum and Nexusmods: Update and notification routine. Thank you for letting me crip and adapt your code!
- kuertee, Egosoft-forum and Nexusmods: Options for mods within the game (extension options). Same reason. Thank you very much!
- aladinaleks, Steam: Russian translation and general support
- cyno op, Steam: Chinese translation

====================================
Modification options for the player:
====================================

If you want to change the mod, you should use the Dropbox download, then you don't have to unpack it with the XRCatTool.
And unsubscribe the mod at Steam and delete the old CAT/Dat files in the mod folder, so that the correct data is loaded by the game.

General notes:
- I tried to comment the most important file, wares.xml, as much as possible to make changes easier for you.
- Comments/notes start with a "<!--" and end with a "-->". Anything included will not be processed by the game.

A: If you want to make general changes to the production rates or the prices of the stations:
1. go to the extensions\mining_station\libraries directory.
2. open the file "wares.xml" with editor, notepad++ or something similar
3. change the lines and parameters you want to change as you like. If something is not described enough, just let me know on Steam or in the Egosoft forum.
4. save the file, play and have fun.

B: If you want to make changes to the influence of the workforce:
1. go to the extensions\mining_station\libraries directory.
2. open the file "wares.xml" with editor, notepad++ or something similar
3. adjust the value of "product" for production method in the following section. The value indicates in percentage the increase in production by labor.

			<effects>
				<effect type="work" product="0.05"/>
			</effects>

4. go to the extensions\mining_station\assets\structures\production\macros directory.
5. from the station you want to change, open the associated *_macro.xml with Editor, Notepad++ or similar. 
6. in the following line change the value. The value represents the labor needed to increase production.

			<workforce max="10" />

7. save the file, play and have fun.
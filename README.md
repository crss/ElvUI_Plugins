# ElvUI Plugins

Persönliche, separat ladbare Erweiterungen für **WoW Forever**. Erstes Plugin:
**ElvUI Who's Who Bridge** (`ElvUI_WhosWho`, Version 0.1.0).

Im ElvUI-Chat ersetzt der WiW-Nickname den sichtbaren Absender vollständig. Der
Spielerlink zeigt weiter auf den echten Charakter. Die Farbe stammt vom aktuell
schreibenden Charakter; ein optionaler Stern markiert den sicher erkannten Main.
Nachrichtentext und WiW-Daten werden nicht verändert.

## Stand und Kompatibilität

Quellcodeprüfung: WoW Forever **1.60.1.70862 / Interface 16001**, ElvUI **v16.01**,
Who's Who **1.0.1**. Für diese installierte Kombination wurden automatische Tests
mit dem originalen ElvUI-Formatter bestanden. **Noch keine Ingame-Abnahme.**
Andere Addon-Versionen sind absichtlich deaktiviert, bis Hook und Schema erneut
geprüft wurden. Retail/Classic werden nicht unterstützt. Fehlende Addons lassen
die Bridge ohne Eingriff in den Chat laden.

## Installation

1. WoW beenden. Den Ordner `ElvUI_WhosWho` aus diesem Repo nach
   `World of Warcraft/_forever_/Interface/AddOns/ElvUI_WhosWho` kopieren.
2. Darin müssen direkt `ElvUI_WhosWho.toc`, `Resolver.lua` und `Bridge.lua` liegen,
   ohne einen zusätzlichen verschachtelten Ordner.
3. ElvUI, ElvUI Chat, Who's Who und die Bridge in der Addon-Auswahl aktivieren.
4. Einloggen; `/wiwbridge status` sollte `ready` und `errors=0` melden. Danach
   die [Testmatrix](docs/QA.md) durchgehen. Bei einem Update reicht `/reload`.

Der Repo-Hauptordner gehört **nicht** komplett in AddOns. Keine Dateien von ElvUI
oder WiW überschreiben. Die Bridge benötigt keine zusätzlichen Bibliotheken.

## Bedienung und Deaktivierung

| Befehl | Wirkung |
| --- | --- |
| `/wiwbridge status` | Zustand, Addon-Versionen, Fehlerzähler; keine Identitäten |
| `/wiwbridge on` / `off` | Neue Zeilen mit/ohne Ersetzung; dauerhaft gespeichert |
| `/wiwbridge star on` / `star off` | Main-Stern ein-/ausschalten (Standard: aus) |
| `/wiwbridge refresh` | WiW-Index sofort neu lesen |

Bereits dargestellte Zeilen bleiben stehen. Vollständig deaktivieren: Bridge in
der Addon-Auswahl ausschalten und `/reload`. Zur Deinstallation nur den Ordner
`ElvUI_WhosWho` löschen; optional die zugehörige SavedVariables-Datei
`ElvUI_WhosWho.lua` entfernen. **Nie `WhosWho.lua` löschen**: dort liegen die
WiW-Identitäten. Die Bridge speichert selbst nur `enabled` und `mainStar`.

## Grenzen und Fallbacks

- Ausschließlich ElvUIs normale Spieler-Chattypen, einschließlich Emotes und
  Whispers. Battle.net, Discord, Communities, Monster und Sondermeldungen bleiben
  unangetastet. Historische Zeilen nur mit noch verlässlich auflösbarer GUID.
- Unbekannte, widersprüchliche, veraltete, unbestätigte oder geschützte Identitäten
  bleiben unverändert. `confirmed`, manuell `added` und `guild` werden akzeptiert;
  `listed`/`relayed` bewusst nicht. Es gibt keine Suche nach Anzeigenamen.
- WiW hat keine öffentliche Resolver-API. Der lesende Adapter verwendet das
  geprüfte Live-Schema `WhosWhoDB.global`; Details in [Discovery](docs/DISCOVERY.md).
- Ein flüchtiger GUID-Index wird jede Sekunde außerhalb der Nachrichtenverarbeitung
  neu aufgebaut. Neue Zuordnungen/Konflikte erscheinen spätestens beim nächsten
  Tick; entfernte oder ersetzte Einträge werden sofort verworfen. Bei mehr als
  50.000 geprüften Einträgen bleibt der Index leer. Keine persistierte Kopie.
- Fehlende Klasseninfo: Nickname ohne eigene Farbmarkierung in normaler Chatfarbe.
  Main-Klasse wird nie als Ersatz verwendet.
- Der Stern nutzt die echte eigene Main-GUID, die signierte globale Main-GUID oder
  den gepflegten Main einer manuellen Identität. Ein bloßer Gilden-Anzeigemain
  erhält keinen Stern.
- WiWs eigener Senderfilter wird vom geprüften ElvUI-Formatter nicht aufgerufen:
  er kann anbleiben. Andere Formatierer können den Wrapper überschreiben oder die
  Anzeige erneut ändern; nach Addon-Updates und mit solchen Plugins neu testen.

## Prüfung und Quellen

Automatische Tests mit synthetischen Daten unter Lua 5.1 und 5.4:

```powershell
python -m pip install --target .test-tools -r tests/requirements.txt
python tests/run.py
# Optional: zusätzlich die lokal installierte ElvUI-Funktion direkt prüfen
python tests/run.py --elvui-chat 'C:/Games/World of Warcraft/_forever_/Interface/AddOns/ElvUI/Game/Shared/Modules/Chat/Chat.lua'
```

[QA und offene Ingame-Abnahme](docs/QA.md) ·
[Quellen, Versionen und Integrationsentscheidung](docs/DISCOVERY.md) ·
[Zielbild in Notion](https://app.notion.com/p/412784d57d1a81b09f3ef6b43823df91) ·
[Linear-Projekt](https://linear.app/elvui-plugins/project/01-whos-who-elvui-chat-bridge-3863a7f03ac1)

Keine SavedVariables, privaten Identitäten oder Accountdaten ins Repo kopieren.
Dies ist ein Entwicklungsstand für lokale Nutzung, kein öffentlicher Addon-Release.

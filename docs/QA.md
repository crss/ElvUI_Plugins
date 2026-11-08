# ELV-10: Testprotokoll und Ingame-Abnahme

Stand: 08.11.2026. Alle Identitäten im automatischen Test sind frei erfunden.
Versionen und Quellen: [Discovery](DISCOVERY.md).

## Automatische Ist/Soll-Ergebnisse

`python tests/run.py --elvui-chat <installierte Chat.lua>`: **79 Assertions je
Lua 5.1 und Lua 5.4 bestanden**, einschließlich der unverändert aus der lokalen
ElvUI-Datei geladenen `MessageFormatter`-Funktion. Game-APIs sind simuliert.
Ohne `--elvui-chat` laufen die unabhängigen Resolver-/Wrapper-Tests.

| Fall | Soll | Ist |
| --- | --- | --- |
| Krieger-Main / Magier-Twink | Buddy, jeweils eigene Klassenfarbe | Bestanden |
| Main-Stern an/aus, echter Main / Twink / Gildenmain | Nur wahrer Main mit aktivierter Option | Bestanden |
| Unbekannte / doppelte GUID / Secret-GUID | Originalanzeige | Bestanden |
| Listed / relayed / outdated / noIdentity | Keine Ersetzung | Bestanden |
| Manueller Link / eigener verknüpfter Charakter | Nickname/Default-Mainname | Bestanden |
| Live-Override / gelöschter Eintrag / neues Schema | Neue Anzeige / Fallback / Fallback | Bestanden |
| Markup-Injektion im Nickname | Originalanzeige | Bestanden |
| Keine Klasse | Nickname ohne eigene Farbmarkierung | Bestanden |
| API-Fehler | Originalformatter einmal aufrufen, Nachricht erhalten | Bestanden |
| 1.000 schnelle Nachrichten, globale Tabelleniteration gesperrt | Kein Vollscan im Chat-Hotpath | Bestanden |
| Argumente mit nils, History, weitere Rückgabewerte | Unverändert weitergeben | Bestanden |
| Fehlende Addons / unbekannte Version / deaktivierter Chat | Kein Wrapper/Timer | Bestanden |
| Gilde, Say/Yell, Whisper in/out, Party, Raid, Officer, Emote | Nickname; Original-Linkziel und Nachricht bytegleich | Bestanden am echten Formatter |
| Text-Emote mit erneutem Sendernamen im Text | Nur Sender-Platzhalter ersetzt | Bestanden am echten Formatter |
| BN-/Monster-Chat | Original | Bestanden am Wrapper |

Diese Tests belegen Daten-/Formatierungsverhalten; echte UI-Interaktionen,
geschützte WoW-Werte und Laufzeitlast im Zielclient werden damit nicht abgenommen.

## Reproduzierbarer Installations-/Reload-Smoke-Test

**Noch nicht ausgeführt:** Spiel war bei der Entwicklung nicht gestartet; das
Plugin wurde nicht ungefragt in die aktive Addon-Installation kopiert.

1. Installation nach [README](../README.md); versionsgleichen Client starten.
2. Lua-Fehleranzeige aktivieren: `/console scriptErrors 1`, danach `/reload`.
3. `/wiwbridge status`: `ready`, `enabled=true`, `errors=0`; Versionen notieren.
4. Eine bekannte WiW-Identität mit zwei bestätigten Charakteren unterschiedlicher
   Klassen verwenden; Nickname in WiW setzen. Nach maximal einer Sekunde chatten.
5. Jeden untenstehenden Fall ausführen und anonymisiertes Ist dokumentieren.
6. `/reload`: Einstellungen bleiben, Index wird neu aufgebaut, kein Lua-Fehler.
7. Bridge deaktivieren und erneut laden: bisherige ElvUI-Anzeige wiederhergestellt.
   Jeweils ElvUI/WiW deaktivieren und neu laden: keine Bridge-Fehler.

## Offene Ingame-Matrix

Für jeden Fall: verwendete Versionen, Ist/Soll, bestanden/fehlgeschlagen und ggf.
Fehlermeldung ohne Namen, GUIDs oder SavedVariables erfassen. Bei Defekten einen
Linear-Bug anlegen und mit ELV-10 verknüpfen. Derzeit **keine beobachteten Defekte**
aus einem Ingame-Lauf; alle folgenden Fälle sind **ungetestet**.

| Fall | Soll | Ingame-Ist |
| --- | --- | --- |
| Gilde, Gruppe, Raid, Say, Yell, Whisper in/out | Nur Nickname, eigene Klassenfarbe, Text gleich | Offen |
| Emote / Text-Emote, mehrere identische Namen im Text | Nur Absender ersetzt | Offen |
| Kanal, unbekannte Sonderformate, Communities/BN/Discord | Unterstützte Spielerlinks korrekt; andere Formate unverändert | Offen |
| Historische Zeilen mit/ohne verfügbare GUID | Mit Match korrekt, sonst Original | Offen |
| Main und Twink anderer Klasse | Gleicher Nickname; verschiedene richtige Farben | Offen |
| `/wiwbridge star on/off` und unsicherer Main | Stern nur für sicheren Main, standardmäßig aus | Offen |
| Linksklick / Rechtsklick auf Nickname | Whisper an echten Charakter / korrektes Kontextmenü | Offen |
| Shift-Klick, Reply, Whisper-Ziel und Chat-History | Echte Identität bleibt erhalten | Offen |
| Unbekannter/ambiger Sender, fehlende Klasse | Original bzw. ungefärbter Nickname | Offen |
| WiW-Chatdarstellung an/aus | Keine Doppelung im ElvUI-Chat, Standardchat unverändert | Offen |
| Andere Chat-Formatierer an/aus | Kein Konflikt; andernfalls Kombination dokumentieren | Offen |
| WiW-Nickname/Link/Main live ändern, neue Konflikte | Nach spätestens einem Tick aktualisiert | Offen |
| Reload / Login / Bridge aus / fehlende Addons | Stabiler Start und definierter Fallback | Offen |
| Geschützte/Secret-Werte, Kampf | Keine Bridge-Fehler/kein Chatverlust, Originalfallback | Offen |
| Schnelle Folge von 100+ Nachrichten | Keine Verluste, kein Scan pro Nachricht, errors=0 | Offen |

ELV-10 bleibt bis zur tatsächlichen Abnahme offen. ELV-6/7/8/9/11/12 sind
implementiert und automatisch geprüft, haben aber noch offene Ingame-Kriterien.

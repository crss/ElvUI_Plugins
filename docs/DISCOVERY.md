# ELV-5: Integrationsentscheidung

Untersuchung am 08.11.2026 anhand der tatsächlich installierten Addon-Quellen.
Kein laufender WoW-Prozess; kein Ingame-Ergebnis behauptet.

| Komponente | Lokal ermittelt | Prüfstatus |
| --- | --- | --- |
| WoW Forever | Wow.exe 1.60.1.70862 | Dateiversion gelesen |
| Interface | 16001 | WiW- und ElvUI-Manifest |
| ElvUI | v16.01 | Manifest und Chat.lua geprüft |
| Who's Who | 1.0.1 | Manifest, Store/Identity/People/Resolver/Chat geprüft |
| Bridge | 0.1.0 | Lua 5.1/5.4 und lokaler ElvUI-Formatter getestet |

## Hook

ElvUI `Game/Shared/Modules/Chat/Chat.lua`:

- `GetColoredName`, Zeile 1938: erzeugt nur den sichtbaren Namen; historische
  Anzeigen umgehen diese Funktion teilweise.
- `MessageFormatter`, Zeile 2103: nimmt `coloredName` getrennt von `arg2`
  (echter Sender) und `arg12` (GUID) entgegen.
- Zeilen 2140–2169: baut aus `coloredName` den Linktext und aus `unitName`/`arg2`
  den echten Player-Link. Daher ersetzt die Bridge ausschließlich `coloredName`
  am Eingang dieses Formatters. Alle anderen Argumente, einschließlich nils,
  History-Metadaten, Line-ID und Chat-Ziel, bleiben unverändert.
- `AddPluginMessageFilter`, Zeile 1929, bekommt am Ende nur `body`: nicht gewählt,
  weil Senderlink und Spielerlinks im Nachrichtentext nicht sicher trennbar sind.
- Der ElvUI-Formatter ruft WiWs `ChatFrameUtil.AddSenderNameFilter` nicht auf.
  Keine globale Chat-Filter-Registrierung; keine Änderung der Blizzard-Anzeige.

Es gibt keinen passenden öffentlichen ElvUI-Hook mit Ersetzungsrückgabe und allen
Senderdaten. Gewählt ist deshalb ein enger Wrapper einer internen Methode;
`hooksecurefunc` kann Argumente/Rückgaben nicht ersetzen. Risiko: andere Plugins
oder ein Upstream-Update können diese Methode überschreiben. Der Adapter prüft
Addon-Versionen und Fähigkeiten; unbekannte Versionen greifen nicht ein.
Jeder Bridge-Formatierungsfehler fällt auf den Originalnamen zurück. Die originale
ElvUI-Funktion wird genau einmal mit allen ursprünglichen Argumenten aufgerufen.

## WiW-Leseweg

WiWs `Core/Resolver.lua` arbeitet im privaten Addon-Namespace; keine exportierte
API entdeckt. Kein Zugriff über Debug-Upvalues, keine Änderungen an WiW.

`Core/Store.lua` erstellt mit AceDB `WhosWhoDB`; `db.global` ist laut mitgeliefertem
`Libs/AceDB-3.0/AceDB-3.0.lua` Zeilen 223–227 dieselbe Tabelle wie `sv.global`.
Die Bridge liest ausschließlich die geprüften Anzeige-/Zuordnungsfelder:

- `global.identity`: eigene `chars[guid].linked`, `removedAt`, `main`, `nickname`.
- `global.people`: `chars[guid]`, `state`, `outdated`, `customNickname`, `nickname`,
  `main` sowie nötigenfalls `signedRecord.main`/`signedRecord.chars[main].name`.
- `global.noIdentity[guid]`: expliziter Ausschluss veralteter Zuordnungen.
- `global.addonVersion`: Schema-Grenze 1.0.1.

Nickname-Priorität entspricht `People.Nickname`/`People.IdentityNickname` und
`Identity.Nickname`: lokaler Override, Identity-Nickname, Main-Name. Abweichend
vom großzügigeren WiW-Resolver werden unbestätigte `listed`/`relayed` und
`outdated` zurückgewiesen. Widersprüchliche GUIDs sind ungelöst. Kein Name-/Realm-
Fallback: Forever-Namen und Regeln erlauben keine verlässliche Ableitung aus
Anzeigenamen allein. Main-Erkennung verwendet keine Nickname-Gleichheit.

Ein Timer baut einen begrenzten, flüchtigen Index pro Sekunde. Pro Nachricht gibt
es nur GUID- und Live-Referenzprüfungen; kein Vollscan. Neue Konflikte können bis
zum nächsten Tick unerkannt bleiben. Live-Entfernung, Austausch, Statusänderung,
Nickname-Änderung und `noIdentity` werden sofort berücksichtigt. `/wiwbridge refresh`
erzwingt einen Neuaufbau. Ein Reload verwirft alle Indizes.

## Klassen und Sonderfälle

`GetPlayerInfoByGUID(arg12)` liefert die Klasse des aktuellen Senders. ElvUIs
`E:ClassColor` respektiert dessen Farbpalette. Die Farbe endet im Linktext mit
`|r`; keine eigene Farbe bei fehlender Klasse. Secret-Werte werden vor String-
Operationen geprüft; unerwartete Strukturen/API-Fehler sind zusätzlich isoliert.
Nickname-Markup (`|`, Steuerzeichen, Klammern) wird nicht übernommen.

Nur die explizite Spieler-Chattypenliste wird bearbeitet. Emotes nutzen ElvUIs
unveränderte native Sender-Platzierung; spätere gleiche Namen im Text bleiben
unangetastet. Battle.net, Communities, Discord, Monster und neue unbekannte
Chattypen fallen unverändert durch. Geschichte ohne verlässliche GUID bleibt
unverändert. Tatsächliche Klick-/Whisper-Aktionen und Secret-Verhalten im Client
sind noch manuell zu prüfen: [QA](QA.md).

## Quellen und Fingerabdrücke

Upstream: [ElvUI](https://github.com/tukui-org/ElvUI),
[Who's Who](https://github.com/yannlugrin/WhosWho). Maßgeblich waren die lokalen
Installationsdateien unter `_forever_/Interface/AddOns`, nicht der möglicherweise
abweichende aktuelle Upstream-Branch. Keine Fremdquellen werden im Repo kopiert.

SHA-256 der lokal geprüften Dateien (vor Implementierung):

| Datei | SHA-256 |
| --- | --- |
| ElvUI `Game/Shared/Modules/Chat/Chat.lua` | `F4E802A9238B0B261F2EF7AEEF8CD8715111A0A18E77E5C886D22685109ED7A7` |
| WiW `Core/Store.lua` | `5EB4548BD1ADDBBD5264F2B50F25A87EA914B8CB31CFB7B9B3065671843B98E8` |
| WiW `Core/People.lua` | `F636393749AE16A900E266064C2639552F243D2661616BB1DB62F014CFE38A6B` |
| WiW `Core/Identity.lua` | `ADB6F4F217911BD69E50C1166BD0A3E2E2DE7B29A3B2B3E3613357C9ADB216D2` |
| WiW `UI/Decorations/Chat.lua` | `D42D9BF0CCDE2829B5AED792C53CED9D697733A7B2E7E0270771EB71E60BBF62` |

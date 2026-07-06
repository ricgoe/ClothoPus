#set text(lang: "de")
#set par(leading: 1.3em)
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 3cm, right: 3cm),
)
#let fig(img, title, source, ..args) = block(
  breakable: false,
  [
    #figure(
      image(img, ..args),
      caption: [#title],
    )
    #v(-0.4em)
    #text(size: 9pt, fill: gray)[Quelle: #source]
    #v(1em)
  ],
)
#set text(size: 12pt)
#set par(
  leading: 1.3em,
  justify: true
)
#show heading: set block(above: 1.2em, below: 0.6em)
#show heading.where(level: 1): set block(above: 2em, below: 1.5em)  
#show heading.where(level: 2): set block(above: 2em, below: 1.2em) 
#show heading.where(level: 3): set block(above: 2em, below: 1.2em)  
#align(center)[
  #v(5cm)

  #text(size: 13pt, tracking: 0.25em)[Projektbericht]

  #v(0.35cm)
  #line(length: 70%, stroke: 0.6pt)

  #v(0.8cm)
  #text(size: 18pt, weight: "bold")[Clothopus]

  #v(0.8cm)
  #line(length: 70%, stroke: 0.6pt)

  #v(1.2cm)

  #text(size: 11pt)[
    *Modul:* Smart Systems II \
    *Dozent:* Prof. Dr.-Ing. Michael Protogerakis \
    *Semester:* Wintersemester 2025/26
  ]

  #v(0.8cm)
  *erarbeitet von*
  #table(
    columns: 2,
    column-gutter: .5cm,
    stroke: none,
    align: (left, ),


    [Richard Bihlmeier], [939194],
    [Jannis Bollien], [940810],
    [Emil Ötting], [934966],
  )


  #v(2cm)

  Hochschule Düsseldorf \ Fachbereich Elektro- & Informationstechnik
]
#pagebreak()
= Präambel

Der Name „ClothoPus“ ist aus einer symbolischen Verbindung zweier Begriffe entstanden.
„Clotho“ entstammt der griechischen Mythologie und bezeichnet eine der drei Moiren, die als Schicksalsgöttinnen den Lebensfaden der Menschen spinnen. In Anlehnung an dieses Motiv steht Clotho sinnbildlich für den Faden als zentrales Element des Systems. Im Kontext des Projekts entspricht dieser Faden dem 3D-Druck-Filament als grundlegendem Fertigungsmaterial.

Der zweite Bestandteil „Pus“ leitet sich vom Maskottchen der Druckmanagement-Software OctoPrint ab, dem Oktopus. Da das entwickelte System direkt in OctoPrint integriert ist, stellt dieser Namensbestandteil die technische und funktionale Verbindung zur Softwareplattform dar.

Aus der Kombination beider Begriffe entstand die Bezeichnung „ClothoPus“.

#set align(center)
#v(20pt)
#figure(
 image("assets/image-1.png"), caption: [ClothoPus Maskottchen.]
)<mascot>

#set align(left)

#pagebreak()

// Inhaltsverzeichnis
#set page(numbering: "1")
#outline(
  title: "Inhaltsverzeichnis", 
  indent: 1.5em
)

#pagebreak()

#outline(
  title: "Abbildungsverzeichnis", 
  target: figure.where(kind: image),
  indent: 1.5em
)
#pagebreak()

= Einleitung

== Motivation

Im Bereich der privaten Nutzung von 3D-Druck-Techniken, insbesondere Fused Deposition Modelling (FDM) und Fused Layer Modelling (FLM), stellt Filament das zentrale Fertigungsmaterial dar  .  
Ein wiederkehrendes Problem sowohl in der eigenen praktischen Arbeit als auch innerhalb der Community ist die regelmäßige und umständliche Überprüfung des verfügbaren Filamentbestands @2ProblemeBestandCheck.

Die Bestimmung der Restmenge erfordert typischerweise das Entnehmen der Filamentrolle aus dem Drucker, eine separate Gewichtsmessung sowie die manuelle Subtraktion des Eigengewichts der Spule. Anschließend muss das Filament erneut montiert und korrekt eingeführt werden @3GewichtGrundlage.
Insbesondere bei Druckvorgängen mit mehreren Materialwechseln oder bei der Nutzung mehrerer Drucker entsteht hierdurch ein erheblicher Zeitaufwand.

Im vorherigen Entwicklungsstand von _ClothoPus_ wurde dieses Problem durch ein System adressiert, das Filamentrollen über NFC-Tags identifiziert und den Materialbestand über Wägezellen erfasst. Die Messdaten wurden zentral verarbeitet und in OctoPrint dargestellt. Dadurch konnte bereits eine deutliche Reduktion manueller Kontrollschritte erreicht werden.

Während der weiteren Entwicklung zeigte sich jedoch, dass die ursprüngliche Architektur in zwei wesentlichen Punkten eingeschränkt war. Zum einen begrenzte die zentrale Anbindung der einzelnen Filament-Stacks über proprietäre Anschlüsse an GPIO-Pins die maximale Anzahl parallel nutzbarer Stacks. Im vorherigen Aufbau konnten dadurch nur bis zu fünf Stacks gleichzeitig betrieben werden. Zum anderen erwies sich die Gewichtsmessung über dauerhaft belastete Wägezellen als problematisch, da die verwendeten HX711-basierten Messsysteme unter Dauerlast ein Kriechverhalten zeigten. Dies führte dazu, dass die Messwerte im Laufe der Zeit ungenauer wurden.

Vor diesem Hintergrund wurde _ClothoPus_ in der aktuellen Projektphase grundlegend weiterentwickelt.

== Zielsetzung

Ziel des Projekts war die Weiterentwicklung von _ClothoPus_ zu einem skalierbaren, dezentralen und netzwerkfähigen System zur automatisierten Filamentverwaltung.

Im Mittelpunkt standen drei zentrale Verbesserungen.
Erstens sollte die bisherige Begrenzung auf fünf Filament-Stacks aufgehoben werden. Statt einer zentralen GPIO-basierten Architektur sollte jeder Stack eine eigene intelligente Steuereinheit erhalten. Hierfür wurde in jedem Stack ein Olimex ESP32 PoE integriert. Dadurch werden sowohl Stromversorgung als auch Datenübertragung über Ethernet realisiert. Die Skalierung erfolgt somit nicht mehr über die Anzahl verfügbarer GPIO-Pins, sondern über einen PoE-fähigen Netzwerkswitch.

Zweitens sollte die bisherige Gewichtserfassung durch Wägezellen ersetzt werden. Da die dauerhaft belasteten Wägezellen langfristig ungenaue Messergebnisse lieferten, wurde ein alternatives Messprinzip auf Basis eines direkt durch das Filament angetriebenen Encoders entwickelt. Über die gemessenen Umdrehungen eines Odometer-Rades, dessen Durchmesser sowie die auf dem NFC-Tag gespeicherten Materialdaten wird der bisher verbrauchte Filamentanteil berechnet.

Drittens sollte die Softwarearchitektur offener gestaltet werden. Zwar bleibt OctoPrint zunächst weiterhin die primäre Benutzeroberfläche, jedoch stellt jeder ESP32-Stack über eine Microdot-basierte REST-API eigene Endpunkte bereit. Dadurch können neben OctoPrint auch beliebige andere Frontends oder Integrationsplattformen verwendet werden, beispielsweise proprietäre Anwendungen oder Home Assistant.

#pagebreak()

== Vorgehensweise

Das Projekt wurde erneut in einen Hardware- und einen Softwareanteil gegliedert.

Die Hardwareentwicklung umfasste den mechanischen und elektronischen Neuaufbau der Filament-Stacks. Jeder Stack wurde mit einem Olimex ESP32 PoE ausgestattet, der als dezentrale Steuereinheit dient. Zusätzlich wurde ein eigenentwickelter Aufnehmer mit zwei Zahnrädern konstruiert, über den das Filament direkt ein Encoder-Rad antreibt. Dadurch kann die durchlaufende Filamentlänge anhand der Encoder-Impulse bestimmt werden.

Die NFC-Hardware blieb gegenüber dem vorherigen Projektstand unverändert. Weiterhin kommt der PN5180 als NFC-Reader zum Einsatz. Die bereits im Vorjahr entwickelten Lese- und Schreibfunktionen wurden nicht funktional verändert. Stattdessen wurde der vorhandene Treiber auf MicroPython übertragen, um ihn direkt auf den ESP32-basierten Stacks ausführen zu können.

Die Softwareentwicklung konzentrierte sich auf die Portierung und Dezentralisierung der bisherigen Funktionalität. Auf jedem ESP32 läuft eine Microdot-Anwendung, die eine Flask-ähnliche REST-API bereitstellt. Über diese Schnittstelle können NFC-Blöcke gelesen und geschrieben, die Erreichbarkeit eines Stacks geprüft sowie der bisher berechnete Materialverbrauch abgefragt werden.

Durch diese Architektur wurde das System von einer zentral gesteuerten Lösung zu einem verteilten Netzwerk aus eigenständigen Filament-Stacks weiterentwickelt. 

Die Umsetzung erfolgte iterativ: Zunächst wurden einzelne Hardware- und Softwarekomponenten getrennt getestet, anschließend wurden Encoder-Messung, NFC-Kommunikation und REST-Schnittstelle zu einem voll funktionsfähigen Gesamtsystem integriert.

#pagebreak()

= Projektmanagement

== Work Breakdown Structure

Zur strukturierten Planung und Durchführung des Projekts wurde eine Work Breakdown Structure (WBS) verwendet, welche das Gesamtvorhaben in klar definierte Arbeitspakete unterteilte.

Auf oberster Ebene wurde das Projekt in die Bereiche Analyse, Hardwareentwicklung, Softwareentwicklung, Integration und Test gegliedert. Die Analysephase diente der Bewertung des vorherigen Systemstands sowie der Identifikation technischer Schwachstellen. Hierbei wurden insbesondere die begrenzte Skalierbarkeit der GPIO-basierten Architektur und die langfristige Ungenauigkeit der Wägezellen als zentrale Problemstellen identifiziert.

Im Bereich der Hardwareentwicklung umfassten die Arbeitspakete die Integration des Olimex ESP32 PoE in jeden Stack, die Entwicklung des mechanischen Encoder-Aufnehmers, die Anpassung der Strom- und Datenversorgung über Power over Ethernet sowie die Integration des weiterhin verwendeten PN5180-NFC-Readers.

Die Softwareentwicklung gliederte sich in die Portierung des PN5180-Treibers nach MicroPython, die Implementierung der Encoder-Auswertung, die Berechnung des Filamentverbrauchs, die Entwicklung der Microdot-REST-API sowie die Anbindung an die bestehende OctoPrint-Integration.

Als wesentliche Meilensteine wurden die erfolgreiche Inbetriebnahme eines ESP32-PoE-Stacks, das zuverlässige Auslesen eines NFC-Tags, die stabile Erfassung von Encoder-Impulsen, die Bereitstellung der REST-Endpunkte und schließlich die funktionsfähige Gesamtdemonstration definiert.

== Organisational Breakdown Structure

Die Organisationsstruktur des Projekts war als kleines, gleichberechtigtes Teammodell ausgelegt.

Im Unterschied zum vorherigen Projekt war Emil in der Weiterentwicklung nicht beteiligt. Die Umsetzung erfolgte durch Richard und Jannis. Richard übernahm schwerpunktmäßig die Hardwareentwicklung und Jannis den Softwareanteil.

Durch die kleine Teamgröße konnten Abstimmungen direkt und effizient erfolgen. Strategische und technische Entscheidungen wurden gemeinsam getroffen. Die klare Aufteilung in Hardware- und Softwareverantwortung ermöglichte paralleles Arbeiten zum Beispiel mit "Dummy Treibern", die erwartete Hardwarerückgabewerte simulierten. Regelmäßige Integrationsschritte stellten sicher, dass beide Entwicklungsbereiche kontinuierlich zusammengeführt werden konnten.

== Projektplan

Das Projekt begann im Oktober 2025 und wurde im Januar 2026 abgeschlossen.

Die zeitliche Planung orientierte sich an den definierten Hauptphasen der WBS.  

Während der Umsetzung traten mehrere technische Herausforderungen auf, die Einfluss auf den Projektverlauf hatten.  
Zentrale Problemstellen waren hardwareseitig die Planung und Iterationsstufen des Kailh Encoder.
Kernherausforderung der Softwareentwicklung war die inkonsitente Implementierung von Basismodulen zwischen upstream Python und Micropython.

Diese Herausforderungen erforderten zusätzliche Entwicklungsarbeit, konnten jedoch innerhalb des vorgesehenen Projektzeitraums gelöst werden.

Der funktionale Projektumfang blieb stabil. 
Die strategische Entscheidung, zunächst eine stabile Integration mit OctoPrint zu realisieren, ermöglichte eine klar abgegrenzte Demonstrationsfähigkeit des Systems.

== Vorgehensmodell in der Entwicklung

Die Projektumsetzung folgte einem hybriden Vorgehensmodell. Auf Makroebene wurde eine phasenorientierte Struktur gewählt, die sich in Analyse, Entwurf, Implementierung, Integration und Test unterteilte. Auf Mikroebene erfolgte die Entwicklung inkrementell.

Einzelne Funktionen wurden zunächst separat umgesetzt und getestet. Dazu gehörten die Netzwerkkommunikation des ESP32, die Microdot-basierte REST-API, die Auswertung des Encoders und die Kommunikation mit dem PN5180. Anschließend wurden diese Komponenten schrittweise zusammengeführt.

Die größte technische Herausforderung bestand in der Ablösung der bisherigen zentralen Architektur. Da jeder Stack nun eigenständig arbeitet, mussten Stromversorgung, Datenkommunikation und Sensorverarbeitung vollständig dezentralisiert werden. Gleichzeitig musste sichergestellt werden, dass die neue Architektur weiterhin mit der bestehenden OctoPrint-Integration kompatibel bleibt.

Positiv hervorzuheben ist bei dieser Weiterentwicklung die agilität aufgrund der kleinen Teamgröße. Allerdings fällt pro Teammitglied mehr arbeit an. Hohe auslastung.

#pagebreak()

= Entwurf und Implementierung

== Produkt und Vernetzung

_Clothopus_ ist als modulares, vernetztes Smart-System zur automatisierten Filamentverwaltung im Bereich des privaten und semiprofessionellen 3D-Drucks konzipiert.  
Das Produkt dient der kontinuierlichen Identifikation und *Längenerfassung* mehrerer Filamentrollen und stellt diese Informationen externen Druckmanagementsystemen zur Verfügung.

#figure(
 image("assets/image-5.png"), caption: [Aufbau des Gesamtsystems.]
)<systemview>

Im Gegensatz zum vorherigen Aufbau existiert keine zentrale GPIO-basierte Steuereinheit mehr, an die alle Stacks direkt angeschlossen werden müssen. Stattdessen verfügt jeder Stack über einen eigenen Olimex ESP32 PoE. Dieser übernimmt lokal die Sensordatenerfassung, die NFC-Kommunikation, die Berechnung des verbrauchten Filaments sowie die Bereitstellung der Daten über eine REST-Schnittstelle.

Die Stromversorgung und Datenübertragung erfolgen über Power over Ethernet. Dadurch genügt ein einziges Netzwerkkabel pro Stack, um sowohl Energie als auch Kommunikation bereitzustellen. Die Skalierung des Systems erfolgt somit über einen PoE-fähigen Netzwerkswitch. 

Diese Architektur stellt eine wesentliche Verbesserung gegenüber dem vorherigen System dar. Während zuvor maximal fünf Stacks aufgrund der begrenzten Anzahl verfügbarer GPIO-Pins betrieben werden konnten, lassen sich nun in einem üblichen IPv4-/24-Subnetz theoretisch bis zu 253 Geräte adressieren @subnet. Durch größere Netzwerke, mehrere Subnetze oder angepasste Netzwerkkonfigurationen ist die Skalierung grundsätzlich nahezu unbegrenzt erweiterbar und lediglich durch die Verwendung von Switches und deren Anschlüssen begrenzt. 

OctoPrint bleibt zunächst weiterhin die primäre Benutzeroberfläche für die Darstellung der Filamentinformationen und wird auf einem Raspberry Pi gehosted.

Gleichzeitig ist das System durch die REST-API jedoch deutlich offener. Jedes beliebige Frontend kann die bereitgestellten Daten abrufen und weiterverarbeiten. Neben OctoPrint wären dadurch beispielsweise eigene proprietäre Anwendungen, Web-Dashboards oder Integrationen in Home Assistant möglich.

== Technologie und Daten

=== Dezentrale Steuereinheit

Als Recheneinheit jedes einzelnen Stacks kommt ein Olimex ESP32 PoE zum Einsatz.
Der Mikrocontroller übernimmt alle lokalen Aufgaben des Stacks. Dazu zählen die Kommunikation mit dem PN5180-NFC-Reader, die Auswertung des Encoders, die Berechnung des verbrauchten Materials sowie die Bereitstellung der REST-API.

#figure(
 image("assets/schachtel_offen_1.png", height: 340pt), caption: [Aufbau des Stacks.]
)<stackview>

Durch die Verwendung des ESP32 (seitlich in @stackview) wird jeder Stack zu einem eigenständigen Netzwerkteilnehmer. Dies reduziert die Abhängigkeit von zentraler Hardware erheblich und verbessert Wartbarkeit, Erweiterbarkeit und Skalierbarkeit des Gesamtsystems. So kann _ClothoPus_ nicht nur in Heimnetzwerken sondern auch in groß skalierten Industrie 4.0 (IOT) Netzwerken verwendet werden.

Die Nutzung von Power over Ethernet ist hierbei besonders vorteilhaft, da keine separate Stromversorgung pro Stack erforderlich ist. Versorgung und Kommunikation werden über dieselbe physische Verbindung realisiert.

=== NFC-Kommunikation

Zur Identifikation der Filamentrollen wird weiterhin der NFC-Reader PN5180 eingesetzt.
Der verwendete NFC-Chip bleibt damit gegenüber dem vorherigen Projektstand unverändert.

#figure(
 image("assets/stack_komplett.png", height: 340pt), caption: [Rückansicht Stack.]
)<stackkomplett>
#pagebreak()
Die bereits entwickelten Lese- und Schreibfunktionen wurden nicht verändert. Die wesentliche Weiterentwicklung bestand stattdessen darin, den vorhandenen Treiber auf MicroPython umzuschreiben. Dadurch kann die NFC-Kommunikation direkt auf dem ESP32 ausgeführt werden.

Über den NFC-Tag werden relevante Filamentdaten ausgelesen. Dazu gehören insbesondere Materialparameter wie Dichte und Filamentdurchmesser. Diese Informationen werden nicht nur zur Identifikation des Filaments genutzt, sondern auch direkt in die Berechnung des bisher verbrauchten Gewichts einbezogen.

=== Verbrauchsmessung über Encoder

Die bisherige Gewichtsmessung über Wägezellen wurde durch ein encoderbasiertes Messprinzip ersetzt.
Grund hierfür war das Kriechverhalten der zuvor eingesetzten HX710-basierten Waagensysteme. Da die Wägezellen dauerhaft durch die Filamentrollen belastet wurden, veränderten sich die Messwerte im Laufe der Zeit. Dies führte zu einer zunehmenden Ungenauigkeit der Gewichtserfassung.

Im neuen System wird der Materialverbrauch nicht mehr durch eine direkte Gewichtsmessung bestimmt, sondern aus der durchlaufenden Filamentlänge berechnet. Hierfür wurde ein eigener mechanischer Aufnehmer mit zwei Zahnrädern entwickelt. Das Filament treibt den Aufnehmer direkt an, wodurch die Bewegung auf ein Odometer-Rad übertragen wird. Die Drehbewegung wird durch einen Encoder erfasst.

Aus der Anzahl der Encoder-Impulse wird zunächst die zurückgelegte Filamentlänge berechnet. Anschließend wird über den Filamentdurchmesser die Querschnittsfläche bestimmt. Zusammen mit der Dichte des Materials ergibt sich daraus das verbrauchte Gewicht.

Die Berechnung erfolgt nach folgendem Prinzip:

```python
def weight_from_clicks(self, density: float, filament_diameter: float):
    o = ODOMETER_DIAMETER / 10
    f = filament_diameter / 10
    length = self.get_count() * (math.pi * o) / PER_ROTATION
    area = math.pi * (f / 2) ** 2
    return density * area * length
```

Der Odometer-Durchmesser und der Filamentdurchmesser werden hierbei von Millimetern in Zentimeter umgerechnet. Die Länge ergibt sich aus der Anzahl der gezählten Encoder-Schritte, dem Umfang des Odometer-Rades und der Anzahl der Encoder-Schritte pro Umdrehung. Die Querschnittsfläche des Filaments wird kreisförmig angenommen. Da die Dichte in Gramm pro Kubikzentimeter angegeben ist, ergibt sich das berechnete Ergebnis direkt als Masse in Gramm.

Die Materialdichte und der Filamentdurchmesser werden direkt vom NFC-Tag ausgelesen. Dadurch ist die Berechnung materialspezifisch und kann automatisch an unterschiedliche Filamente angepasst werden.

=== REST-API

Auf jedem ESP32 läuft eine Microdot-basierte REST-API.
Microdot stellt eine leichtgewichtige, Flask-ähnliche Anwendungsstruktur für MicroPython bereit und eignet sich dadurch für den Einsatz auf ressourcenbeschränkten Mikrocontrollern.

Die API bildet die zentrale Schnittstelle zwischen einem Stack und externen Anwendungen. Sie ermöglicht sowohl den Zugriff auf NFC-Daten als auch auf Status- und Verbrauchsinformationen.

Die implementierten Endpunkte sind:

`GET /blocks`
Dieser Endpunkt liest die Datenblöcke des NFC-Tags aus und stellt sie dem aufrufenden System zur Verfügung.

`POST /blocks`
Dieser Endpunkt ermöglicht das Schreiben von Datenblöcken auf den NFC-Tag.

`GET /reachable`
Dieser Endpunkt dient zur Prüfung, ob ein Stack im Netzwerk erreichbar ist. Dadurch können Frontends oder Integrationssysteme feststellen, welche Stacks aktuell verfügbar sind.

`GET /consumed`
Dieser Endpunkt gibt das bisher berechnete verbrauchte Filamentgewicht in Gramm zurück.

Durch diese Endpunkte entsteht eine klare, offene und leicht integrierbare Schnittstelle. Externe Systeme müssen nicht wissen, wie NFC-Kommunikation oder Encoder-Auswertung intern funktionieren. Sie können stattdessen über HTTP auf die abstrahierten Funktionen des jeweiligen Stacks zugreifen.

=== Connectivity

Die neue Connectivity-Architektur basiert vollständig auf Ethernet und IP-Kommunikation.
Jeder Stack ist über ein Netzwerkkabel mit einem PoE-fähigen Switch verbunden. Über dieses Kabel werden sowohl die Stromversorgung als auch die Netzwerkkommunikation realisiert.

Im Vergleich zur vorherigen proprietären Verkabelung ergeben sich dadurch mehrere Vorteile. Erstens reduziert sich der Verkabelungsaufwand, da keine getrennten Leitungen für Stromversorgung, Datenübertragung und Sensorsignale notwendig sind. Zweitens wird die mechanische Integration vereinfacht, da jeder Stack als eigenständige Einheit betrachtet werden kann. Drittens kann das System wesentlich einfacher erweitert werden, da neue Stacks lediglich an den Switch angeschlossen und im Netzwerk adressiert werden müssen.

Die Kommunikation zwischen Frontend und Stack erfolgt über standardisierte HTTP-Anfragen. Dadurch ist das System nicht an OctoPrint gebunden. OctoPrint kann weiterhin als Bedienoberfläche dienen, ist aber nicht zwingend erforderlich. Andere Softwarelösungen können dieselben REST-Endpunkte verwenden und die Daten in eigene Workflows integrieren.

== Aktoren und Ausgänge

Physische Aktoren sind im aktuellen Entwicklungsstand nicht vorgesehen.
Die Ausgabe der verarbeiteten Informationen erfolgt softwareseitig über die REST-API und zunächst über die bestehende OctoPrint-Integration.

Dem Nutzer können dort Informationen über die eingesetzten Filamente, deren NFC-Daten und den bisher berechneten Verbrauch angezeigt werden. Da die Daten über die einzelnen ESP32-Stacks bereitgestellt werden, ist die Darstellung jedoch nicht auf OctoPrint beschränkt. Zukünftige Benutzeroberflächen können die REST-API direkt nutzen und eigene Visualisierungen, Inventaransichten oder Automatisierungen umsetzen.

Insbesondere durch die Möglichkeit der Integration in Plattformen wie Home Assistant entsteht eine deutlich offenere Systemarchitektur. _ClothoPus_ kann dadurch nicht nur als OctoPrint-Erweiterung, sondern auch als allgemeines Smart-Inventory-System für Filamentrollen verstanden werden.

== Service und Unterstützung

_ClothoPus_ bleibt als offenes und erweiterbares System konzipiert.
Durch die Verwendung standardisierter Netzwerktechnik, einer HTTP-basierten REST-API und dezentraler ESP32-Stacks wird die Anpassbarkeit des Systems gegenüber dem vorherigen Stand deutlich erhöht.

Die Offenheit zeigt sich sowohl auf Hardware- als auch auf Softwareebene. Einzelne Stacks können unabhängig voneinander aufgebaut, getestet, ersetzt oder erweitert werden. Softwareseitig erlaubt die REST-API eine einfache Integration in unterschiedliche Frontends und Automatisierungssysteme.

Dadurch eignet sich das System nicht nur für den ursprünglichen Einsatz innerhalb von OctoPrint, sondern auch für weiterführende Anwendungen wie zentrale Filamentinventare, Druckfarm-Verwaltung oder Smart-Home-Integrationen. Die modulare Architektur erleichtert zudem zukünftige Erweiterungen, beispielsweise zusätzliche Sensorik, alternative Benutzeroberflächen oder eine automatisierte Bestandsverwaltung.

#pagebreak()

= Fazit und Ausblick

Das im Rahmen dieses Projekts weiterentwickelte System _ClothoPus_ erfüllt die gesetzten Anforderungen.
Es wurde ein vollständig funktionsfähiges, dezentrales und skalierbares System zur automatisierten Filamentverwaltung realisiert.

Gegenüber dem vorherigen Projektstand konnten zwei zentrale technische Schwachstellen behoben werden. Die zuvor durch GPIO-Pins begrenzte Skalierbarkeit wurde durch eine Netzwerkarchitektur mit ESP32-PoE-Stacks ersetzt. Jeder Stack arbeitet nun als eigenständiger Netzwerkteilnehmer und kann über einen PoE-fähigen Switch angebunden werden. Damit steigt die praktisch nutzbare Anzahl paralleler Stacks von zuvor fünf auf bis zu 253 Geräte in einem üblichen Subnetz. Durch angepasste Netzwerktopologien ist darüber hinaus eine nahezu unbegrenzte Erweiterung denkbar.

Auch die Messmethodik wurde grundlegend verbessert. Die bisher verwendeten Wägezellen zeigten unter dauerhafter Belastung ein Kriechverhalten, wodurch die Messgenauigkeit langfristig abnahm. Durch den Wechsel auf eine encoderbasierte Verbrauchserfassung wird der Materialverbrauch nun aus der tatsächlich durchlaufenden Filamentlänge berechnet. In Kombination mit den auf dem NFC-Tag gespeicherten Materialdaten, insbesondere Dichte und Filamentdurchmesser, kann daraus das verbrauchte Gewicht berechnet werden.

Die NFC-Funktionalität konnte erhalten bleiben. Der PN5180 wird weiterhin verwendet, wobei der bestehende Treiber auf MicroPython portiert wurde. Die bereits entwickelten Lese- und Schreibfunktionen blieben funktional unverändert.

Ein weiterer wesentlicher Fortschritt liegt in der neuen Softwarearchitektur. Auf jedem ESP32 läuft eine Microdot-basierte REST-API, über die NFC-Blöcke gelesen und geschrieben, die Erreichbarkeit geprüft und der bisherige Verbrauch abgefragt werden kann. Dadurch ist _ClothoPus_ deutlich offener als zuvor. OctoPrint bleibt zunächst als Benutzeroberfläche bestehen, ist aber nicht mehr zwingend notwendig. Proprietäre Frontends, Webanwendungen oder Plattformen wie Home Assistant können dieselben Schnittstellen verwenden.

Damit entwickelt sich _ClothoPus_ von einem lokal begrenzten, zentral gesteuerten Messsystem zu einer skalierbaren, verteilten Smart-Inventory-Lösung. Die aktuelle Version konnte vollständig funktionsfähig präsentiert werden und bildet eine stabile Grundlage für zukünftige Erweiterungen.

Zukünftige Ausbaustufen könnten insbesondere ein umfassendes digitales Filamentinventar, eine automatische Erkennung neu angeschlossener Stacks, eine zentrale Verwaltung mehrerer Drucker oder eine tiefere Integration in Smart-Home- und Druckfarm-Systeme umfassen. Durch die offene REST-Architektur sind diese Erweiterungen ohne grundlegende Änderung der Stack-Hardware realisierbar.

#pagebreak()
#show link: set text(hyphenate: true)
#bibliography(
  "literatur.bib",
  title: "Literaturverzeichnis",
  style: "ieee"
)

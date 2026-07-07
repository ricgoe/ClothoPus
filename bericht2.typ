#set text(lang: "de")
#set heading(numbering: "1.")
#set par(leading: 1.3em)
#set page(
  paper: "a4",
  margin: (top: 2.5cm, bottom: 2.5cm, left: 3cm, right: 3cm),
)
#set math.equation(numbering: "1.")
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
  #text(size: 18pt, weight: "bold")[ClothoPus II]

  #v(0.8cm)
  #line(length: 70%, stroke: 0.6pt)

  #v(1.2cm)

  #text(size: 11pt)[
    *Modul:* Smart Systems I \
    *Dozent:* Prof. Dr.-Ing. Michael Protogerakis \
    *Semester:* Sommersemester 2026
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
  )


  #v(2cm)

  Hochschule Düsseldorf \ Fachbereich Elektro- & Informationstechnik
]
#pagebreak()
= Präambel

Der Name „ClothoPus“ ist aus einer symbolischen Verbindung zweier Begriffe entstanden.
„Clotho“ entstammt der griechischen Mythologie und bezeichnet eine der drei Moiren, die als Schicksalsgöttinnen den Lebensfaden der Menschen spinnen. In Anlehnung an dieses Motiv steht Clotho sinnbildlich für den Faden als zentrales Element des Systems. Im Kontext des Projekts entspricht dieser Faden dem 3D-Druck-Filament als grundlegendem Fertigungsmaterial.

Der zweite Bestandteil „Pus“ leitet sich vom Maskottchen der Druckmanagement-Software OctoPrint ab, dem Oktopus.

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

#outline(
  title: "Gleichungsverzeichnis",
  target: math.equation.where(block: true),
  indent: 1.5em,
)
#pagebreak()

= Einleitung

== Motivation

Im Bereich der privaten Nutzung von 3D-Druck-Techniken, insbesondere Fused Deposition Modelling (FDM) und Fused Layer Modelling (FLM), stellt Filament das zentrale Fertigungsmaterial dar.  
Ein wiederkehrendes Problem sowohl in der eigenen praktischen Arbeit als auch innerhalb der Community ist die regelmäßige und umständliche Überprüfung des verfügbaren Filamentbestands @2ProblemeBestandCheck.

Die Bestimmung der Restmenge erfordert typischerweise das Entnehmen der Filamentrolle aus dem Drucker, eine separate Gewichtsmessung sowie die manuelle Subtraktion des Eigengewichts der Spule. Anschließend muss das Filament erneut montiert und korrekt eingeführt werden @3GewichtGrundlage.
Insbesondere bei Druckvorgängen mit mehreren Materialwechseln oder bei der Nutzung mehrerer Drucker entsteht hierdurch ein erheblicher Zeitaufwand.

Im vorherigen Entwicklungsstand von _ClothoPus_ wurde dieses Problem durch ein System adressiert, das Filamentrollen über NFC-Tags identifiziert und den Materialbestand über Wägezellen erfasst. Die Messdaten wurden zentral verarbeitet und in OctoPrint dargestellt. Dadurch konnte bereits eine deutliche Reduktion manueller Kontrollschritte erreicht werden.

Während der weiteren Entwicklung zeigte sich jedoch, dass die ursprüngliche Architektur in zwei wesentlichen Punkten eingeschränkt war. Zum einen begrenzte die zentrale Anbindung der einzelnen Filament-Stacks über proprietäre Anschlüsse an GPIO-Pins die maximale Anzahl parallel nutzbarer Stacks. Zum anderen erwies sich die Gewichtsmessung über dauerhaft belastete Wägezellen als problematisch, da die verwendeten Messsysteme unter Dauerlast ein Kriechverhalten zeigten. Dies führte dazu, dass die Messwerte im Laufe der Zeit ungenauer wurden.

Vor diesem Hintergrund wurde _ClothoPus_ in der aktuellen Projektphase grundlegend weiterentwickelt.

== Zielsetzung

Ziel des Projekts war die Weiterentwicklung von ClothoPus zu einem skalierbaren, dezentralen und netzwerkfähigen System zur automatisierten Filamentverwaltung.

Ausgehend von den Einschränkungen des bisherigen Entwicklungsstands standen vier Anforderungen im Vordergrund: die Aufhebung der Begrenzung parallel nutzbarer Filament-Stacks durch eine dezentrale, netzwerkfähige Architektur, die Entwicklung eines alternativen Messprinzips ohne dauerhaft belastete Wägezellen, eine offenere und modularere Softwarearchitektur sowie die Implementierung datenbasierter Vorhersagen zukünftiger Filamentbestände.


#pagebreak()

== Vorgehensweise

Das Projekt wurde erneut in einen Hardware- und einen Softwareanteil gegliedert.

Im Hardwareanteil wurden die bestehenden Filament-Stacks an die neue Architektur angepasst. Dabei konnten zentrale Elemente des vorherigen Entwicklungsstands weiterverwendet werden. Die Anpassungen betrafen insbesondere die Integration eines Olimex ESP32 PoE als lokale Steuereinheit sowie die Umsetzung eines neuen Messprinzips zur Erfassung der durchlaufenden Filamentlänge. Hierfür wurde ein Aufnehmer mit zwei Zahnrädern konstruiert, über den das Filament ein Encoder-Rad antreibt. Die zurückgelegte Filamentlänge kann dadurch anhand der erfassten Encoder-Impulse bestimmt werden.

Die NFC-Hardware blieb gegenüber dem vorherigen Projektstand unverändert. Weiterhin kommt der PN5180 als NFC-Reader zum Einsatz. Die bereits bestehenden Lese- und Schreibfunktionen wurden funktional beibehalten. Der vorhandene Treiber wurde jedoch auf MicroPython übertragen, damit er direkt auf den ESP32-basierten Stacks ausgeführt werden kann.

Die Softwareentwicklung konzentrierte sich auf die Portierung und Dezentralisierung der bisherigen Funktionalität. Auf jedem ESP32 läuft eine Microdot-Anwendung, die eine Flask-ähnliche REST-API bereitstellt @microdot_doc. Über diese Schnittstelle können NFC-Blöcke gelesen und geschrieben, die Erreichbarkeit eines Stacks geprüft sowie der bisher berechnete Materialverbrauch abgefragt werden.

Durch diese Architektur wurde das System von einer zentral gesteuerten Lösung zu einem verteilten Netzwerk aus eigenständigen Filament-Stacks weiterentwickelt. 

Ergänzend wurde eine Vorhersagefunktion zur Abschätzung der verbleibenden Nutzungsdauer des Filaments implementiert. Grundlage hierfür bilden die zuletzt erfassten Verbrauchsdaten, aus denen der aktuelle Verbrauchstrend abgeleitet wird. Auf dieser Basis kann näherungsweise prognostiziert werden, wie lange das jeweilige Filament voraussichtlich noch ausreicht.

Die Umsetzung erfolgte iterativ: Zunächst wurden einzelne Hardware- und Softwarekomponenten getrennt getestet und anschließend zu einem funktionsfähigen Gesamtsystem integriert.


#pagebreak()

= Projektmanagement

== Work Breakdown Structure

Zur strukturierten Planung und Durchführung des Projekts wurde eine Work Breakdown Structure (WBS) verwendet, welche das Gesamtvorhaben in klar definierte Arbeitspakete unterteilte.

Auf oberster Ebene wurde das Projekt in die Bereiche Analyse, Hardware, Software, Integration und Test gegliedert. Die Analyse umfasste die Bewertung des vorherigen Systemstands sowie die Ableitung der zentralen Anforderungen für die Weiterentwicklung. Dabei wurden insbesondere die eingeschränkte Skalierbarkeit der GPIO-basierten Architektur und die langfristige Messungenauigkeit der Wägezellen als relevante Schwachstellen identifiziert.

Der Bereich Hardware beinhaltete die Anpassung der bestehenden Filament-Stacks an die dezentrale Systemarchitektur. Dazu zählten insbesondere die Integration des Olimex ESP32 PoE, die mechanische Umsetzung des Encoder-basierten Messprinzips sowie notwendige Anpassungen an Stromversorgung, Verkabelung und Bauraum innerhalb der Stacks.

Im Bereich Software wurden die zentralen Entwicklungsaufgaben in mehrere Arbeitspakete gegliedert. Dazu gehörten die Portierung des PN5180-Treibers nach MicroPython, die Implementierung der Encoder-Auswertung einschließlich der Berechnung des Filamentverbrauchs, die Entwicklung der Microdot-basierten REST-API, die Anbindung an die bestehende OctoPrint-Integration sowie die Implementierung der Vorhersagefunktion für die verbleibenden Filamentnutzungsdauer.

Die Bereiche Integration und Test fassten die schrittweise Zusammenführung der einzelnen Komponenten sowie deren Überprüfung im Gesamtsystem. Als wesentliche Meilensteine wurden die Inbetriebnahme eines ESP32-PoE-Stacks, das erfolgreiche Auslesen und Beschreiben eines NFC-Tags, die Erfassung von Encoder-Impulsen, die Bereitstellung der REST-Endpunkte, die Berechnung und Vorhersage des Filamentverbrauchs sowie die abschließende Gesamtdemonstration definiert.

== Organisational Breakdown Structure

Die Organisationsstruktur des Projekts war als kleines, gleichberechtigtes Teammodell ausgelegt. Die Umsetzung erfolgte durch Richard und Jannis, wobei Richard schwerpunktmäßig die Hardwareentwicklung und Jannis den Softwareanteil übernahm.

Aufgrund der geringen Teamgröße konnten Abstimmungen direkt und effizient erfolgen. Strategische und technische Entscheidungen wurden gemeinsam getroffen. Die klare Aufteilung in Hardware- und Softwareverantwortung ermöglichte paralleles Arbeiten an voneinander abhängigen Komponenten. So konnten softwareseitig beispielsweise Dummy-Treiber eingesetzt werden, die erwartete Rückgabewerte der Hardware simulierten und dadurch eine frühzeitige Entwicklung sowie Tests unabhängig vom finalen Hardwarestand ermöglichten.

Regelmäßige Integrationsschritte stellten sicher, dass beide Entwicklungsbereiche kontinuierlich zusammengeführt werden konnten.

== Projektplan

Das Projekt begann im April 2026 und wurde im Juli 2026 abgeschlossen.

Die zeitliche Planung orientierte sich an den definierten Hauptphasen der WBS.  

Während der Umsetzung traten mehrere technische Herausforderungen auf, die Einfluss auf den Projektverlauf hatten.  
Zentrale Problemstellen waren hardwareseitig die Planung und Integration des Encoders zur Längenmessung.
Kernherausforderung der Softwareentwicklung war die inkonsitente Implementierung von Basismodulen zwischen upstream Python und Micropython.
Zudem konnte die geplante Speicherung der Verbrauchsdaten direkt auf dem NFC-Tag aufgrund begrenzter Speicherkapazitäten in den vorgesehenen Speicherbereichen nicht umgesetzt werden. Die finale alternative Umsetzung der Speicherung und Verarbeitung der Verbrauchsdaten wird in @DataAnalytics beschrieben.
Diese Herausforderungen erforderten zusätzliche Entwicklungsarbeit, konnten jedoch innerhalb des vorgesehenen Projektzeitraums gelöst werden.

Die strategische Entscheidung, zunächst eine stabile Integration mit OctoPrint zu realisieren, ermöglichte eine klar abgegrenzte Demonstrationsfähigkeit des Systems.

== Vorgehensmodell in der Entwicklung

Die Projektumsetzung folgte einem hybriden Vorgehensmodell. Auf Makroebene wurde eine phasenorientierte Struktur gewählt, die sich in Analyse, Entwurf, Implementierung, Integration und Test unterteilte. Auf Mikroebene erfolgte die Entwicklung inkrementell.

Einzelne Funktionen wurden zunächst separat umgesetzt und getestet. Dazu gehörten die Netzwerkkommunikation des ESP32, die Microdot-basierte REST-API, die Auswertung des Encoders und die Kommunikation mit dem PN5180. Anschließend wurden diese Komponenten schrittweise zusammengeführt.

Die größte technische Herausforderung bestand in der Ablösung der bisherigen zentralen Architektur. Da jeder Stack nun eigenständig arbeitet, mussten Stromversorgung, Datenkommunikation und Sensorverarbeitung vollständig dezentralisiert werden. Gleichzeitig musste sichergestellt werden, dass die neue Architektur weiterhin mit der bestehenden OctoPrint-Integration kompatibel bleibt.

Die geringe Teamgröße wirkte sich positiv auf die Agilität des Projekts aus. Abstimmungen konnten kurzfristig erfolgen, Entscheidungen wurden schnell getroffen und Anpassungen ließen sich ohne aufwendige Kommunikationswege umsetzen. Gleichzeitig führte die kleine Teamgröße jedoch zu einer hohen individuellen Auslastung, da sämtliche Aufgaben der Planung, Entwicklung, Integration, Dokumentation und Fehlerbehebung auf zwei Personen verteilt waren. Dadurch entstand ein erhöhter Koordinations- und Arbeitsaufwand pro Teammitglied, insbesondere in Phasen, in denen Hardware- und Softwarearbeiten parallel vorangetrieben werden mussten.

#pagebreak()

= Entwurf und Implementierung

== Produkt und Vernetzung

_ClothoPus_ ist als modulares, vernetztes Smart-System zur automatisierten Filamentverwaltung im Bereich des privaten und semiprofessionellen 3D-Drucks konzipiert.  
Das Produkt dient der kontinuierlichen Identifikation, Längenerfassung und Bestandsvorhersage mehrerer Filamentrollen und stellt diese Informationen externen Druckmanagementsystemen zur Verfügung.

#figure(
 image("assets/image-5.png"), caption: [Aufbau des Gesamtsystems.]
)<systemview>

Im Gegensatz zum vorherigen Aufbau existiert keine zentrale GPIO-basierte Steuereinheit mehr, an die alle Stacks direkt angeschlossen werden müssen. Stattdessen verfügt jeder Stack über einen eigenen Olimex ESP32 PoE. Dieser übernimmt lokal die Sensordatenerfassung, die NFC-Kommunikation, die Berechnung des verbrauchten Filaments sowie die Bereitstellung der Daten über eine REST-Schnittstelle.

Die Stromversorgung und Datenübertragung erfolgen über Power over Ethernet. Dadurch genügt ein einziges Netzwerkkabel pro Stack, um sowohl Energie als auch Kommunikation bereitzustellen. Die Skalierung des Systems erfolgt somit über einen PoE-fähigen Netzwerkswitch. 

Diese Architektur stellt eine wesentliche Verbesserung gegenüber dem vorherigen System dar. Während zuvor maximal fünf Stacks aufgrund der begrenzten Anzahl verfügbarer GPIO-Pins betrieben werden konnten, lassen sich nun in einem üblichen IPv4-/24-Subnetz theoretisch bis zu 253 Geräte adressieren @subnet. Durch größere Netzwerke, mehrere Subnetze oder angepasste Netzwerkkonfigurationen ist die Skalierung grundsätzlich nahezu unbegrenzt erweiterbar und lediglich durch die Verwendung von Switches und deren Anschlüssen begrenzt.

Die in der ersten Iterationsstufe entwickelten Leiterplatten konnten aufgrund einer vorausschauenden Planung weiterhin genutzt werden. Hierzu wurden die Wägezellentreiber entfernt und die interne Verbindung zu den SUB-D-Steckern durch einen mit dem ESP32 kompatiblen Stecker ersetzt. Die Eingangspins des Wägezellentreibers konnten für den Encoder wiederverwendet werden, da dieser lediglich zwei GPIO-Pins sowie einen GND-Pin benötigt. @aktualisierte_verk zeigt die oben beschriebenen Änderungen.

#figure(
 image("assets/schachtel_offen_3.png", height: 220pt), caption: [Aktualisierte Verkabelung innerhalb des Stacks.]
)<aktualisierte_verk>

OctoPrint bleibt zunächst weiterhin die primäre Benutzeroberfläche für die Darstellung der Filamentinformationen und wird auf einem Raspberry Pi gehosted. Dieser befindet sich in einem zentralen Gehäuse, welches vor groben äußeren Einflüssen schützt. 

#figure(
 image("assets/clothobox.png"), caption: [Verkabelung innerhalb des zentralen Gehäuses.]
)<clothobox>

== Technologie und Daten

=== Dezentrale Steuereinheit

Als Recheneinheit jedes einzelnen Stacks kommt ein Olimex ESP32 PoE zum Einsatz.
Der Mikrocontroller übernimmt alle lokalen Aufgaben des Stacks. Dazu zählen die Kommunikation mit dem PN5180-NFC-Reader, die Auswertung des Encoders, die Berechnung des verbrauchten Materials sowie die Bereitstellung der REST-API.

#figure(
 image("assets/schachtel_offen_1.png", height: 290pt), caption: [Aufbau des Stacks.]
)<stackview>

Durch die Verwendung des ESP32 (seitlich in @stackview) wird jeder Stack zu einem eigenständigen Netzwerkteilnehmer. Dies reduziert die Abhängigkeit von zentraler Hardware erheblich und verbessert Wartbarkeit, Erweiterbarkeit und Skalierbarkeit des Gesamtsystems.

Die Nutzung von Power over Ethernet ist hierbei besonders vorteilhaft, da keine separate Stromversorgung pro Stack erforderlich ist. Versorgung und Kommunikation werden über dieselbe physische Verbindung realisiert.

=== NFC-Kommunikation

Zur Identifikation der Filamentrollen wird weiterhin der NFC-Reader PN5180 eingesetzt.
Der verwendete NFC-Chip bleibt damit gegenüber dem vorherigen Projektstand unverändert.

#figure(
 image("assets/stack_komplett.png", height: 340pt), caption: [Rückansicht Stack.]
)<stackkomplett>
#pagebreak()
Die bereits entwickelten Lese- und Schreibfunktionen wurden nicht verändert. Die wesentliche Weiterentwicklung bestand stattdessen darin, den vorhandenen Treiber auf MicroPython umzuschreiben. Dadurch kann die NFC-Kommunikation direkt auf dem ESP32 ausgeführt werden.

Über den NFC-Tag werden relevante Filamentdaten wie Materialtyp, Farbe, Dichte und Filamentdurchmesser ausgelesen. Während Materialtyp und Farbe vor allem der Identifikation und Darstellung dienen, werden Dichte und Durchmesser für die Berechnung des bisher verbrauchten Filamentgewichts verwendet.


=== Verbrauchsmessung über Encoder

Im neuen System wird der Materialverbrauch nicht mehr durch eine direkte Gewichtsmessung bestimmt, sondern aus der durchlaufenden Filamentlänge berechnet. Hierfür wurde ein eigener mechanischer Aufnehmer mit zwei Zahnrädern entwickelt. Das Filament treibt den Aufnehmer direkt an, wodurch die Bewegung auf ein Odometer-Rad übertragen wird. Die Drehbewegung wird durch einen Encoder erfasst.

Aus der Anzahl der Encoder-Impulse wird zunächst die zurückgelegte Filamentlänge berechnet. Der verwendete Encoder hat eine Auflösung von 24 Schritten pro Umdrehung @kailh_spreadsheet.
Anschließend wird über den Filamentdurchmesser die Querschnittsfläche bestimmt. Zusammen mit der Dichte des Materials ergibt sich daraus das verbrauchte Gewicht.

Die Berechnung erfolgt nach folgendem Prinzip:

Länge: $ l ["mm"] = pi dot (n_"clicks")/24 dot diameter_o ["mm"] $<länge>

Querschnittsfläche $ A ["mm"^2] = pi dot (diameter_f/2)^2 $

Gewicht: $ m [g] = rho [g/"mm"^3] dot l dot A $

Die Materialdichte und der Filamentdurchmesser werden direkt vom NFC-Tag ausgelesen. Dadurch ist die Berechnung materialspezifisch und kann automatisch an unterschiedliche Filamente angepasst werden.

=== REST-API

Auf jedem ESP32 läuft eine Microdot-basierte REST-API.
Microdot stellt eine leichtgewichtige, Flask-ähnliche Anwendungsstruktur für MicroPython bereit und eignet sich dadurch für den Einsatz auf ressourcenbeschränkten Mikrocontrollern @microdot_doc.

Die API bildet die zentrale Schnittstelle zwischen einem Stack und externen Anwendungen. Sie ermöglicht sowohl den Zugriff auf NFC-Daten als auch auf Status- und Verbrauchsinformationen.

Die implementierten Endpunkte sind:

#align(center, 
  table(columns: (auto, auto), align: left,
    table.header(
        [*Endpunkt*], [*Beschreibung*],
    ),
    stroke: none,
    table.hline(),
    `GET /blocks`, table.vline(), "Auslesen von NDEF OpenPrintTag Datenblöcken.",
    `POST /blocks`, "Schreiben von NDEF OpenPrintTag Datenblöcken.",
    `GET /reachable`, "Prüfung der Netzwerkerreichbarkeit von Stacks.",
    `GET /consumed`, "Abfrage des seit letzter Anfrage verbrauchten Materials."
  )
)

Durch diese Endpunkte entsteht eine klare, offene und leicht integrierbare Schnittstelle. Externe Systeme müssen keine Kenntnisse über die interne Umsetzung der NFC-Kommunikation oder Encoder-Auswertung besitzen. Stattdessen können sie über HTTP auf die abstrahierten Funktionen des jeweiligen Stacks zugreifen.

=== Connectivity

Die neue Connectivity-Architektur basiert vollständig auf Ethernet und IP-Kommunikation.
Jeder Stack ist über ein Netzwerkkabel mit einem PoE-fähigen Switch verbunden. Über dieses Kabel werden sowohl die Stromversorgung als auch die Netzwerkkommunikation realisiert.

Im Vergleich zur vorherigen proprietären Verkabelung ergeben sich dadurch mehrere Vorteile. Erstens reduziert sich der Verkabelungs und Lötaufwand, da keine getrennten Leitungen für Stromversorgung, Datenübertragung und Sensorsignale notwendig sind. Zweitens wird die mechanische Integration vereinfacht, da jeder Stack als eigenständige Einheit betrachtet werden kann. Drittens kann das System wesentlich einfacher erweitert werden, da neue Stacks lediglich an den Switch angeschlossen und im Netzwerk adressiert werden müssen.

Die Kommunikation zwischen Frontend und Stack erfolgt über standardisierte HTTP-Anfragen. Dadurch ist das System nicht an OctoPrint gebunden. OctoPrint kann weiterhin als Bedienoberfläche dienen, ist aber nicht zwingend erforderlich. Andere Softwarelösungen können dieselben REST-Endpunkte verwenden und die Daten in eigene Workflows integrieren.

Die Kommunikation mit dem PN5180-NFC-Reader erfolgt über eine SPI-Schnittstelle, über die Steuer- und Nutzdaten ausgetauscht werden.
Der Kailh-Encoder erzeugt bei Drehbewegung steigende Flanken, die mithilfe eines Interrupt-Handlers des ESP32 erfasst werden. Dabei wird ein interner Zähler hochgezählt, wodurch, wie in @länge beschrieben, die abgespulte Materiallänge berechnet werden kann.

=== Data Analytics <DataAnalytics>

Die bisherige reine Anzeige des Filamentbestands wird in dieser Iterationsstufe um eine Vorhersage zukünftiger Materialbestände erweitert. Grundlage hierfür ist eine Zeitreihe aus Zeitstempeln und den jeweils zugehörigen Materialbeständen.

In der Planungsphase des Projekts war zunächst vorgesehen, diese Verlaufsdaten direkt auf dem NFC-Tag zu speichern. Der OpenPrintTag-Standard reserviert für dynamische Daten einen gesonderten Speicherbereich, die sogenannte _Auxiliary Region_. Die Aufteilung des Speicherbereichs auf dem Tag ist in @optspeicher dargestellt. In diesem Bereich werden auch die zuvor gemessenen und nun berechneten Gewichtsdaten gespeichert. Die Größe dieses Speicherbereichs wird bei der Initialisierung des Tags festgelegt, welche im Regelfall durch den Hersteller des Filaments erfolgt. Laut @6OpenPrintTag ist vorgesehen, dass dieser Bereich mindestens 16 Byte groß ist. Empfohlen wird eine Größe von 32 Byte. Tests während der Entwicklung zeigten, dass die meisten Hersteller diese empfohlene Größe verwenden.

#figure(
image("assets/speicherregionen.png", height: 70pt), caption: [Aufteilung des Speicherbereiches auf einem OpenPrintTag @6OpenPrintTag]
)<optspeicher>

Die Speicherung eines Zeitstempels einschließlich des zugehörigen Gewichts belegt 4 Byte. Bei vollständiger Nutzung der Auxiliary Region könnten somit maximal acht Messpunkte gespeichert werden. Da in diesem Bereich jedoch zusätzlich die aktuellen Gewichtsdaten abgelegt werden, reduziert sich die verfügbare Kapazität auf sieben Zeit-Gewichts-Paare.

Eine nachträgliche Vergrößerung des Speicherbereichs ist ohne Reinitialisierung des NFC-Tags nicht möglich. Dafür müssten die vorhandenen Daten zunächst ausgelesen und vom Tag gelöscht werden. Anschließend müsste der Tag mit einer vergrößerten Auxiliary Region neu initialisiert und erneut mit den bisherigen Daten sowie den zusätzlichen Zeit-Gewichts-Werten beschrieben werden. Dieser Lese- und Schreibvorgang benötigt etwa 0,5 bis 2 Sekunden. Störungen oder ein Entfernen des Tags während dieses Vorgangs könnten dazu führen, dass der Tag nicht vollständig beschrieben wird und dadurch korrupt wird.

Theoretisch könnte das Gewicht des letzten gespeicherten Messpunkts zugleich zur Anzeige des aktuellen Filamentbestands verwendet werden, um die Speicherausnutzung zu optimieren. Andere Systeme, beispielsweise die Prusa App @prusa_app, verwenden für die Darstellung des aktuellen Filamentbestands jedoch den unter dem Keyword _consumed_weight_ gespeicherten Wert. Zudem würde diese Speicheroptimierung die Anzahl speicherbarer Messpunkte nur geringfügig erhöhen und damit keine ausreichend belastbare Datengrundlage für die Vorhersage schaffen.

Die finale Speicherung der Verbrauchsdaten erfolgt daher nicht auf dem NFC-Tag, sondern innerhalb von OctoPrint. Nach dem erstmaligen Einlesen einer Filamentrolle wird ein Eintrag in einer Lookup-Tabelle erzeugt, in dem die Tag-UID abgelegt wird. Für jede neue Messung wird anschließend ein Tupel aus Zeitstempel und berechnetem Gewicht gespeichert.

Die Prädiktion zukünftiger Materialbestände erfolgt auf Grundlage einer zeitlich geordneten Messreihe, in der jeder Messpunkt aus dem jeweiligen Tag und dem bis dahin kumuliert verbrauchten Material besteht. Aus den Differenzen aufeinanderfolgender Verbrauchswerte wird der tägliche Materialverbrauch berechnet. Tage ohne Verbrauch werden dabei mit einem Verbrauch von null berücksichtigt.

Auf Basis dieser Tagesverbräuche wird ein Vorhersagemodell trainiert, das zusätzlich kalenderbasierte Merkmale wie Wochentag und Wochenende und Jahreszeiten einbezieht @hyndman_fpp3. Die Implementierung erfolgt mithilfe eines histogrammbasierten Gradient-Boosting-Regressors @hang2021gradientboostedbinaryhistogram @sklearn_hgbregressor.

Der zukünftige Verbrauch wird tageweise vorhergesagt und zum bisherigen kumulierten Verbrauch addiert. Sobald der prognostizierte verbleibende Materialbestand erstmals null erreicht oder unterschreitet, gilt dieser Zeitpunkt als voraussichtliche vollständige Entleerung der Filamentrolle. Die Berechnung wird nach jedem neuen Messwert aktualisiert und in der Benutzeroberfläche von OctoPrint dargestellt.

== Aktoren und Ausgänge

Die Ausgabe der verarbeiteten Daten erfolgt vollständig softwareseitig über das Webinterface von OctoPrint.
Dem Nutzer werden dort Informationen über das aktuell eingesetzte Filament sowie dessen verbleibendes Gewicht übersichtlich dargestellt (@filament-view).

#figure(
 image("assets/Clotho_filament_view.png"), caption: [Darstellung des aktuellen Filamentinventars in OctoPrint.]
)<filament-view>
 
Physische Aktoren wie Anzeigen oder Signale sind im aktuellen Entwicklungsstand nicht vorgesehen, da der Fokus auf einer nahtlosen Integration in bestehende Druck-Workflows liegt.

== Service und Unterstützung

_ClothoPus_ ist bewusst als Open-Source-System konzipiert. Sowohl die Softwarekomponenten als auch die Hardwareentwürfe sind offen zugänglich und dokumentiert. Dadurch wird es Dritten ermöglicht, das System nachzubauen, anzupassen und weiterzuentwickeln.

Im Gegensatz zu klassischen, proprietären Smart-Systemen basiert das Unterstützungsmodell nicht primär auf einem zentralisierten Kundendienst, sondern auf einer kollaborativen Community-Struktur. Anwender und Entwickler können Fehlerberichte einreichen, Verbesserungsvorschläge diskutieren und eigene Erweiterungen beitragen. Dieser offene Entwicklungsansatz entspricht der in der 3D-Druck-Community etablierten Praxis und fördert Transparenz sowie Innovationsgeschwindigkeit.

Die Offenlegung der Hard- und Software erlaubt es zudem, das System an individuelle Anforderungen anzupassen. Beispielsweise können alternative Sensoren integriert, zusätzliche Schnittstellen wie Home Assistant Bridges implementiert oder neue Visualisierungsfunktionen entwickelt werden. Auch mechanische Anpassungen lassen sich auf Basis der Konstruktionsdaten realisieren.

#pagebreak()

= Fazit und Ausblick

Das im Rahmen dieses Projekts weiterentwickelte System _ClothoPus_ erfüllt die in der Zielsetzung formulierten Anforderungen.
Es wurde ein vollständig funktionsfähiges, dezentrales und skalierbares System zur automatisierten Filamentverwaltung realisiert.

Gegenüber dem vorherigen Projektstand konnten zwei zentrale technische Schwachstellen behoben werden. Die zuvor durch GPIO-Pins begrenzte Skalierbarkeit wurde durch eine Netzwerkarchitektur mit ESP32-PoE-Stacks ersetzt. Jeder Stack arbeitet nun als eigenständiger Netzwerkteilnehmer und kann über einen PoE-fähigen Switch angebunden werden. Damit steigt die praktisch nutzbare Anzahl paralleler Stacks von zuvor fünf auf bis zu 253 Geräte in einem üblichen Subnetz. Durch angepasste Netzwerktopologien ist darüber hinaus eine nahezu unbegrenzte Erweiterung denkbar.

Auch die Messmethodik wurde grundlegend verbessert. Die bisher verwendeten Wägezellen zeigten unter dauerhafter Belastung ein Kriechverhalten, wodurch die Messgenauigkeit langfristig abnahm. Durch den Wechsel auf eine encoderbasierte Verbrauchserfassung wird der Materialverbrauch nun aus der tatsächlich durchlaufenden Filamentlänge berechnet. In Kombination mit den auf dem NFC-Tag gespeicherten Materialdaten (Dichte und Filamentdurchmesser), kann daraus das verbrauchte Gewicht berechnet werden.

Die NFC-Funktionalität blieb erhalten. Der PN5180 wird weiterhin verwendet, wobei der bestehende Treiber auf MicroPython portiert wurde. Die bereits entwickelten Lese- und Schreibfunktionen blieben funktional unverändert.

Ein weiterer wesentlicher Fortschritt liegt in der neuen Softwarearchitektur. Auf jedem ESP32 läuft eine Microdot-basierte REST-API, über die NFC-Blöcke gelesen und geschrieben, die Erreichbarkeit geprüft und der bisherige Verbrauch abgefragt werden kann. Dadurch ist _ClothoPus_ deutlich offener als zuvor. OctoPrint bleibt zunächst als Benutzeroberfläche bestehen, ist aber nicht mehr zwingend notwendig. Proprietäre Frontends, Webanwendungen oder Plattformen wie Home Assistant können dieselben Schnittstellen verwenden.

Damit entwickelt sich _ClothoPus_ von einem lokal begrenzten, zentral gesteuerten Messsystem zu einer skalierbaren, verteilten Smart-Inventory-Lösung. Die aktuelle Version konnte vollständig funktionsfähig präsentiert werden und bildet eine stabile Grundlage für zukünftige Erweiterungen.

Zukünftige Ausbaustufen könnten eine automatische Erkennung und Einrichtung neu angeschlossener Stacks, eine zentrale Verwaltung mehrerer Drucker oder eine tiefere Integration in Smart-Home- und Druckfarm-Systeme umfassen. Durch die offene REST-Architektur sind diese Erweiterungen ohne grundlegende Änderung der Stack-Hardware realisierbar.
Auch die implementierte Vorhersagefunktion bietet weiteres Erweiterungspotenzial. Künftig könnten nicht nur die Verbrauchsdaten einzelner Rollen, sondern auch rollenübergreifende historische Daten ausgewertet werden. Eine Differenzierung nach Materialtyp oder nach Kombinationen aus Materialtyp und Farbe würde es ermöglichen, typische Nutzungsmuster einzelner Filamentarten zu berücksichtigen. Dadurch könnten die Verbrauchsmodelle verfeinert und die Vorhersagen zukünftiger Filamentbestände weiter verbessert werden.


#pagebreak()
#show link: set text(hyphenate: true)
#bibliography(
  "literatur.bib",
  title: "Literaturverzeichnis",
  style: "ieee"
)

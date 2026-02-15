// SEITE 1: Titelseite
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
„Clotho“ entstammt der griechischen Mythologie und bezeichnet eine der drei Moiren, die als Schicksalsgöttinnen den Lebensfaden der Menschen spinnen. In Anlehnung an dieses Motiv steht Clotho sinnbildlich für den Faden als zentrales Element des Systems. Im Kontext des Projekts entspricht dieser Faden dem 3D-Druck-Filament als grundlegendes Fertigungsmaterial.
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

= Einleitung
// == Motivation
// Im Bereich der privaten Nutzung von 3D-Druck Techniken, spezifisch Fused Deposition Modelling (FDM) und Fused Layer Modelling (FLM) ist das Filament als Fertigungsmaterial ein Kernbestandteil.  
// Ein häufiges Problem, das sowohl in der persönlichen Arbeit als auch in der FLM/FDM-Community identifiziert wurde, ist die regelmäßige und umständliche Überprüfung des Filamentbestandes.  
// Diese umfasst im Mindesten das Überprüfen des aktuell eingebauten Filemants, das Demontieren der Filamentrolle aus dem Drucker selbst, einer anschließenden Gewichtsmessung inklusive Subtraktionsrechnung des Eigenwichts der Filamentrolle selbst und schließlich erneutem Einsetzen des Filaments im Vorfeld des eigentlichen Fertigungsprozesses. 
// Besonders bei der Arbeit mit mehreren Filamenten innerhalb eines Druckvorgangs, wo dieser Vorgang im Notfall für jedes Filemant durchgeführt werden muss, kann so ein großer Zeitaufwand entstehen.  
// In Zeiten, in denen verfügbare Zeit und ihrer effizienten Nutzung indirekt stets an Wert zunimmt, ist die Entwicklung einer zeitsparenderen Lösung unabdingbar.
// Durch die kontiuierlich sinkenden Preise für Druckgeräte wächst die Anzahl der Nutzer mehr und mehr.

// Um dieses Problem zu entschärfen präsentieren wir _Clothopus_, ein smartes System zur automatischen Registrierung und Gewichtsmessung von bis zu fünf Filamenten zeitgleich. 
// _Clothopus_ verlegt den Fokus für den Nutzer zurück auf die Kernaufgabe des Kostruierens und sorgt so für einen zeitoptimierten Workflow, insbesondere bei der Nutzung von Remote-Systemen. Hierbei können potenzielle Schäden an Druckhardware infolge einer Verwechselung von Filamentmaterialien vorgebeugt werden, da eine eindeutige Kennzeichnung von Filamentrollen stattfindet. 

// == Zielsetzung
// _Clothopus_ soll den Nutzern als ein inuitives und schlankes System zur Filemantverwaltung und -übersicht dienen, dass die zeitlichen Anfordungen an nebensächlich anfallende Aufgaben reduziert.  
// Präziser umfasst dies das automatisierte Identifizieren und Auswiegen der in den Drucker eingesetzten Filamente.  
// Über eine entsprechende Software können die Nutzer die aktuell eingesetzten Filamente samt Gewichtsangabe einsehen.
// Die Handwarekomponente des Produkt setzt sich zusammen aus fünf identischen Filamentstationen sowie einem zentralen Gehäuse, in dem die Komponenten zur Evaluation der Messdaten verbait sind.
// Zusätzlich zu externen RFID-Tags ist _Clothopus_ explizit mit neuen Filemantprodukten der Marke Prusa Research, die seit Kurzem


== Motivation

Im Bereich der privaten Nutzung von 3D-Druck-Techniken, insbesondere Fused Deposition Modelling (FDM) und Fused Layer Modelling (FLM), stellt Filament das zentrale Fertigungsmaterial dar.  
Ein wiederkehrendes Problem sowohl in der eigenen praktischen Arbeit als auch innerhalb der Community ist die regelmäßige und umständliche Überprüfung des verfügbaren Filamentbestands.

Die Bestimmung der Restmenge erfordert typischerweise das Entnehmen der Filamentrolle aus dem Drucker, eine separate Gewichtsmessung sowie die manuelle Subtraktion des Eigengewichts der Spule. Anschließend muss das Filament erneut montiert und korrekt eingeführt werden.  
Insbesondere bei Druckvorgängen mit mehreren Materialwechseln oder bei der Nutzung mehrerer Drucker entsteht hierdurch ein erheblicher Zeitaufwand.

Mit der zunehmenden Verbreitung kostengünstiger 3D-Drucksysteme wächst auch die Anzahl der Anwender kontinuierlich. Parallel dazu steigt der Anspruch an Effizienz, Automatisierung und Remote-Fähigkeit der eingesetzten Systeme.  
Eine fehlende Transparenz über eingesetzte Materialien und verbleibende Restmengen kann dabei nicht nur zu abgebrochenen Druckaufträgen führen, sondern im ungünstigsten Fall auch zu Materialverwechslungen und daraus resultierenden Hardwareproblemen.

Vor diesem Hintergrund ergibt sich der Bedarf nach einer automatisierten, zuverlässigen und in bestehende Workflows integrierbaren Lösung zur Filamentverwaltung.

== Zielsetzung

Ziel des Projekts ist die Entwicklung eines integrierten Gesamtsystems zur automatisierten Verwaltung von 3D-Druck-Filamenten.  
Das System soll Filamentrollen kontinuierlich wiegen, die zugehörigen NFC-Tags auslesen und die gewonnenen Informationen dem Nutzer innerhalb einer überscihtlichen Umgebung bereitstellen.

\pagebreak()
== Vorgehensweise
Das Projekt wurde grundlegend in einen Hardware- und einen Softwareanteil gegliedert.

Die Hardwarearchitektur umfasst bis zu fünf identische Filamentstationen sowie eine zentrale Steuereinheit.  
Jede Filamentstation integriert eine Wägezelle zur kontinuierlichen Gewichtserfassung sowie einen NFC-Reader zum Auslesen der eingesetzten Filamentrollen.

Bei den verwendeten NFC-Tags handelt es sich um sogenannte OpenPrintTags, die dem im November 2025 veröffentlichten OpenPrintTag-Standard entsprechen.  
Dieser Standard definiert eine herstellerübergreifende Struktur zur digitalen Beschreibung von Filamentparametern auf Basis von ISO-15693 (NFC-V). Ziel ist es, Materialinformationen wie Typ, Farbe, empfohlene Druckparameter oder Chargenzuordnung direkt auf der Filamentrolle zu speichern und maschinell auslesbar zu machen.

Der OpenPrintTag-Standard schafft damit die Grundlage für automatisierte Materialerkennung und digitale Materialbibliotheken. 
Wie in der offiziellen Ankündigung beschrieben, eröffnen sich dadurch insbesondere für Druckfarmen und professionelle Anwendungen neue Möglichkeiten wie Echtzeit-Inventarverwaltung, Materialverfolgung und automatisierte Prozesssicherheit. Genau an diesem Punkt setzt _ClothoPus_ an und erweitert diesen Ansatz um eine kontinuierliche Gewichtserfassung.

Die Softwarekomponente übernimmt die zyklische Erfassung der Sensordaten, die Zuordnung von Gewicht und Identität sowie die Visualisierung der Informationen innerhalb von OctoPrint.  
Durch die direkte Integration in die bestehende Druckumgebung entsteht ein geschlossenes System, das Materialidentifikation und Bestandsüberwachung miteinander kombiniert.

Die Umsetzung erfolgte iterativ: Einzelne Komponenten wurden zunächst separat getestet und anschließend schrittweise zu einem funktionalen Gesamtsystem integriert.

#pagebreak()
= Projektmanagement

== Work Breakdown Structure

Zur strukturierten Planung und Durchführung des Projekts wurde eine Work Breakdown Structure (WBS) entwickelt, welche das Gesamtvorhaben hierarchisch in klar definierte Arbeitspakete gliederte.

Auf oberster Ebene wurde das Projekt in folgende Hauptphasen unterteilt:

- Anforderungsanalyse  
- Konzeptentwicklung  
- Hardwareentwicklung  
- Softwareentwicklung  
- Integration und Test  

Diese phasenorientierte Gliederung wurde durch eine komponentenorientierte Struktur ergänzt. Dadurch konnten sowohl zeitliche als auch funktionale Abhängigkeiten systematisch berücksichtigt werden.

Im Bereich der Hardwareentwicklung umfassten die Arbeitspakete unter anderem:

- Integration der Wägezellen  
- Integration des NFC-Readers  
- Entwicklung des 11-Pin-Kommunikationssystems  
- Mechanische Integration der Filament-Stacks  

Die Softwareentwicklung gliederte sich in:

- Implementierung der Sensordatenerfassung  
- Entwicklung der SPI-Kommunikation  
- Implementierung der NFC-Kommunikation gemäß ISO-15693  
- Erweiterung des PN5180-Treibers um Lese- und Schreibfunktionen  
- Entwicklung der REST-Schnittstelle  
- Integration in das OctoPrint-Plugin  

Die Zerlegung erfolgte bis auf Ebene funktionaler Module, sodass klar abgegrenzte, testbare Einheiten entstanden.

Als Meilensteine wurden technische Funktionsnachweise definiert, darunter:

- erfolgreiche Gewichtsmessung eines Stacks  
- stabile NFC-Kommunikation  
- vollständige Lese- und Schreiboperation gemäß OpenPrintTag-Spezifikation  
- erfolgreiche Datenanzeige in OctoPrint  
- vollständige Systemintegration aller Komponenten  

Diese Struktur ermöglichte eine transparente Fortschrittskontrolle und eine zielgerichtete Umsetzung des Systems.

== Organisational Breakdown Structure

Die Organisationsstruktur des Projekts war als gleichberechtigtes, selbstorganisiertes Teammodell ausgelegt.  

Die Aufgabenverteilung erfolgte kompetenzbasiert und orientierte sich an individuellen Stärken.  
Richard übernahm schwerpunktmäßig die Hardwareentwicklung, Jannis fokussierte sich auf die Softwareentwicklung, während Emil beide Bereiche unterstützte und insbesondere integrative Aufgaben zwischen Hard- und Software übernahm.

Strategische und operative Entscheidungen wurden im Konsens getroffen.  
Durch die geringe Teamgröße konnten Abstimmungsprozesse effizient und ohne hierarchische Eskalationsstufen durchgeführt werden.

Die operative Organisation erfolgte über ein Kanban-Board, das als zentrales Backlog diente. Aufgaben wurden priorisiert, transparent verwaltet und kontinuierlich aktualisiert.

Für die Versionsverwaltung wurde GitHub eingesetzt. Die Entwicklung erfolgte nach dem Feature-Branch-Prinzip. Neue Funktionalitäten wurden isoliert entwickelt, getestet und nach gemeinsamer Prüfung in den Hauptbranch integriert. Dieses Vorgehen reduzierte Integrationsrisiken und ermöglichte parallele Entwicklungsarbeit.

Regelmäßige Abstimmungsmeetings fanden durchschnittlich viermal pro Woche statt und dienten der Fortschrittskontrolle, Problemidentifikation sowie kurzfristigen Repriorisierung.

== Projektplan

Das Projekt begann im Oktober 2025 und wurde im Dezember 2025 abgeschlossen.

Die zeitliche Planung orientierte sich an den definierten Hauptphasen der WBS.  
Eine iterative Detailplanung erfolgte fortlaufend über das Kanban-System, wodurch flexibel auf neue Erkenntnisse reagiert werden konnte.

Während der Umsetzung traten mehrere technische Herausforderungen auf, die Einfluss auf den Projektverlauf hatten.  
Dazu zählten insbesondere:

- die Beschaffung inkompatibler NFC-Reader (ISO-14443 statt ISO-15693),  
- Timing-Probleme innerhalb der SPI-Kommunikation,  
- notwendige Erweiterungen des PN5180-Treibers,  
- das Kriechverhalten der Wägezellen unter Dauerlast.

Diese Herausforderungen erforderten zusätzliche Entwicklungsarbeit, konnten jedoch innerhalb des vorgesehenen Projektzeitraums gelöst werden.

Der funktionale Projektumfang blieb stabil. Die strategische Entscheidung, zunächst eine stabile Integration mit OctoPrint zu realisieren, ermöglichte eine klar abgegrenzte Demonstrationsfähigkeit des Systems.

== Vorgehensmodell in der Entwicklung

Das Projekt folgte einem hybriden Vorgehensmodell.  

Auf Makroebene wurde eine phasenorientierte Struktur gewählt (Analyse, Konzept, Hardware, Software, Integration).  
Auf Mikroebene erfolgte die Umsetzung agil und inkrementell.

Die Steuerung der Entwicklung basierte auf einem Kanban-System mit priorisierten Aufgaben.  
Neue Funktionalitäten wurden eigenständig in Feature-Branches entwickelt und nach erfolgreichem Test in gemeinsamen Integrationsschritten zusammengeführt. Insgesamt wurden drei zentrale Integrationspunkte definiert, auf denen jeweils weiterführende Funktionen aufbauten.

Testing erfolgte kontinuierlich während der Entwicklung sowie verpflichtend vor jedem Merge-Vorgang.  
Ein erheblicher Teil der Implementierung wurde im Pair-Programming durchgeführt, wodurch eine implizite Qualitätssicherung gewährleistet war.

Formale Sprintzyklen wurden nicht dauerhaft etabliert; in kritischen Projektphasen wurden jedoch gezielt intensive Entwicklungsintervalle eingesetzt, um Verzögerungen auszugleichen.

Die größte Herausforderung bestand in der Bewältigung unvorhergesehener technischer Probleme, insbesondere im Bereich der Low-Level-Kommunikation.  

Positiv hervorzuheben ist die hohe Reaktionsfähigkeit des Teams. Durch konsensorientierte Entscheidungsfindung und kurze Kommunikationswege konnten kritische Situationen schnell analysiert und nachhaltig gelöst werden.

Für zukünftige Projekte empfiehlt sich die explizite Einplanung zusätzlicher Zeitpuffer sowie eine frühzeitige technische Risikoanalyse zur weiteren Optimierung des Projektmanagements.


#pagebreak()
= Entwurf und Implementierung
== Produkt und Vernetzung
_Clothopus_ ist als modulares, vernetztes Smart-System zur automatisierten Filamentverwaltung im Bereich des privaten und semiprofessionellen 3D-Drucks konzipiert.  
Das Produkt dient der kontinuierlichen Identifikation und Gewichtserfassung mehrerer Filamentrollen und stellt diese Informationen externen Druckmanagementsystemen zur Verfügung.


#figure(
 image("assets/image-2.png"), caption: [Aufbau des Gesamtsystems.]
)<systemview>

Das Gesamtsystem, welches in  @systemview dargestellt ist, besteht aus mehreren identischen Filamentstationen sowie einer zentralen Steuereinheit. Für die zentrale Steuereinheit kommt ein Raspberry Pi 4 zum Einsatz. 
Jede Filamentstation, im Folgenden als Stack bezeichnet, ist für die Aufnahme einer Filamentrolle ausgelegt und integriert sowohl eine Wägezelle zur Gewichtsmessung als auch einen NFC-Reader zur Identifikation des eingesetzten Filaments.  
Durch die modulare Auslegung des Systems können bis zu fünf Stacks parallel innerhalb eines Gesamtsystems betrieben werden. Die Einschränkung auf maximal fünf Stacks ist hierbei der Anzahl der auf dem Raspberry Pi verfügbaren GPIO-Pins geschuldet.

  
Der Raspberry Pi übernimmt die zyklische Abfrage der angeschlossenen Stacks, die Verarbeitung Sensordaten sowie die Zuordnung von Gewichtsmessungen zu den Filamentdaten.  
#figure(
 image("assets/Clotho_Clothobox.jpeg", width: 50%), caption: [Verkabelung innerhalb des zentralen Gehäuses inklusive des eigens entwickelten PiHats.]
)<clothobox>

Die Kommunikation zwischen den Stacks und der zentralen Steuereinheit erfolgt über einen Kabelanschluss.  
Dieser dient sowohl der Spannungsversorgung der Sensorik als auch der Datenübertragung von Steuersignalen und Sensordaten, wie Messwerten der Wägezellen sowie Daten der NFC-Tags.
Das Bündeln aller relevanten Signale erfolgt über eigens entwickelte Leiterplatten (PCBs) innerhalb der Stacks (@stack-underside) sowie auf der zentralen Steuereinheit (Ausführung als PiHat (@clothobox)). Dies vereinfacht die mechanische Integration, den modularen Ausbau sowie Wartungsarbeiten.

#figure(
 image("assets/Clotho_Stacks_underside.jpeg"), caption: [Ansicht auf die kompakte Integration der Wägezellen und NFC-Reader-Verkabelung.]
)<stack-underside>

Zur externen Vernetzung ist der Raspberry Pi 4 über WLAN oder Ethernet in das lokale Netzwerk des Nutzers eingebunden.  
Auf dem Raspberry Pi wird OctoPrint ausgeführt, sodass die Filamentdaten lokal durch über das Clothopus-Plugin zur Verfügung gestellt werden.



== Technologie und Daten
=== Sensoren und Eingänge

Als primäre Sensorkomponenten kommen in jedem Stack eine Wägezelle sowie ein NFC-Reader zum Einsatz.  
Die Gewichtserfassung erfolgt über eine Wägezelle, deren analoges Brückensignal durch den HX711-Wägezellentreiber mit integriertem Analog-Digital-Wandler verstärkt und digitalisiert wird.  
Der HX711 stellt die gemessenen Gewichtswerte über eine taktgesteuerte Schnittstelle bereit und ermöglicht eine für den Einsatzzweck ausreichende Messgenauigkeit.

Zum Auslesen der NFC-Tags und somit zur Identifikation der Filamente wird ein NFC-Reader des Typs PN5180 verwendet.  
Dieser unterstützt mehrere NFC-Standards, wobei im Rahmen des Projekts gezielt der ISO-15693-Standard (NFC-V) genutzt wird, da dieser den Spezifikationen des OpenPrintTag-Standards entspricht.  
Über den NFC-Reader werden sowohl Identifikations- als auch sämtliche Nutzdaten der Filamenttags erfasst.\
Auf Basis eines bestehenden Open-Source-Treibers wurde eine vollständige Erweiterung implementiert.
Während der ursprüngliche Treiber lediglich grundlegende Inventory-Anfragen, wie beispielsweise das Auslesen der UUID, unterstützte, wurden sämtliche Lese- und Schreiboperationen zur standardkonformen Verarbeitung der auf dem NFC-Tag gespeicherten Datenblöcke gemäß der ISO15693-Spezifikation eigenständig entwickelt.

Die Kommunikation mit dem PN5180 erfolgt dabei auf niedriger Abstraktionsebene durch den Versand hersteller[Quelle]- und normdefinierter[Quelle] Datenframes in hexadezimaler Form über die SPI-Schnittstelle des Raspberry Pi.  
Diese Vervollständigung des Treibers stellt eine zentrale technische Eigenleistung des Projekts dar.


Die Kombination aus Gewichtsmessung und eindeutiger Filamentidentifikation bildet die Grundlage für eine automatisierte und zuverlässige Erfassung aller relevanten Eingangsdaten des Systems.

=== Connectivity

Die Anbindung der Filament-Stacks an die zentrale Steuereinheit erfolgt über ein proprietäres 11-Pin-Kommunikationssystem.  
Über diese Verbindung werden sowohl die Spannungsversorgung als auch die Datenübertragung realisiert.

Die Kommunikation mit dem PN5180-NFC-Reader erfolgt über eine SPI-Schnittstelle, über die Steuer- und Nutzdaten ausgetauscht werden.  
Die Anbindung der Wägezelle erfolgt über das HX711-Modul, welches über je eine Takt- und Datenleitung ausgelesen wird.

Zur externen Vernetzung stellt die zentrale Steuereinheit die erfassten Daten über eine modulare Softwareschnittstelle bereit.  
Aktuell ist das System in ein OctoPrint-Plugin eingebunden, wobei die Datenübertragung über eine REST-API erfolgt.  
Durch diese Architektur kann das _Clothopus_-Backend flexibel in bestehende Systeme integriert oder zukünftig um weitere Kommunikationsschnittstellen erweitert werden.

=== Data Analytics

Die erfassten Sensordaten werden auf der zentralen Steuereinheit verarbeitet und logisch miteinander verknüpft.  
Hierbei erfolgt die eindeutige Zuordnung von Gewichtsmessungen zu den identifizierten Filamenten durch die softwareseitige Zusammenfassung von Wägezelle und NFC-Reader in einem Software-Stack.

Eine Kalibrierungsroutine bei der Ersteinrichtung der Stacks stellt sicher, dass die Gewichtsmessung präzise erfolgt. Hier für wird der Stack mit einem dem Nutzer bekannten Gewicht belastet.
Aus dem Messwert der Wägezelle wird die Skalierung sowie Nullpunktverschiebung des Wägezellentreibers berechnet und gespeichert. Beim Neustart des Systems werden die entsprechenden Parameter geladen und eingestellt.
Für eine erfolgreiche Kalibrierung wird der Nutzer mithilfe eines Wizards durch das Prozedere geführt.

Neben der reinen Anzeige des aktuellen Filamentgewichts wird dieses zusätzlich in einem definierten Speicherbereich des NFC-Tags (Aux-Region) abgelegt.  
Dadurch wird das Filament selbstzustandsbehaftet, da relevante Informationen direkt auf dem Tag gespeichert und unabhängig vom System wieder ausgelesen werden können.

=== Aktoren und Ausgänge

Die Ausgabe der verarbeiteten Daten erfolgt vollständig softwareseitig über das Webinterface von OctoPrint.
Dem Nutzer werden dort Informationen über das aktuell eingesetzte Filament sowie dessen verbleibendes Gewicht übersichtlich dargestellt (@filament-view).

#figure(
 image("assets/Clotho_filament_view.png"), caption: [Darstellung des aktuellen Filamentinventars in OctoPrint.]
)<filament-view>

Zusätzlich zur Visualisierung stellt das System die Daten über eine Programmierschnittstelle (REST-API) bereit, sodass sie von weiteren Softwarekomponenten oder Erweiterungen genutzt werden können.  
Physische Aktoren wie Anzeigen oder Signale sind im aktuellen Entwicklungsstand nicht vorgesehen, da der Fokus auf einer nahtlosen Integration in bestehende Druck-Workflows liegt.

== Service und Unterstützung

_ClothoPus_ ist bewusst als Open-Source-System konzipiert. Sowohl die Softwarekomponenten als auch die Hardwareentwürfe sind offen zugänglich und dokumentiert. Dadurch wird es Dritten ermöglicht, das System nachzubauen, anzupassen und weiterzuentwickeln.

Im Gegensatz zu klassischen, proprietären Smart-Systemen basiert das Unterstützungsmodell nicht primär auf einem zentralisierten Kundendienst, sondern auf einer kollaborativen Community-Struktur. Anwender und Entwickler können Fehlerberichte einreichen, Verbesserungsvorschläge diskutieren und eigene Erweiterungen beitragen. Dieser offene Entwicklungsansatz entspricht der in der 3D-Druck-Community etablierten Praxis und fördert Transparenz sowie Innovationsgeschwindigkeit.

Die Offenlegung der Hard- und Software erlaubt es zudem, das System an individuelle Anforderungen anzupassen. Beispielsweise können alternative Sensoren integriert, zusätzliche Schnittstellen implementiert oder neue Visualisierungsfunktionen entwickelt werden. Auch mechanische Anpassungen lassen sich auf Basis der Konstruktionsdaten realisieren.

#pagebreak()
= Fazit und Ausblick
Das im Rahmen dieses Projekts entwickelte System _ClothoPus_ erfüllt die in der Zielsetzung formulierten Anforderungen.
Es wurde ein integriertes Gesamtsystem realisiert, das Filamentrollen automatisiert wiegt, NFC-Tags eindeutig identifiziert und die gewonnenen Informationen innerhalb von OctoPrint bereitstellt.
Sowohl die mechanische Auslegung der Filamentstationen als auch die elektronische und softwareseitige Integration konnten erfolgreich umgesetzt werden.
Die Gewichtserfassung erfolgt kontinuierlich, die Identifikation der Filamente ist standardkonform implementiert, und die Visualisierung der Daten innerhalb der bestehenden Druckmanagementumgebung ermöglicht einen praxisnahen Einsatz.
Damit wurde das zentrale Projektziel erreicht: die Automatisierung der Filamentverwaltung sowie die Reduktion manueller Mess- und Kontrollprozesse.
Hinsichtlich einer möglichen Kommerzialisierung ist festzuhalten, dass _ClothoPus_ konzeptionell als Open-Source-Lösung gedacht ist.
Die Software basiert auf OctoPrint, welches vollständig Open-Source entwickelt wird. Auch die Erweiterung in Form des Plugins folgt diesem Ansatz.
Eine direkte Vermarktung als klassisches kommerzielles Produkt würde dem Open-Source-Grundgedanken entgegenstehen und müsste mit einer klar definierten Geschäftsstrategie verbunden werden.
Mögliche Ansätze könnten beispielsweise Kooperationen mit Filamentherstellern sein. Denkbar wäre eine optionale Integration produktspezifischer Informationen innerhalb des Plugins oder eine Bestellfunktion bei niedrigem Filamentstand. In einem solchen Modell könnte eine provisionsbasierte Finanzierung erfolgen, ohne die Offenheit der Kernlösung einzuschränken.
Ein weiterer wesentlicher Aspekt für eine nachhaltige Weiterentwicklung ist der Aufbau einer aktiven Community.
Durch die Offenlegung von Hard- und Softwarekomponenten kann das System kontinuierlich verbessert, erweitert und an unterschiedliche Anwendungsfälle angepasst werden. Insbesondere im Umfeld des 3D-Drucks ist dieser kollaborative Entwicklungsansatz etabliert und fördert Innovationsgeschwindigkeit sowie Akzeptanz.
Im aktuellen Entwicklungsstand ist das System funktional, jedoch noch nicht feature-complete.
Die grafische Darstellung innerhalb von OctoPrint ist bewusst schlank gehalten und bietet Potenzial für Erweiterungen, beispielsweise durch ein digitales Filamentinventar, Verlaufsanalysen des Materialverbrauchs oder eine automatisierte Bestandsverwaltung über mehrere Drucker hinweg.
Insbesondere die Realisierung eines digitalen Filamentinventars würde eine weiterführende Anpassung der Systemarchitektur erfordern.  
Die derzeitige kabelgebundene Anbindung der Filamentstationen an die zentrale Steuereinheit begrenzt sowohl die räumliche Flexibilität als auch die Anzahl integrierbarer Stacks.
Eine zukünftige Ausbaustufe könnte daher auf funkbasierte Mikrocontroller innerhalb der einzelnen Filamentstationen setzen, beispielsweise auf Basis eines ESP32.  
Jeder Stack würde Sensordaten eigenständig erfassen und drahtlos an eine zentrale Instanz übertragen. Dadurch ließe sich die physikalische Verkabelung eliminieren und das System nahezu beliebig skalieren.
Eine solche dezentrale, funkbasierte Architektur würde _ClothoPus_ von einem lokal gebundenen Messsystem zu einer skalierbaren, verteilten Smart-Inventory-Lösung weiterentwickeln und die Grundlage für ein umfassendes, netzwerkbasiertes Filamentmanagement schaffen.




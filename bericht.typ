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

// Inhaltsverzeichnis
#set page(numbering: "1")
#outline(
  title: "Inhaltsverzeichnis", 
  indent: 1.5em
)
#pagebreak()

= Einleitung
== Motivation
Im Bereich der privaten Nutzung von 3D-Druck Techniken, spezifisch Fused Deposition Modelling (FDM) und Fused Layer Modelling (FLM) ist das Filament als Fertigungsmaterial ein Kernbestandteil.  
Ein häufiges Problem, das sowohl in der persönlichen Arbeit als auch in der FLM/FDM-Community identifiziert wurde, ist die regelmäßige und umständliche Überprüfung des Filamentbestandes.  
Diese umfasst im Mindesten das Überprüfen des aktuell eingebauten Filemants, das Demontieren der Filamentrolle aus dem Drucker selbst, einer anschließenden Gewichtsmessung inklusive Subtraktionsrechnung des Eigenwichts der Filemantrolle selbst und schließlich erneutem Einsetzen des Filaments im Vorfeld des eigentlichen Fertigungsprozesses. 
Besonders bei der Arbeit mit mehreren Filamenten innerhalb eines Druckvorgangs, wo dieser Vorgang im Notfall für jedes Filemant durchgeführt werden muss, kann so ein großer Zeitaufwand entstehen.  
In Zeiten, in denen verfügbare Zeit und ihrer effizienten Nutzung indirekt stets an Wert zunimmt, ist die Entwicklung einer zeitsparenderen Lösung unabdingbar.
Durch die kontiuierlich sinkenden Preise für Druckgeräte wächst die Anzahl der Nutzer mehr und mehr.

Um dieses Problem zu entschärfen präsentieren wir _Clothopus_, ein smartes System zur automatischen Registrierung und Gewichtsmessung von bis zu fünf Filamenten zeitgleich. 
_Clothopus_ verlegt den Fokus für den Nutzer zurück auf die Kernaufgabe des Designens und sorgt so für einen angenehmeren Workflow.

== Zielsetzung
_Clothopus_ soll den Nutzern als ein inuitives und schlankes System zur Filemantverwaltung und -übersicht dienen, dass die zeitlichen Anfordungen an nebensächlich anfallende Aufgaben reduziert.  
Präziser umfasst dies das automatisierte Identifizieren und Vermessen der in den Drucker eingesetzten Filamente.  
Über eine entsprechende Software können die Nutzer die aktuell eingesetzten Filamente samt Gewichtsangabe einsehen.
Die Handwarekomponente des Produkt setzt sich zusammen aus fünf identischen Filamentstationen sowie einer zentralen Box mit verbauten Komponenten zur Evaluation der Messdaten.
Zusätzlich zu externen RFID-Tags ist _Clothopus_ explizit mit neuen Filemantprodukten der Marke Prusa Research, die seit Kurzem

== Vorgehensweise
Der Einsatz von Techniken aus dem Bereich der Radio-Frequency-Identification sowie unaufällig eingesetzen Wägezellen bieten eine elegante Lösung zur Filamentüberwachung. 

#pagebreak()
= Projektmanagement
== Work Breakdown Structure
== Organisational Breakdown Structure
== Projektplan
== Vorgehensmodell in der Entwicklung

#pagebreak()
= Entwurf und Implementierung
== Produkt und Vernetzung
_Clothopus_ ist als modulares, vernetztes Smart-System zur automatisierten Filamentverwaltung im Bereich des privaten und semiprofessionellen 3D-Drucks konzipiert.  
Das Produkt dient der kontinuierlichen Identifikation und Gewichtserfassung mehrerer Filamentrollen und stellt diese Informationen externen Druckmanagementsystemen zur Verfügung.

Das Gesamtsystem besteht aus mehreren identischen Filamentstationen sowie einer zentralen Steuereinheit.  
Jede Filamentstation, im Folgenden als Stack bezeichnet, ist für die Aufnahme genau einer Filamentrolle ausgelegt und integriert sowohl eine Wägezelle zur Gewichtsmessung als auch einen NFC-Reader zur Identifikation des eingesetzten Filaments.  
Durch die modulare Auslegung können bis zu fünf Stacks parallel innerhalb eines Systems betrieben werden.

Als zentrale Steuereinheit kommt ein Raspberry Pi 4 zum Einsatz.  
Dieser übernimmt die zyklische Abfrage der angeschlossenen Stacks, die Vorverarbeitung und Plausibilisierung der Sensordaten sowie die eindeutige Zuordnung von Gewichtsmessungen zu den identifizierten Filamenten.  
Darüber hinaus stellt der Raspberry Pi die gesammelten Informationen über eine Netzwerkverbindung für externe Softwarekomponenten bereit.

Die interne Kommunikation zwischen den Filamentstationen und der zentralen Steuereinheit erfolgt über ein unser 11-Pin-Kommunikationssystem.  
Dieses Interface dient sowohl der Spannungsversorgung der Sensorik als auch der bidirektionalen Datenübertragung.  
Über die Verbindung werden Messwerte der Wägezelle, Identifikationsdaten des NFC-Readers sowie Status- und Steuerinformationen übertragen.  
Die Bündelung aller relevanten Signale in einem einheitlichen Stecksystem vereinfacht die mechanische Integration, den modularen Ausbau sowie Wartungsarbeiten.

Zur externen Vernetzung ist der Raspberry Pi 4 über WLAN oder Ethernet in das lokale Netzwerk des Nutzers eingebunden.  
Über diese Verbindung werden die erfassten Filamentdaten an angeschlossene Anwendungen übermittelt, beispielsweise an Druckmanagement-Software wie OctoPrint.  
Dem Nutzer stehen dadurch jederzeit aktuelle Informationen über eingesetzte Filamente und verfügbare Restmengen zur Verfügung, ohne dass manuelle Messungen erforderlich sind.

== Technologie und Daten
=== Sensoren und Eingänge (Beteiligter A)

Als primäre Sensorkomponenten kommen in jedem Filament-Stack eine Wägezelle sowie ein NFC-Reader zum Einsatz.  
Die Gewichtserfassung erfolgt über eine einzelne Wägezelle pro Stack, deren Messsignal mittels eines HX711-Verstärker- und ADC-Moduls digitalisiert wird.  
Der HX711 stellt die gemessenen Gewichtswerte über eine taktgesteuerte Schnittstelle bereit und ermöglicht eine hochauflösende Erfassung auch geringer Gewichtsänderungen.

Zur Identifikation der Filamente wird ein NFC-Reader des Typs PN5180 verwendet.  
Dieser unterstützt mehrere NFC-Standards, wobei im Rahmen des Projekts gezielt der ISO-15693-Standard (NFC-V) genutzt wird, da dieser den Spezifikationen der OpenPrintTags entspricht.  
Über den NFC-Reader werden sowohl Identifikations- als auch Zusatzdaten der Filamenttags erfasst.

Die Kombination aus Gewichtsmessung und eindeutiger Filamentidentifikation bildet die Grundlage für eine automatisierte und zuverlässige Erfassung aller relevanten Eingangsdaten des Systems.

=== Connectivity (Beteiligter B)

Die interne Anbindung der Filament-Stacks an die zentrale Steuereinheit erfolgt über ein proprietäres 11-Pin-Kommunikationssystem.  
Über diese Verbindung werden sowohl die Spannungsversorgung als auch die Datenübertragung realisiert.

Die Kommunikation mit dem PN5180-NFC-Reader erfolgt über eine SPI-Schnittstelle, über die Steuer- und Nutzdaten ausgetauscht werden.  
Die Anbindung der Wägezelle erfolgt über das HX711-Modul, welches über dedizierte Takt- und Datenleitungen ausgelesen wird.

Zur externen Vernetzung stellt die zentrale Steuereinheit die erfassten Daten über eine modulare Softwareschnittstelle bereit.  
Aktuell ist das System in ein OctoPrint-Plugin eingebunden, wobei die Datenübertragung über eine REST-API erfolgt.  
Durch diese Architektur kann _Clothopus_ flexibel in bestehende Systeme integriert oder zukünftig um weitere Kommunikationsschnittstellen erweitert werden.

=== Data Analytics (Beteiligter C)

Die erfassten Sensordaten werden auf der zentralen Steuereinheit verarbeitet und logisch miteinander verknüpft.  
Hierbei erfolgt die eindeutige Zuordnung von Gewichtsmessungen zu den identifizierten Filamenten anhand der ausgelesenen NFC-Tag-Informationen.

Eine Tara- und Kalibrierungsroutine stellt sicher, dass die Gewichtsmessung präzise und reproduzierbar erfolgt.  
Diese Kalibrierung wird einmalig während der Einrichtung der Filamentstationen durchgeführt und softwareseitig unterstützt.

Neben der reinen Anzeige des aktuellen Filamentgewichts wird dieses zusätzlich in einem definierten Speicherbereich des NFC-Tags (Aux-Region) abgelegt.  
Dadurch wird das Filament selbstzustandsbehaftet, da relevante Informationen direkt auf dem Tag gespeichert und unabhängig vom System wieder ausgelesen werden können.

=== Aktoren und Ausgänge (Beteiligter D)

Die Ausgabe der verarbeiteten Daten erfolgt vollständig softwareseitig über das Webinterface von OctoPrint.  
Dem Nutzer werden dort Informationen über das aktuell eingesetzte Filament sowie dessen verbleibendes Gewicht übersichtlich dargestellt.

Zusätzlich zur Visualisierung stellt das System die Daten über eine Programmierschnittstelle bereit, sodass sie von weiteren Softwarekomponenten oder Erweiterungen genutzt werden können.  
Physische Aktoren wie Anzeigen oder Signale sind im aktuellen Entwicklungsstand nicht vorgesehen, da der Fokus auf einer nahtlosen Integration in bestehende Druck-Workflows liegt.

Ein besonderer technischer Schwerpunkt des Projekts liegt in der Entwicklung der NFC-Kommunikation.  
Auf Basis eines bestehenden Open-Source-Treibers wurde durch das Projektteam eine vollständige Erweiterung um Lese- und Schreibfunktionen gemäß der offiziellen OpenPrintTag-Spezifikation implementiert.  
Während der ursprüngliche Treiber lediglich einfache Inventory-Anfragen unterstützte, wurden sämtliche Datenblock-Operationen eigenständig entwickelt.

Die Kommunikation mit dem PN5180 erfolgt dabei auf niedriger Abstraktionsebene durch den Versand selbst definierter Datenframes in hexadezimaler Form über die SPI-Schnittstelle.  
Dies ermöglicht eine direkte, standardkonforme Interaktion mit den ISO-15693-Tags und stellt eine zentrale technische Eigenleistung des Projekts dar.

== Organisation und Management
== Menschen und Kultur
== Business und Ökosystem
Beschreibung des Business Cases inkl. Abschätzung von Kosten in der Serie, Preisen, Margen. Ideen zur Finanzierung eines Ramp-Ups. 

#sym.arrow.r.double Die Nutzungs des Systems für Endverbraucher setzt zunächst den Erwerb der benötigten Hardwarekomponenten voraus. 
Zusammen mit dem physischen Produkt stehen zunächst Basisfunktionen zur Verfügung. 
Über ein Abonnement-Modell oder den einmalige Zahlung können in jeder Produktiteration erweiterte Features genutzt werden.

== Service und Unterstützung

#pagebreak()
= Fazit und Ausblick
Abgleich mit den initial beschriebenen Zielen
Was muss passieren um ein kommerzielles Smart System vermarkten zu können?



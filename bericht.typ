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
== Technologie und Daten
=== Sensoren und Eingänge (Beteiligter A)
=== Connectivity (Beteiligter B)
=== Data Analytics (Beteiligter C)
=== Aktoren und Ausgänge (Beteiligter D)
== Organisation und Management
== Menschen und Kultur
== Business und Ökosystem
Beschreibung des Business Cases inkl. Abschätzung von Kosten in der Serie, Preisen, Margen. Ideen zur Finanzierung eines Ramp-Ups. 

=> Die Nutzungs des Systems für Endverbraucher setzt zunächst den Erwerb der benötigten Hardwarekomponenten voraus. 
Zusammen mit dem physischen Produkt stehen zunächst Basisfunktionen zur Verfügung. 
Über ein Abonnement-Modell oder den einmalige Zahlung können in jeder Produktiteration erweiterte Features genutzt werden.

== Service und Unterstützung

#pagebreak()
= Fazit und Ausblick
Abgleich mit den initial beschriebenen Zielen
Was muss passieren um ein kommerzielles Smart System vermarkten zu können?



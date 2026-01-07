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

=	Einleitung
== Motivation
== Zielsetzung
== Vorgehensweise


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
== 3.6 Service und Unterstützung

#pagebreak()
= Fazit und Ausblick
Abgleich mit den initial beschriebenen Zielen
Was muss passieren um ein kommerzielles Smart System vermarkten zu können?



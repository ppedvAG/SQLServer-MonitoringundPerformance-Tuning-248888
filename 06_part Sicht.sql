/*
Welche Tabelle wird schneller ein Ergebnis iefern:

TAB A 10000 DS
TAB B 1000000 DS

beide Tabellen sind absolut gleich, sie haben nur versch Anzahl an DS

Die Abfrage bingt immer nur 3 Zeilen zurück

-- kleinere ist schneller.. Indizes

*/

--Idee große Tabelle Umsatz muss schneller werden
--aus Umsatz wird u2021 u2020 u2019 usw...
--Problem: Die Abfrage auf Umsatz geht nicht mehr!!!



create table u2021(id int , jahr int, spx int)
create table u2020(id int , jahr int, spx int)
create table u2019(id int , jahr int, spx int)

--Problem: wo ist mein "UMSATZ"

create view UMSATZ
as
select * from u2021
UNION ALL --keine doppelte Zeilensuche
select * from u2020
UNION ALL
select * from u2019
GO


USE [testdb]
GO

ALTER TABLE [dbo].[u2019]  WITH CHECK ADD  CONSTRAINT [CK_u2019] CHECK  (([jahr]=(2019)))
GO
ALTER TABLE [dbo].[u2019] CHECK CONSTRAINT [CK_u2019]
GO


select * from UMSATZ --Sicht=gemerkte Abfrage

--bisher 0 Optimierung
select * from UMSATZ
select * from UMSATZ where jahr = 2021

--aber.. INS UP DEL
--muss gelten. Kein identity, der PK muss aus mind 2 Spalten bestehen
--so dass der DS über die Sicht eindeutig wird


--Partitionierung

--Dateigruppe

create table test3 (id int) on HOT

  select * from UMSATZ where ID= 2021

--TÜV Siegel
--Garantie

--Problem: bei Insert
--aber dann darf kein identity, PK muss eindeutig über die Sicht (jahr und id)


create table test2 (id int) on HOT






--im Plan sieht man, dass er nach den Einschränkungen 
--nur noch die Tabelle verwendet, in der die Daten sein könnten..

select * from UMSATZ where jahr= 2019
select * from UMSATZ where id= 2018

--Aber was ist mit INS UP DEL
--eine Sicht kann INS UP DEL haben

--Aber in unserem Fall: kein Identity
--                      PK muss eindeutig über die Sicht
						--(ID und jahr)

--hmm APP geht nicht mehr

--für Archivierung ok, aber bei INS UP DEL. ziemlich blöd










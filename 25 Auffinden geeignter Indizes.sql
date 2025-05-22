---Auffinden geeignter Indizes
-- Suchen nach Platzhaltern

--Was ist gut und was ist schlecht?
--SARG!!


select * from tabelle where name like '%der'

select * from tabelle where name like '%der'



--keine SARG
--Abfragen mit or kann dazu f�hren, dass Indizes nicht verwendet werden
--ebenfalls all, Some, in


--Vermeiden von Spaltenausdr�cken
select * from tabelle where bestelldatum + 30 > CURRENT_TIMESTAMP
--wie besser??


--keine Funktionen in Where 
select * from tabelle where LEFT(name,1) = 'M'
--besser mit?
select * from tabelle where MONTH(besteldatum) = 10

select * from tabelle where year(besteldatum) = 2010





--Auswahl des gruppierten Index
--gibts genau 1 man--
--Primary Key??
--uniqueidentifier

--schlechtes Beispiel:
create table verkauf
	(
	verkaufid uniqueidentifier not null default newid() primary key,
	verkaufsdatum date date not null default current_timestamp
	)

--besser: schon mal ..newsequentialid()...
--bei nicht abdeckenden Suchen
--Schl�sselsuche:  Suche im gruppierten Index (teuer)
--rowID Lookup: Direkte Verweise auf Datenseiten
--indexsuche auf Schl�sselwerte kann teurer werden als Table Scan oder Index Scan


--um einen Index zu verwenden , der nicht abdeckend ist bedarf es hoher Selektivit�t

use QueryTest;
-- Anlegen einer Tabelle f�r den Test
if (object_id('Person', 'U') is not null)
  drop table Person
go
select BusinessEntityID as Id
      ,LastName         as Nachname
      ,FirstName        as Vorname
  into Person 
  from AdventureWorks2008.Person.Person
go


create index IX_PTP_Id on .Person(Id) include (Vorname)
go
select Nachname from Person where Id<12000
go
--Table Scan: ca 11000 Zeilen


--mit Index?
select Nachname from Person with (index=IX_PTP_Id) where Id<12000
go

--Anzeigen der Statistischen Information IO!!


--Wie selektiv muss die Abfrage sein
--evtl vorhandenen automatisch parametrisierten Plan ignorieren...
select Nachname from Person where Id<40 option (recompile)
go

-- 40 w�re tats�hlich die Grenze... entpricht 0,2% der Werte.. normalerweise bereits ab 100 Zeilen



set statistics io on
select Nachname from Person where Id<50
select Nachname from Person with (index=IX_PTP_Id) where Id<50
go



set statistics io on
select Nachname from Person where Id<100
select Nachname from Person with (index=IX_PTP_Id) where Id<100
go

--Abw�gung ob Table Scan etc..betrifft nur bei nicht abdeckenden Indizes 

-- Die % - Selektivit�t f�r eine Indexverwendung ist allerdings nicht genau vorhersagbar
-- zudem h�ngt dies auch von der Tabellenbreite ab...


alter table Person 
  add BreiteSpalte nchar(2000) not null default'#'
go

--trotz grosser Ergebnismenge: index verwendung
--Index immer noch besser als Tabelle, da nicht alle Tabellenseiten durchsucht werden m�ssen
select Nachname from Person where Id<5000 option (recompile)
go


--Arbeiten mit included Spalten
--Index mit included wurde bereits oben angelegt..
--obwohl nicht so selektiv, dennoch Verwendung des Index Seek..abdeckend!
select Vorname from Person where Id<12000
go

-- Fazit:
-- Abdeckene Indizes:
-- super.. aber eigtl nur f�r spezielle Abfragen
-- kein Select * verwenden



--------Richtiger Index?? Welcher

set statistics io on

drop table kfz

go
create table Kfz
 (
   FgstNr char(36) not null primary key
  ,Kennzeichen char(10) not null unique
  ,Erstzulassung date not null
  -- Platzhalter. Steht stellvertretend f�r weitere Spalten
  ,Platzhalter char(500) null
 )
go

-- F�ge 1.000.000 Zeilen in die Tabelle ein
insert Kfz(FgstNr,Kennzeichen,Erstzulassung)
 select newid()                                              as FgStNr
       ,char(65 + abs(checksum(newid())) % 26)
          + char(65 + abs(checksum(newid())) % 26) + '-'
          + right('000000' + cast(n as varchar(7)), 6)       as Kennzeichen
       ,dateadd(d,-abs(checksum(newid())) % 1000,'20081231') as Erstzulassung
   from querytest..Numbers
  where n <= 1000000
go

set statistics io on
set statistics time on

-- Alle Fahrzeuge, die im Mai 2006 zugelassen wurden
--sehr teuere Abfrage .. Parallelism wurde eingef�hrt..
select Kennzeichen, FgstNr, ErstZulassung
  from Kfz
 where Erstzulassung between '20060501' and '20060531'
 order by Kennzeichen
go

Kosten 80, 103346 Lesevorg�nge


--vorgeschlagenen Index

create nonclustered index Ix_Kfz_EZ_FgStNr_KZ
    on Kfz (Erstzulassung) include (FgstNr, Kennzeichen)
go

--deutlich besser!
select Kennzeichen, FgstNr, ErstZulassung
  from Kfz
 where Erstzulassung between '20060501' and '20060531'
 order by Kennzeichen
go

Kosten 2,2 .. 206 Lesevorg�nge

--Sortieren so hohe Kosten.. hmm


drop index Ix_Kfz_EZ_FgStNr_KZ on kfz
go

--Abfrage ge�ndert .. deutlich mehr Datens�tze 2005 bis 2007
--Ausf�hrungsplan: Indexhinweise derselbe wie oben... obwohl deutlich mehr Zeilen zur�ckgeliefert werden.. > 50%
--order by wird ignoriert..??
select Kennzeichen, FgstNr, Erstzulassung
  from Kfz
 where Erstzulassung between '20050101' and '20071231'
 order by Kennzeichen
go

Kosten: 103345 Lesevorg�nge , 133



--nochmals die Abfrage mit vorgeschlagegen Index
--bessser, aber seltsam da hoher Verbrauch f�r Sortierung 
CREATE NONCLUSTERED INDEX ix_Erst
ON [dbo].[Kfz] ([Erstzulassung]) INCLUDE ([FgstNr],[Kennzeichen])


select Kennzeichen, FgstNr, Erstzulassung
  from Kfz
 where Erstzulassung between '20050101' and '20071231'
 order by Kennzeichen
go

Kosten: 59 , 4120

--besser w�re wohl: 
create index IxKfz_Kennzeichen
    on Kfz(Kennzeichen) include (FgStNr,Erstzulassung)
go

drop index ix_Erst on KFZ


select Kennzeichen, FgstNr, Erstzulassung
  from Kfz
 where Erstzulassung between '20050101' and '20071231'
 order by Kennzeichen
go


Kosten 5,8  6498  

--deutlich g�nstiger.. obwohl fehlnder Index angezeigt wird
--indizes werden auf E/A optimiert aber nicht auf order by




------Foreign Key!!
-- PK erzeugt immer einen Index, aber nicht FK


create table KfzTyp
 (
  KfzTypID int identity(1,1) not null primary key
 ,TypName nvarchar(100) not null
 ,MaximalGewicht int not null
 )
go

insert KfzTyp(TypName, MaximalGewicht)
  values ('PKW', 2300)
        ,('Kleintransporter', 3500)
        ,('LKW', 35000)
go

alter table Kfz
  add KfzTypID int null
go

update Kfz set KfzTypID = 1 + abs(checksum(newid())) % 3
go

alter table Kfz
  alter column KfzTypID int not null 
go
alter table Kfz
  add constraint FK_Kfz_KfzTyp
     foreign key (KfzTypID) references KfzTyp(KfzTypID)
go


--R�ckgabe von LKWs
select Kfz.*
  from Kfz
       inner join KfzTyp on KfzTyp.KfzTypID = Kfz.KfzTypID
 where KfzTyp.TypName = 'LKW'
go

--vorgeschlagener Index auf KFZTypID nicht besonders hlfreich...da nicht besonders selektiv
--einzig ein abdeckender index auf kfztypid


--was wenn..
--was wenn ein Wert eingef�gt wird, der keinen DS in KFZ aufweist...??
--sobald man diesen Wert l�scht m�sste jede Zeile in KFZ auf FK Werte �berpr�ft werden...


insert KfzTyp(TypName, MaximalGewicht)
 values ('Fahrrad', 10)


---L�sung..??



--hier w�re ein Index auf KFZTYPId gut, da  Referenz �berpr�ft werden muss...also alle FKs
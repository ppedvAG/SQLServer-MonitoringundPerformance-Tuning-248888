/*
https://learn.microsoft.com/de-de/sql/t-sql/database-console-commands/dbcc-traceon-trace-flags-transact-sql?view=sql-server-ver16


*/
--Startparameter per SQL KOnfigmanager -Txxxx
--oder per TSQL
-- Traceflags k�nnen das Verhalten des SQL Server ver�ndern
--es gibt viele TRaceflags.. ohne gro�e Ordnung
--hier ein paar, die man sich �berlegen kann

dbcc Traceon(Nummer, -1) --auf allen Ebenen aktiviert
select * from tabelle OPTION (QUERYTRACEON 4199, QUERYTRACEON 4137) --f�r Abfrage

dbcc traceoff(nummer,nummer,  -1)--Traceflag deaktivieren

dbcc tracestatus (-1)--welche sind global aktiviert
--Status 1 ON   0 OFF
--Global 1 = true  0 = False
--Sitzung 1=True 0 = False


dbcc tracestatus (1118, 1117)-- aktiviert?
dbcc traceon (3226,-1) --setzen--> Only Successful Backups in History

3042 so that backups don�t write out the full size before being compressed at the end 

9567 Legacy Cardinal Estimation

7752: Asynchronous load of Query Store.
I would rather get databases up faster than wait for Query Store to finish loading.
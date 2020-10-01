DECLARE @counter INT = 1;-- Compteur pour les societes
DECLARE @societe_current varchar(100);-- Variable pour stocker le nom de la societe en cours
DECLARE @LST_SOCIETES TABLE(ID INT IDENTITY, NOM_SOCIETE VARCHAR(100))-- Table temporaire pour stocker le nom des societes � traiter
DECLARE @Sql varchar(1000)-- Variable temporaire pour ecrire une requete SQL � executer

-- j'initialise les societes dans ma table tempoare @LST_SOCIETES
INSERT INTO @LST_SOCIETES
    (NOM_SOCIETE)
VALUES
    ('TI'),
    ('COMUNDI'),
    ('TISSOT'),
    ('WEKA');


-- Cette partie permet de realiser des statistiques sur chaqu'une des societes
SET @counter = 1
DECLARE @sql_stats varchar(1000)
DECLARE @NBR_societes int
SET @NBR_societes = (SELECT count(*) FROM @LST_SOCIETES)

WHILE @counter <= (SELECT count(*) FROM @LST_SOCIETES)
BEGIN
	SET @societe_current = (SELECT NOM_SOCIETE FROM @LST_SOCIETES WHERE ID = @counter);

	-- Permet d'afficcher le nombre d'emails qui vont etre supprimès
	SET @sql='SELECT ''NB_mail_supprime'',count(*),'''+@societe_current+''',  DATEFROMPARTS ( DATEPART(YEAR, DATEADD(year, 3, '+@societe_current+')), DATEPART(month, '+@societe_current+'), 01 )
	FROM DATA_ADMIN_EMAIL_GRP_WEKAFR
	WHERE '+@societe_current+' > DATEADD(year, -3, GETDATE())
	GROUP BY DATEFROMPARTS ( DATEPART(YEAR, DATEADD(year, 3, '+@societe_current+')), DATEPART(month, '+@societe_current+'), 01 )';

	SET @sql_stats='INSERT INTO STATS_SOCIETES (TYPE_STAT,VALEUR,SOCIETE,DATE_SUPPRESSION) '+@sql+'';
	exec( @sql_stats);

SET @counter += 1
END;


INSERT INTO STATS_SOCIETES (TYPE_STAT,VALEUR,SOCIETE,DATE_SUPPRESSION)

SELECT 'NB_mail_supprime',count(*),'GLOBAL',  DATEFROMPARTS ( DATEPART(YEAR, DATEADD(year, 3, DATE_DERNIERE_ACTIVITE)), DATEPART(month, DATE_DERNIERE_ACTIVITE), 01 )
	FROM DATA_ADMIN_EMAIL_GRP_WEKAFR
	WHERE DATE_DERNIERE_ACTIVITE > DATEADD(year, -3, GETDATE())
	GROUP BY DATEFROMPARTS ( DATEPART(YEAR, DATEADD(year, 3, DATE_DERNIERE_ACTIVITE)), DATEPART(month, DATE_DERNIERE_ACTIVITE), 01 );
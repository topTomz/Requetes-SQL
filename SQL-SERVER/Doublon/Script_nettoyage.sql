 DECLARE @counter INT = 0;-- Compteur pour les societes
DECLARE @counter_TABLE INT = 1;-- Compteur pour les tables des users
DECLARE @societe_current varchar(100);-- Variable pour stocker le nom de la societe en cours
DECLARE @table_users varchar(100);-- Variable pour stocker le nom d'une table de USERS
DECLARE @LST_SOCIETES TABLE(ID INT IDENTITY, NOM_SOCIETE VARCHAR(100))-- Table temporaire pour stocker le nom des societes � traiter
DECLARE @LST_TABLES_USERS TABLE(ID INT IDENTITY, NOM_TABLE VARCHAR(100))-- Table temporaire pour stocker le nom des tables USERS
DECLARE @Sql varchar(1000)-- Variable temporaire pour ecrire une requete SQL � executer

TRUNCATE TABLE TMP_USERS_ONLY

INSERT INTO @LST_TABLES_USERS(NOM_TABLE) SELECT table_name FROM information_schema.tables
    WHERE table_name LIKE 'USERS[_]COMUNDI%'
    -- Incrementation du compteur pour passer � la societe suivante

    -- Cette partie permet de boucler sur chaque table USERS_ afin de selectionner les mails d'une table de fa�on unique et de les inserer dans la table @LST_TABLES_USERS
    WHILE @counter_TABLE <= (SELECT max(ID) FROM @LST_TABLES_USERS)
	BEGIN
        SET @table_users=(SELECT NOM_TABLE FROM @LST_TABLES_USERS WHERE ID = @counter_TABLE)-- la table sur la quelle la recherche va s'effectuer
		-- Permet d'integrer un mail avec sa societe dans la table TMP_USERS_ONLY
        SET @sql= 'INSERT INTO TMP_USERS_ONLY (MAIL, NOM_TABLE)
		SELECT DISTINCT MAIL,'''+@table_users+'''
		FROM '+@table_users+' T1 WITH(NOLOCK)
		WHERE MAIl IS NOT NULL AND NOT EXISTS  (
		SELECT MAIL
		FROM TMP_USERS_ONLY T2
		WHERE T1.MAIL = T2.MAIL
		)';

		exec(@sql);
        SET @counter_TABLE =@counter_TABLE+1 -- passe a la table suivante
    END


SELECT * FROM @LST_TABLES_USERS




SELECT *
		FROM TMP_USERS_ONLY WITH(NOLOCK)
		WHERE MAIl IS NOT NULL AND PATINDEX('%[^a-z,0-9,@,.,_]%', REPLACE(MAIL, '-', 'a')) = 1
		                                        -- si dans 'MAIL' il y a un caractere pas present ci dessus alors on obtient 1 et si c'est egal a  1 alors on retient la ligne
DELETE
		FROM USERS_COMUNDI_EMAILS
		WHERE MAIl IS NOT NULL AND PATINDEX('%[^a-z,0-9,@,.,_]%', REPLACE(MAIL, '-', 'a')) = 1





@SOCIETE NVARCHAR(250)

AS
BEGIN
SET NOCOUNT ON;

-- Variable temporaire pour ecrire une requete SQL à executer
DECLARE @sql varchar(1000)

-- Table temporaire pour stocker le nom des societes à traiter
DECLARE @LST_SOCIETES TABLE(ID INT IDENTITY, NOM_SOCIETE VARCHAR(100))

-- Compteur pour les societes
DECLARE @counter INT

-- j'initialise les societes dans ma table temporaire @LST_SOCIETES
INSERT INTO @LST_SOCIETES
    (NOM_SOCIETE)
SELECT * FROM STRING_SPLIT(@SOCIETE, ',')

-- Cette partie permet de preparer un paterne pour la mise à jour de 'DATE_DERNIERE_ACTIVITE -->
DECLARE @Sql_maker_societe varchar(1000)

SET @Sql_maker_societe_activite = NULL
SET @Sql_maker_societe_creation = NULL
SET @counter = 1
WHILE @counter <= (SELECT count(*) FROM @LST_SOCIETES)

--count(value) FROM STRING_SPLIT(@SOCIETE, ',')
BEGIN
	IF @Sql_maker_societe is NULL -- Cette partie permet d'eviter ',' en debut
		SET @Sql_maker_societe_activite = '('+(SELECT NOM_SOCIETE FROM @LST_SOCIETES WHERE ID = @counter)+'_ACTIVITE_DT)';
		--SET @Sql_maker_societe_creation = '('+(SELECT NOM_SOCIETE FROM @LST_SOCIETES WHERE ID = @counter)+'_CREATION_DT)'
	ELSE
		SET @Sql_maker_societe_activite += ',('+(SELECT NOM_SOCIETE FROM @LST_SOCIETES WHERE ID = @counter)+'_ACTIVITE_DT)';
		--SET @Sql_maker_societe_creation += ',('+(SELECT NOM_SOCIETE FROM @LST_SOCIETES WHERE ID = @counter)+'_CREATION_DT)'
	SET @counter +=  1
END;


-------------------------------------------------------------------FIN PARTIE DECLARATIVE---------------------------------------------------------------


-- Permet de mettre a jour la colonne 'DATE_DERNIERE_ACTIVITE'
SET @sql='UPDATE DATA_ADMIN_EMAIL_GRP_WEKAFR
SET DERNIERE_ACTIVITE_DT = (SELECT Max(v) FROM (VALUES '+@Sql_maker_societe_activite+') AS value(v))';
EXEC(@sql); -- Execute la requete


-- Permet de mettre a jour la colonne 'PREMIERE_CREATION_DT'
--SET @sql='UPDATE DATA_ADMIN_EMAIL_GRP_WEKAFR
--SET PREMIERE_CREATION_DT = (SELECT Max(v) FROM (VALUES '+@Sql_maker_societe_creation+') AS value(v))';
--EXEC(@sql); -- Execute la requete

END


Execution failed: failed to execute SP (SP_DQ_ADMIN_EMAIL_GROUPEWEKA_MERGE) - [Invalid column name 'TISSOT_ACTIVITI_DT'.] - Unable to execute query [DECLARE	@return_value int ; EXEC @return_value = @SPNAME
@SOCIETE = @SOCIETEVALUE ; SELECT
@return_value as '@return_value'; ]

DROP TABLE TMP_USERS_ONLY
--TRUNCATE TABLE DATA_ADMIN_EMAIL_GRP_WEKAFR

IF OBJECT_ID('dbo.TMP_USERS_ONLY', 'U') IS NULL
	  CREATE TABLE [dbo].[TMP_USERS_ONLY](
	[ID] [int] IDENTITY(1,1) NOT NULL,
	[MAIL] [varchar](255) NULL,
	[SOCIETE] [varchar](10) NULL,
	[NOM_TABLE] [varchar](50) NULL

) ON [PRIMARY]


DECLARE @counter INT = 1;-- Compteur pour les societes
DECLARE @counter_TABLE INT = 1;-- Compteur pour les tables des users
DECLARE @societe_current varchar(100);-- Variable pour stocker le nom de la societe en cours
DECLARE @table_users varchar(100);-- Variable pour stocker le nom d'une table de USERS
DECLARE @LST_SOCIETES TABLE(ID INT IDENTITY, NOM_SOCIETE VARCHAR(100))-- Table temporaire pour stocker le nom des societes � traiter
DECLARE @LST_TABLES_USERS TABLE(ID INT IDENTITY, NOM_TABLE VARCHAR(100))-- Table temporaire pour stocker le nom des tables USERS
DECLARE @Sql varchar(1000)-- Variable temporaire pour ecrire une requete SQL � executer

-- j'initialise les societes dans ma table tempoare @LST_SOCIETES
INSERT INTO @LST_SOCIETES
    (NOM_SOCIETE)
VALUES
 ('TISSOT')
,
 ('COMUNDI')
,
('TI')
,
   ('WEKA')


-- Cette partie Permet de preparer un paterne pour supprimer un ligne dans DATA_ADMIN_EMAIL_GRP_WEKAFR si toutes les entreprises son � NULL -->
DECLARE @Sql_maker_delete varchar(1000) -- Variable pour integrer la requete de suppression d'une ligne
SET @Sql_maker_delete = NULL
SET @counter = 1
WHILE @counter <= (SELECT count(*) FROM @LST_SOCIETES) -- Tant qu'il y a des societes
BEGIN
	IF @Sql_maker_delete is NULL -- Cette partie permet d'eviter AND au debut de la requetes de suppression
		SET @Sql_maker_delete ='DELETE FROM DATA_ADMIN_EMAIL_GRP_WEKAFR WHERE '+(SELECT NOM_SOCIETE FROM @LST_SOCIETES WHERE ID = @counter)+' IS NULL' -- requette de suppression d'une ligne si toutes les societes sont � null
	ELSE -- Cette partie ajoute une societe is null tant qu'il ya des societe
		SET @Sql_maker_delete += ' AND '+(SELECT NOM_SOCIETE FROM @LST_SOCIETES WHERE ID = @counter)+' IS NULL ';
	SET @counter = @counter + 1
END


-- Cette partie permet de preparer un paterne pour la mise � jour de 'DATE_DERNIERE_ACTIVITE -->
DECLARE @Sql_maker_DATE varchar(1000)
SET @Sql_maker_DATE = NULL
SET @counter = 1
WHILE @counter <= (SELECT count(*) FROM @LST_SOCIETES)
BEGIN
	IF @Sql_maker_DATE is NULL -- Cette partie permet d'eviter ',' en debut
		SET @Sql_maker_DATE = '('+(SELECT NOM_SOCIETE FROM @LST_SOCIETES WHERE ID = @counter)+')'
	ELSE
		SET @Sql_maker_DATE += ',('+(SELECT NOM_SOCIETE FROM @LST_SOCIETES WHERE ID = @counter)+')' ;
	SET @counter = @counter + 1
END

-------------------------------------------------------------------FIN PARTIE DECLARATIVE--------------------------------------------------------------------------

-- Vide table TMP_USERS_ONLY
--TRUNCATE TABLE TMP_USERS_ONLY
-- Je boucle sur chaque societe
SET @counter = 1;
WHILE @counter <= (SELECT count(*) FROM @LST_SOCIETES)
BEGIN
    SET @societe_current = (SELECT NOM_SOCIETE FROM @LST_SOCIETES WHERE ID = @counter) -- affecte le nom de la societe en cours
    --  Cherche  toutes les tables de la societe en cours � l'aide de 'information_schema.tables' � inserer dans @LST_TABLES_USERS
    INSERT INTO @LST_TABLES_USERS(NOM_TABLE) SELECT table_name FROM information_schema.tables
    WHERE table_name LIKE CONCAT('USERS_',(
	SELECT NOM_SOCIETE FROM @LST_SOCIETES
    WHERE ID = @counter),'[_]%');
    -- Incrementation du compteur pour passer � la societe suivante
    SET @counter = @counter + 1;
    -- Cette partie permet de boucler sur chaque table USERS_ afin de selectionner les mails d'une table de fa�on unique et de les inserer dans la table @LST_TABLES_USERS
    WHILE @counter_TABLE <= (SELECT max(ID) FROM @LST_TABLES_USERS)
	BEGIN
        SET @table_users=(SELECT NOM_TABLE FROM @LST_TABLES_USERS WHERE ID = @counter_TABLE)-- la table sur la quelle la recherche va s'effectuer
		-- Permet d'integrer un mail avec sa societe dans la table TMP_USERS_ONLY
        SET @sql= 'INSERT INTO TMP_USERS_ONLY (MAIL, SOCIETE, NOM_TABLE)
		SELECT DISTINCT MAIL,'''+@societe_current+''','''+@table_users+'''
		FROM '+@table_users+' T1 WITH(NOLOCK)
		WHERE MAIl IS NOT NULL AND NOT EXISTS  (
		SELECT MAIL
		FROM TMP_USERS_ONLY T2
		WHERE T1.MAIL = T2.MAIL AND T2.SOCIETE = '''+@societe_current+'''
		)';

		EXEC(@sql);
        SET @counter_TABLE =@counter_TABLE+1 -- passe a la table suivante
    END

-- AND PATINDEX(''%[^a-z,0-9,@,.,_]%'', REPLACE(MAIL, ''-'', ''a'')) = 0

--DELETE FROM TMP_USERS_ONLY WHERE  PATINDEX('%[^a-z,0-9,@,.,_]%', REPLACE(MAIL, '-', 'a')) = 1

	-- Cette partie permet sur la table DATA_ADMIN_EMAIL_GRP_WEKAFR:
	-- 1 ajouter un mail si il n'est pas present
	-- 2 mettre a jour les date de derniere activite pour les mail present par entreprise
	-- 3 supprimer une date de derniere activite si l'mail de la societe concernee n'est plus presente
	SET @sql= 'MERGE INTO DATA_ADMIN_EMAIL_GRP_WEKAFR T -- table � cible (target)
				USING (SELECT
						TA.MAIL,
						MAIL_CODE,
						CASE
							WHEN DERNIERE_ACTIVITE_DT IS NULL THEN GETDATE()
							ELSE DERNIERE_ACTIVITE_DT
						END AS DERNIERE_ACTIVITE_DT
					FROM TMP_USERS_ONLY TA
					LEFT JOIN USERS_'+@societe_current+'_EMAILS TB WITH (NOLOCK) ON TA.MAIL = TB.MAIL
				WHERE SOCIETE = '''+@societe_current+''' ) S -- table (source)
				ON (T.MAIL = S.MAIL) -- condition d un email identique
				WHEN MATCHED THEN -- quand �a match
					UPDATE SET T.'+@societe_current+' = S.DERNIERE_ACTIVITE_DT , T.'+@societe_current+'_MAIL_CODE = S.MAIL_CODE -- il met � jour
				WHEN NOT MATCHED BY TARGET THEN --  quand il n y a pas de match
					INSERT (
					MAIL,
					'+@societe_current+'_MAIL_CODE,
					'+@societe_current+') -- on insert la ligne
					VALUES (
					S.MAIL,
					S.MAIL_CODE,
					S.DERNIERE_ACTIVITE_DT)-- avec les valeurs concernees
				   ;'

    EXEC(@sql); -- Execute la requete

	    -- Permet de mettre a jour la colonne 'DATE_DERNIERE_ACTIVITE'
	 	SET @sql='UPDATE DATA_ADMIN_EMAIL_GRP_WEKAFR
        SET DATE_DERNIERE_ACTIVITE = (SELECT Max(v) FROM (VALUES '+@Sql_maker_DATE+') AS value(v))';
		--EXEC(@sql); -- Execute la requete

    DELETE FROM @LST_TABLES_USERS -- vider toutes les tables USERS de la societe en cours pour passer la societe suivante

--TRUNCATE TABLE TMP_USERS_ONLY

END

-- Execution de la suppression des lignes qui n'ont aucune date
--EXEC(@Sql_maker_delete)
SELECT @Sql_maker_delete




	
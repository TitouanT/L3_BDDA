# TP1: Plateforme de jeux en ligne

## Connection:

```bash
psql --host=info --username=u_l3info029 --dbname=bd_l3info029
# mdp: TeTi
```

1. création de la base:
``` sql
CREATE DATABASE bd_l3info029
WITH OWNER = u_l3info029;
```

2. création des schémas u_l3info029 et TP1_jeu
```sql
CREATE SCHEMA u_l3info029;
CREATE SCHEMA TP1_jeu;
```

3. modification du search path

```sql
SET search_path TO "TP1_jeu", "$user";
```

4. suppression du schéma publique
```sql
DROP SCHEMA public
```
<!-- => \dn et SHOW search_path pour vérifier -->

5. compléter le script

a. jeu
```sql
CREATE TABLE jeu (
	id_jeu serial PRIMARY KEY,
	nom_jeu varchar(20),
	type varchar(20) CHECK (type IN ('role', 'plateau', 'tower defense', 'MMORPG', 'Autre')),
	nb_joueur integer
);
```

b. partie
```sql
CREATE TABLE partie (
	id_avatar bigint REFERENCES avatar,
	id_jeu bigint REFERENCES jeu,
	role varchar(20),
	highscore integer,
	PRIMARY KEY (id_avatar, id_jeu)
);
```

c. save
```sql
CREATE TABLE save (
	id_avatar bigint REFERENCES avatar,
	id_jeu bigint REFERENCES jeu,
	date_s date,
	nb_pv integer,
	fichier varchar(50) UNIQUE NOT NULL,
	PRIMARY KEY (id_avatar, id_jeu, date_s)
);
```
6. checker un @ dans un mail:
```sql
CHECK (mail LIKE '%@%')
```

7. création d'une table ville

```sql
CREATE TABLE ville (
	id_ville serial PRIMARY KEY,
	code_postale integer,
	nom_ville varchar(50)
);
```
8. Insertion de données:
```sql
INSERT INTO ville VALUES (DEFAULT, 13100, 'Aix en Provence');
INSERT INTO ville VALUES (DEFAULT, 72250, 'Brette les Pins');
INSERT INTO ville VALUES (DEFAULT, 09000, 'Foix');
INSERT INTO ville VALUES (DEFAULT, 54000, 'Nancy');
INSERT INTO ville VALUES (DEFAULT, 59640, 'Dunkerque');
INSERT INTO ville VALUES (DEFAULT, 38000, 'Grenoble');
INSERT INTO ville VALUES (DEFAULT, 74000, 'Annecy');
```


9. Execution du script:
```psql
\! pwd # pour savoir ou on est
\cd path/to/script/dir
\i script.sql
```

10. modification de visiteurs

```sql
-- ajouter le champ id_ville dans visiteur
ALTER TABLE visiteur
ADD COLUMN id_ville bigint REFERENCES ville;

-- donner les bons id de ville
UPDATE visiteur
SET id_ville = (
	SELECT id_ville FROM ville WHERE visiteur.ville = ville.nom_ville
);

-- suppression de la colonne ville de visiteur
ALTER TABLE visiteur DROP COLUMN ville;
```
11. ajout de données:

```sql
-- Ian habite à Aix en Provence
UPDATE visiteur
SET id_ville = (
	SELECT id_ville
	FROM ville
	WHERE nom_ville = 'Aix en Provence'
)
WHERE login = 'Ian';

-- Sean habite à 'Brette les Pins'
UPDATE visiteur
SET id_ville = (
	SELECT id_ville
	FROM ville
	WHERE nom_ville = 'Brette les Pins'
)
WHERE login = 'Sean';
```

12. renommer nb_joueur en nb_joueur_max dans jeu
```sql
ALTER TABLE jeu
RENAME nb_joueur TO nb_joueur_max;
```


13. combien y a t il de visiteur ?
```sql
SELECT count(visiteur) FROM visiteur;
```

14. quel avatar joue à 'League of Angels'
```sql
SELECT id_avatar
FROM partie
WHERE id_jeu IN (
	SELECT id_jeu
	FROM jeu
	WHERE nom_jeu = 'League of Angels'
);
```



# Partie Notée:


1. Ajouter le champ parrain dans visiteur
```sql
ALTER TABLE visiteur
ADD COLUMN parrain bigint REFERENCES visiteur(id_visiteur);
```
2. ajout d'information
```sql
-- 'Elijah' est le parain de 'Sean'
-- 'Elijah' est le parain de 'Billy'
-- 'Elijah' est le parain de 'Dominic'
UPDATE visiteur
SET parrain = (
	SELECT id_visiteur
	FROM visiteur
	WHERE login = 'Elijah'
)
WHERE login IN ('Sean', 'Billy', 'Dominic');

-- 'Ian' est le parain de 'Vigo'
UPDATE visiteur
SET parrain = (
	SELECT id_visiteur
	FROM visiteur
	WHERE login = 'Ian'
)
WHERE login = 'Viggo';
```

3.
a. Trouver le parrain qui a engendré le plus d'avatar
```sql
SELECT count(*) FROM visiteur GROUP BY parrain HAVING parrain IS NOT NULL;

```

b. Donner 10 gants à Elijah
```sql
INSERT INTO stock VALUES (
	(SELECT id_objet FROM objet WHERE nom_objet = 'Gant de venin'),
	(SELECT id_visiteur FROM visiteur WHERE login = 'Elijah'),
	10, 10
);
```


-----------------------
-- PARTIE 1: postgre --
-----------------------

-- 1. mise en place

-- création du schémas du tp
CREATE SCHEMA "videoclub";

-- set le search path
SET search_path TO "videoclub", "u_l3info029";






-------------------
-- PARTIE 2: DDL --
-------------------

-- 2. Ajouter un champ 'statut' dans la table client.
-- valeurs possible -> 'ok', 'bannis', 'sursis'

ALTER TABLE client
ADD COLUMN statut varchar(6)
CHECK (statut IN ('ok', 'bannis', 'sursis'))
DEFAULT 'ok';


-- 3 maj auto du numero de dvd dans la table emprunt quand il est modifié dans la table dvd.
\d emprunt -- pour lister les contraintes sur emprunt
ALTER TABLE emprunt
DROP CONSTRAINT emprunt_id_dvd_fkey;

-- supression auto d'un emprunt quand le dvd est supprimé de la base
-- maj auto du numero de dvd dans la table emprunt
ALTER TABLE emprunt
ADD CONSTRAINT emprunt_id_dvd_fkey
FOREIGN KEY (id_dvd)
REFERENCES dvd(id_dvd)
ON DELETE CASCADE
ON UPDATE CASCADE;




-------------------
-- PARTIE 3: SQL --
-------------------

-- 4. les réalisateur qui sont aussi acteur dramatique:

SELECT *
FROM PERSONNE
WHERE
id_pers IN (
	SELECT id_pers
	FROM acteur
	WHERE id_film IN (
		SELECT id_film
		FROM film
		WHERE id_genre = (
			SELECT id_genre
			FROM genre
			WHERE nom_genre = 'Drame'
		)
	)
)
AND
id_pers IN (
	SELECT id_pers FROM film
);




-- 5. Créer une vue qui rassemble des infos pour un humain

CREATE VIEW dvd_human
AS
SELECT id_dvd, titre, nom_pers AS nom_realisateur, nom_genre, id_magasin
FROM (
	(film NATURAL JOIN personne)
	NATURAL JOIN
	genre
)
NATURAL JOIN dvd;


-- 6. Creer une fonction qui renvois le nombre d'emprunt pour un film:
-- commande a mettre dans la fontion (coloration)
SELECT count(*) FROM emprunt WHERE id_dvd IN (
	SELECT id_dvd FROM dvd_human WHERE titre = titre_film_arg
);

CREATE OR REPLACE FUNCTION nb_emprunt (titre_film_arg varchar(100)) RETURNS bigint AS '
	SELECT count(*) FROM emprunt WHERE id_dvd IN (
		SELECT id_dvd FROM dvd_human WHERE titre = titre_film_arg
	);
' LANGUAGE sql;

-- 7. quels sont les films les plus souvent loués ?
SELECT titre, count(*)
FROM dvd_human NATURAL JOIN emprunt
GROUP BY titre
HAVING count(*) >= ALL (
	SELECT count(*)
	FROM dvd_human NATURAL JOIN emprunt
	GROUP BY titre
);












-------------------------
-- PARTIE 4: Fonctions --
-------------------------


-- 8. renvoyer pour un client le nombre de dvd qu'il a le droit d'emprunter

CREATE OR REPLACE FUNCTION emprunt_max (id_client_arg bigint) RETURNS bigint AS $$
	declare
		emprunt_max bigint;
	begin
		SELECT caution/10 INTO emprunt_max FROM client WHERE id_client = id_client_arg ;
		return emprunt_max;
	end;
$$ LANGUAGE plpgsql;

-- 9. renvoyer le nombre de film d'un certain genre disponible dans un magasin:

-- VERSION 1
CREATE OR REPLACE FUNCTION film_par_genre_et_magasin (nom_genre_arg varchar(60), id_magasin_arg bigint) RETURNS setof record AS $$
	declare
		rec record;
	begin

		for rec in (
			SELECT titre
			FROM dvd_human
			WHERE id_magasin = id_magasin_arg
			AND nom_genre = nom_genre_arg
		)
		loop
			return next rec;
		end loop;
		return;
	end;
$$ LANGUAGE plpgsql;

-- VERSION 2
CREATE OR REPLACE FUNCTION film_par_genre_et_magasin (nom_genre_arg varchar(60), id_magasin_arg bigint) RETURNS setof record AS $$
	begin
		return query (
			SELECT titre
			FROM dvd_human
			WHERE id_magasin = id_magasin_arg
			AND nom_genre = nom_genre_arg
		);
	end;
$$ LANGUAGE plpgsql;



SELECT * from film_par_genre_et_magasin('Science Fiction', 1) as tmp(titre varchar(100));


-- 10. maj Statut

CREATE OR REPLACE FUNCTION emprunte_par (id_client_arg bigint) RETURNS bigint AS $$
	declare
		nb_emprunt bigint;
	begin
		SELECT count(*)
		INTO nb_emprunt
		FROM emprunt
		WHERE id_client = id_client_arg
		AND date_fin IS NULL;
		return nb_emprunt;
	end;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION empruntable_par (id_client_arg bigint) RETURNS bigint AS $$
	declare
		nb_emprunt_max bigint;
		nb_emprunt bigint;
	begin
		SELECT emprunt_max(id_client_arg) INTO nb_emprunt_max;
		SELECT emprunte_par(id_client_arg) INTO nb_emprunt;
		return nb_emprunt_max - nb_emprunt;
	end;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION nb_retard (id_client_arg bigint) RETURNS bigint AS $$
	declare
		nb_retard bigint;
	begin
		SELECT count(*) INTO nb_retard FROM emprunt WHERE id_client = id_client_arg and date_fin IS NULL and extract(day from age(date_deb)) > 3;
		return nb_retard;
	end;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION maj_statut (id_client_arg bigint) RETURNS void AS $$
	declare
		nb_empruntable bigint;
		nb_retard bigint;
		nouveau_statut varchar(6);
	begin
		SELECT empruntable_par(id_client_arg) INTO nb_empruntable;
		SELECT nb_retard(id_client_arg) INTO nb_retard;

		if nb_empruntable < 0 or nb_retard > 0 then
			nouveau_statut := 'sursis';
		else
			nouveau_statut := 'ok';
		end if;

		UPDATE client
		SET statut = nouveau_statut
		WHERE id_client = id_client_arg;
	end;
$$ LANGUAGE plpgsql;


11. comptage des retard sur trois mois

CREATE OR REPLACE FUNCTION nb_retard_3_mois (id_client_arg bigint) RETURNS bigint AS $$
	declare
		nb_retard bigint;
	begin
		SELECT count(*) INTO nb_retard
		FROM emprunt
		WHERE id_client = id_client_arg
		and age(date_fin) < '3 month'
		and date_fin IS NOT NULL
		and extract(day from age(date_fin, date_deb)) > 3;
		return nb_retard + nb_retard(id_client_arg);
	end;
$$ LANGUAGE plpgsql;

































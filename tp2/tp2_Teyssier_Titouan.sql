-- en salle mac:
-- $ ssh info
-- $ psql --username=u_l3info029 --dbname=bd_l3info029


-- 1. changement du mdp:
ALTER USER u_l3info029 WITH ENCRYPTED PASSWORD 'newpass';


-- 2. creer un groupe avec moi et qqun d'autre:
CREATE GROUP l3info_titouan_corentin;
ALTER USER


-- a finir

---------------------
-- SQL procedurale --
---------------------


CREATE LANGUAGE plpgsql HANDLER plpgsql_call_handler VALIDATOR plpgsql_validator;

-- 1. fonction bonjour

-- CREATE OR REPLACE FUNCTION nom_fonction (param,...) RETURNS type AS $$
-- 	declare
--
-- 	begin
--
-- 	end;
-- $$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION bonjour () RETURNS void AS $$
	begin
		raise notice 'bonjour %, comment vas tu ?', current_user;
	end;
$$ LANGUAGE plpgsql;


-- 2. comparer deux entiers
CREATE OR REPLACE function compare (a integer, b integer) returns record AS $$
	declare
		res record;
	begin
		if a = b then
			SELECT a,b,true INTO res;
			raise notice 'a equal b';

		else
			if a > b then
				SELECT b,a,false INTO res;

				raise notice 'a > b';
			else
				SELECT a,b,false INTO res;
				raise notice 'a < b';
			end if;
		end if;


		return res;

	end;
$$ language plpgsql;



select * from compare(1,2) as tmp(min integer, max integer, equal boolean);
select * from compare(2,1) as tmp(min integer, max integer, equal boolean);
select * from compare(2,2) as tmp(min integer, max integer, equal boolean);


-- 3. ajouter nom et prénom dans visiteurs

-- CREATE OR REPLACE FUNCTION nom_fonction (param,...) RETURNS type AS '
-- ...
-- ' LANGUAGE sql;


ALTER TABLE visiteur ADD COLUMN nom varchar(30);
ALTER TABLE visiteur ADD COLUMN prenom varchar(30);



-- 4. fonction qui met à jours le nom et le prénom d'un visiteur grace à son login
CREATE OR REPLACE FUNCTION maj_nom_prenom (login_arg varchar(20), nom_arg varchar(30), prenom_arg varchar(30)) RETURNS void AS '
	UPDATE visiteur
	SET nom = nom_arg, prenom = prenom_arg
	WHERE login = login_arg;
' LANGUAGE sql;

select maj_nom_prenom('Billy', 'Bil', 'ly');


5. fonction listing qui renvois pour (nom_jeu, login) la liste des avatars(nom_avatar, nom_race) du visiteur login qui sont dans le jeu nom_jeu
CREATE OR REPLACE FUNCTION listing (nom_jeu_arg varchar(20), login_arg varchar(10))
RETURNS set of records AS --'
	SELECT nom_avatar, race
	FROM
--'


-- partie notée

-- 1. quel visiteur a le plus grand nombre d'objets disponibles ?

SELECT login FROM (
	SELECT login, sum(nb_dispo) as totalDispo
	FROM visiteur NATURAL JOIN stock
	GROUP BY login
) AS login_qtt
WHERE totalDispo >= ALL (
	SELECT sum(nb_dispo)
	FROM visiteur NATURAL JOIN stock
	GROUP BY login
);

-- 2. afficher le prix d'un objet à partir du nom

CREATE OR REPLACE FUNCTION prix_obj (nom_obj_arg varchar(40)) RETURNS integer AS '
	SELECT prix FROM objet WHERE nom_objet = nom_obj_arg;
' LANGUAGE sql;

select prix_obj('Gant de venin');

-- 3. le login qui a le plus parmi deux avatars passé en param:

CREATE OR REPLACE FUNCTION nb_avatar (login_a varchar(10)) RETURNS bigint AS '
	SELECT count(id_avatar)
	FROM avatar NATURAL JOIN visiteur
	WHERE login = login_a;
' LANGUAGE sql;


CREATE OR REPLACE FUNCTION max_avatar (login_a varchar(10), login_b varchar(10)) RETURNS varchar(10) AS $$
	declare
		nb_avatar_a bigint;
		nb_avatar_b bigint;
	begin
		SELECT nb_avatar(login_a) INTO nb_avatar_a;
		SELECT nb_avatar(login_b) INTO nb_avatar_b;


		if nb_avatar_a > nb_avatar_b then
			return login_a;
		else
			return login_b;
		end if;

	end;
$$ LANGUAGE plpgsql;


select max_avatar('Elijah', 'Ian');

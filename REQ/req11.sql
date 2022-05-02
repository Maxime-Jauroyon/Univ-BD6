-- Renvoie une ligne par pays en guerre les uns contre les autres avec le gagnant probable et le perdant probable
-- (en fonction de la taille de sa flotte).

-- Returns a line per countries in war with each other with the probable winner and probable looser
-- (depending on the size of its fleet).

WITH fleets (
	country,
	fleet
) AS (
	SELECT
		country_name,
		count(*) AS fleet
	FROM
		countries
	NATURAL JOIN ships_nationalities AS S
	WHERE
		start_possesion_date = (
			SELECT
				MAX(start_possesion_date)
			FROM
				ships_nationalities
			WHERE
				ship_id = S.ship_id)
	GROUP BY
		country_name
)
SELECT
	F1.country AS probable_winner,
	F2.country AS probable_looser
FROM
	diplomatic_relationships,
	fleets AS F1,
	fleets AS F2
WHERE
	country_name_1 = F1.country
AND country_name_2 = F2.country
AND relation = 'En guerre'
AND F1.fleet > F2.fleet;

-- Retourne l'évolution des nationalités pour chaque navire avec le nombre d'expéditions qu'ils ont effectuées sous chaque bannière.

-- Returns the evolution of nationalities for each ship with the number of
-- shipments they did under each banner.

SELECT
	ship_id,
	country_name,
	count(*) AS travel
FROM (ships_nationalities
	NATURAL JOIN (
		SELECT
			*
		FROM
			ships
		NATURAL JOIN shipments) AS F) AS S
WHERE
	start_possesion_date = (
		SELECT
			MAX(start_possesion_date)
		FROM
			ships_nationalities
		WHERE
			ship_id = S.ship_id
		AND start_possesion_date <= S.start_date)
GROUP BY
	ship_id,
	country_name;

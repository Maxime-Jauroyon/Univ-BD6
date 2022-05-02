-- Retourne le nombre d'expéditions effectuées par continent, ainsi que le nombre de
-- navires capturés par un pays d'un continent donné et le nombre de navires capturés
-- précédemment possédés par un pays d'un continent donné.

-- Returns the number of shipments done per continent, alongside the number of
-- ships captured by a country of a given continent and the number of ships captured
-- previously owned by a country of a given continent.

SELECT
	continent,
	SUM(N.done) AS done,
	SUM(N.captured) AS captured,
	SUM(N.being_captured) AS being_captured
FROM
	countries
NATURAL JOIN (
	SELECT
		C.country_name,
		(
			SELECT
				count(*) AS travel 
			FROM (ships_nationalities
					NATURAL JOIN (
						SELECT
							* 
						FROM ships
						NATURAL JOIN shipments) AS F) AS S
			WHERE
				start_possesion_date = (
						SELECT
							MAX(start_possesion_date)
						FROM ships_nationalities
						WHERE
							ship_id = S.ship_id
						AND start_possesion_date <= S.start_date)
			AND country_name = C.country_name
					GROUP BY
						country_name) AS done, 
		(
			SELECT
				count(*)
			FROM
				shipments AS S,
				ships_nationalities AS S1,
				ships_nationalities AS S2
			WHERE
				S.capture_date IS NOT NULL
			AND S.ship_id = S1.ship_id
			AND S1.ship_id = S2.ship_id
			AND S.capture_date = S1.start_possesion_date
			AND S2.start_possesion_date < S.capture_date
			AND S2.start_possesion_date >= ALL (
					SELECT
						S3.start_possesion_date
					FROM
						ships_nationalities AS S3
					WHERE
						S3.ship_id = S2.ship_id
					AND S3.start_possesion_date < S.capture_date)
			AND S1.country_name = C.country_name) AS captured, 
		(
			SELECT
				count(*)
			FROM
				shipments AS S,
				ships_nationalities AS S1,
				ships_nationalities AS S2
			WHERE
				S.capture_date IS NOT NULL
			AND S.ship_id = S1.ship_id
			AND S1.ship_id = S2.ship_id
			AND S.capture_date = S1.start_possesion_date
			AND S2.start_possesion_date < S.capture_date
			AND S2.start_possesion_date >= ALL (
							SELECT
								S3.start_possesion_date
							FROM
								ships_nationalities AS S3
							WHERE
								S3.ship_id = S2.ship_id
							AND S3.start_possesion_date < S.capture_date)
			AND S2.country_name = C.country_name) AS being_captured
	FROM
		countries AS C) AS N
GROUP BY
	continent;

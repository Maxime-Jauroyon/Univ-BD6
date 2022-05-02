-- Renvoie la taille de l'expédition la plus longue (en termes de port parcouru) par catégorie de navire.
-- La taille de l'expédition est calculée à partir du port de départ ajouté au port de chaque étape et enfin
-- ajouté au port de fin.

-- Returns the longuest shipment's size (in term of port travelled) per ship cagegory.
-- The shipment size is calculated with the start port added with each leg's port and finally
-- added with the end port.

WITH RECURSIVE shipment (
	ship_id,
	port_name_start,
	port_country_name_start,
	port_name_end,
	port_country_name_end,
	start_date,
	end_date,
	ports
) AS (
	SELECT
		ship_id,
		port_name_start,
		port_country_name_start,
		port_name_end,
		port_country_name_end,
		start_date,
		end_date,
		(2 + (
				SELECT
					COUNT(*)
				FROM
					legs
				WHERE
					shipment_id = S.shipment_id)) AS ports
	FROM
		shipments AS S
	UNION
	SELECT
		T.ship_id,
		T.port_name_start,
		T.port_country_name_start,
		S.port_name_end,
		S.port_country_name_end,
		T.start_date,
		S.end_date,
		(T.ports + 1 + (
						SELECT
							COUNT(*)
						FROM
							legs
						WHERE
							shipment_id = S.shipment_id)) AS ports
	FROM
		shipments AS S,
		shipment AS T
	WHERE
		S.ship_id = T.ship_id
	AND S.port_name_start = T.port_name_end
	AND S.port_country_name_start = T.port_country_name_end
	AND T.end_date IS NOT NULL
	AND T.end_date < S.start_date
	AND S.start_date <= ALL (
							SELECT
								S1.start_date
							FROM
								shipments AS S1
							WHERE
								S1.ship_id = S.ship_id
							AND T.end_date < S1.start_date
							AND S1.port_name_start = T.port_name_end
							AND S1.port_country_name_start = T.port_country_name_end)
)
SELECT
	ship_category, MAX(ports)
FROM
	shipment
NATURAL JOIN ships
GROUP BY
	ship_category;

-- Retourne le total du volume et du nombre de passagers transportés par catégorie de navire.

-- Returns the total of volume and passengers count transported per ship category.

SELECT
	ship_category,
	SUM(D.volume_total) as volume_total,
	SUM(D.passengers_total) as passengers_total
FROM
	ships
NATURAL JOIN (
	SELECT
		ship_id,
		SUM(COALESCE(A.volume_cargo, 0)) AS volume_total,
		SUM(passengers) AS passengers_total
	FROM
		shipments
	NATURAL LEFT OUTER JOIN (
		SELECT
			shipment_id,
			cargo_id,
			((quantity * volume) + 0.0) AS volume_cargo
		FROM
			cargo
		NATURAL JOIN products) AS A
	GROUP BY
		ship_id) AS D
GROUP BY
	ship_category;

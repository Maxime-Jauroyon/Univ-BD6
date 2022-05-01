-- Retourne le produit le plus vendu par classe ou par continent.

-- Returns the most sold product per class or continent.

-- Par classe :
-- Per class:
SELECT
	S1.class,
	S1.product_id,
	S1.quantity
FROM (shipments
	NATURAL JOIN (
		SELECT
			shipment_id,
			product_id,
			SUM(sold + bought) AS quantity
		FROM
			trading
			NATURAL JOIN cargo
		GROUP BY
			shipment_id,
			product_id) AS S) AS S1
WHERE
	S1.quantity = (
		SELECT
			MAX(quantity)
		FROM (
			SELECT
				shipment_id,
				product_id,
				SUM(sold + bought) AS quantity
			FROM
				trading
			NATURAL JOIN cargo
		GROUP BY
			shipment_id,
			product_id) AS S2
	NATURAL JOIN shipments
WHERE
	class = S1.class);

-- Par continent :
-- Per continent:
SELECT
	C.continent,
	S2.product_id,
	S2.quantity
FROM
	countries AS C
	NATURAL JOIN (
		SELECT
			S.port_country_name AS country_name,
			S.product_id,
			S.quantity
		FROM (
			SELECT
				port_name,
				port_country_name,
				product_id,
				SUM(sold + bought) AS quantity
			FROM
				trading
				NATURAL JOIN cargo
			GROUP BY
				port_name,
				port_country_name,
				product_id) AS S
		WHERE
			S.quantity = (
				SELECT
					MAX(quantity)
				FROM (
					SELECT
						port_name,
						port_country_name,
						product_id,
						SUM(sold + bought) AS quantity
					FROM
						trading
					NATURAL JOIN cargo
				GROUP BY
					port_name,
					port_country_name,
					product_id) AS S1
			WHERE
				S1.port_country_name = S.port_country_name)) AS S2
WHERE
	S2.quantity = (
		SELECT
			MAX(quantity)
		FROM
			countries AS C2
		NATURAL JOIN (
			SELECT
				S3.port_country_name AS country_name, S3.product_id, S3.quantity
			FROM (
				SELECT
					port_name,
					port_country_name,
					product_id,
					SUM(sold + bought) AS quantity
				FROM
					trading
					NATURAL JOIN cargo
				GROUP BY
					port_name,
					port_country_name,
					product_id) AS S3
			WHERE
				S3.quantity = (
					SELECT
						MAX(quantity)
					FROM (
						SELECT
							port_name,
							port_country_name,
							product_id,
							SUM(sold + bought) AS quantity
						FROM
							trading
						NATURAL JOIN cargo
					GROUP BY
						port_name,
						port_country_name,
						product_id) AS S4
				WHERE
					S4.port_country_name = S3.port_country_name)) AS S5
		WHERE
			C2.continent = C.continent);

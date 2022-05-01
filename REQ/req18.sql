SELECT
	F1.country_name,
	F1.product_id,
	F1.bought,
	F2.product_id,
	F2.sold
FROM (
	SELECT
		S.country_name,
		S.product_id,
		S.bought
	FROM (
		SELECT
			port_country_name AS country_name,
			product_id,
			SUM(bought) AS bought
		FROM
			trading
		NATURAL JOIN cargo
	GROUP BY
		port_name,
		port_country_name,
		product_id) AS S
WHERE
	S.bought = (
		SELECT
			MAX(bought)
		FROM (
			SELECT
				port_country_name AS country_name,
				product_id,
				SUM(bought) AS bought
			FROM
				trading
			NATURAL JOIN cargo
		GROUP BY
			port_name,
			port_country_name,
			product_id) AS S1
	WHERE
		S1.country_name = S.country_name)) AS F1
	JOIN (
		SELECT
			S.country_name, S.product_id, S.sold
		FROM (
			SELECT
				port_country_name AS country_name,
				product_id,
				SUM(sold) AS sold
			FROM
				trading
				NATURAL JOIN cargo
			GROUP BY
				port_name,
				port_country_name,
				product_id) AS S
		WHERE
			S.sold = (
				SELECT
					MAX(sold)
				FROM (
					SELECT
						port_country_name AS country_name,
						product_id,
						SUM(sold) AS sold
					FROM
						trading
					NATURAL JOIN cargo
				GROUP BY
					port_name,
					port_country_name,
					product_id) AS S1
			WHERE
				S1.country_name = S.country_name)) AS F2 ON F1.country_name = F2.country_name;

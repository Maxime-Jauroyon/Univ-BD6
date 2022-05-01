-- The quantity of product sold per category for each continent.

WITH trade_data (
	continent,
	product_id,
	quantity
) AS (
	SELECT
		C.continent,
		S1.product_id,
		S1.quantity
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
				product_id) AS S) AS S1
)
SELECT
	continent,
	SUM(clothes) AS clothes,
	SUM(materials) AS materials,
	SUM(food) AS food,
	SUM(misc) AS misc
FROM (
	SELECT
		continent,
		SUM(quantity) AS clothes,
		0 AS materials,
		0 AS food,
		0 AS misc
	FROM
		trade_data
	NATURAL JOIN clothes
GROUP BY
	continent
UNION
SELECT
	continent,
	0 AS clothes,
	SUM(quantity) AS materials,
	0 AS food,
	0 AS misc
FROM
	trade_data
	NATURAL JOIN materials
GROUP BY
	continent
UNION
SELECT
	continent,
	0 AS clothes,
	0 AS materials,
	0 AS food,
	SUM(quantity) AS misc
FROM
	trade_data
	NATURAL JOIN misc
GROUP BY
	continent
UNION
SELECT
	continent,
	0 AS clothes,
	0 AS materials,
	SUM(quantity) AS food,
	0 AS msic
FROM
	trade_data
	NATURAL JOIN food
GROUP BY
	continent) AS F
GROUP BY
	continent;

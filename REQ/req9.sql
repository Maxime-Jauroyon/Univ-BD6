-- because we could have 2 cargo of the same product on the same shipment we need to do this :
-- SELECT shipment_id,product_id,SUM(quantity)
-- FROM cargo
-- GROUP BY shipment_id,product_id;

SELECT
	*
FROM (
	SELECT
		AVG(PCL.quantity) AS clothes
	FROM (
		SELECT
			shipment_id,
			SUM(P.quantity) AS quantity
		FROM
			clothes
		NATURAL JOIN (
			SELECT
				shipment_id,
				product_id,
				SUM(quantity) AS quantity
			FROM
				cargo
			GROUP BY
				shipment_id,
				product_id) AS P
		GROUP BY
			shipment_id) AS PCL) AS CL,
	(
		SELECT
			AVG(PMA.quantity) AS material
		FROM (
			SELECT
				shipment_id,
				SUM(P.quantity) AS quantity
			FROM
				materials
			NATURAL JOIN (
				SELECT
					shipment_id,
					product_id,
					SUM(quantity) AS quantity
				FROM
					cargo
				GROUP BY
					shipment_id,
					product_id) AS P
			GROUP BY
				shipment_id) AS PMA) AS MA,
	(
		SELECT
			AVG(PFO.quantity) AS food
		FROM (
			SELECT
				shipment_id,
				SUM(P.quantity) AS quantity
			FROM
				food
			NATURAL JOIN (
				SELECT
					shipment_id,
					product_id,
					SUM(quantity) AS quantity
				FROM
					cargo
				GROUP BY
					shipment_id,
					product_id) AS P
			GROUP BY
				shipment_id) AS PFO) AS F0,
	(
		SELECT
			AVG(PMI.quantity) AS misc
		FROM (
			SELECT
				shipment_id,
				SUM(P.quantity) AS quantity
			FROM
				misc
			NATURAL JOIN (
				SELECT
					shipment_id,
					product_id,
					SUM(quantity) AS quantity
				FROM
					cargo
				GROUP BY
					shipment_id,
					product_id) AS P
			GROUP BY
				shipment_id) AS PMI) AS MI;

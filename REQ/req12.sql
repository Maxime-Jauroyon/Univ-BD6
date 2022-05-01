-- Returns the shipment who has made the biggest trading in either quantity or volume.

-- In quantity:
SELECT
	S.shipment_id,
	S.quantity
FROM (
	SELECT
		shipment_id,
		SUM(sold + bought) AS quantity
	FROM
		trading
	GROUP BY
		shipment_id) AS S
WHERE
	S.quantity = (
		SELECT
			MAX(S1.quantity)
		FROM (
			SELECT
				shipment_id,
				SUM(sold + bought) AS quantity
			FROM
				trading
			GROUP BY
				shipment_id) AS S1);

-- In volume:
SELECT
	S.shipment_id,
	S.volume
FROM (
	SELECT
		shipment_id,
		SUM((bought + sold) * volume) AS volume
	FROM
		trading
	NATURAL JOIN (
		SELECT
			cargo_id,
			volume
		FROM
			cargo
			NATURAL JOIN products) AS PR
	GROUP BY
		shipment_id) AS S
WHERE
	S.volume = (
		SELECT
			Max(S1.volume)
		FROM (
			SELECT
				shipment_id,
				SUM((bought + sold) * volume) AS volume
			FROM
				trading
			NATURAL JOIN (
				SELECT
					cargo_id,
					volume
				FROM
					cargo
					NATURAL JOIN products) AS PR
			GROUP BY
				shipment_id) AS S1);
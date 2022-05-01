-- Returns each shipment with its count of passenger at the start then at the end
-- and identically for the volume.

SELECT
	shipment_id,
	PAF.passengers_start,
	PAF.passengers_end,
	COALESCE(VF.volume_start, 0) AS volume_start,
	COALESCE(VF.volume_end, 0) AS volume_end
FROM (
	SELECT
		shipment_id,
		passengers AS passengers_start,
		((passengers + COALESCE(gain, 0)) - COALESCE(lose, 0)) AS passengers_end
	FROM
		shipments
	NATURAL
	LEFT OUTER JOIN (
	SELECT
		shipment_id,
		SUM(loaded_passengers) AS gain,
		SUM(offloaded_passengers) AS lose
	FROM
		legs
	GROUP BY
		shipment_id) AS PA) AS PAF
	NATURAL
	LEFT OUTER JOIN (
	SELECT
		shipment_id,
		S.volume_shipment AS volume_start,
		((S.volume_shipment + COALESCE(T.gain, 0)) - COALESCE(T.lose, 0)) AS volume_end
	FROM (
		SELECT
			shipment_id,
			SUM(A.volume_cargo) AS volume_shipment
		FROM
			shipments
			NATURAL JOIN (
				SELECT
					shipment_id,
					cargo_id,
					((quantity * volume) + 0.0) AS volume_cargo
				FROM
					cargo
					NATURAL JOIN products) AS A
			GROUP BY
				shipment_id) AS S
		NATURAL
	LEFT OUTER JOIN (
	SELECT
		shipment_id,
		SUM(bought * volume_cargo) AS gain,
		SUM(sold * volume_cargo) AS lose
	FROM
		trading
		NATURAL JOIN (
			SELECT
				cargo_id,
				volume AS volume_cargo
			FROM
				cargo
				NATURAL JOIN products) AS PR
		GROUP BY
			shipment_id) AS T) AS VF
ORDER BY
	shipment_id;
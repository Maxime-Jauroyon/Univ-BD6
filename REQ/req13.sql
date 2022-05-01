-- Retourne l'évolution du nombre de passagers et du volume de marchandises
-- pour chaque étape de chaque expédition.

-- Returns the evolution of the number of passengers and volume of merchandises
-- for each shipments at each step of the shipment.

WITH RECURSIVE evolution (
	shipment_id,
	port_name,
	port_country_name,
	distance,
	passengers,
	volume
) AS (
	SELECT
		shipment_id,
		port_name_start AS port_name,
		port_country_name_start AS port_country_name,
		0 AS distance,
		passengers,
		COALESCE(S.volume_shipment,
			0) AS volume
	FROM
		shipments
	NATURAL
	LEFT OUTER JOIN (
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
	UNION
	SELECT
		S1.shipment_id,
		S1.port_name,
		S1.port_country_name,
		S1.distance,
		S1.passengers,
		((S1.volume + COALESCE(S2.gain,
					0)) - COALESCE(S2.lose,
				0)) AS volume
	FROM (
		SELECT
			E.shipment_id,
			L.port_name,
			L.port_country_name,
			L.traveled_distance AS distance,
			((E.passengers + L.loaded_passengers) - L.offloaded_passengers) AS passengers,
			E.volume
		FROM
			legs AS L,
			evolution AS E
		WHERE
			E.shipment_id = L.shipment_id
			AND L.traveled_distance > E.distance
			AND L.traveled_distance = (
				SELECT
					MIN(traveled_distance)
				FROM
					legs
				WHERE
					shipment_id = L.shipment_id
					AND traveled_distance > E.distance)) AS S1
		LEFT OUTER JOIN (
		SELECT
			shipment_id,
			port_name,
			port_country_name,
			SUM(bought * volume) AS gain,
			SUM(sold * volume) AS lose
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
				shipment_id,
				port_name,
				port_country_name) AS S2 ON S1.port_name = S2.port_name
			AND S1.port_country_name = S2.port_country_name
			AND S1.shipment_id = S2.shipment_id
)
SELECT
	*
FROM
	evolution
UNION
SELECT
	shipment_id,
	port_name_end AS port_name,
	port_country_name_end AS port_country_name,
	distance,
	0 AS passengers,
	0 AS volume
FROM
	shipments
ORDER BY
	shipment_id,
	distance;

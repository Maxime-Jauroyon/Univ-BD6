-- Returns the status of each port with the number of passengers that arrived and left
-- and the number of merchandises bought and sold.

WITH shipment_data (
	shipment_id,
	port_name_start,
	port_country_name_start,
	port_name_end,
	port_country_name_end,
	passengers_start,
	passengers_end,
	volume_start,
	volume_end
) AS (
	SELECT
		shipment_id,
		PAF.port_name_start,
		PAF.port_country_name_start,
		PAF.port_name_end,
		PAF.port_country_name_end,
		PAF.passengers_start,
		PAF.passengers_end,
		COALESCE(VF.volume_start,
			0) AS volume_start,
		COALESCE(VF.volume_end,
			0) AS volume_end
	FROM (
		SELECT
			shipment_id,
			port_name_start,
			port_country_name_start,
			port_name_end,
			port_country_name_end,
			passengers AS passengers_start,
			((passengers + COALESCE(gain,
						0)) - COALESCE(lose,
					0)) AS passengers_end
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
		((S.volume_shipment + COALESCE(T.gain,
					0)) - COALESCE(T.lose,
				0)) AS volume_end
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
)
SELECT
	port_name,
	port_country_name,
	SUM(passengers_arrive) AS passengers_arrive,
	SUM(passengers_left) AS passengers_left,
	SUM(volume_receive) AS volume_receive,
	SUM(volume_send) AS volume_send,
	SUM(nb_shipment) AS nb_shipment
FROM (
	SELECT
		port_name_start AS port_name,
		port_country_name_start AS port_country_name,
		0 AS passengers_arrive,
		SUM(passengers_start) AS passengers_left,
		0 AS volume_receive,
		SUM(volume_start) AS volume_send,
		count(*) AS nb_shipment
	FROM
		shipment_data
	GROUP BY
		port_name_start,
		port_country_name_start
	UNION
	SELECT
		port_name_end AS port_name,
		port_country_name_end AS port_country_name,
		SUM(passengers_end) AS passengers_arrive,
		0 AS passengers_left,
		SUM(volume_end) AS volume_receive,
		0 AS volume_send,
		count(*) AS nb_shipment
	FROM
		shipment_data
	GROUP BY
		port_name_end,
		port_country_name_end
	UNION
	SELECT
		port_name,
		port_country_name,
		P.arrive AS passengers_arrive,
		P.left AS passengers_left,
		V.receive AS volume_receive,
		V.send AS volume_send,
		P.nb_shipment
	FROM (
		SELECT
			port_name,
			port_country_name,
			SUM(loaded_passengers) AS
		LEFT,
		SUM(offloaded_passengers) AS arrive,
		count(*) AS nb_shipment
	FROM
		legs
	GROUP BY
		port_name,
		port_country_name) AS P
	NATURAL
	LEFT OUTER JOIN (
	SELECT
		port_name,
		port_country_name,
		SUM(bought * volume_cargo) AS send,
		SUM(sold * volume_cargo) AS receive
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
			port_name,
			port_country_name) AS V) AS F
GROUP BY
	port_name,
	port_country_name
ORDER BY
	port_country_name;

-- Liste tous les navires qui ont effectué au moins 2 expéditions.
-- Renvoie l'identifiant du navire et le volume moyen transporté par expédition.

-- Lists every ships who made at least 2 shipments.
-- Returns the ship id and the average volume transported per shipment.

SELECT
    ship_id,
    AVG(volume_shipment)
FROM
    ships
NATURAL JOIN (
    SELECT
        shipment_id,
        ship_id,
        SUM(COALESCE(A.volume_cargo,0)) AS volume_shipment
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
        shipment_id,
        ship_id) AS B
GROUP BY
    ship_id
HAVING
    COUNT(shipment_id) > 1;

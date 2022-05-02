-- Liste tous les navires qui ont toujours commencé leurs expéditions avec le nombre de passagers remplis.
-- Retourne l'identifiant du navire.

-- Lists every ships who always started their shipments with the count of passengers filled.
-- Returns the ship id.

SELECT
    ship_id
FROM (
    SELECT
        ship_id,
        COUNT(shipment_id) AS nbFull
    FROM
        ships
    NATURAL JOIN shipments
    WHERE
        passengers_capacity = passengers
    GROUP BY
        ship_id) AS F
NATURAL JOIN (
    SELECT
        ship_id,
        COUNT(shipment_id) AS nbTotal
    FROM
        ships
    NATURAL JOIN shipments
    GROUP BY
        ship_id) AS T
WHERE
    F.nbFull = T.nbTotal;
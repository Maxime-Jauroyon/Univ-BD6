-- Liste tous les navires qui ont toujours commencé leurs expéditions avec le nombre de passagers remplis.
-- Retourne l'identifiant du navire.

-- Lists every ships who always started their shipments with the count of passengers filled.
-- Returns the ship id.

SELECT
    DISTINCT ship_id
FROM
    ships AS S
NATURAL JOIN shipments
WHERE NOT EXISTS (
    SELECT
        *
    FROM
        ships
    NATURAL JOIN shipments
    WHERE
        S.ship_id = ship_id AND passengers_capacity <> passengers);

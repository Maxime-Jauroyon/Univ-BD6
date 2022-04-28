-- Liste les bateaux qui ont fait tous leurs voyages en partant avec le nombre maximum de passagers

SELECT
    DISTINCT ship_id
FROM
    ships AS S
    NATURAL JOIN shipments
WHERE
    NOT EXISTS (
        SELECT
            *
        FROM
            ships
        NATURAL JOIN shipments
    WHERE
        S.ship_id = ship_id
        AND passengers_capacity <> passengers);

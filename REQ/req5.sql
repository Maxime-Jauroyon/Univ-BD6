-- Liste récursivement tous les trajets effectués par un navire pendant ses expéditions jusqu'à sa capture par un ennemi.

-- Recursively lists all travels made per ship during their shipments until capture by an enemy.

WITH RECURSIVE shipment (
    ship_id,
    port_name_start,
    port_country_name_start,
    port_name_end,
    port_country_name_end,
    start_date,
    end_date
) AS (
    SELECT
        ship_id,
        port_name_start,
        port_country_name_start,
        port_name_end,
        port_country_name_end,
        start_date,
        end_date
    FROM
        shipments
    UNION
    SELECT
        T.ship_id,
        T.port_name_start,
        T.port_country_name_start,
        S.port_name_end,
        S.port_country_name_end,
        T.start_date,
        S.end_date
    FROM
        shipments AS S,
        shipment AS T
    WHERE
        S.ship_id = T.ship_id
        AND S.port_name_start = T.port_name_end
        AND S.port_country_name_start = T.port_country_name_end
        AND T.end_date IS NOT NULL
        AND T.end_date < S.start_date
        AND S.start_date <= ALL (
            SELECT
                S1.start_date
            FROM
                shipments AS S1
            WHERE
                S1.ship_id = S.ship_id
                AND T.end_date < S1.start_date
                AND S1.port_name_start = T.port_name_end
                AND S1.port_country_name_start = T.port_country_name_end)
)
SELECT
    *
FROM
    shipment;

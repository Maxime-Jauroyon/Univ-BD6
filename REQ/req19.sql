-- quantité

SELECT arrival_date,quantity
FROM
(SELECT arrival_date,SUM(sold+bought) as quantity
FROM trading
NATURAL JOIN legs
GROUP BY arrival_date) as F
WHERE quantity = (SELECT MAX(quantity)
                  FROM (SELECT arrival_date,SUM(sold+bought) as quantity
                        FROM trading
                        NATURAL JOIN legs
                        GROUP BY arrival_date) as T);



-- volume
SELECT
    arrival_date,
    volume
FROM (
    SELECT
        arrival_date,
        SUM(sold + bought) AS volume
    FROM
        legs
    NATURAL JOIN (
        SELECT
            shipment_id,
            port_name,
            port_country_name,
            (bought * volume) AS bought,
            (sold * volume) AS sold
        FROM
            trading
            NATURAL JOIN (
                SELECT
                    cargo_id,
                    volume
                FROM
                    cargo
                    NATURAL JOIN products) AS V) AS V1
        GROUP BY
            arrival_date) AS F
WHERE
    volume = (
        SELECT
            MAX(volume)
        FROM (
            SELECT
                arrival_date,
                SUM(sold + bought) AS volume
            FROM
                legs
            NATURAL JOIN (
                SELECT
                    shipment_id,
                    port_name,
                    port_country_name,
                    (bought * volume) AS bought,
                    (sold * volume) AS sold
                FROM
                    trading
                    NATURAL JOIN (
                        SELECT
                            cargo_id,
                            volume
                        FROM
                            cargo
                            NATURAL JOIN products) AS V2) AS V3
                GROUP BY
                    arrival_date) AS T);

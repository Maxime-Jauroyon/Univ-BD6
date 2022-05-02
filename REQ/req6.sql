-- retourne l'id du voyage qui a duré le plus longtemps.

-- Returns the shipment id with the longuest duration travelled.

-- valeurs NULL sont ignorées par MAX().
-- NULL values skipped by MAX().
SELECT
    shipment_id
FROM
    shipments
WHERE
    duration = (
        SELECT
            MAX(duration)
        FROM
            shipments);

-- les valeurs NULL donnent unknown comme résultat.
-- NULL values give unknown result.
SELECT
    shipment_id
FROM
    shipments
WHERE
    duration >= ALL (
        SELECT
            duration
        FROM
            shipments);

-- Avec une modification pour géré les valeurs NULL.
-- With a fix for NULL values.
SELECT
    shipment_id
FROM
    shipments
WHERE
    duration >= ALL (
        SELECT
            COALESCE(duration, 0)
        FROM
            shipments);
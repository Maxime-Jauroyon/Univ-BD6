-- Liste récursivement toutes les expéditions effectués par un navire pendant ses expéditions jusqu'à sa capture par un ennemi.

-- Returns the shipment id with the longuest distance travelled.

-- Sans valeurs NULL.
-- Without NULL values.
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

-- Avec valeurs NULL.
-- With NULL values.
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
-- Returns the shipment id with the longuest distance travelled.

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
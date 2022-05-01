-- Checks if every trading happens within a port that supports its ship's category.

CREATE OR REPLACE FUNCTION category_mismatches_trading()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM (
            SELECT
                *
            FROM
                shipments
            NATURAL JOIN ships) AS S
            JOIN (
                SELECT
                    *
                FROM
                    ports
                    NATURAL JOIN trading) AS S1 ON S1.shipment_id = S.shipment_id
        WHERE
            ship_category > port_category);
END;
$function$;

ALTER TABLE trading ADD CONSTRAINT check_category CHECK (category_mismatches_trading() = 0);
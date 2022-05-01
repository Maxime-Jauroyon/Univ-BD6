-- Checks if every shipments is starting and leaving from a port with a category
-- supporting its ship's category.

CREATE OR REPLACE FUNCTION category_mismatches_shipment()
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
            FROM (
                SELECT
                    *
                FROM
                    shipments
                NATURAL JOIN ships) AS S
            JOIN ports ON port_name = S.port_name_start
                AND port_country_name = S.port_country_name_start
        WHERE
            ship_category > port_category
        UNION
        SELECT
            *
        FROM (
            SELECT
                *
            FROM
                shipments
            NATURAL JOIN ships) AS S
        JOIN ports ON port_name = S.port_name_end
            AND port_country_name = S.port_country_name_end
        WHERE
            ship_category > port_category) AS C);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_category CHECK (category_mismatches_shipment() = 0);

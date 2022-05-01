CREATE OR REPLACE FUNCTION type_mismatches()
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
            WHERE
                shipment_type = 'court'
                AND distance >= 1000
            UNION
            SELECT
                *
            FROM
                shipments
            WHERE
                shipment_type = 'moyen'
                AND(distance < 1000
                    OR distance >= 2000)
            UNION
            SELECT
                *
            FROM
                shipments
            WHERE
                shipment_type = 'long'
                AND distance < 2000) AS D);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_type CHECK (type_mismatches() = 0);
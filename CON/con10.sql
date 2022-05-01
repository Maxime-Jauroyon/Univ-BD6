CREATE OR REPLACE FUNCTION perishable_mismatches()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM
            shipments
        WHERE
            shipment_id IN (
                SELECT
                    shipment_id FROM cargo AS C
                NATURAL JOIN products
            WHERE
                perishable IS TRUE) AND (shipment_type = 'moyen' OR shipment_type = 'long'));
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_perishable CHECK (perishable_mismatches() = 0);

CREATE OR REPLACE FUNCTION class_mismatches_Intercontinental()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM
            shipments
            NATURAL JOIN ships
        WHERE
            class = 'Intercontinental'
            AND ship_category <> 5);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_class_Intercontinental CHECK (class_mismatches_Intercontinental() = 0);
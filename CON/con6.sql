CREATE OR REPLACE FUNCTION class_mismatches()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM
            shipments
            JOIN countries ON country_name = port_country_name_end
        WHERE
            class <> 'Intercontinental'
            AND class <> continent);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_class CHECK (class_mismatches() = 0);
-- Checks if every shipments doing an intercontinental travel will travel a distance greater than 1000km.

CREATE OR REPLACE FUNCTION class_mismatches_Intercontinental2()
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
            class = 'Intercontinental'
            AND distance < 1000);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_class_Intercontinental2 CHECK (class_mismatches_Intercontinental2() = 0);
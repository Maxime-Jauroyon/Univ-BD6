-- Checks if every shipments happens at least 14 days before the previous one of the same ship.

CREATE OR REPLACE FUNCTION date_mismatches()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM
            shipments AS S1
            JOIN shipments AS S2 ON S1.ship_id = S2.ship_id
        WHERE
            S1.end_date IS NOT NULL
            AND S2.start_date < (S1.end_date + '14 day'::interval)::date
            AND S2.start_date > S1.start_date);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_date CHECK (date_mismatches() = 0);
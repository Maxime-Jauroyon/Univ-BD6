-- Checks if every shipments has at least one leg when needed before departure.

CREATE OR REPLACE FUNCTION leg_mismatches()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM
            shipments AS S
        WHERE
            NOT EXISTS (
                SELECT
                    *
                FROM
                    shipments
                NATURAL JOIN legs
            WHERE
                distance > 2000
                AND S.shipment_id = shipment_id
                AND traveled_distance <= (distance / 2 + 500)
                AND traveled_distance >= (distance / 2 - 500))
            AND distance > 2000);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_leg CHECK (departed = FALSE OR leg_mismatches() = 0);
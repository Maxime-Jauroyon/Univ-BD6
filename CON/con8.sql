-- Checks if every shipments has a volume that it can sustain before departure.

CREATE OR REPLACE FUNCTION volume_mismatches()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM
            ships
            NATURAL JOIN (
                SELECT
                    shipment_id,
                    ship_id,
                    passengers,
                    SUM(A.volume_cargo) AS volume_shipment
                FROM
                    shipments
                    NATURAL
                    LEFT OUTER JOIN (
                        SELECT
                            shipment_id,
                            cargo_id,
                            quantity * volume AS volume_cargo
                        FROM
                            cargo
                            NATURAL JOIN products) AS A
                    GROUP BY
                        shipment_id,
                        ship_id,
                        passengers) AS B
        WHERE
            B.volume_shipment > tonnage_capacity);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_volume CHECK (departed = FALSE OR volume_mismatches() = 0);
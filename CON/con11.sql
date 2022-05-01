-- Checks if every shipments does not start or end within a country it is in war with.

CREATE OR REPLACE FUNCTION wars_mismatches()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM
            shipments AS SS,
            (
                SELECT
                    *
                FROM
                    diplomatic_relationships,
                    (
                        SELECT
                            shipment_id,
                            ship_id,
                            country_name
                        FROM (ships_nationalities
                        NATURAL JOIN (
                            SELECT
                                *
                            FROM
                                ships
                                NATURAL JOIN shipments) AS F) AS S
                    WHERE
                        start_possesion_date = (
                            SELECT
                                MAX(start_possesion_date)
                            FROM
                                ships_nationalities
                            WHERE
                                ship_id = S.ship_id AND start_possesion_date <= S.start_date)) AS S1
                    WHERE
                        country_name_1 = S1.country_name AND relation = 'En guerre') AS S2
        WHERE
            SS.ship_id = S2.ship_id AND (port_country_name_start = S2.country_name_2 OR port_country_name_end = S2.country_name_2));
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_wars CHECK (wars_mismatches() = 0);

-- Checks if every products categories form disjointed sets.

CREATE OR REPLACE FUNCTION categorized_disjointed()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM ((
                SELECT
                    F.product_id
                FROM
                    food AS F,
                    clothes AS C
                WHERE
                    F.product_id = C.product_id
                UNION
                SELECT
                    F.product_id
                FROM
                    food AS F,
                    material AS M
                WHERE
                    F.product_id = M.product_id)
            UNION
            SELECT
                C.product_id
            FROM
                clothes AS C,
                material AS M
            WHERE
                C.product_id = M.product_id) AS FCM);
END;
$function$;

ALTER TABLE products ADD CONSTRAINT check_disjointed CHECK (categorized = FALSE OR categorized_disjointed() = 0);

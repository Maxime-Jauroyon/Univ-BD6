CREATE OR REPLACE FUNCTION categorized_total()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM
            products AS P
        WHERE
            NOT EXISTS (
                SELECT
                    *
                FROM
                    food AS F,
                    clothes AS C,
                    material AS M
                WHERE
                    P.product_id = F.product_id
                    OR P.product_id = C.product_id
                    OR P.product_id = M.product_id));
END;
$function$;

ALTER TABLE products ADD CONSTRAINT check_total CHECK (categorized = FALSE OR categorized_total() = 0);

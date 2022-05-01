-- Checks if every products categories form disjointed sets.

CREATE OR REPLACE FUNCTION categorized_disjointed()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM (
            SELECT
                C.product_id
            FROM
                food AS F,
                clothes AS C
            WHERE
                C.product_id = F.product_id
            UNION
            SELECT
                C.product_id
            FROM
                clothes AS C,
                materials AS MA
            WHERE
                C.product_id = MA.product_id
            UNION
            SELECT
                C.product_id
            FROM
                clothes AS C,
                misc AS MI
            WHERE
                C.product_id = MI.product_id
            UNION
            SELECT
                MA.product_id
            FROM 
               materials AS MA,
               food AS F
            WHERE MA.product_id = F.product_id
            UNION
            SELECT
                MA.product_id
            FROM 
               materials AS MA,
               misc AS MI
            WHERE MA.product_id = MI.product_id
            UNION
            SELECT
                MI.product_id
            FROM 
               misc AS MI,
               food AS F
            WHERE MI.product_id = F.product_id) AS FINAL);
END;
$function$;

ALTER TABLE products ADD CONSTRAINT check_disjointed CHECK (categorized = FALSE OR categorized_disjointed() = 0);
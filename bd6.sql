-- Drops every existing triggers.
DROP TRIGGER IF EXISTS trigger_shipment_for_mismatches on shipments;

-- Drops every existing functions.
DROP FUNCTION IF EXISTS check_shipment_for_mismatches;

-- Drops every existing tables.
DROP TABLE IF EXISTS trading;
DROP TABLE IF EXISTS cargo;
DROP TABLE IF EXISTS misc;
DROP TABLE IF EXISTS materials;
DROP TABLE IF EXISTS clothes;
DROP TABLE IF EXISTS food;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS legs;
DROP TABLE IF EXISTS shipments;
DROP TABLE IF EXISTS ships_nationalities;
DROP TABLE IF EXISTS ships;
DROP TABLE IF EXISTS ports;
DROP TABLE IF EXISTS diplomatic_relationships;
DROP TABLE IF EXISTS countries;

-- Creates every tables.
CREATE TABLE countries (
    country_name text NOT NULL,
    continent text NOT NULL,
    PRIMARY KEY (country_name)
);

CREATE TABLE diplomatic_relationships (
    country_name_1 text NOT NULL,
    country_name_2 text NOT NULL,
    relation text NOT NULL,
    PRIMARY KEY (country_name_1, country_name_2)
);

CREATE TABLE ports (
    port_name text NOT NULL,
    port_country_name text NOT NULL,
    latitude float8 NOT NULL,
    longitude float8 NOT NULL,
    port_category int4 NOT NULL,
    PRIMARY KEY (port_name, port_country_name)
);

CREATE TABLE ships (
    ship_id int4 NOT NULL,
    ship_type text NOT NULL,
    ship_category int4 NOT NULL,
    tonnage_capacity int4 NOT NULL,
    passengers_capacity int4 NOT NULL,
    PRIMARY KEY (ship_id)
);

CREATE TABLE ships_nationalities (
    ship_id int4 NOT NULL,
    country_name text NOT NULL,
    start_possesion_date date NOT NULL,
    PRIMARY KEY (ship_id, country_name, start_possesion_date)
);

CREATE TABLE shipments (
    shipment_id int4 NOT NULL,
    ship_id int4,
    port_name_start text,
    port_name_end text,
    port_country_name_start text,
    port_country_name_end text,
    start_date date NOT NULL,
    end_date date,
    duration int4,
    passengers int4 NOT NULL,
    shipment_type text NOT NULL,
    class text NOT NULL,
    capture_date date,
    distance int4 NOT NULL,
    departed bool NOT NULL DEFAULT FALSE,
    PRIMARY KEY (shipment_id)
);

CREATE TABLE legs (
    shipment_id int4 NOT NULL,
    port_name text NOT NULL,
    port_country_name text NOT NULL,
    offloaded_passengers int4 NOT NULL,
    loaded_passengers int4 NOT NULL,
    traveled_distance int4 NOT NULL,
    PRIMARY KEY (shipment_id, port_name, port_country_name)
);

CREATE TABLE products (
    product_id int4 NOT NULL,
    name text NOT NULL,
    volume int4 NOT NULL,
    perishable bool NOT NULL,
    categorized bool NOT NULL DEFAULT FALSE,
    PRIMARY KEY (product_id)
);

CREATE TABLE food (
    product_id int4 NOT NULL,
    shelf_life int4 NOT NULL,
    price_per_kg int4 NOT NULL,
    PRIMARY KEY (product_id)
);

CREATE TABLE clothes (
    product_id int4 NOT NULL,
    material text NOT NULL,
    unit_price int4 NOT NULL,
    unit_weight float8 NOT NULL,
    PRIMARY KEY (product_id)
);

CREATE TABLE materials (
    product_id int4 NOT NULL,
    volume_price int4 NOT NULL,
    PRIMARY KEY (product_id)
);

CREATE TABLE misc (
    product_id int4 NOT NULL,
    PRIMARY KEY (product_id)
);

CREATE TABLE cargo (
    cargo_id int4 NOT NULL,
    shipment_id int4,
    product_id int4,
    quantity int4 NOT NULL,
    PRIMARY KEY (cargo_id)
);

CREATE TABLE trading (
    cargo_id int4 NOT NULL,
    shipment_id int4 NOT NULL,
    port_name text NOT NULL,
    port_country_name text NOT NULL,
    sold int4 NOT NULL,
    bought int4 NOT NULL,
    PRIMARY KEY (cargo_id, shipment_id, port_name, port_country_name)
);

-- Adds every foreign key references to the newly created tables.
ALTER TABLE diplomatic_relationships ADD FOREIGN KEY (country_name_1) REFERENCES countries(country_name);
ALTER TABLE diplomatic_relationships ADD FOREIGN KEY (country_name_1) REFERENCES countries(country_name);
ALTER TABLE ports ADD FOREIGN KEY (port_country_name) REFERENCES countries(country_name);
ALTER TABLE ships_nationalities ADD FOREIGN KEY (country_name) REFERENCES countries(country_name);
ALTER TABLE ships_nationalities ADD FOREIGN KEY (ship_id) REFERENCES ships(ship_id);
ALTER TABLE shipments ADD FOREIGN KEY (port_name_start, port_country_name_start) REFERENCES ports(port_name, port_country_name);
ALTER TABLE shipments ADD FOREIGN KEY (port_name_end, port_country_name_end) REFERENCES ports(port_name, port_country_name);
ALTER TABLE shipments ADD FOREIGN KEY (ship_id) REFERENCES ships(ship_id);
ALTER TABLE legs ADD FOREIGN KEY (port_name, port_country_name) REFERENCES ports(port_name, port_country_name);
ALTER TABLE legs ADD FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id);
ALTER TABLE food ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE clothes ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE materials ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE misc ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE cargo ADD FOREIGN KEY (product_id) REFERENCES products(product_id);
ALTER TABLE cargo ADD FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id);
ALTER TABLE trading ADD FOREIGN KEY (port_name, port_country_name) REFERENCES ports(port_name, port_country_name);
ALTER TABLE trading ADD FOREIGN KEY (cargo_id) REFERENCES cargo(cargo_id);
ALTER TABLE trading ADD FOREIGN KEY (shipment_id) REFERENCES shipments(shipment_id);

-- Creates every triggers.

-- To depart, a shipment must be filled with passengers and/or filled with merchandises.
-- This raises an exception if a shipment does not fulfill those necessary conditions.
CREATE OR REPLACE FUNCTION check_shipment_for_mismatches()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $function$
DECLARE
    v_passengers_capacity INT4;
    v_passengers_filled BOOLEAN := TRUE;
    v_tonnage_capacity INT4;
    v_tonnage INT4;
    v_tonnage_filled BOOLEAN := TRUE;
BEGIN
    IF NEW.departed = FALSE THEN
        RETURN NEW;
    END IF;

    v_passengers_capacity := (
        SELECT
            passengers_capacity
        FROM
            ships
        WHERE
            ship_id = NEW.ship_id);

    IF NEW.passengers > v_passengers_capacity THEN
        RAISE EXCEPTION 'Shipment % contains too much passengers to depart!', NEW.shipment_id;
    END IF;

    IF NEW.passengers <> v_passengers_capacity THEN
        v_passengers_filled := FALSE;
    END IF;

    v_tonnage_capacity := (SELECT
            tonnage_capacity
        FROM
            ships
        WHERE
            ship_id = NEW.ship_id);

    v_tonnage := (
        SELECT
            SUM(A.volume_of_cargo)
        FROM
            shipments
            NATURAL
            LEFT OUTER JOIN (
            SELECT
                quantity * volume AS volume_of_cargo
            FROM
                cargo
                NATURAL JOIN products
            WHERE
                shipment_id = NEW.shipment_id) AS A
        WHERE
            shipment_id = NEW.shipment_id);

    IF v_tonnage > v_tonnage_capacity THEN
        RAISE EXCEPTION 'Shipment % contains too much merchandises to depart!', NEW.shipment_id;
    END IF;

    IF v_tonnage <> v_tonnage_capacity THEN
        v_tonnage_filled := FALSE;
    END IF;

    IF v_passengers_filled = FALSE AND v_tonnage_filled = FALSE THEN
        RAISE EXCEPTION 'Shipment % is not filled enough to depart!', NEW.shipment_id;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE TRIGGER trigger_shipment_for_mismatches
   AFTER INSERT OR UPDATE OF departed ON shipments
   FOR EACH ROW
   EXECUTE PROCEDURE check_shipment_for_mismatches();

-- To be categorized, a product must be present in exactly one category.
-- This raises an exception if a product does not fulfill those necessary conditions.
CREATE OR REPLACE FUNCTION check_product_for_mismatches()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $function$
DECLARE
    v_is_unique BOOLEAN := TRUE;
BEGIN
    IF NEW.categorized = FALSE THEN
        RETURN NEW;
    END IF;

    IF (SELECT
            COUNT(*)
        FROM (
            SELECT
                product_id
            FROM
                food AS A
            WHERE
                NEW.product_id = A.product_id
            UNION ALL
            SELECT
                product_id
            FROM
                clothes AS A
            WHERE
                NEW.product_id = A.product_id
            UNION ALL
            SELECT
                product_id
            FROM
                materials AS A
            WHERE
                NEW.product_id = A.product_id
            UNION ALL
            SELECT
                product_id
            FROM
                misc AS A
            WHERE
                NEW.product_id = A.product_id
            ) AS DERIVED_TABLE) <> 1
    THEN
        v_is_unique := FALSE;
    END IF;

    IF v_is_unique = FALSE THEN
        RAISE EXCEPTION 'Product % doesn''t respect the requirements to be considered categorized!', NEW.product_id;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE TRIGGER trigger_product_for_mismatches
   AFTER INSERT OR UPDATE OF categorized ON products
   FOR EACH ROW
   EXECUTE PROCEDURE check_product_for_mismatches();

-- TODO: REFACTOR

CREATE OR REPLACE FUNCTION category_mismatches_shipment()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
             COUNT(*)
        FROM
            (SELECT *
            FROM(SELECT *
                 FROM shipments
                 NATURAL JOIN ships) as S
            JOIN ports
            ON port_name = S.port_name_start
            AND port_country_name = S.port_country_name_start
            WHERE ship_category > port_category
            UNION
            SELECT *
            FROM(SELECT *
                 FROM shipments
                 NATURAL JOIN ships) as S
            JOIN ports
            ON port_name = S.port_name_end
            AND port_country_name = S.port_country_name_end
            WHERE ship_category > port_category) as C);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_category CHECK (category_mismatches_shipment() = 0);

CREATE OR REPLACE FUNCTION category_mismatches_trading()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
             COUNT(*)
        FROM(SELECT *
             FROM shipments
             NATURAL JOIN ships) as S
        JOIN(SELECT *
             FROM ports
             NATURAL JOIN trading) as S1
        ON S1.shipment_id = S.shipment_id
        WHERE ship_category > port_category);
END;
$function$;

ALTER TABLE trading ADD CONSTRAINT check_category CHECK (category_mismatches_trading() = 0);


CREATE OR REPLACE FUNCTION type_mismatches()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT COUNT(*)
        FROM
            (SELECT *
            FROM shipments
            WHERE shipment_type = 'court'
            AND distance >= 1000
            UNION
            SELECT *
            FROM shipments
            WHERE shipment_type = 'moyen'
            AND (distance < 1000 OR distance >= 2000)
            UNION
            SELECT *
            FROM shipments
            WHERE shipment_type = 'long'
            AND distance < 2000) as D);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_type CHECK (type_mismatches() = 0);

CREATE OR REPLACE FUNCTION class_mismatches_Intercontinental()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
             COUNT(*)
        FROM shipments
        NATURAL JOIN ships
        WHERE class = 'Intercontinental'
        AND ship_category <> 5);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_class_Intercontinental CHECK (class_mismatches_Intercontinental() = 0);

CREATE OR REPLACE FUNCTION class_mismatches_Intercontinental2()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
             COUNT(*)
        FROM shipments
        WHERE class = 'Intercontinental'
        AND distance < 1000);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_class_Intercontinental2 CHECK (class_mismatches_Intercontinental2() = 0);


CREATE OR REPLACE FUNCTION class_mismatches()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
             COUNT(*)
        FROM shipments
        JOIN countries
        ON country_name = port_country_name_end
        WHERE class <> 'Intercontinental'
        AND class <> continent);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_class CHECK (class_mismatches() = 0);

CREATE OR REPLACE FUNCTION leg_mismatches()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
             COUNT(*)
        FROM shipments as S
        WHERE NOT EXISTS (SELECT *
                          FROM shipments
                          NATURAL JOIN legs
                          WHERE distance > 2000
                          AND S.shipment_id = shipment_id
                          AND traveled_distance <= (distance/2 + 500)
                          AND traveled_distance >= (distance/2 - 500))
        AND distance > 2000);
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_leg CHECK (departed = FALSE OR leg_mismatches() = 0);

CREATE OR REPLACE FUNCTION date_mismatches()
 RETURNS integer
 LANGUAGE plpgsql
AS $function$
BEGIN
    RETURN (
        SELECT
            COUNT(*)
        FROM shipments as S1
        JOIN shipments as S2
        ON S1.ship_id = S2.ship_id
        WHERE S1.end_date IS NOT NULL
        and S2.start_date < (S1.end_date + '14 day'::interval)::date
        and S2.start_date > S1.start_date );
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_date CHECK (date_mismatches() = 0);

CREATE OR REPLACE FUNCTION perishable_mismatches()
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
            shipment_id IN (
                SELECT
                    shipment_id FROM cargo AS C
                NATURAL JOIN products
            WHERE
                perishable IS TRUE) AND (shipment_type = 'moyen' OR shipment_type = 'long'));
END;
$function$;

ALTER TABLE shipments ADD CONSTRAINT check_perishable CHECK (perishable_mismatches() = 0);

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


\i 'load.sql';

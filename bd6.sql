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

-- Represents a country within the world.
CREATE TABLE countries (
    country_name text NOT NULL,
    continent text NOT NULL,
    PRIMARY KEY (country_name)
);

-- Represents a relationship between two countries.
CREATE TABLE diplomatic_relationships (
    country_name_1 text NOT NULL,
    country_name_2 text NOT NULL,
    relation text NOT NULL,
    PRIMARY KEY (country_name_1, country_name_2)
);

-- Represents a port within a country.
CREATE TABLE ports (
    port_name text NOT NULL,
    port_country_name text NOT NULL,
    latitude float8 NOT NULL,
    longitude float8 NOT NULL,
    port_category int4 NOT NULL,
    PRIMARY KEY (port_name, port_country_name)
);

-- Represents a ship.
CREATE TABLE ships (
    ship_id int4 NOT NULL,
    ship_type text NOT NULL,
    ship_category int4 NOT NULL,
    tonnage_capacity int4 NOT NULL,
    passengers_capacity int4 NOT NULL,
    PRIMARY KEY (ship_id)
);

-- Represents ownership of a ship to a country.
CREATE TABLE ships_nationalities (
    ship_id int4 NOT NULL,
    country_name text NOT NULL,
    start_possesion_date date NOT NULL,
    PRIMARY KEY (ship_id, country_name, start_possesion_date)
);

-- Represents a shipment (= a travel).
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

-- Represents a leg (= a stop during a travel).
CREATE TABLE legs (
    shipment_id int4 NOT NULL,
    port_name text NOT NULL,
    port_country_name text NOT NULL,
    offloaded_passengers int4 NOT NULL,
    loaded_passengers int4 NOT NULL,
    traveled_distance int4 NOT NULL,
    arrival_date date NOT NULL,
    PRIMARY KEY (shipment_id, port_name, port_country_name)
);

-- Represents a product which can be sold or bought.
CREATE TABLE products (
    product_id int4 NOT NULL,
    name text NOT NULL,
    volume int4 NOT NULL,
    perishable bool NOT NULL,
    categorized bool NOT NULL DEFAULT FALSE,
    PRIMARY KEY (product_id)
);

-- Represents food (a category of products).
CREATE TABLE food (
    product_id int4 NOT NULL,
    shelf_life int4 NOT NULL,
    price_per_kg int4 NOT NULL,
    PRIMARY KEY (product_id)
);

-- Represents a cloth (a category of products).
CREATE TABLE clothes (
    product_id int4 NOT NULL,
    material text NOT NULL,
    unit_price int4 NOT NULL,
    unit_weight float8 NOT NULL,
    PRIMARY KEY (product_id)
);

-- Represents a material (a category of products).
CREATE TABLE materials (
    product_id int4 NOT NULL,
    volume_price int4 NOT NULL,
    PRIMARY KEY (product_id)
);

-- Represents another product (a category of products).
CREATE TABLE misc (
    product_id int4 NOT NULL,
    PRIMARY KEY (product_id)
);

-- Represents a cargo (a set of a specific product with a given quantity).
CREATE TABLE cargo (
    cargo_id int4 NOT NULL,
    shipment_id int4,
    product_id int4,
    quantity int4 NOT NULL,
    PRIMARY KEY (cargo_id)
);

-- Represents the trading (buying and selling) of parts of a cargo.
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

-- A country must exists on a predefined continent.
-- This raises an exception if a country does not fulfill those necessary conditions.
CREATE OR REPLACE FUNCTION check_country_continent_for_mismatches()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $function$
BEGIN
    IF NEW.continent <> 'Europe' AND
        NEW.continent <> 'Afrique' AND
        NEW.continent <> 'Amérique' AND
        NEW.continent <> 'Asie' AND
        NEW.continent <> 'Océanie' AND
        NEW.continent <> 'Antarctique'
    THEN
        RAISE EXCEPTION 'Country % cannot be created in an imaginary continent!', NEW.country_name;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE TRIGGER trigger_country_continent_for_mismatches
   AFTER INSERT OR UPDATE OF continent ON countries
   FOR EACH ROW
   EXECUTE PROCEDURE check_country_continent_for_mismatches();

-- A shipment must:
-- - Travel a distance that corresponds to its type.
-- - Start at a port that can handle its ship category.
-- - End at a port that can handle its ship category.
-- - Travel a certain distance and have a ship category that supports intercontinal shipment if it is one.
-- - Have a class ('Intercontinal' or a continent name) that corresponds to its end port.
-- - Travel at least 14 days after the last shipment of its ship.
-- - Not travel with perishable good if it isn't a short travel.
-- - Travel from or to a country with wich its ship's nationality is in war with.
-- This raises an exception if a shipment does not fulfill those necessary conditions.
CREATE OR REPLACE FUNCTION check_shipment_for_mismatches()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $function$
DECLARE
    v_ship_category INT4;
BEGIN
    IF (NEW.shipment_type = 'court' AND NEW.distance >= 1000) OR
       (NEW.shipment_type = 'moyen' AND (NEW.distance < 1000 OR NEW.distance >= 2000)) OR
       (NEW.shipment_type = 'long' AND NEW.distance < 2000)
    THEN
        RAISE EXCEPTION 'Shipment % travels a distance that does not corresponds to its type!', NEW.shipment_id;
    END IF;

    v_ship_category := (
        SELECT
            ship_category
        FROM
            ships
        WHERE
            ship_id = NEW.ship_id
        );

    IF v_ship_category > (
        SELECT
            port_category
        FROM
            ports
        WHERE
            port_name = NEW.port_name_start AND port_country_name = NEW.port_country_name_start)
    THEN
        RAISE EXCEPTION 'Shipment % starts at a port that doesn''t support its category!', NEW.shipment_id;
    END IF;

    IF v_ship_category > (
        SELECT
            port_category
        FROM
            ports
        WHERE
            port_name = NEW.port_name_end AND port_country_name = NEW.port_country_name_end)
    THEN
        RAISE EXCEPTION 'Shipment % ends at a port that doesn''t support its category!', NEW.shipment_id;
    END IF;

    IF NEW.class = 'Intercontinental' AND v_ship_category <> 5 THEN
        RAISE EXCEPTION 'Shipment % ship''s category does not permit intercontinental shipments!', NEW.shipment_id;
    END IF;

    IF NEW.class = 'Intercontinental' AND NEW.distance < 1000 THEN
        RAISE EXCEPTION 'Shipment % travelled distance does not permit intercontinental shipments!', NEW.shipment_id;
    END IF;

    IF NEW.class <> 'Intercontinental' AND
        NEW.class <> (
        SELECT
            continent
        FROM
            countries
        WHERE
            continent = NEW.port_country_name_end) 
    THEN
        RAISE EXCEPTION 'Shipment % class is not correct!', NEW.shipment_id;
    END IF;

    IF (SELECT
            COUNT(*)
        FROM
            shipments AS A
        WHERE
            NEW.ship_id = A.ship_id AND
            A.end_date IS NOT NULL AND
            NEW.start_date < (A.end_date + '14 day'::interval)::date AND
            NEW.start_date > A.start_date) <> 0
    THEN
        RAISE EXCEPTION 'Shipment % ship has travelled too recently to be able to depart so soon!', NEW.shipment_id;
    END IF;

    IF NEW.shipment_id IN (
            SELECT
                shipment_id FROM cargo AS A
            NATURAL JOIN products
            WHERE
                perishable IS TRUE) AND
        (NEW.shipment_type = 'moyen' OR NEW.shipment_type = 'long')
    THEN
        RAISE EXCEPTION 'Shipment % contains perishable good when it shouldn''t!', NEW.shipment_id;
    END IF;

    IF 0 <> (
        SELECT
            COUNT(*)
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
                        ship_id = S.ship_id
                        AND start_possesion_date <= S.start_date)) AS S1
        WHERE
            country_name_1 = S1.country_name AND
                relation = 'En guerre' AND
                NEW.ship_id = ship_id AND (
                    NEW.port_country_name_start = country_name_2 OR NEW.port_country_name_end = country_name_2))
    THEN
        RAISE EXCEPTION 'Shipment % starts from or end to a port with wich its ship''s nationality is in war with!', NEW.shipment_id;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE TRIGGER trigger_shipment_for_mismatches
   AFTER INSERT OR UPDATE ON shipments
   FOR EACH ROW
   EXECUTE PROCEDURE check_shipment_for_mismatches();

-- To depart, a shipment must be filled with passengers and/or filled with merchandises.
-- This raises an exception if a shipment does not fulfill those necessary conditions.
CREATE OR REPLACE FUNCTION check_shipment_departure_for_mismatches()
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

    IF NEW.distance > 2000 AND (
        SELECT
            COUNT(*)
        FROM
            legs
        WHERE
            NEW.shipment_id = shipment_id
            AND traveled_distance <= (NEW.distance / 2 + 500)
            AND traveled_distance >= (NEW.distance / 2 - 500)) = 0
    THEN
        RAISE EXCEPTION 'Shipment % should possess at least one leg!', NEW.shipment_id;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE TRIGGER trigger_shipment_departure_for_mismatches
   AFTER INSERT OR UPDATE OF departed ON shipments
   FOR EACH ROW
   EXECUTE PROCEDURE check_shipment_departure_for_mismatches();

-- To be categorized, a product must be present in exactly one category.
-- This raises an exception if a product does not fulfill those necessary conditions.
CREATE OR REPLACE FUNCTION check_product_category_for_mismatches()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $function$
DECLARE
    v_is_unique BOOLEAN := TRUE;
BEGIN
    IF (SELECT
            categorized
        FROM
            products as A
        WHERE
            NEW.product_id = A.product_id) = FALSE
    THEN
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
        RAISE EXCEPTION 'Product % is present in more than one category!', NEW.product_id;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE TRIGGER trigger_product_category_for_mismatches
   AFTER INSERT OR UPDATE OF categorized ON products
   FOR EACH ROW
   EXECUTE PROCEDURE check_product_category_for_mismatches();

CREATE OR REPLACE TRIGGER trigger_food_category_for_mismatches
   AFTER INSERT OR UPDATE OF product_id ON food
   FOR EACH ROW
   EXECUTE PROCEDURE check_product_category_for_mismatches();

CREATE OR REPLACE TRIGGER trigger_clothes_category_for_mismatches
   AFTER INSERT OR UPDATE OF product_id ON clothes
   FOR EACH ROW
   EXECUTE PROCEDURE check_product_category_for_mismatches();

CREATE OR REPLACE TRIGGER trigger_materials_category_for_mismatches
   AFTER INSERT OR UPDATE OF product_id ON materials
   FOR EACH ROW
   EXECUTE PROCEDURE check_product_category_for_mismatches();

CREATE OR REPLACE TRIGGER trigger_misc_category_for_mismatches
   AFTER INSERT OR UPDATE OF product_id ON misc
   FOR EACH ROW
   EXECUTE PROCEDURE check_product_category_for_mismatches();

-- A trading must happen on a port that support its ship category.
-- This raises an exception if a trading does not fulfill those necessary conditions.
CREATE OR REPLACE FUNCTION check_trading_port_for_mismatches()
    RETURNS TRIGGER
    LANGUAGE plpgsql
    AS $function$
BEGIN
    IF (SELECT
            ship_category
        FROM
            ships as A
        WHERE
            A.ship_id = (
            SELECT
                ship_id
            FROM
                shipment as B
            WHERE
                B.shipment_id = NEW.shipment_id)) > (
        SELECT
            port_category
        FROM
            ports as A
        WHERE
            NEW.port_name = A.port_name AND NEW.port_country_name = A.port_country_name)
    THEN
        RAISE EXCEPTION 'Trading % happens in a port that doesn''t support its ship!', NEW.shipment_id;
    END IF;

    RETURN NEW;
END;
$function$;

CREATE OR REPLACE TRIGGER trigger_trading_port_for_mismatches
   AFTER INSERT OR UPDATE OF shipment_id OR UPDATE OF port_name OR UPDATE OF port_country_name ON trading
   FOR EACH ROW
   EXECUTE PROCEDURE check_trading_port_for_mismatches();

-- Loads the initial set of data.
\i 'load.sql';

-- Requête 1
-- Liste toutes les expéditions où un bateau a été capturé.
-- Retourne l'identifiant de l'expédition, l'attaquant, le défenseur et leur relation.

-- Lists every shipments where a boat has been captured.
-- Returns the shipment id, the raider, the defender and their relationship.

SELECT
    A.shipment_id,
    A.raider,
    A.defender_country,
    relation
FROM (
    SELECT
        S.shipment_id,
        S1.country_name AS raider,
        S2.country_name AS defender_country
    FROM
        shipments AS S,
        ships_nationalities AS S1,
        ships_nationalities AS S2
    WHERE
        S.capture_date IS NOT NULL
        AND S.ship_id = S1.ship_id
        AND S1.ship_id = S2.ship_id
        AND S.capture_date = S1.start_possesion_date
        AND S2.start_possesion_date < S.capture_date
        AND S2.start_possesion_date >= ALL (
            SELECT
                S3.start_possesion_date
            FROM
                ships_nationalities AS S3
            WHERE
                S3.ship_id = S2.ship_id AND S3.start_possesion_date < S.capture_date)) AS A
    LEFT OUTER JOIN diplomatic_relationships ON A.raider = country_name_1 AND A.defender_country = country_name_2;

-- Requête 2
-- Liste tous les navires qui ont effectué au moins 2 expéditions.
-- Renvoie l'identifiant du navire et le volume moyen transporté par expédition.

-- Lists every ships who made at least 2 shipments.
-- Returns the ship id and the average volume transported per shipment.

SELECT
    ship_id,
    AVG(volume_shipment)
FROM
    ships
NATURAL JOIN (
    SELECT
        shipment_id,
        ship_id,
        SUM(COALESCE(A.volume_cargo,0)) AS volume_shipment
    FROM
        shipments
    NATURAL LEFT OUTER JOIN (
        SELECT
            shipment_id,
            cargo_id,
            ((quantity * volume) + 0.0) AS volume_cargo
        FROM
            cargo
        NATURAL JOIN products) AS A
    GROUP BY
        shipment_id,
        ship_id) AS B
GROUP BY
    ship_id
HAVING
    COUNT(shipment_id) > 1;

-- Requête 3
-- Liste tous les navires qui ont toujours commencé leurs expéditions avec le nombre de passagers remplis.
-- Retourne l'identifiant du navire.

-- Lists every ships who always started their shipments with the count of passengers filled.
-- Returns the ship id.

SELECT
    ship_id
FROM (
    SELECT
        ship_id,
        COUNT(shipment_id) AS nbFull
    FROM
        ships
    NATURAL JOIN shipments
    WHERE
        passengers_capacity = passengers
    GROUP BY
        ship_id) AS F
NATURAL JOIN (
    SELECT
        ship_id,
        COUNT(shipment_id) AS nbTotal
    FROM
        ships
    NATURAL JOIN shipments
    GROUP BY
        ship_id) AS T
WHERE
    F.nbFull = T.nbTotal;

-- Requête 4
-- Liste tous les navires qui ont toujours commencé leurs expéditions avec le nombre de passagers remplis.
-- Liste tous les navires qui ont toujours commencé leurs expéditions avec le nombre de passagers remplis.
-- Retourne l'identifiant du navire.

-- Lists every ships who always started their shipments with the count of passengers filled.
-- Returns the ship id.

SELECT
    DISTINCT ship_id
FROM
    ships AS S
NATURAL JOIN shipments
WHERE NOT EXISTS (
    SELECT
        *
    FROM
        ships
    NATURAL JOIN shipments
    WHERE
        S.ship_id = ship_id AND passengers_capacity <> passengers);

-- Requête 5
-- Liste récursivement tous les trajets effectués par un navire pendant ses expéditions jusqu'à sa capture par un ennemi.

-- Recursively lists all travels made per ship during their shipments until capture by an enemy.

WITH RECURSIVE shipment (
    ship_id,
    port_name_start,
    port_country_name_start,
    port_name_end,
    port_country_name_end,
    start_date,
    end_date
) AS (
    SELECT
        ship_id,
        port_name_start,
        port_country_name_start,
        port_name_end,
        port_country_name_end,
        start_date,
        end_date
    FROM
        shipments
    UNION
    SELECT
        T.ship_id,
        T.port_name_start,
        T.port_country_name_start,
        S.port_name_end,
        S.port_country_name_end,
        T.start_date,
        S.end_date
    FROM
        shipments AS S,
        shipment AS T
    WHERE
        S.ship_id = T.ship_id
        AND S.port_name_start = T.port_name_end
        AND S.port_country_name_start = T.port_country_name_end
        AND T.end_date IS NOT NULL
        AND T.end_date < S.start_date
        AND S.start_date <= ALL (
            SELECT
                S1.start_date
            FROM
                shipments AS S1
            WHERE
                S1.ship_id = S.ship_id
                AND T.end_date < S1.start_date
                AND S1.port_name_start = T.port_name_end
                AND S1.port_country_name_start = T.port_country_name_end)
)
SELECT
    *
FROM
    shipment;

-- Requête 6
-- retourne l'id du voyage qui a duré le plus longtemps.

-- Returns the shipment id with the longuest duration travelled.

-- valeurs NULL sont ignorées par MAX().
-- NULL values skipped by MAX().
SELECT
    shipment_id
FROM
    shipments
WHERE
    duration = (
        SELECT
            MAX(duration)
        FROM
            shipments);

-- les valeurs NULL donnent unknown comme résultat.
-- NULL values give unknown result.
SELECT
    shipment_id
FROM
    shipments
WHERE
    duration >= ALL (
        SELECT
            duration
        FROM
            shipments);

-- Avec une modification pour géré les valeurs NULL.
-- With a fix for NULL values.
SELECT
    shipment_id
FROM
    shipments
WHERE
    duration >= ALL (
        SELECT
            COALESCE(duration, 0)
        FROM
            shipments);

-- Requête 7
-- Retourne chaque expédition avec son nombre de passager au début puis à la fin
-- et de manière identique pour le volume.

-- Returns each shipment with its count of passenger at the start then at the end
-- and identically for the volume.

SELECT
    shipment_id,
    PAF.passengers_start,
    PAF.passengers_end,
    COALESCE(VF.volume_start, 0) AS volume_start,
    COALESCE(VF.volume_end, 0) AS volume_end
FROM (
    SELECT
        shipment_id,
        passengers AS passengers_start,
        ((passengers + COALESCE(gain, 0)) - COALESCE(lose, 0)) AS passengers_end
    FROM
        shipments
    NATURAL LEFT OUTER JOIN (
        SELECT
            shipment_id,
            SUM(loaded_passengers) AS gain,
            SUM(offloaded_passengers) AS lose
        FROM
            legs
        GROUP BY
            shipment_id) AS PA) AS PAF
NATURAL LEFT OUTER JOIN (
    SELECT
        shipment_id,
        S.volume_shipment AS volume_start,
        ((S.volume_shipment + COALESCE(T.gain, 0)) - COALESCE(T.lose, 0)) AS volume_end
    FROM (
        SELECT
            shipment_id,
            SUM(A.volume_cargo) AS volume_shipment
        FROM
            shipments
        NATURAL JOIN (
            SELECT
                shipment_id,
                cargo_id,
                ((quantity * volume) + 0.0) AS volume_cargo
            FROM
                cargo
            NATURAL JOIN products) AS A
        GROUP BY
            shipment_id) AS S
    NATURAL LEFT OUTER JOIN (
        SELECT
            shipment_id,
            SUM(bought * volume_cargo) AS gain,
            SUM(sold * volume_cargo) AS lose
        FROM
            trading
        NATURAL JOIN (
            SELECT
                cargo_id,
                volume AS volume_cargo
            FROM
                cargo
            NATURAL JOIN products) AS PR
        GROUP BY
            shipment_id) AS T) AS VF
ORDER BY
    shipment_id;

-- Requête 8
-- Retourne l'évolution des nationalités pour chaque navire avec le nombre d'expéditions qu'ils ont effectuées sous chaque bannière.

-- Returns the evolution of nationalities for each ship with the number of
-- shipments they did under each banner.

SELECT
    ship_id,
    country_name,
    count(*) AS travel
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
        AND start_possesion_date <= S.start_date)
GROUP BY
    ship_id,
    country_name;


-- Requête 9
-- Renvoie la moyenne de la quantité expédiée pour chaque catégorie de produits.

-- Returns the average of quantity shipped for each category of products.

-- Because we could have 2 cargo of the same product on the same shipment we need to do it this way:
-- SELECT
--     shipment_id,product_id,SUM(quantity)
-- FROM
--     cargo
-- GROUP BY
--     shipment_id,product_id;

SELECT
    *
FROM (
    SELECT
        AVG(PCL.quantity) AS clothes
    FROM (
        SELECT
            shipment_id,
            SUM(P.quantity) AS quantity
        FROM
            clothes
        NATURAL JOIN (
            SELECT
                shipment_id,
                product_id,
                SUM(quantity) AS quantity
            FROM
                cargo
            GROUP BY
                shipment_id,
                product_id) AS P
        GROUP BY
            shipment_id) AS PCL) AS CL,
    (
        SELECT
            AVG(PMA.quantity) AS material
        FROM (
            SELECT
                shipment_id,
                SUM(P.quantity) AS quantity
            FROM
                materials
            NATURAL JOIN (
                SELECT
                    shipment_id,
                    product_id,
                    SUM(quantity) AS quantity
                FROM
                    cargo
                GROUP BY
                    shipment_id,
                    product_id) AS P
            GROUP BY
                shipment_id) AS PMA) AS MA,
    (
        SELECT
            AVG(PFO.quantity) AS food
        FROM (
            SELECT
                shipment_id,
                SUM(P.quantity) AS quantity
            FROM
                food
            NATURAL JOIN (
                SELECT
                    shipment_id,
                    product_id,
                    SUM(quantity) AS quantity
                FROM
                    cargo
                GROUP BY
                    shipment_id,
                    product_id) AS P
            GROUP BY
                shipment_id) AS PFO) AS F0,
    (
        SELECT
            AVG(PMI.quantity) AS misc
        FROM (
            SELECT
                shipment_id,
                SUM(P.quantity) AS quantity
            FROM
                misc
            NATURAL JOIN (
                SELECT
                    shipment_id,
                    product_id,
                    SUM(quantity) AS quantity
                FROM
                    cargo
                GROUP BY
                    shipment_id,
                    product_id) AS P
            GROUP BY
                shipment_id) AS PMI) AS MI;

-- Requête 10
-- Renvoie la taille de l'expédition la plus longue (en termes de port parcouru) par catégorie de navire.
-- La taille de l'expédition est calculée à partir du port de départ ajouté au port de chaque étape et enfin
-- ajouté au port de fin.

-- Returns the longuest shipment's size (in term of port travelled) per ship cagegory.
-- The shipment size is calculated with the start port added with each leg's port and finally
-- added with the end port.

WITH RECURSIVE shipment (
    ship_id,
    port_name_start,
    port_country_name_start,
    port_name_end,
    port_country_name_end,
    start_date,
    end_date,
    ports
) AS (
    SELECT
        ship_id,
        port_name_start,
        port_country_name_start,
        port_name_end,
        port_country_name_end,
        start_date,
        end_date,
        (2 + (
                SELECT
                    COUNT(*)
                FROM
                    legs
                WHERE
                    shipment_id = S.shipment_id)) AS ports
    FROM
        shipments AS S
    UNION
    SELECT
        T.ship_id,
        T.port_name_start,
        T.port_country_name_start,
        S.port_name_end,
        S.port_country_name_end,
        T.start_date,
        S.end_date,
        (T.ports + 1 + (
                        SELECT
                            COUNT(*)
                        FROM
                            legs
                        WHERE
                            shipment_id = S.shipment_id)) AS ports
    FROM
        shipments AS S,
        shipment AS T
    WHERE
        S.ship_id = T.ship_id
    AND S.port_name_start = T.port_name_end
    AND S.port_country_name_start = T.port_country_name_end
    AND T.end_date IS NOT NULL
    AND T.end_date < S.start_date
    AND S.start_date <= ALL (
                            SELECT
                                S1.start_date
                            FROM
                                shipments AS S1
                            WHERE
                                S1.ship_id = S.ship_id
                            AND T.end_date < S1.start_date
                            AND S1.port_name_start = T.port_name_end
                            AND S1.port_country_name_start = T.port_country_name_end)
)
SELECT
    ship_category, MAX(ports)
FROM
    shipment
NATURAL JOIN ships
GROUP BY
    ship_category;

-- Requête 11
-- Renvoie une ligne par pays en guerre les uns contre les autres avec le gagnant probable et le perdant probable
-- (en fonction de la taille de sa flotte).

-- Returns a line per countries in war with each other with the probable winner and probable looser
-- (depending on the size of its fleet).

WITH fleets (
    country,
    fleet
) AS (
    SELECT
        country_name,
        count(*) AS fleet
    FROM
        countries
    NATURAL JOIN ships_nationalities AS S
    WHERE
        start_possesion_date = (
            SELECT
                MAX(start_possesion_date)
            FROM
                ships_nationalities
            WHERE
                ship_id = S.ship_id)
    GROUP BY
        country_name
)
SELECT
    F1.country AS probable_winner,
    F2.country AS probable_looser
FROM
    diplomatic_relationships,
    fleets AS F1,
    fleets AS F2
WHERE
    country_name_1 = F1.country
AND country_name_2 = F2.country
AND relation = 'En guerre'
AND F1.fleet > F2.fleet;

-- Requête 12
-- Retourne l'expédition qui a fait le plus gros échange en quantité ou en volume.

-- Returns the shipment who has made the biggest trading in either quantity or volume.

-- En quantité:
-- In quantity:
SELECT
    S.shipment_id,
    S.quantity
FROM (
    SELECT
        shipment_id,
        SUM(sold + bought) AS quantity
    FROM
        trading
    GROUP BY
        shipment_id) AS S
WHERE
    S.quantity = (
        SELECT
            MAX(S1.quantity)
        FROM (
            SELECT
                shipment_id,
                SUM(sold + bought) AS quantity
            FROM
                trading
            GROUP BY
                shipment_id) AS S1);

-- En volume:
-- In volume:
SELECT
    S.shipment_id,
    S.volume
FROM (
    SELECT
        shipment_id,
        SUM((bought + sold) * volume) AS volume
    FROM
        trading
    NATURAL JOIN (
        SELECT
            cargo_id,
            volume
        FROM
            cargo
            NATURAL JOIN products) AS PR
    GROUP BY
        shipment_id) AS S
WHERE
    S.volume = (
        SELECT
            Max(S1.volume)
        FROM (
            SELECT
                shipment_id,
                SUM((bought + sold) * volume) AS volume
            FROM
                trading
            NATURAL JOIN (
                SELECT
                    cargo_id,
                    volume
                FROM
                    cargo
                    NATURAL JOIN products) AS PR
            GROUP BY
                shipment_id) AS S1);

-- Requête 13
-- Retourne l'évolution du nombre de passagers et du volume de marchandises
-- pour chaque étape de chaque expédition.

-- Returns the evolution of the number of passengers and volume of merchandises
-- for each shipments at each step of the shipment.

WITH RECURSIVE evolution (
    shipment_id,
    port_name,
    port_country_name,
    distance,
    passengers,
    volume
) AS (
    SELECT
        shipment_id,
        port_name_start AS port_name,
        port_country_name_start AS port_country_name,
        0 AS distance,
        passengers,
        COALESCE(S.volume_shipment,0) AS volume
    FROM
        shipments
    NATURAL LEFT OUTER JOIN (
        SELECT
            shipment_id,
            SUM(A.volume_cargo) AS volume_shipment
        FROM
            shipments
        NATURAL JOIN (
            SELECT
                shipment_id,
                cargo_id,
                ((quantity * volume) + 0.0) AS volume_cargo
            FROM
                cargo
            NATURAL JOIN products) AS A
        GROUP BY
            shipment_id) AS S
    UNION
    SELECT
        S1.shipment_id,
        S1.port_name,
        S1.port_country_name,
        S1.distance,
        S1.passengers,
        ((S1.volume + COALESCE(S2.gain,0)) - COALESCE(S2.lose,0)) AS volume
    FROM (
        SELECT
            E.shipment_id,
            L.port_name,
            L.port_country_name,
            L.traveled_distance AS distance,
            ((E.passengers + L.loaded_passengers) - L.offloaded_passengers) AS passengers,
            E.volume
        FROM
            legs AS L,
            evolution AS E
        WHERE
            E.shipment_id = L.shipment_id
        AND L.traveled_distance > E.distance
        AND L.traveled_distance = (
                SELECT
                    MIN(traveled_distance)
                FROM
                    legs
                WHERE
                    shipment_id = L.shipment_id
                AND traveled_distance > E.distance)) AS S1
        LEFT OUTER JOIN (
            SELECT
                shipment_id,
                port_name,
                port_country_name,
                SUM(bought * volume) AS gain,
                SUM(sold * volume) AS lose
            FROM
                trading
            NATURAL JOIN (
                    SELECT
                        cargo_id,
                        volume
                    FROM
                        cargo
                    NATURAL JOIN products) AS PR
            GROUP BY
                shipment_id,
                port_name,
                port_country_name) AS S2 
        ON S1.port_name = S2.port_name
        AND S1.port_country_name = S2.port_country_name
        AND S1.shipment_id = S2.shipment_id
)
SELECT
    *
FROM
    evolution
UNION
SELECT
    shipment_id,
    port_name_end AS port_name,
    port_country_name_end AS port_country_name,
    distance,
    0 AS passengers,
    0 AS volume
FROM
    shipments
ORDER BY
    shipment_id,
    distance;

-- Requête 14
-- Retourne le nombre d'expéditions effectuées par continent, ainsi que le nombre de
-- navires capturés par un pays d'un continent donné et le nombre de navires capturés
-- précédemment possédés par un pays d'un continent donné.

-- Returns the number of shipments done per continent, alongside the number of
-- ships captured by a country of a given continent and the number of ships captured
-- previously owned by a country of a given continent.

SELECT
    continent,
    SUM(N.done) AS done,
    SUM(N.captured) AS captured,
    SUM(N.being_captured) AS being_captured
FROM
    countries
NATURAL JOIN (
    SELECT
        C.country_name,
        (
            SELECT
                count(*) AS travel 
            FROM (ships_nationalities
                    NATURAL JOIN (
                        SELECT
                            * 
                        FROM ships
                        NATURAL JOIN shipments) AS F) AS S
            WHERE
                start_possesion_date = (
                        SELECT
                            MAX(start_possesion_date)
                        FROM ships_nationalities
                        WHERE
                            ship_id = S.ship_id
                        AND start_possesion_date <= S.start_date)
            AND country_name = C.country_name
                    GROUP BY
                        country_name) AS done, 
        (
            SELECT
                count(*)
            FROM
                shipments AS S,
                ships_nationalities AS S1,
                ships_nationalities AS S2
            WHERE
                S.capture_date IS NOT NULL
            AND S.ship_id = S1.ship_id
            AND S1.ship_id = S2.ship_id
            AND S.capture_date = S1.start_possesion_date
            AND S2.start_possesion_date < S.capture_date
            AND S2.start_possesion_date >= ALL (
                    SELECT
                        S3.start_possesion_date
                    FROM
                        ships_nationalities AS S3
                    WHERE
                        S3.ship_id = S2.ship_id
                    AND S3.start_possesion_date < S.capture_date)
            AND S1.country_name = C.country_name) AS captured, 
        (
            SELECT
                count(*)
            FROM
                shipments AS S,
                ships_nationalities AS S1,
                ships_nationalities AS S2
            WHERE
                S.capture_date IS NOT NULL
            AND S.ship_id = S1.ship_id
            AND S1.ship_id = S2.ship_id
            AND S.capture_date = S1.start_possesion_date
            AND S2.start_possesion_date < S.capture_date
            AND S2.start_possesion_date >= ALL (
                            SELECT
                                S3.start_possesion_date
                            FROM
                                ships_nationalities AS S3
                            WHERE
                                S3.ship_id = S2.ship_id
                            AND S3.start_possesion_date < S.capture_date)
            AND S2.country_name = C.country_name) AS being_captured
    FROM
        countries AS C) AS N
GROUP BY
    continent;

-- Requête 15
-- Retourne le statut de chaque port avec le nombre de passagers qui sont arrivés et repartis
-- ainsi que le nombre de marchandises achetées et vendues.

-- Returns the status of each port with the number of passengers that arrived and left
-- and the number of merchandises bought and sold.

WITH shipment_data (
    shipment_id,
    port_name_start,
    port_country_name_start,
    port_name_end,
    port_country_name_end,
    passengers_start,
    passengers_end,
    volume_start,
    volume_end
) AS (
    SELECT
        shipment_id,
        PAF.port_name_start,
        PAF.port_country_name_start,
        PAF.port_name_end,
        PAF.port_country_name_end,
        PAF.passengers_start,
        PAF.passengers_end,
        COALESCE(VF.volume_start,0) AS volume_start,
        COALESCE(VF.volume_end,0) AS volume_end
    FROM (
        SELECT
            shipment_id,
            port_name_start,
            port_country_name_start,
            port_name_end,
            port_country_name_end,
            passengers AS passengers_start,
            ((passengers + COALESCE(gain,0)) - COALESCE(lose,0)) AS passengers_end
        FROM
            shipments
        NATURAL LEFT OUTER JOIN (
            SELECT
                shipment_id,
                SUM(loaded_passengers) AS gain,
                SUM(offloaded_passengers) AS lose
            FROM
                legs
            GROUP BY
                shipment_id) AS PA) AS PAF
    NATURAL LEFT OUTER JOIN (
        SELECT
            shipment_id,
            S.volume_shipment AS volume_start,
            ((S.volume_shipment + COALESCE(T.gain,0)) - COALESCE(T.lose,0)) AS volume_end
        FROM (
            SELECT
                shipment_id,
                SUM(A.volume_cargo) AS volume_shipment
            FROM
                shipments
            NATURAL JOIN (
                SELECT
                    shipment_id,
                    cargo_id,
                    ((quantity * volume) + 0.0) AS volume_cargo
                FROM
                    cargo
                NATURAL JOIN products) AS A
            GROUP BY
                shipment_id) AS S
        NATURAL LEFT OUTER JOIN (
            SELECT
                shipment_id,
                SUM(bought * volume_cargo) AS gain,
                SUM(sold * volume_cargo) AS lose
            FROM
                trading
            NATURAL JOIN (
                SELECT
                    cargo_id,
                    volume AS volume_cargo
                FROM
                    cargo
                NATURAL JOIN products) AS PR
            GROUP BY
                shipment_id) AS T) AS VF
)
SELECT
    port_name,
    port_country_name,
    SUM(passengers_arrive) AS passengers_arrive,
    SUM(passengers_left) AS passengers_left,
    SUM(volume_receive) AS volume_receive,
    SUM(volume_send) AS volume_send,
    SUM(nb_shipment) AS nb_shipment
FROM (
    SELECT
        port_name_start AS port_name,
        port_country_name_start AS port_country_name,
        0 AS passengers_arrive,
        SUM(passengers_start) AS passengers_left,
        0 AS volume_receive,
        SUM(volume_start) AS volume_send,
        count(*) AS nb_shipment
    FROM
        shipment_data
    GROUP BY
        port_name_start,
        port_country_name_start
    UNION
    SELECT
        port_name_end AS port_name,
        port_country_name_end AS port_country_name,
        SUM(passengers_end) AS passengers_arrive,
        0 AS passengers_left,
        SUM(volume_end) AS volume_receive,
        0 AS volume_send,
        count(*) AS nb_shipment
    FROM
        shipment_data
    GROUP BY
        port_name_end,
        port_country_name_end
    UNION
    SELECT
        port_name,
        port_country_name,
        P.arrive AS passengers_arrive,
        P.left AS passengers_left,
        COALESCE(V.receive,0) AS volume_receive,
        COALESCE(V.send,0) AS volume_send,
        P.nb_shipment
    FROM (
        SELECT
            port_name,
            port_country_name,
            SUM(loaded_passengers) AS left,
            SUM(offloaded_passengers) AS arrive,
            count(*) AS nb_shipment
        FROM
            legs
        GROUP BY
            port_name,
            port_country_name) AS P
    NATURAL LEFT OUTER JOIN (
        SELECT
            port_name,
            port_country_name,
            SUM(bought * volume_cargo) AS send,
            SUM(sold * volume_cargo) AS receive
        FROM
            trading
        NATURAL JOIN (
            SELECT
                cargo_id,
                volume AS volume_cargo
            FROM
                cargo
            NATURAL JOIN products) AS PR
        GROUP BY
            port_name,
            port_country_name) AS V) AS F
GROUP BY
    port_name,
    port_country_name
ORDER BY
    port_country_name;

-- Requête 16
-- Retourne le produit le plus échangé par classe ou par continent.

-- Returns the most trade product per class or continent.

-- Par classe :
-- Per class:
SELECT
    S1.class,
    S1.product_id,
    S1.quantity
FROM (shipments
    NATURAL JOIN (
        SELECT
            shipment_id,
            product_id,
            SUM(sold + bought) AS quantity
        FROM
            trading
        NATURAL JOIN cargo
        GROUP BY
            shipment_id,
            product_id) AS S) AS S1
WHERE
    S1.quantity = (
        SELECT
            MAX(quantity)
        FROM (
            SELECT
                shipment_id,
                product_id,
                SUM(sold + bought) AS quantity
            FROM
                trading
            NATURAL JOIN cargo
            GROUP BY
                shipment_id,
                product_id) AS S2
        NATURAL JOIN shipments
        WHERE
            class = S1.class);

-- Par continent :
-- Per continent:
SELECT
    C.continent,
    S2.product_id,
    S2.quantity
FROM
    countries AS C
NATURAL JOIN (
    SELECT
        S.port_country_name AS country_name,
        S.product_id,
        S.quantity
    FROM (
        SELECT
            port_name,
            port_country_name,
            product_id,
            SUM(sold + bought) AS quantity
        FROM
            trading
        NATURAL JOIN cargo
        GROUP BY
            port_name,
            port_country_name,
            product_id) AS S
    WHERE
        S.quantity = (
            SELECT
                MAX(quantity)
            FROM (
                SELECT
                    port_name,
                    port_country_name,
                    product_id,
                    SUM(sold + bought) AS quantity
                FROM
                    trading
                NATURAL JOIN cargo
                GROUP BY
                    port_name,
                    port_country_name,
                    product_id) AS S1
            WHERE
                S1.port_country_name = S.port_country_name)) AS S2
WHERE
    S2.quantity = (
        SELECT
            MAX(quantity)
        FROM
            countries AS C2
        NATURAL JOIN (
            SELECT
                S3.port_country_name AS country_name, S3.product_id, S3.quantity
            FROM (
                SELECT
                    port_name,
                    port_country_name,
                    product_id,
                    SUM(sold + bought) AS quantity
                FROM
                    trading
                NATURAL JOIN cargo
                GROUP BY
                    port_name,
                    port_country_name,
                    product_id) AS S3
            WHERE
                S3.quantity = (
                    SELECT
                        MAX(quantity)
                    FROM (
                        SELECT
                            port_name,
                            port_country_name,
                            product_id,
                            SUM(sold + bought) AS quantity
                        FROM
                            trading
                        NATURAL JOIN cargo
                        GROUP BY
                            port_name,
                            port_country_name,
                            product_id) AS S4
                    WHERE
                        S4.port_country_name = S3.port_country_name)) AS S5
        WHERE
            C2.continent = C.continent);

-- Requête 17
-- Retourne le total du volume et du nombre de passagers transportés par catégorie de navire.

-- Returns the total of volume and passengers count transported per ship category.

SELECT
    ship_category,
    SUM(D.volume_total) as volume_total,
    SUM(D.passengers_total) as passengers_total
FROM
    ships
NATURAL JOIN (
    SELECT
        ship_id,
        SUM(COALESCE(A.volume_cargo, 0)) AS volume_total,
        SUM(passengers) AS passengers_total
    FROM
        shipments
    NATURAL LEFT OUTER JOIN (
        SELECT
            shipment_id,
            cargo_id,
            ((quantity * volume) + 0.0) AS volume_cargo
        FROM
            cargo
        NATURAL JOIN products) AS A
    GROUP BY
        ship_id) AS D
GROUP BY
    ship_category;

-- Requête 18
-- Retourne le produit le plus vendu et le plus acheté par pays.

-- Returns the most sold and most bought product per country.

SELECT
    F1.country_name,
    F1.product_id,
    F1.bought,
    F2.product_id,
    F2.sold
FROM (
    SELECT
        S.country_name,
        S.product_id,
        S.bought
    FROM (
        SELECT
            port_country_name AS country_name,
            product_id,
            SUM(bought) AS bought
        FROM
            trading
        NATURAL JOIN cargo
        GROUP BY
            port_country_name,
            product_id) AS S
    WHERE
        S.bought = (
            SELECT
                MAX(bought)
            FROM (
                SELECT
                    port_country_name AS country_name,
                    product_id,
                    SUM(bought) AS bought
                FROM
                    trading
                NATURAL JOIN cargo
                GROUP BY
                    port_country_name,
                    product_id) AS S1
            WHERE
                S1.country_name = S.country_name)) AS F1
    JOIN (
        SELECT
            S.country_name,
            S.product_id,
             S.sold
        FROM (
            SELECT
                port_country_name AS country_name,
                product_id,
                SUM(sold) AS sold
            FROM
                trading
            NATURAL JOIN cargo
            GROUP BY
                port_name,
                port_country_name,
                product_id) AS S
        WHERE
            S.sold = (
                    SELECT
                        MAX(sold)
                    FROM (
                        SELECT
                            port_country_name AS country_name,
                            product_id,
                            SUM(sold) AS sold
                        FROM
                            trading
                        NATURAL JOIN cargo
                        GROUP BY
                            port_name,
                            port_country_name,
                            product_id) AS S1
                    WHERE
                        S1.country_name = S.country_name)) AS F2 
    ON F1.country_name = F2.country_name;

-- Requête 19
-- Retourne la date à laquelle la plus grande quantité ou le plus grand volume de marchandises a été échangé (acheté et vendu).

-- Returns the date where the most quantity or volume of merchandises was traded (bought and sold).


-- Par quantité :
-- Per quantity:
SELECT
    arrival_date,
    quantity
FROM (
    SELECT
        arrival_date,
        SUM(sold + bought) AS quantity
    FROM
        trading
    NATURAL JOIN legs
    GROUP BY
        arrival_date) AS F
WHERE
    quantity = (
        SELECT
            MAX(quantity)
        FROM (
            SELECT
                arrival_date,
                SUM(sold + bought) AS quantity
            FROM
                trading
            NATURAL JOIN legs
            GROUP BY
                arrival_date) AS T);

-- Par volume :
-- Per volume:
SELECT
    arrival_date,
    volume
FROM (
    SELECT
        arrival_date,
        SUM(sold + bought) AS volume
    FROM
        legs
    NATURAL JOIN (
        SELECT
            shipment_id,
            port_name,
            port_country_name,
            (bought * volume) AS bought,
            (sold * volume) AS sold
        FROM
            trading
        NATURAL JOIN (
            SELECT
                   cargo_id,
                volume
            FROM
                 cargo
            NATURAL JOIN products) AS V) AS V1
    GROUP BY
        arrival_date) AS F
WHERE
    volume = (
        SELECT
            MAX(volume)
        FROM (
            SELECT
                arrival_date,
                SUM(sold + bought) AS volume
            FROM
                legs
            NATURAL JOIN (
                SELECT
                    shipment_id,
                    port_name,
                    port_country_name,
                    (bought * volume) AS bought,
                    (sold * volume) AS sold
                FROM
                    trading
                NATURAL JOIN (
                    SELECT
                        cargo_id,
                        volume
                    FROM
                        cargo
                    NATURAL JOIN products) AS V2) AS V3
            GROUP BY
                arrival_date) AS T);

-- Requête 20
-- Retourne la quantité de produits vendus par catégorie pour chaque continent.

-- Returns the quantity of product sold per category for each continent.

WITH trade_data (
    continent,
    product_id,
    quantity
) AS (
    SELECT
        C.continent,
        S1.product_id,
        S1.quantity
    FROM
        countries AS C
    NATURAL JOIN (
        SELECT
            S.port_country_name AS country_name,
            S.product_id,
            S.quantity
        FROM (
            SELECT
                port_name,
                port_country_name,
                product_id,
                SUM(sold + bought) AS quantity
            FROM
                trading
            NATURAL JOIN cargo
            GROUP BY
                port_name,
                port_country_name,
                product_id) AS S) AS S1
)
SELECT
    continent,
    SUM(clothes) AS clothes,
    SUM(materials) AS materials,
    SUM(food) AS food,
    SUM(misc) AS misc
FROM (
    SELECT
        continent,
        SUM(quantity) AS clothes,
        0 AS materials,
        0 AS food,
        0 AS misc
    FROM
        trade_data
    NATURAL JOIN clothes
    GROUP BY
        continent
    UNION
    SELECT
        continent,
        0 AS clothes,
        SUM(quantity) AS materials,
        0 AS food,
        0 AS misc
    FROM
        trade_data
    NATURAL JOIN materials
    GROUP BY
        continent
    UNION
    SELECT
        continent,
        0 AS clothes,
        0 AS materials,
        0 AS food,
        SUM(quantity) AS misc
    FROM
        trade_data
    NATURAL JOIN misc
    GROUP BY
        continent
    UNION
    SELECT
        continent,
        0 AS clothes,
        0 AS materials,
        SUM(quantity) AS food,
        0 AS msic
    FROM
        trade_data
    NATURAL JOIN food
    GROUP BY
        continent) AS F
GROUP BY
    continent;

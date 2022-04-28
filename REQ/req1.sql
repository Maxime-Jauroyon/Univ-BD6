-- Liste les voyages où le bateau a été capturé, l'attaquant et la victime (pays) ainsi que leur relation diplomatique

SELECT
      A.shipment_id,
      A.attaquant,
      A.victime,
      TYPE
FROM (
      SELECT
            S.shipment_id,
            S1.country_name AS attaquant,
            S2.country_name AS victime
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
                        AND S3.start_possesion_date < S.capture_date)) AS A
      LEFT OUTER JOIN diplomatic_relationships ON A.attaquant = country_name_1
      AND A.victime = country_name_2;

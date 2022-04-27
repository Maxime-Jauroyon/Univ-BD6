-- Liste les voyages où le bateau a été capturé, l'attaquant et la victime (pays) ainsi que leur relation diplomatique

SELECT A.shipment_id,A.attaquant,A.victime,type
FROM (SELECT S.shipment_id,S1.country_name as attaquant,S2.country_name as victime
      FROM shipments as S,ships_nationalities as S1,ships_nationalities as S2
      WHERE S.capture_date IS NOT NULL
      AND S.ship_id = S1.ship_id
      AND S1.ship_id = S2.ship_id
      AND S.capture_date = S1.start_possesion_date
      AND S2.start_possesion_date < S.capture_date
      AND S2.start_possesion_date >= ALL(SELECT S3.start_possesion_date
                                         FROM ships_nationalities as S3
                                         WHERE S3.ship_id = S2.ship_id
                                         AND S3.start_possesion_date < S.capture_date)) 
as A LEFT OUTER JOIN diplomatic_relationships
ON A.attaquant = country_name_1
AND A.victime = country_name_2;
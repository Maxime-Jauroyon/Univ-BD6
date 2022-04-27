-- Liste les bateaux qui ont fait tous leurs voyages en partant avec le nombre maximum de passagers

SELECT ship_id
FROM (SELECT ship_id,COUNT(shipment_id) as nbFull
      FROM ships NATURAL JOIN shipments
      WHERE passengers_capacity = passengers
      GROUP BY ship_id) as F
NATURAL JOIN (SELECT ship_id,COUNT(shipment_id) as nbTotal
              FROM ships NATURAL JOIN shipments
              GROUP BY ship_id) as T
WHERE F.nbFull = T.nbTotal;
-- Liste les bateaux qui ont fait tous leurs voyages en partant avec le nombre maximum de passagers

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

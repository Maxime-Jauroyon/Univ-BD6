-- l'id du voyage le plus long

SELECT shipment_id 
FROM shipments
WHERE duration = (SELECT MAX(duration)
                  FROM shipments);

SELECT shipment_id 
FROM shipments
WHERE duration >= ALL(SELECT duration
                      FROM shipments);

-- correction de la requete

SELECT shipment_id 
FROM shipments
WHERE duration >= ALL(SELECT COALESCE(duration,0)
                      FROM shipments);
-- Loads initial `.csv` files.
\COPY countries FROM 'CSV/countries.csv' WITH csv;
\COPY diplomatic_relationships FROM 'CSV/diplomatic_relationships.csv'  WITH csv;
\COPY ports FROM 'CSV/ports.csv' WITH csv;
\COPY ships FROM 'CSV/ships.csv' WITH csv;
\COPY ships_nationalities FROM 'CSV/ships_nationalities.csv' WITH csv;
\COPY shipments FROM 'CSV/shipments.csv' WITH csv;
\COPY legs FROM 'CSV/legs.csv' WITH csv;
\COPY products FROM 'CSV/products.csv' WITH csv;
\COPY food FROM 'CSV/food.csv' WITH csv;
\COPY clothes FROM 'CSV/clothes.csv' WITH csv;
\COPY materials FROM 'CSV/materials.csv' WITH csv;
\COPY misc FROM 'CSV/misc.csv' WITH csv;
\COPY cargo FROM 'CSV/cargo.csv' WITH csv;
\COPY trading FROM 'CSV/trading.csv' WITH csv;

-- Updates necessary tables to fulfill the constraint requirements.
\i 'load_updates.sql';

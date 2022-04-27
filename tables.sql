drop table if exists material cascade;
drop table if exists clothes cascade;
drop table if exists food cascade;
drop table if exists trading cascade;
drop table if exists cargo cascade;
drop table if exists products cascade;
drop table if exists legs cascade;
drop table if exists shipments cascade;
drop table if exists ships_nationalities cascade;
drop table if exists ships cascade;
drop table if exists ports cascade;
drop table if exists diplomatic_relationships cascade;
drop table if exists countries cascade;


create table countries (
    country_name text primary key,
    continent text not null);

create table diplomatic_relationships (
    country_name_1 text,
    country_name_2 text,
    type text not null,
    primary key (country_name_1,country_name_2),
    foreign key (country_name_1) references countries(country_name),
    foreign key (country_name_1) references countries(country_name));

create table ports (
    port_name text,
    port_country_name text,
    latitude float not null,
    longitude float not null,
    category integer not null,
    primary key (port_name,port_country_name),
    foreign key (port_country_name) references countries(country_name));
 
create table ships (
    ship_id integer primary key,
    type text not null,
    category integer not null,
    tonnage_capacity integer not null,
    passengers_capacity integer not null);   

create table ships_nationalities (
    ship_id integer,
    country_name text,
    start_possesion_date date,
    primary key (ship_id,country_name,start_possesion_date),
    foreign key (country_name) references countries(country_name),
    foreign key (ship_id) references ships(ship_id));

create table shipments (
    shipment_id integer primary key,
    ship_id integer,
    port_name_start text,
    port_name_end text,
    port_country_name_start text,
    port_country_name_end text,
    start_date date not null,
    end_date date,
    duration integer,
    passengers integer not null,
    type_shipment text not null,
    class text not null,
    capture_date date,
    distance integer not null,
    foreign key (port_name_start,port_country_name_start) references ports(port_name,port_country_name),
    foreign key (port_name_end,port_country_name_end) references ports(port_name,port_country_name),
    foreign key (ship_id) references ships(ship_id));

create table legs (
    shipment_id integer,
    port_name text,
    port_country_name text,
    offloaded_passengers integer not null,
    loaded_passengers integer not null,
    traveled_distance integer not null,
    primary key (shipment_id,port_name,port_country_name),
    foreign key (port_name,port_country_name) references ports(port_name,port_country_name),
    foreign key (shipment_id) references shipments(shipment_id));

create table products (
    product_id integer primary key,
    name text not null,
    volume integer not null,
    perishable boolean not null);

create table cargo (
    cargo_id integer primary key,
    shipment_id integer,
    product_id integer,
    quantity integer not null,
    foreign key (shipment_id) references shipments(shipment_id),
    foreign key (product_id) references products(product_id));

create table trading (
    cargo_id integer,
    shipment_id integer,
    port_name text,
    port_country_name text,
    sold integer not null,
    bought integer not null,
    primary key (cargo_id,shipment_id,port_name,port_country_name),
    foreign key (shipment_id) references shipments(shipment_id),
    foreign key (port_name,port_country_name) references ports(port_name,port_country_name),
    foreign key (cargo_id) references cargo(cargo_id));

create table food (
    product_id integer primary key,
    shelf_life integer not null,
    price_per_kg integer not null,
    foreign key (product_id) references products(product_id));

create table clothes (
    product_id integer primary key,
    material text not null,
    unit_price integer not null,
    unit_weight float not null,
    foreign key (product_id) references products(product_id));

create table material (
    product_id integer primary key,
    volume_price integer not null,
    foreign key (product_id) references products(product_id));




-- remplissage des tables

\COPY countries FROM 'CSV/countries.csv' WITH csv;
\COPY diplomatic_relationships FROM 'CSV/diplomatic_relationships.csv'  WITH csv;
\COPY ports FROM 'CSV/ports.csv' WITH csv;
\COPY ships FROM 'CSV/ships.csv' WITH csv;
\COPY ships_nationalities FROM 'CSV/ships_nationalities.csv' WITH csv;
\COPY shipments FROM 'CSV/shipments.csv' WITH csv;
\COPY legs FROM 'CSV/legs.csv' WITH csv;
\COPY products FROM 'CSV/products.csv' WITH csv;
\COPY cargo FROM 'CSV/cargo.csv' WITH csv;
\COPY trading FROM 'CSV/trading.csv' WITH csv;
\COPY food FROM 'CSV/food.csv' WITH csv;
\COPY clothes FROM 'CSV/clothes.csv' WITH csv;
\COPY material FROM 'CSV/material.csv' WITH csv;
# BD6

This project is the modeling, settlement, and implementation of a database based on the maritime trade in the 18th century.

## Architecture

Tree of the files and folder in the project's hierarchy:

```
/
├─CON/: Deprecated files used to create constraints with CHECK (now replaced by TRIGGER).
├─CSV/: The CSV data files.
├─Models/: The model used to implement this database (represented in different ways).
├─REQ/: A list of 20 requests.
├─bd6.sql: The main file of the database implementation.
├─load_from_csv.sql: The main file of the database settlement (using CSV files).
├─load_from_sql.sql: The main file of the database settlement (in plain SQL).
├─load_updates.sql: A file called after loading every values to check the constraints.
└─README.md: This file.
```

## Installation

- Open a terminal in the project's root directory.
- Connect to PostgreSQL with the desired user.
- Connect to (or create) an empty database with UTF-8 encoding.
- Run `\i bd6.sql`.

The database should now be populated with tables and data.

## Contributors

### Groupe 5

- JAUROYON Maxime (21954099)
- KINDEL Hugo (21952778)

## License

This project is made for educational purposes only and any part of it can be used freely.

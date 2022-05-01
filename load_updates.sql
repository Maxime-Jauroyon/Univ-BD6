-- Updates necessary tables to fulfill the constraint requirements.
UPDATE products SET categorized = TRUE;
UPDATE shipments SET departed = TRUE;

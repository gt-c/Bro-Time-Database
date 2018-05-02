-- All columns.
CREATE VIEW test.columns AS
SELECT table_schema, table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'discord';
-- All columns without implicit range limits.
CREATE VIEW test.columns_unlimited AS
SELECT table_schema, table_name, column_name
FROM information_schema.columns
WHERE table_schema = 'discord' AND data_type IN ('text', 'ARRAY', 'json', 'jsonb', 'xml');

UPDATE test.tests
SET total = total + COUNT(*)
FROM test.columns, test.columns_unlimited

CREATE FUNCTION test.columns() RETURNS setof text AS $$
DECLARE
	v_column record;
	v_all cursor FOR SELECT table_schema, table_name, column_name
		FROM test.columns;
	v_unlimited cursor FOR SELECT table_schema, table_name, column_name
		FROM test.columns_unlimited;
BEGIN   
	OPEN v_all;
	LOOP
		FETCH v_all INTO v_column;
		EXIT WHEN NOT FOUND;

		RETURN NEXT matches(v_column.column_name, '^(?:[a-z]+_?)+[a-z]+$', 'Column name contains alphabetic words separated by underscores.');
	END LOOP;
	CLOSE v_all;
	OPEN v_unlimited;
	LOOP
		FETCH v_unlimited INTO v_column;
		EXIT WHEN NOT FOUND;

		RETURN NEXT col_has_check(v_column.table_schema, v_column.table_name, v_column.column_name, 'Columns that are not implicitly limited on range must be explicitly limited.');
	END LOOP;
	CLOSE v_unlimited;
END;
$$ LANGUAGE plpgsql;

/*
    SessionFinancialBankDB - READ-ONLY schema audit
    Purpose: inspect existing database objects before Fraud integration.
    This script does NOT create, alter, delete, truncate, or insert anything.
*/
SET NOCOUNT ON;

IF DB_ID(N'SessionFinancialBankDB') IS NULL
BEGIN
    SELECT
        N'DATABASE_NOT_FOUND' AS audit_status,
        N'SessionFinancialBankDB does not exist on the connected SQL Server instance.' AS details;
    RETURN;
END;

USE [SessionFinancialBankDB];

SELECT
    N'DATABASE' AS section_name,
    DB_NAME() AS database_name,
    compatibility_level,
    collation_name,
    state_desc
FROM sys.databases
WHERE name = DB_NAME();

/* 1) Existing tables and approximate row counts */
SELECT
    N'TABLES' AS section_name,
    s.name AS schema_name,
    t.name AS table_name,
    SUM(CASE WHEN p.index_id IN (0, 1) THEN p.rows ELSE 0 END) AS approximate_row_count
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
LEFT JOIN sys.partitions AS p
    ON p.object_id = t.object_id
GROUP BY s.name, t.name
ORDER BY s.name, t.name;

/* 2) Existing views */
SELECT
    N'VIEWS' AS section_name,
    s.name AS schema_name,
    v.name AS view_name
FROM sys.views AS v
INNER JOIN sys.schemas AS s
    ON s.schema_id = v.schema_id
ORDER BY s.name, v.name;

/* 3) Columns, data types, nullability, identity and defaults */
SELECT
    N'COLUMNS' AS section_name,
    s.name AS schema_name,
    o.name AS object_name,
    o.type_desc AS object_type,
    c.column_id,
    c.name AS column_name,
    ty.name AS data_type,
    CASE
        WHEN ty.name IN (N'nvarchar', N'nchar') AND c.max_length <> -1
            THEN c.max_length / 2
        WHEN ty.name IN (N'varchar', N'char', N'varbinary', N'binary')
            THEN c.max_length
        ELSE c.max_length
    END AS declared_length_bytes_or_characters,
    c.precision,
    c.scale,
    c.is_nullable,
    c.is_identity,
    dc.definition AS default_definition,
    cc.definition AS computed_definition
FROM sys.objects AS o
INNER JOIN sys.schemas AS s
    ON s.schema_id = o.schema_id
INNER JOIN sys.columns AS c
    ON c.object_id = o.object_id
INNER JOIN sys.types AS ty
    ON ty.user_type_id = c.user_type_id
LEFT JOIN sys.default_constraints AS dc
    ON dc.object_id = c.default_object_id
LEFT JOIN sys.computed_columns AS cc
    ON cc.object_id = c.object_id
   AND cc.column_id = c.column_id
WHERE o.type IN ('U', 'V')
ORDER BY s.name, o.name, c.column_id;

/* 4) Primary keys and unique constraints */
SELECT
    N'KEYS' AS section_name,
    s.name AS schema_name,
    t.name AS table_name,
    kc.name AS constraint_name,
    kc.type_desc AS constraint_type,
    i.name AS index_name,
    STRING_AGG(QUOTENAME(c.name), N', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns
FROM sys.key_constraints AS kc
INNER JOIN sys.tables AS t
    ON t.object_id = kc.parent_object_id
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
INNER JOIN sys.indexes AS i
    ON i.object_id = kc.parent_object_id
   AND i.index_id = kc.unique_index_id
INNER JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id
   AND ic.index_id = i.index_id
INNER JOIN sys.columns AS c
    ON c.object_id = ic.object_id
   AND c.column_id = ic.column_id
WHERE ic.key_ordinal > 0
GROUP BY s.name, t.name, kc.name, kc.type_desc, i.name
ORDER BY s.name, t.name, kc.name;

/* 5) Foreign-key relationships */
SELECT
    N'FOREIGN_KEYS' AS section_name,
    fk.name AS foreign_key_name,
    ps.name AS parent_schema,
    pt.name AS parent_table,
    pc.name AS parent_column,
    rs.name AS referenced_schema,
    rt.name AS referenced_table,
    rc.name AS referenced_column,
    fk.delete_referential_action_desc,
    fk.update_referential_action_desc,
    fk.is_disabled,
    fk.is_not_trusted
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc
    ON fkc.constraint_object_id = fk.object_id
INNER JOIN sys.tables AS pt
    ON pt.object_id = fkc.parent_object_id
INNER JOIN sys.schemas AS ps
    ON ps.schema_id = pt.schema_id
INNER JOIN sys.columns AS pc
    ON pc.object_id = pt.object_id
   AND pc.column_id = fkc.parent_column_id
INNER JOIN sys.tables AS rt
    ON rt.object_id = fkc.referenced_object_id
INNER JOIN sys.schemas AS rs
    ON rs.schema_id = rt.schema_id
INNER JOIN sys.columns AS rc
    ON rc.object_id = rt.object_id
   AND rc.column_id = fkc.referenced_column_id
ORDER BY ps.name, pt.name, fk.name, fkc.constraint_column_id;

/* 6) Index inventory */
SELECT
    N'INDEXES' AS section_name,
    s.name AS schema_name,
    t.name AS table_name,
    i.name AS index_name,
    i.type_desc AS index_type,
    i.is_primary_key,
    i.is_unique,
    i.is_disabled,
    STRING_AGG(
        CASE WHEN ic.is_included_column = 0 THEN QUOTENAME(c.name) END,
        N', '
    ) WITHIN GROUP (ORDER BY ic.key_ordinal) AS key_columns,
    STRING_AGG(
        CASE WHEN ic.is_included_column = 1 THEN QUOTENAME(c.name) END,
        N', '
    ) WITHIN GROUP (ORDER BY c.column_id) AS included_columns
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON s.schema_id = t.schema_id
INNER JOIN sys.indexes AS i
    ON i.object_id = t.object_id
LEFT JOIN sys.index_columns AS ic
    ON ic.object_id = i.object_id
   AND ic.index_id = i.index_id
LEFT JOIN sys.columns AS c
    ON c.object_id = ic.object_id
   AND c.column_id = ic.column_id
WHERE i.index_id > 0
  AND i.is_hypothetical = 0
GROUP BY s.name, t.name, i.name, i.type_desc,
         i.is_primary_key, i.is_unique, i.is_disabled
ORDER BY s.name, t.name, i.name;

SELECT
    N'AUDIT_COMPLETED' AS audit_status,
    N'Read-only metadata inspection completed. No database objects or rows were changed.' AS details;

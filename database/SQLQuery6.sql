/*
SessionFinancialBankDB - READ ONLY SCHEMA AUDIT
IMPORTANT: In SSMS, select SessionFinancialBankDB in the database dropdown before pressing F5.
This script reads metadata only. It does not create, alter, insert, update, delete, or truncate data.
Compatible with common SQL Server versions; avoids STRING_AGG.
*/
SET NOCOUNT ON;

IF DB_NAME() <> N'SessionFinancialBankDB'
BEGIN
    SELECT
        N'WRONG_DATABASE_CONTEXT' AS audit_status,
        DB_NAME() AS current_database,
        N'Select SessionFinancialBankDB in the SSMS database dropdown, then run this script again.' AS instruction;
    RETURN;
END;

/* 1. Database information */
SELECT
    N'DATABASE' AS section_name,
    d.name AS database_name,
    d.compatibility_level,
    d.collation_name,
    d.state_desc
FROM sys.databases AS d
WHERE d.database_id = DB_ID();

/* 2. User tables and approximate row counts */
SELECT
    N'TABLES' AS section_name,
    sch.name AS schema_name,
    tbl.name AS table_name,
    COALESCE(SUM(CASE WHEN part.index_id IN (0, 1) THEN part.rows ELSE 0 END), 0) AS approximate_row_count
FROM sys.tables AS tbl
INNER JOIN sys.schemas AS sch ON sch.schema_id = tbl.schema_id
LEFT JOIN sys.partitions AS part ON part.object_id = tbl.object_id
GROUP BY sch.name, tbl.name
ORDER BY sch.name, tbl.name;

/* 3. Views */
SELECT
    N'VIEWS' AS section_name,
    sch.name AS schema_name,
    vw.name AS view_name
FROM sys.views AS vw
INNER JOIN sys.schemas AS sch ON sch.schema_id = vw.schema_id
ORDER BY sch.name, vw.name;

/* 4. Columns for tables and views */
SELECT
    N'COLUMNS' AS section_name,
    sch.name AS schema_name,
    obj.name AS object_name,
    obj.type_desc AS object_type,
    col.column_id,
    col.name AS column_name,
    typ.name AS data_type,
    col.max_length,
    col.precision,
    col.scale,
    col.is_nullable,
    col.is_identity,
    defc.definition AS default_definition,
    comp.definition AS computed_definition
FROM sys.objects AS obj
INNER JOIN sys.schemas AS sch ON sch.schema_id = obj.schema_id
INNER JOIN sys.columns AS col ON col.object_id = obj.object_id
INNER JOIN sys.types AS typ ON typ.user_type_id = col.user_type_id
LEFT JOIN sys.default_constraints AS defc ON defc.object_id = col.default_object_id
LEFT JOIN sys.computed_columns AS comp
    ON comp.object_id = col.object_id AND comp.column_id = col.column_id
WHERE obj.type IN ('U', 'V')
ORDER BY sch.name, obj.name, col.column_id;

/* 5. Primary keys and unique constraints */
SELECT
    N'KEYS' AS section_name,
    sch.name AS schema_name,
    tbl.name AS table_name,
    kc.name AS constraint_name,
    kc.type_desc AS constraint_type,
    idx.name AS index_name,
    STUFF((
        SELECT N', ' + QUOTENAME(col2.name)
        FROM sys.index_columns AS ic2
        INNER JOIN sys.columns AS col2
            ON col2.object_id = ic2.object_id AND col2.column_id = ic2.column_id
        WHERE ic2.object_id = idx.object_id
          AND ic2.index_id = idx.index_id
          AND ic2.key_ordinal > 0
        ORDER BY ic2.key_ordinal
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 2, N'') AS key_columns
FROM sys.key_constraints AS kc
INNER JOIN sys.tables AS tbl ON tbl.object_id = kc.parent_object_id
INNER JOIN sys.schemas AS sch ON sch.schema_id = tbl.schema_id
INNER JOIN sys.indexes AS idx
    ON idx.object_id = kc.parent_object_id AND idx.index_id = kc.unique_index_id
ORDER BY sch.name, tbl.name, kc.name;

/* 6. Foreign-key relationships */
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
INNER JOIN sys.foreign_key_columns AS fkc ON fkc.constraint_object_id = fk.object_id
INNER JOIN sys.tables AS pt ON pt.object_id = fkc.parent_object_id
INNER JOIN sys.schemas AS ps ON ps.schema_id = pt.schema_id
INNER JOIN sys.columns AS pc
    ON pc.object_id = pt.object_id AND pc.column_id = fkc.parent_column_id
INNER JOIN sys.tables AS rt ON rt.object_id = fkc.referenced_object_id
INNER JOIN sys.schemas AS rs ON rs.schema_id = rt.schema_id
INNER JOIN sys.columns AS rc
    ON rc.object_id = rt.object_id AND rc.column_id = fkc.referenced_column_id
ORDER BY ps.name, pt.name, fk.name, fkc.constraint_column_id;

/* 7. Index inventory */
SELECT
    N'INDEXES' AS section_name,
    sch.name AS schema_name,
    tbl.name AS table_name,
    idx.name AS index_name,
    idx.type_desc AS index_type,
    idx.is_primary_key,
    idx.is_unique,
    idx.is_disabled,
    STUFF((
        SELECT N', ' + QUOTENAME(col2.name)
        FROM sys.index_columns AS ic2
        INNER JOIN sys.columns AS col2
            ON col2.object_id = ic2.object_id AND col2.column_id = ic2.column_id
        WHERE ic2.object_id = idx.object_id
          AND ic2.index_id = idx.index_id
          AND ic2.is_included_column = 0
          AND ic2.key_ordinal > 0
        ORDER BY ic2.key_ordinal
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 2, N'') AS key_columns,
    STUFF((
        SELECT N', ' + QUOTENAME(col3.name)
        FROM sys.index_columns AS ic3
        INNER JOIN sys.columns AS col3
            ON col3.object_id = ic3.object_id AND col3.column_id = ic3.column_id
        WHERE ic3.object_id = idx.object_id
          AND ic3.index_id = idx.index_id
          AND ic3.is_included_column = 1
        ORDER BY col3.column_id
        FOR XML PATH(''), TYPE
    ).value('.', 'nvarchar(max)'), 1, 2, N'') AS included_columns
FROM sys.tables AS tbl
INNER JOIN sys.schemas AS sch ON sch.schema_id = tbl.schema_id
INNER JOIN sys.indexes AS idx ON idx.object_id = tbl.object_id
WHERE idx.index_id > 0
  AND idx.is_hypothetical = 0
ORDER BY sch.name, tbl.name, idx.name;

SELECT
    N'AUDIT_COMPLETED' AS audit_status,
    N'Read-only metadata inspection completed. No database objects or rows were changed.' AS details;

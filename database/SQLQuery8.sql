USE [SessionFinancialBankDB];
GO

SELECT
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fkc.parent_object_id) AS ParentTable,
    pc.name AS ParentColumn,
    OBJECT_NAME(fkc.referenced_object_id) AS ReferencedTable,
    rc.name AS ReferencedColumn,
    fk.delete_referential_action_desc AS OnDelete,
    fk.is_disabled AS IsDisabled,
    fk.is_not_trusted AS IsNotTrusted
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc
    ON fk.object_id = fkc.constraint_object_id
INNER JOIN sys.columns AS pc
    ON pc.object_id = fkc.parent_object_id
    AND pc.column_id = fkc.parent_column_id
INNER JOIN sys.columns AS rc
    ON rc.object_id = fkc.referenced_object_id
    AND rc.column_id = fkc.referenced_column_id
ORDER BY
    ParentTable,
    ForeignKeyName;
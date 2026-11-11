
USE [SessionFinancialBankDB];
GO

DECLARE @Payload NVARCHAR(MAX);

SELECT TOP (1)
    @Payload = SourcePayloadJson
FROM dbo.BankTransactions
WHERE SourceSystem = 'PAYSIM'
  AND DatasetSplit = 'VALIDATION'
  AND ISJSON(SourcePayloadJson) = 1
ORDER BY TransactionID;

SELECT
    [key] AS JsonProperty,
    CASE [type]
        WHEN 0 THEN 'NULL'
        WHEN 1 THEN 'STRING'
        WHEN 2 THEN 'NUMBER'
        WHEN 3 THEN 'BOOLEAN'
        WHEN 4 THEN 'ARRAY'
        WHEN 5 THEN 'OBJECT'
        ELSE 'UNKNOWN'
    END AS JsonDataType
FROM OPENJSON(@Payload)
ORDER BY [key];
GO

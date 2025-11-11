-- SQL Validation Queries for Products Domain Schema
-- Database: TEKA (SQL Server)
-- Purpose: Fill gaps in C# DataObjects.NET schema analysis
-- Run these queries on the old SQL Server and paste results in next chat

-- ============================================================
-- QUERY 1: Complete Products Table Schema
-- ============================================================
-- Purpose: Get exact column definitions including computed columns, default values
SELECT 
    c.COLUMN_NAME,
    c.DATA_TYPE,
    c.CHARACTER_MAXIMUM_LENGTH,
    c.NUMERIC_PRECISION,
    c.NUMERIC_SCALE,
    c.IS_NULLABLE,
    c.COLUMN_DEFAULT,
    CASE 
        WHEN pk.COLUMN_NAME IS NOT NULL THEN 'PRIMARY KEY'
        ELSE ''
    END AS [Key_Type]
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN (
    SELECT ku.COLUMN_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE ku 
        ON tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
    WHERE tc.TABLE_NAME = 'Products' 
        AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
) pk ON c.COLUMN_NAME = pk.COLUMN_NAME
WHERE c.TABLE_NAME = 'Products'
ORDER BY c.ORDINAL_POSITION;

-- ============================================================
-- QUERY 2: Products Table Indexes
-- ============================================================
-- Purpose: Get all indexes including complex ones we couldn't determine from C#
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS IndexColumns
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('Products')
GROUP BY i.name, i.type_desc, i.is_unique, i.is_primary_key
ORDER BY i.is_primary_key DESC, i.name;

-- ============================================================
-- QUERY 3: Products Foreign Keys
-- ============================================================
-- Purpose: Get FK relationships with cascade rules
SELECT 
    fk.name AS ForeignKeyName,
    OBJECT_NAME(fk.parent_object_id) AS TableName,
    c1.name AS ColumnName,
    OBJECT_NAME(fk.referenced_object_id) AS ReferencedTable,
    c2.name AS ReferencedColumn,
    fk.delete_referential_action_desc AS OnDelete,
    fk.update_referential_action_desc AS OnUpdate
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
JOIN sys.columns c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id
WHERE fk.parent_object_id = OBJECT_ID('Products')
ORDER BY fk.name;

-- ============================================================
-- QUERY 4: ProductPrices Table Structure (if exists)
-- ============================================================
-- Purpose: Determine if ProductPrices is a separate table or inline storage
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ProductPrices')
BEGIN
    SELECT 'ProductPrices table EXISTS' AS Result;
    
    SELECT 
        COLUMN_NAME,
        DATA_TYPE,
        CHARACTER_MAXIMUM_LENGTH,
        NUMERIC_PRECISION,
        NUMERIC_SCALE,
        IS_NULLABLE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'ProductPrices'
    ORDER BY ORDINAL_POSITION;
END
ELSE
BEGIN
    SELECT 'ProductPrices table DOES NOT EXIST - prices likely stored inline in Products table' AS Result;
    
    -- Check for price-related columns in Products table
    SELECT COLUMN_NAME, DATA_TYPE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'Products' 
        AND COLUMN_NAME LIKE '%Price%'
    ORDER BY ORDINAL_POSITION;
END

-- ============================================================
-- QUERY 5: Categories, MeasureUnits, ProductPriceTypes Tables
-- ============================================================
-- Purpose: Quick validation of related tables structure
SELECT 'Categories' AS TableName, COUNT(*) AS ColumnCount
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Categories'
UNION ALL
SELECT 'MeasureUnits', COUNT(*) 
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'MeasureUnits'
UNION ALL
SELECT 'ProductPriceTypes', COUNT(*) 
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'ProductPriceTypes'
UNION ALL
SELECT 'Stores', COUNT(*) 
FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'Stores';

-- ============================================================
-- QUERY 6: Stores Table Complex Indexes
-- ============================================================
-- Purpose: Understand indexes on Items, LogItems, InitiationItems collections
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    STRING_AGG(c.name, ', ') WITHIN GROUP (ORDER BY ic.key_ordinal) AS IndexColumns
FROM sys.indexes i
JOIN sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('Stores')
    AND i.name IS NOT NULL
GROUP BY i.name, i.type_desc, i.is_unique
ORDER BY i.name;

-- ============================================================
-- QUERY 7: Child Collection Tables
-- ============================================================
-- Purpose: Identify tables for StoreItems, StoreLogItems, etc.
SELECT 
    TABLE_NAME,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS c WHERE c.TABLE_NAME = t.TABLE_NAME) AS ColumnCount
FROM INFORMATION_SCHEMA.TABLES t
WHERE TABLE_NAME IN (
    'StoreItems',
    'StoreLogItems', 
    'StoreRequestItems',
    'StoreInitiationItems',
    'StoreInitiationLogItems',
    'ProductPrimeCostItems'
)
ORDER BY TABLE_NAME;

-- ============================================================
-- QUERY 8: Sample Data Statistics
-- ============================================================
-- Purpose: Get row counts and data samples for context
SELECT 
    'Products' AS TableName, 
    COUNT(*) AS RowCount,
    COUNT(DISTINCT CategoryID) AS UniqueCategories,
    COUNT(DISTINCT SupplierID) AS UniqueSuppliers
FROM Products
UNION ALL
SELECT 'Categories', COUNT(*), NULL, NULL FROM Categories
UNION ALL
SELECT 'Stores', COUNT(*), NULL, NULL FROM Stores
UNION ALL
SELECT 'MeasureUnits', COUNT(*), NULL, NULL FROM MeasureUnits
UNION ALL
SELECT 'ProductPriceTypes', COUNT(*), NULL, NULL FROM ProductPriceTypes;

-- ============================================================
-- QUERY 9: Check for Triggers
-- ============================================================
-- Purpose: Identify any triggers on Products/Categories/Stores
SELECT 
    t.name AS TriggerName,
    OBJECT_NAME(t.parent_id) AS TableName,
    t.type_desc AS TriggerType,
    OBJECTPROPERTY(t.object_id, 'ExecIsTriggerDisabled') AS IsDisabled
FROM sys.triggers t
WHERE OBJECT_NAME(t.parent_id) IN ('Products', 'Categories', 'Stores', 'MeasureUnits', 'ProductPriceTypes')
ORDER BY TableName, TriggerName;

-- ============================================================
-- QUERY 10: Value Type Storage Pattern
-- ============================================================
-- Purpose: Determine DataObjects.NET storage pattern for Prices
-- Check if there are columns like Prices$0$Product, Prices$0$Price, etc.
SELECT COLUMN_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'Products'
    AND COLUMN_NAME LIKE 'Prices$%'
ORDER BY COLUMN_NAME;

-- If no Prices$ columns, check for separate ProductPrices table with Owner column
IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'ProductPrices')
BEGIN
    SELECT TOP 5 *
    FROM ProductPrices
    ORDER BY ProductID;
END

-- ============================================================
-- INSTRUCTIONS FOR NEXT CHAT
-- ============================================================
-- 1. Run all queries above in SQL Server Management Studio
-- 2. Export results to Excel or text files
-- 3. In next chat, provide:
--    - Query results (can be pasted as text or screenshots)
--    - Any error messages
-- 4. I will use results to:
--    - Complete schema-draft.json (fix all "sql_validation_needed" items)
--    - Generate accurate PostgreSQL DDL scripts
--    - Create final core-tables-schema.json at 100% accuracy

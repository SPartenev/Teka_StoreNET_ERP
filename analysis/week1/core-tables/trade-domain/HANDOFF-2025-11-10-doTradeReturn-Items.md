# HANDOFF INSTRUCTIONS - doTradeReturn-Items Analysis

**Date:** 2025-11-10  
**Current Progress:** 8/14 tables (57%) ✅  
**Last Completed:** doTradeReturn  
**Next Task:** doTradeReturn-Items (Table #9)  
**Analyst:** Светльо + Claude

---

## 📍 WHERE WE ARE

### Completed Tables (8/14):
1. ✅ doTrade - 365K records
2. ✅ doTradeItem - 1M records
3. ✅ doTradeTransaction - 765K events
4. ✅ doTradePayment - 366K payments
5. ✅ doTradePayment-Items - 1.4K partial payments
6. ✅ doTradeDelivery - 32K deliveries
7. ✅ doTradeDelivery-Items - 93K items
8. ✅ **doTradeReturn - 1,059 returns** ← JUST COMPLETED!

### Ready to Analyze (Next):
9. 🔄 **doTradeReturn-Items** ← START HERE

### Remaining (5 tables):
10. doTradeCancel
11. doTradeCancel-Items
12. doTransaction
13. doTransactionInfo
14. doSystemTransaction

---

## 🎯 NEXT TASK: doTradeReturn-Items

### What We Know:
- **Total items:** ~2,242 (from earlier query)
- **Unique returns:** 1,059 (all have items)
- **Expected columns:** 8 (like Delivery-Items, Payment-Items)
- **Expected pattern:** Similar to doTradeDelivery-Items

### What to Check:
1. **Schema:** Get exact columns and data types
2. **ReturnedQuantity field:** Does it exist? (UNLIKELY based on header)
3. **Return reason:** Any reason/rejection code fields?
4. **Header-item integrity:** Does sum(items) = header.TotalAmount?
5. **Orphaned items:** Any items without valid return header?
6. **Items per return:** Distribution (expected: similar to delivery 70% single-item)

### Critical Questions:
- ❓ Does table track WHICH items were actually returned (vs planned)?
- ❓ Any reason codes for returns/rejections?
- ❓ Same perfect integrity as Delivery-Items?

---

## 📂 FILE LOCATIONS

### Analysis Files:
```
C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\
├── 01-doTrade-analysis.md ✅
├── 02-doTradeItem-analysis.md ✅
├── 03-doTradeTransaction-analysis.md ✅
├── 04-doTradePayment-analysis.md ✅
├── 05-doTradePayment-Items-analysis.md ✅
├── 06-doTradeDelivery-analysis.md ✅
├── 07-doTradeDelivery-Items-analysis.md ✅
├── 08-doTradeReturn-analysis.md ✅ ← JUST COMPLETED
├── 09-doTradeReturn-Items-analysis.md 🔄 ← CREATE THIS
└── trade-domain-progress.md ✅ (updated to 57%)
```

### Progress Tracker:
```
C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\trade-domain-progress.md
```

---

## 🔄 STEP-BY-STEP WORKFLOW

### Step 1: Initiate Session
**User says:** "Продължавам анализа на Teka_StoreNET_ERP Trade Domain. Прочети trade-domain-progress.md и започни анализ на doTradeReturn-Items."

**Claude responds:**
- Reads progress tracker
- Confirms 8/14 completed (57%)
- Starts with schema query for doTradeReturn-Items

### Step 2: Schema Analysis
**SQL Query #1:**
```sql
-- Get table schema
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
        WHEN fk.COLUMN_NAME IS NOT NULL THEN 'FOREIGN KEY → ' + fk.REFERENCED_TABLE + '.' + fk.REFERENCED_COLUMN
        ELSE ''
    END AS KEY_TYPE
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN (
    SELECT ku.COLUMN_NAME
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE ku 
        ON tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
    WHERE tc.TABLE_NAME = 'doTradeReturn-Items' 
        AND tc.CONSTRAINT_TYPE = 'PRIMARY KEY'
) pk ON c.COLUMN_NAME = pk.COLUMN_NAME
LEFT JOIN (
    SELECT 
        ku.COLUMN_NAME,
        cu.TABLE_NAME AS REFERENCED_TABLE,
        cu.COLUMN_NAME AS REFERENCED_COLUMN
    FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc
    JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE ku 
        ON tc.CONSTRAINT_NAME = ku.CONSTRAINT_NAME
    LEFT JOIN INFORMATION_SCHEMA.REFERENTIAL_CONSTRAINTS rc 
        ON tc.CONSTRAINT_NAME = rc.CONSTRAINT_NAME
    LEFT JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE cu 
        ON rc.UNIQUE_CONSTRAINT_NAME = cu.CONSTRAINT_NAME
    WHERE tc.TABLE_NAME = 'doTradeReturn-Items' 
        AND tc.CONSTRAINT_TYPE = 'FOREIGN KEY'
) fk ON c.COLUMN_NAME = fk.COLUMN_NAME
WHERE c.TABLE_NAME = 'doTradeReturn-Items'
ORDER BY c.ORDINAL_POSITION;
```

**Expected columns (based on Delivery-Items):**
- ID (bigint, PK)
- Owner (bigint, FK to doTradeReturn)
- Item (bigint, FK to doTradeItem)
- Quantity (decimal 28,10)
- Price (decimal 28,10)
- TotalPrice (decimal 28,10)
- TaxAmount (decimal 28,10)
- TotalTaxAmount (decimal 28,10)

**Check for additional fields:**
- ReturnedQuantity? (unlikely)
- ReturnReason? (would be nice!)
- RejectionReason?

### Step 3: Indexes Analysis
**SQL Query #2:**
```sql
-- Get indexes
SELECT 
    i.name AS IndexName,
    i.type_desc AS IndexType,
    i.is_unique AS IsUnique,
    i.is_primary_key AS IsPrimaryKey,
    COL_NAME(ic.object_id, ic.column_id) AS ColumnName,
    ic.key_ordinal AS KeyOrder,
    ic.is_included_column AS IsIncluded
FROM sys.indexes i
INNER JOIN sys.index_columns ic 
    ON i.object_id = ic.object_id 
    AND i.index_id = ic.index_id
WHERE i.object_id = OBJECT_ID('doTradeReturn-Items')
    AND i.type > 0
ORDER BY i.name, ic.key_ordinal;
```

**Expected indexes:**
- PK_doTradeReturn-Items (ID) - Clustered
- IX_0 (Owner, Item) - UNIQUE (prevent duplicate items in same return)
- IX_1 (Owner) - Nonclustered
- IX_Owner (Owner, ID) - UNIQUE

### Step 4: Basic Statistics
**SQL Query #3:**
```sql
-- Basic statistics
SELECT 
    COUNT(*) AS TotalRecords,
    COUNT(DISTINCT [Owner]) AS UniqueReturns,
    COUNT(DISTINCT [Item]) AS UniqueTradeItems,
    
    SUM([TotalPrice]) AS TotalAmount_Sum,
    SUM([TotalTaxAmount]) AS TotalTaxAmount_Sum,
    
    MIN([TotalPrice]) AS MinAmount,
    MAX([TotalPrice]) AS MaxAmount,
    AVG([TotalPrice]) AS AvgAmount,
    
    MIN([ID]) AS MinID,
    MAX([ID]) AS MaxID
    
FROM [doTradeReturn-Items]
WHERE [ID] > 0;
```

**Expected results:**
- Total records: ~2,242
- Unique returns: 1,059 (should match doTradeReturn count)
- Total amount: Should match sum of doTradeReturn.TotalAmount

### Step 5: Header-Item Integrity Check
**SQL Query #4:**
```sql
-- Validate header = sum(items)
SELECT 
    'Overall Validation' AS Analysis,
    COUNT(*) AS TotalReturns,
    
    SUM(CASE 
        WHEN ABS(tr.[TotalAmount] - COALESCE(items_sum.[TotalPrice], 0)) <= 0.01 
        THEN 1 ELSE 0 
    END) AS Perfect_Matches,
    
    SUM(CASE 
        WHEN ABS(tr.[TotalAmount] - COALESCE(items_sum.[TotalPrice], 0)) > 0.01 
        THEN 1 ELSE 0 
    END) AS Mismatches,
    
    CAST(SUM(CASE 
        WHEN ABS(tr.[TotalAmount] - COALESCE(items_sum.[TotalPrice], 0)) <= 0.01 
        THEN 1 ELSE 0 
    END) * 100.0 / COUNT(*) AS DECIMAL(5,2)) AS Match_Percent

FROM [doTradeReturn] tr
LEFT JOIN (
    SELECT [Owner], SUM([TotalPrice]) AS TotalPrice
    FROM [doTradeReturn-Items]
    GROUP BY [Owner]
) items_sum ON items_sum.[Owner] = tr.[ID]
WHERE tr.[ID] > 0;
```

**Expected:** 100% match (like Delivery-Items)

### Step 6: Items Distribution
**SQL Query #5:**
```sql
-- Items per return distribution
SELECT 
    ItemCount,
    COUNT(*) AS ReturnCount,
    CAST(COUNT(*) * 100.0 / (SELECT COUNT(DISTINCT [Owner]) FROM [doTradeReturn-Items]) AS DECIMAL(5,2)) AS Percentage
FROM (
    SELECT [Owner], COUNT(*) AS ItemCount
    FROM [doTradeReturn-Items]
    GROUP BY [Owner]
) AS ItemCounts
GROUP BY ItemCount
ORDER BY ItemCount;
```

**Expected distribution:**
- 70%+ single-item returns
- ~15% two-item returns
- Few multi-item returns

### Step 7: Sample Data
**SQL Query #6:**
```sql
-- Get sample data
SELECT TOP 20
    tri.[ID],
    tri.[Owner] AS ReturnID,
    tri.[Item] AS TradeItemID,
    tri.[Quantity],
    tri.[Price],
    tri.[TotalPrice],
    tri.[TaxAmount],
    tri.[TotalTaxAmount],
    tr.[TotalAmount] AS Header_TotalAmount,
    tr.[ReturnedAmount] AS Header_ReturnedAmount,
    tr.[FinanceTransaction],
    tr.[ProductReceipt]
FROM [doTradeReturn-Items] tri
INNER JOIN [doTradeReturn] tr ON tr.[ID] = tri.[Owner]
WHERE tri.[Owner] > 0
ORDER BY tri.[Owner], tri.[ID];
```

### Step 8: Orphaned Items Check
**SQL Query #7:**
```sql
-- Check for orphaned items
SELECT 
    'Orphaned Items' AS Analysis,
    COUNT(*) AS TotalItems,
    
    (SELECT COUNT(*) 
     FROM [doTradeReturn-Items] 
     WHERE [Owner] NOT IN (SELECT [ID] FROM [doTradeReturn] WHERE [ID] > 0)
    ) AS OrphanedItems,
    
    (SELECT COUNT(*) 
     FROM [doTradeReturn-Items] 
     WHERE [Item] NOT IN (SELECT [ID] FROM [doTradeItem] WHERE [ID] > 0)
    ) AS ItemsWithoutTradeItem;
```

**Expected:** 0 orphans (perfect integrity)

---

## 📝 ANALYSIS TEMPLATE

After gathering data, create file: `09-doTradeReturn-Items-analysis.md`

### File Structure:
```markdown
# doTradeReturn-Items - Analysis Report

**Table:** `doTradeReturn-Items`
**Domain:** Trade/Sales - Return Line Items
**Analysis Date:** 2025-11-10
**Database:** TEKA (SQL Server 2005)

## 📋 Schema
[Table with columns]

## 🔗 Relationships
[Foreign keys]

## 📊 Data Statistics
[Basic counts and amounts]

## 💡 Business Logic
### 1. Item-Level Return Tracking
[Does it track ReturnedQuantity?]

### 2. Return Reasons
[Any reason/rejection fields?]

### 3. Header-Item Integrity
[100% match expected]

### 4. Multi-Item Returns
[Distribution analysis]

## 🚨 Critical Data Quality Issues
[Orphans, negatives, anomalies]

## 🔧 PostgreSQL Migration Complexity
**Complexity Rating:** MEDIUM

[Schema, indexes, triggers]

## 🎯 Migration Recommendations
[Step-by-step migration plan]

## 📝 Questions for Stakeholders
[Business logic questions]

## 🔍 Sample Data
[Examples]

## ✅ Analysis Complete
```

---

## 🚨 CRITICAL CONTEXT FROM doTradeReturn

### Key Findings to Reference:
1. **58.26% pending returns** (617/1,059) - affects all items!
2. **No ReturnedQuantity in header** - check if in items table
3. **Partial returns exist** (10 cases, 0.95%) - how tracked at item level?
4. **Four return scenarios:**
   - Plan Only: 444 returns
   - Refund Only: 263 returns (845K BGN!)
   - Full Cycle: 179 returns
   - Stock Only: 173 returns
5. **100% header-item match expected** (like Delivery-Items)

### Questions to Answer:
- ❓ Does items table have ReturnedQuantity field?
- ❓ For partial returns (10 cases), can we see which items were accepted/rejected?
- ❓ Any return reason codes?
- ❓ Same perfect integrity as Delivery-Items?

---

## 📊 PROGRESS TRACKING

### After Completing doTradeReturn-Items:
1. Update progress tracker to **9/14 (64%)**
2. Update cumulative statistics (add 2,242 records)
3. Add migration time estimate (~10-12 hours)
4. Update "Next Steps" section

### Remaining After This:
- 5 tables left (36%)
- Estimated 30-40 hours
- Week 2-3 completion target

---

## 🎯 SUCCESS CRITERIA

### Completed When:
✅ Schema documented (all columns, types, constraints)  
✅ All indexes documented  
✅ Basic statistics gathered  
✅ Header-item integrity validated  
✅ Items distribution analyzed  
✅ Sample data reviewed  
✅ Orphaned items checked  
✅ Business logic interpreted  
✅ Migration complexity assessed  
✅ PostgreSQL schema designed  
✅ Stakeholder questions documented  
✅ Analysis file created (09-doTradeReturn-Items-analysis.md)  
✅ Progress tracker updated

---

## 💾 BACKUP REMINDER

Before starting, ensure all files are backed up:
```powershell
# Backup command (run in PowerShell)
Copy-Item "C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\*" `
          "C:\TEKA_NET\Teka_StoreNET_ERP\analysis\backups\trade-domain-2025-11-10\" `
          -Recurse -Force
```

---

## 📞 CONTACT INFO

**Analyst:** Светльо Партенев  
**Project:** Teka_StoreNET_ERP Migration  
**Phase:** Week 1 - Database Analysis  
**Domain:** Trade/Sales Operations

---

## 🚀 READY TO START

**First Message to Claude:**
```
Продължавам анализа на Teka_StoreNET_ERP Trade Domain.
Прочети:
1. C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\trade-domain-progress.md
2. C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\08-doTradeReturn-analysis.md

След това започни анализ на doTradeReturn-Items с първата SQL заявка за schema.
Работи стъпка по стъпка - дай ми SQL, изчакай резултата, анализирай, дай следваща SQL.
ВАЖНО: Работим с TEKA база (не TEKA MAT)!
```

**Expected Response:**
Claude will read both files, confirm 8/14 completed (57%), and provide first SQL query for doTradeReturn-Items schema.

---

## ⚠️ IMPORTANT NOTES

### Database:
- ✅ Use **TEKA** database (not TEKA MAT)
- ✅ SQL Server 2005 syntax
- ✅ Use square brackets for column names: `[Owner]`, `[Item]`

### Analysis Style:
- ✅ Step-by-step (one SQL at a time)
- ✅ Wait for results before next query
- ✅ Comprehensive documentation
- ✅ Business logic interpretation
- ✅ PostgreSQL migration planning

### Critical Checks:
- ✅ ReturnedQuantity field existence
- ✅ Return reason fields
- ✅ Header-item integrity (100% expected)
- ✅ Orphaned items (0 expected)
- ✅ Items per return distribution

---

**Document Status:** ✅ READY FOR HANDOFF  
**Created:** 2025-11-10  
**Next Analyst:** Claude (Sonnet 4.5)  
**Next Task:** doTradeReturn-Items schema analysis

**Good luck! 🚀**

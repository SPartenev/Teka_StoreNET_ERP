# 🎯 NEXT TABLE: doFinanceTransaction

**CRITICAL:** Use MCP tools directly! Only ask Светльо if MCP fails.

---

## ⚡ YOUR SINGLE TASK

Analyze **doFinanceTransaction** table ONLY.

**DO NOT:**
- ❌ Read other table analyses
- ❌ Read progress files
- ❌ Read handoff documents
- ❌ Update any progress tracking files
- ❌ Compare with completed work

**DO:**
- ✅ Use `teka-sql-server:executeQuery` directly (MCP)
- ✅ Analyze THIS table only
- ✅ Document findings
- ✅ Save ONE file: `analysis/domains/financial/08-doFinanceTransaction.md`

---

## 📋 WHAT WE KNOW (Context)

**Just Completed:**
- ✅ **doSystemTransaction** - Base class (1,255,901 total records across 7 types)
- ✅ Confirmed inheritance pattern: doDataObject → doSystemTransaction → [7 child types]
- ✅ Two-phase commit workflow validated (99.9965% committed)
- ✅ 55 active users, date range 1901-01-01 to 2021-09-15

**Known Child Transaction Types (7 total):**
1. ✅ doTradeTransaction (764,906 records) - DONE
2. 🔄 **doFinanceTransaction** ← YOU ARE HERE
3. 🔲 doStoreTransfer
4. 🔲 doStoreAssembly
5. 🔲 doStoreDiscard
6. 🔲 doCashDeskCurrencyChange
7. 🔲 doCashDeskAmountTransfer

**Estimated Records:**
- Total in doSystemTransaction: 1,255,901
- Trade: 764,906 (60.9%)
- **Remaining 6 types: ~491,000 (39.1%)**
- **Your table likely has: 80,000-150,000 records** (second largest after Trade)

---

## 🔍 ANALYSIS STEPS (Use MCP directly!)

### Step 1: Schema (5 min)
**Use MCP:**
```javascript
teka-sql-server:executeQuery({
  sql: `SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    CHARACTER_MAXIMUM_LENGTH
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'doFinanceTransaction'
  AND TABLE_SCHEMA = 'dbo'
ORDER BY ORDINAL_POSITION;`
})
```

### Step 2: Row Count (2 min)
**Use MCP:**
```javascript
teka-sql-server:executeQuery({
  sql: `SELECT COUNT(*) AS TotalRecords FROM doFinanceTransaction;`
})
```

### Step 3: Foreign Keys OUT (5 min)
**Use MCP:**
```javascript
teka-sql-server:executeQuery({
  sql: `SELECT 
    fk.name AS FK_Name,
    OBJECT_NAME(fk.referenced_object_id) AS Parent_Table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS Parent_Column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) = 'doFinanceTransaction';`
})
```

### Step 4: Foreign Keys IN (5 min)
**Use MCP:**
```javascript
teka-sql-server:executeQuery({
  sql: `SELECT 
    fk.name AS FK_Name,
    OBJECT_NAME(fk.parent_object_id) AS Child_Table,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS Child_Column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.referenced_object_id) = 'doFinanceTransaction';`
})
```

### Step 5: Sample Data (5 min)
**Use MCP:**
```javascript
teka-sql-server:executeQuery({
  sql: `SELECT TOP 10 * FROM doFinanceTransaction ORDER BY ID DESC;`
})
```

### Step 6: Date Range & Stats (3 min)
**Use MCP:**
```javascript
teka-sql-server:executeQuery({
  sql: `SELECT 
    MIN(ft.ID) AS MinID,
    MAX(ft.ID) AS MaxID,
    COUNT(DISTINCT st.UserCreated) AS UniqueUsers
FROM doFinanceTransaction ft
INNER JOIN doSystemTransaction st ON ft.ID = st.ID;`
})
```

### Step 7: Financial Amounts Analysis (5 min)
**Use MCP - Adjust column names based on Step 1 schema:**
```javascript
teka-sql-server:executeQuery({
  sql: `SELECT 
    MIN(Amount) AS MinAmount,
    MAX(Amount) AS MaxAmount,
    AVG(Amount) AS AvgAmount,
    SUM(Amount) AS TotalAmount,
    COUNT(CASE WHEN Amount < 0 THEN 1 END) AS NegativeCount,
    COUNT(CASE WHEN Amount > 0 THEN 1 END) AS PositiveCount
FROM doFinanceTransaction;`
})
```
**Note:** If "Amount" column doesn't exist, check schema and adjust query accordingly.

---

## 📝 DOCUMENT STRUCTURE

**Save to:** `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\financial\08-doFinanceTransaction.md`

**Use:** `Filesystem:write_file`

```markdown
# doFinanceTransaction Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо

---

## 📋 Overview

**Purpose:** Financial transactions (likely payments, invoices, adjustments)  
**Parent Table:** doSystemTransaction  
**Row Count:** [X records]  
**Percentage of Total:** [X%] of 1,255,901 system transactions  
**Migration Complexity:** [3-4]/5

---

## 🗂️ Schema

### Columns ([X] total):
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | ... | Primary key (inherits from doSystemTransaction) |
| [Column2] | [Type] | [Yes/No] | ... | [Description based on name] |
| ... | ... | ... | ... | ... |

**Key Observations:**
- [List important columns related to financial operations]
- [Note any amount/currency/account fields]
- [Identify relationship fields]

---

## 🔗 Relationships

### Foreign Keys (Outgoing):
- `ID` → `doSystemTransaction.ID` - Inherits transaction base
- [List other FKs found in Step 3]

### Foreign Keys (Incoming):
- [List child tables if any from Step 4, or state "None - leaf table"]

---

## 📊 Data Analysis

### Total Records: [X]
**Percentage:** [X%] of 1,255,901 total system transactions

### Sample Data Observations:
[Key patterns from TOP 10 records - what types of financial operations?]

### Financial Statistics (if applicable):
| Metric | Value |
|--------|-------|
| Min Amount | [X] |
| Max Amount | [X] |
| Avg Amount | [X] |
| Total Amount | [X] |
| Negative (debits?) | [X] |
| Positive (credits?) | [X] |

### ID Range:
- **Min ID:** [X]
- **Max ID:** [X]
- **Unique Users:** [X]

---

## 🏗️ Architecture Pattern

**Inheritance:**
```
doDataObject
    └─ doSystemTransaction (1,255,901 records)
           └─ doFinanceTransaction ([X] records - [X]%)
```

**Purpose in System:**
[Based on schema and sample data - describe what this table does]

**Key Fields:**
- [List 3-5 most important columns and their business meaning]

---

## 🔄 PostgreSQL Migration

### Complexity: [3-4]/5

**Why [Medium/High] Complexity:**
- [Reason 1 based on findings]
- [Reason 2 based on findings]
- [Volume/relationships/business logic concerns]

**Strategy:**
```sql
CREATE TABLE finance_transactions (
    -- Finance-specific columns
    [column1] [type],
    [column2] [type],
    -- ...
) INHERITS (system_transactions);
```

### Schema Changes:
- [ ] Convert [SQL Server type] → [PostgreSQL type]
- [ ] Add indexes on [key columns]
- [ ] Handle [any data quality issues found]

### Estimated Time: [X-Y] hours

---

## ❓ Stakeholder Questions

1. **Business Purpose:**
   - What financial operations does this table track?
   - Relationship to accounting system?
   - Payment types covered?

2. **Data Volume:**
   - Expected growth rate?
   - Archival strategy?

3. **Integration:**
   - Link to doTradeTransaction for payments?
   - External system integrations?

[Add 2-3 more relevant questions based on findings]

---

## 🚨 Migration Risks

### High Priority:
1. **[Risk based on findings]** - [Mitigation]
2. **[Risk based on findings]** - [Mitigation]

### Medium Priority:
3. **[Risk based on findings]** - [Mitigation]

---

## 📝 Notes

### Key Insights:
- [Important architectural or business finding 1]
- [Important architectural or business finding 2]
- [Important architectural or business finding 3]

### Migration Considerations:
- [PostgreSQL-specific consideration]
- [Data quality issue if found]
- [Performance consideration]

---

## ✅ Analysis Complete

**Status:** DONE  
**Complexity:** [3-4]/5  
**Time Estimate:** [X-Y] hours migration  
**Priority:** [HIGH/MEDIUM] (financial transactions are critical)

---

**Next:** doStoreTransfer or continue with remaining transaction types.
```

---

## ✅ COMPLETION

When done:
1. ✅ Save file using `Filesystem:write_file`
2. ✅ Tell Светльо: "doFinanceTransaction complete! Saved to 08-doFinanceTransaction.md"
3. ❌ **DO NOT** update any other files!

---

## 🚀 START NOW

**Simply begin with:**
```
Starting doFinanceTransaction analysis using MCP.

Step 1: Getting schema...
```

Then call `teka-sql-server:executeQuery` directly!

---

## 💡 TIPS FROM PREVIOUS ANALYSIS

**What Worked Well:**
- TOP 10 sample data is enough (don't over-fetch)
- Join with doSystemTransaction for user/date info
- Focus on business meaning, not just technical details
- Financial tables likely have Amount/Currency/Account columns
- Look for patterns: debits vs credits, payment types, etc.

**Watch For:**
- Default date values (1901-01-01) - data quality issue
- Float types for money - should be DECIMAL in PostgreSQL
- NULL patterns in financial fields - business logic?
- Relationship to Trade transactions (payments?)

---

**If MCP fails:**
Only then ask Светльо to execute the query manually.

---

**Time:** 30-40 minutes  
**Focus:** ONE table analysis  
**Output:** ONE file in financial domain (not trade!)  
**Tools:** MCP first, Светльо backup  
**Remember:** This is a FINANCIAL transaction type, not trade! 🎯

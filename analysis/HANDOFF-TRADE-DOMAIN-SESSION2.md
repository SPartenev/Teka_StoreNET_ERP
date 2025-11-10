# HANDOFF INSTRUCTIONS - Trade Domain Analysis (Session 2)

**Date:** 2025-11-10  
**Current Status:** 2/14 tables analyzed (14%)  
**Next Table:** doTradeTransaction (Table 3/14)  
**Session Progress:** doTrade ✅, doTradeItem ✅

---

## 🎯 QUICK START - Tell Claude:

```
"Продължавам анализа на Teka_StoreNET_ERP Trade Domain.
Прочети:
1. C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\trade-domain-progress.md
2. C:\TEKA_NET\Teka_StoreNET_ERP\analysis\HANDOFF-TRADE-DOMAIN-SESSION2.md

Готов съм да изпълня SQL заявките за doTradeTransaction.
Работи стъпка по стъпка."
```

---

## ✅ COMPLETED IN SESSION 1

### Tables Analyzed (2/14):
1. ✅ **doTrade** (50 columns, 365,771 records)
   - Complexity: 4/5 HIGH
   - Key Issues: Future date bug (3013), float for tax, 6.62% cancellation rate
   - Migration Time: 14 hours

2. ✅ **doTradeItem** (30 columns, 1,031,069 records)
   - Complexity: 5/5 VERY HIGH
   - **CRITICAL ISSUES FOUND:**
     - ⚠️ Negative profit margin: -21% (98M sales, 119M cost)
     - ⚠️ Delivered > Ordered quantities (10x anomalies!)
     - ⚠️ Pricing calculation errors (2.52 vs 0.25 expected)
     - ⚠️ 2 orphan trades (no line items)
   - Migration Time: 25 hours

### Files Created:
```
C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\
├── trade-domain-progress.md ✅
├── 01-doTrade.md ✅
└── 02-doTradeItem.md ✅
```

---

## 🔄 NEXT TABLE: doTradeTransaction (Table 3/14)

**Purpose:** Transaction metadata - likely contains Store reference, timestamps, user info

**SQL Queries to Execute:**

### Query 1: Schema
```sql
SELECT 
    ORDINAL_POSITION as [#], 
    COLUMN_NAME, 
    DATA_TYPE, 
    CHARACTER_MAXIMUM_LENGTH as [MaxLen], 
    IS_NULLABLE, 
    COLUMN_DEFAULT as [Default]
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'doTradeTransaction' 
ORDER BY ORDINAL_POSITION;
```

### Query 2: Foreign Keys
```sql
SELECT 
    fk.name AS FK_Name,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS Column_Name,
    OBJECT_NAME(fk.referenced_object_id) AS Referenced_Table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS Referenced_Column
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc 
    ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) = 'doTradeTransaction'
ORDER BY fk.name;
```

### Query 3: Sample Data
```sql
SELECT TOP 20 * 
FROM doTradeTransaction 
ORDER BY ID DESC;
```

### Query 4: Statistics
```sql
SELECT 
    COUNT(*) as TotalTransactions,
    COUNT(DISTINCT Store) as UniqueStores,
    COUNT(DISTINCT CashDesk) as UniqueCashDesks,
    MIN(Date) as FirstDate,
    MAX(Date) as LastDate
FROM doTradeTransaction;
```

---

## 📋 REMAINING TABLES (12)

| # | Table Name | Priority | Notes |
|---|------------|----------|-------|
| 3 | doTradeTransaction | 🔄 NEXT | Metadata |
| 4 | doTradePayment | HIGH | Payment records |
| 5 | doTradePayment-Items | HIGH | Payment details |
| 6 | doTradeDelivery | HIGH | Delivery tracking |
| 7 | doTradeDelivery-Items | HIGH | Delivery details |
| 8 | doTradeReturn | MEDIUM | Returns |
| 9 | doTradeReturn-Items | MEDIUM | Return details |
| 10 | doTradeCancel | MEDIUM | Cancellations |
| 11 | doTradeCancel-Items | MEDIUM | Cancel details |
| 12 | doTransaction | LOW | Base entity |
| 13 | doTransactionInfo | LOW | Additional metadata |
| 14 | doSystemTransaction | LOW | System transactions |

---

## 🚨 CRITICAL ISSUES TO TRACK

From Session 1 analysis, these issues need investigation:

### 1. **Negative Profit Margin (doTradeItem)**
```
Total Sales:  98,246,476.15 BGN
Total Cost:  119,176,533.60 BGN
LOSS:        -20,930,057.45 BGN (21% loss!)
```
**Action:** Continue monitoring cost/revenue patterns in related tables

### 2. **Quantity Tracking Anomalies (doTradeItem)**
```
Example: Ordered 0.5 units → Delivered 5.04 units (10x more!)
```
**Action:** Check if doTradeDelivery explains this pattern

### 3. **Pricing Calculation Issues (doTradeItem)**
```
Expected: Quantity × Price = 0.5 × 0.50 = 0.25 BGN
Actual: TotalPaymentPrice = 2.52 BGN
```
**Action:** Investigate formula in source code or stored procedures

### 4. **Data Quality Issues**
- Future dates in doTrade (year 3013)
- Float data types for financial values
- 2 orphan trades without line items
- High cancellation rate (6.62%)

---

## 📊 MIGRATION COMPLEXITY SUMMARY

### Completed Tables:
- **doTrade:** 4/5 (HIGH) - 14 hours
- **doTradeItem:** 5/5 (VERY HIGH) - 25 hours
- **Total:** 39 hours (~5-6 days)

### Expected for Remaining 12 Tables:
- **Estimated:** 80-100 hours (~10-15 days)
- **Total Domain:** 120-140 hours (~15-20 days)

---

## 🎯 SESSION 2 GOALS

1. ✅ Analyze doTradeTransaction (metadata)
2. ✅ Analyze doTradePayment (payment records)
3. ✅ Analyze doTradePayment-Items (payment line items)
4. 🎯 **Target:** Complete 3-4 tables (50% domain progress)

---

## 📝 ANALYSIS WORKFLOW REMINDER

### Step-by-Step Process:
1. **Run Query 1** (Schema) → Wait for results
2. **Run Query 2** (Foreign Keys) → Wait for results
3. **Run Query 3** (Sample Data) → Wait for results
4. **Run Query 4** (Statistics) → Wait for results
5. **Claude documents** table → Creates .md file
6. **Update progress** file → Move to next table
7. **Repeat** for each table

### File Naming Convention:
```
03-doTradeTransaction.md
04-doTradePayment.md
05-doTradePayment-Items.md
...etc
```

---

## ⚡ CRITICAL RULES (NEVER FORGET!)

### File Operations:
✅ **USE:** `Filesystem:write_file` (always works)  
❌ **AVOID:** `create_file` (causes errors)

### SQL Queries:
✅ **DO:** Execute queries ONE at a time, wait for results  
❌ **DON'T:** Assume results or run multiple without seeing output

### Session Management:
✅ **DO:** Update progress file after EACH table  
✅ **DO:** Create HANDOFF file if session ending  
❌ **DON'T:** Analyze 5+ tables without saving progress

---

## 📞 CONTACT & RESOURCES

**Analyst:** Светльо Партенев  
**Project:** TEKA_NET Migration - Month 1, Week 1.5  
**Timeline:** 4-week analysis phase  
**Backup Location:** C:\TEKA_NET\Backups\  
**GitHub Repo:** https://github.com/SPartenev/Teka_StoreNET_ERP

---

## 🎉 MOTIVATIONAL NOTE

**Great progress!** You've completed 2 critical tables and discovered important business issues:
- Negative profit margins → pricing strategy review needed
- Quantity anomalies → inventory logic requires investigation
- Data quality issues → pre-migration cleanup essential

These findings will save the business from major migration headaches! Keep up the excellent work! 💪

The Trade Domain is the **revenue heart** of the system. Your thorough analysis ensures:
- ✅ No lost sales during migration
- ✅ Accurate financial reporting
- ✅ Proper inventory tracking
- ✅ Customer satisfaction maintained

---

**Handoff Created:** 2025-11-10  
**Session Status:** 2/14 tables complete (14%)  
**Next Action:** Execute SQL queries for doTradeTransaction  
**Expected Session 2 Duration:** 3-4 hours  
**Expected Session 2 Output:** 3-4 tables documented

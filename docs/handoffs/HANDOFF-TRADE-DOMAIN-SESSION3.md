# HANDOFF INSTRUCTIONS - Trade Domain Session 3

**Date:** 2025-11-10  
**Session:** Trade Domain Analysis - Part 3  
**Status:** 4/14 tables complete (29%)  
**Next Task:** Analyze doTradePayment-Items

---

## 📊 SESSION PROGRESS

### ✅ Completed Tables (4/14):
1. **doTrade** - 365,771 records, future date bug discovered
2. **doTradeItem** - 1,031,069 records, negative margins (-21%!)
3. **doTradeTransaction** - 764,906 events, event sourcing architecture
4. **doTradePayment** - 365,963 payments, 2.7M BGN unpaid gap!

### 🔄 Next Table: doTradePayment-Items
- **Expected:** Junction table linking payments to trade items
- **Purpose:** Payment allocation logic (how payments split across line items)
- **Complexity:** MEDIUM-HIGH (amounts + line item relationships)

---

## 🎯 IMMEDIATE NEXT STEPS

### Step 1: Read Context Files
```
Прочети:
1. C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\trade-domain-progress.md
2. C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\doTradePayment-analysis.md
```

### Step 2: Start doTradePayment-Items Analysis

**SQL Query #1 - Schema:**
```sql
-- Get schema
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'doTradePayment-Items'
ORDER BY ORDINAL_POSITION;

-- Row count
SELECT COUNT(*) as total_items
FROM [doTradePayment-Items];

-- Indexes & Keys
EXEC sp_helpindex 'doTradePayment-Items';

-- Foreign keys
EXEC sp_fkeys @pktable_name = 'doTradePayment-Items';
EXEC sp_fkeys @fktable_name = 'doTradePayment-Items';
```

**Note:** Table name has hyphen, so use `[doTradePayment-Items]` in queries!

### Step 3: Micro-Steps Approach
After schema query, proceed with:
1. Data statistics (amounts, counts)
2. Payment-to-item distribution
3. Validation against parent tables
4. Sample data inspection
5. Document findings

---

## 🚨 CRITICAL ISSUES TO TRACK

### 1. Payment Gap (2.7M BGN)
```
Sales: 98,246,476.15 BGN
Paid:  95,552,383.61 BGN
Gap:    2,694,092.54 BGN (2.7%)
```
**Question:** Does doTradePayment-Items explain this gap?

### 2. Installment Payments
- 2,930 trades have 2+ payments
- Max: 21 payments for Trade 1230765
**Question:** How are multiple payments allocated to items?

### 3. FinanceTransaction Pattern
- Every payment: FinanceTransaction = PaymentID + 1
**Question:** Is there similar pattern in payment items?

---

## 📋 KEY PATTERNS DISCOVERED

### Event Sourcing Architecture:
```
doSystemTransaction (base)
└─ doTradeTransaction (adds Trade + Store)
       ├─ doTrade (365,771)
       ├─ doTradePayment (365,963)
       │    └─ doTradePayment-Items (? items) ← WE ARE HERE
       ├─ doTradeDelivery (32,113)
       ├─ doTradeReturn (1,060)
       └─ doTradeCancel (3)
```

### Expected Relationships:
```
doTradePayment (Owner)
    ↓ one-to-many
doTradePayment-Items
    ↓ many-to-one
doTradeItem (TradeItem FK?)
```

---

## 💡 ANALYSIS EXPECTATIONS

### Likely Schema:
- **ID** - Primary key
- **Owner** - FK to doTradePayment
- **TradeItem** - FK to doTradeItem (linking payment to product)
- **Amount** - Payment amount for this item
- **TaxAmount** - Tax portion for this item

### Key Questions:
1. **Can one payment cover multiple items?** (likely YES)
2. **Can one item have multiple payments?** (installments → YES)
3. **Do amounts sum correctly?**
   - Sum(PaymentItems.Amount) = Payment.TotalAmount?
   - Sum(PaymentItems for Trade) = Trade total?

### Validation Queries Needed:
1. Payment items per payment (distribution)
2. Sum validation (PaymentItems → Payment)
3. Orphan detection (missing FKs)
4. Edge cases (zero amounts, negative amounts)

---

## 🔧 SQL SERVER 2005 CONSTRAINTS

**Remember:**
- ❌ No `STRING_AGG()` function
- ❌ Strict `ORDER BY` in `GROUP BY` (cannot use non-aggregated columns)
- ✅ Use subqueries for complex aggregations
- ✅ Use `CASE` statements in aggregations carefully

**Pattern that works:**
```sql
-- Good (SQL 2005)
SELECT category, COUNT(*) 
FROM (SELECT col, CASE WHEN ... END as category FROM table) as sub
GROUP BY category;

-- Bad (SQL 2005)
SELECT CASE WHEN ... END as category, COUNT(*)
FROM table
GROUP BY CASE WHEN ... END
ORDER BY col;  -- ❌ col not in GROUP BY
```

---

## 📁 FILE LOCATIONS

### Analysis Files (Read):
```
C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\
├── trade-domain-progress.md (✅ updated)
├── doTrade-analysis.md
├── doTradeItem-analysis.md
├── doTradeTransaction-analysis.md
└── doTradePayment-analysis.md (✅ just completed)
```

### Output File (Write):
```
C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\doTradePayment-Items-analysis.md
```

---

## 🎯 SUCCESS CRITERIA

### For doTradePayment-Items Analysis:

✅ **Schema documented:**
- All columns with types
- Primary key identified
- Foreign keys mapped
- Indexes listed

✅ **Data statistics:**
- Total record count
- Amount distributions
- Items per payment (avg, min, max)
- Payments per item (for installments)

✅ **Validation completed:**
- Sum(Items.Amount) = Payment.TotalAmount ✓/✗
- Zero orphaned records ✓/✗
- Payment gap explained ✓/✗

✅ **Migration complexity rated:**
- PostgreSQL schema design
- Data type conversions
- Index strategy
- Constraints needed

✅ **Documentation saved:**
- Markdown file created
- Progress file updated
- Issues flagged for stakeholders

---

## 🚀 AGENT STARTUP COMMAND

**Prompt:**
```
Продължавам анализа на Teka_StoreNET_ERP Trade Domain.

Прочети:
1. C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\trade-domain-progress.md
2. C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\trade-domain\doTradePayment-analysis.md

След това започни анализа на doTradePayment-Items с първата SQL заявка за schema.

Работи стъпка по стъпка - дай ми SQL, изчакай резултата, анализирай, дай следващата SQL.
```

---

## 📊 COMPLETION TRACKING

**Trade Domain: 4/14 tables (29%)**

| Table | Status | File |
|-------|--------|------|
| doTrade | ✅ | doTrade-analysis.md |
| doTradeItem | ✅ | doTradeItem-analysis.md |
| doTradeTransaction | ✅ | doTradeTransaction-analysis.md |
| doTradePayment | ✅ | doTradePayment-analysis.md |
| doTradePayment-Items | 🔄 NEXT | (to be created) |
| doTradeDelivery | 🔲 TODO | |
| doTradeDelivery-Items | 🔲 TODO | |
| doTradeReturn | 🔲 TODO | |
| doTradeReturn-Items | 🔲 TODO | |
| doTradeCancel | 🔲 TODO | |
| doTradeCancel-Items | 🔲 TODO | |
| doTransaction | 🔲 TODO | |
| doTransactionInfo | 🔲 TODO | |
| doSystemTransaction | 🔲 TODO | |

---

## ⏱️ TIME TRACKING

**Sessions:**
- Session 1: doTrade + doTradeItem (2 hours)
- Session 2: doTradeTransaction + doTradePayment (1.5 hours)
- **Session 3:** doTradePayment-Items (est. 45 min)

**Estimated remaining:** 10 tables × 45 min = 7.5 hours (5-6 sessions)

---

## 🎓 WORKFLOW REMINDER

1. **Read context** (progress + previous analysis)
2. **Start with schema** (columns, keys, indexes)
3. **Gather statistics** (counts, distributions, ranges)
4. **Validate relationships** (FK integrity, sum checks)
5. **Inspect samples** (real data patterns)
6. **Document findings** (save markdown file)
7. **Update progress** (trade-domain-progress.md)
8. **Flag issues** (stakeholder questions list)

**Never skip documentation!** Files are the deliverable, not just analysis.

---

**Created by:** Claude (Sonnet 4.5)  
**For:** Svetlyo Partenev  
**Next Analyst:** Claude (new session)  
**Ready to proceed!** 🚀

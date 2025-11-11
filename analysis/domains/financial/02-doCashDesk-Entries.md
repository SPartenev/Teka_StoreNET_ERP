# doCashDesk-Entries Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо  
**Domain:** Financial

---

## 📋 Overview

**Purpose:** Current balance snapshot for each cash desk by currency (cash position tracking)  
**Type:** Balance/Position Table (not transaction log)  
**Parent Table:** doCashDesk  
**Row Count:** 94 records  
**Coverage:** 50 of 51 cash desks (98%)  
**Migration Complexity:** 2/5 (Low-Medium)

---

## 🗂️ Schema

### Columns (5 total):

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | - | Primary key (auto-increment) |
| Owner | bigint | NOT NULL | ((0)) | FK to doCashDesk - which cash desk/bank account |
| Currency | bigint | NOT NULL | ((0)) | FK to doCurrency - which currency |
| Amount | decimal | NOT NULL | ((0.0)) | Current balance in this currency |
| OverdraftAmount | decimal | NOT NULL | ((0.0)) | Overdraft limit/credit line for this cash desk+currency |

### Key Observations:
- ✅ **Uses DECIMAL for money** - correct financial data type (NOT float!)
- **Multi-currency support:** Each cash desk can have multiple entries (one per currency)
- **Simple 5-column design** - pure balance tracking table
- **No temporal fields** - this is a "current state" snapshot, not historical log
- **Overdraft tracking** - system supports credit lines on cash desks

### Schema Precision:
```sql
-- Check DECIMAL precision
SELECT 
    NUMERIC_PRECISION, 
    NUMERIC_SCALE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE TABLE_NAME = 'doCashDesk-Entries' AND COLUMN_NAME = 'Amount';
```
**Assumption:** Likely `DECIMAL(18,2)` or `DECIMAL(19,4)` - should verify before migration.

---

## 🔗 Relationships

### Foreign Keys (Outgoing - 2):
- `Owner` → `doCashDesk.ID` - Which cash desk or bank account
- `Currency` → `doCurrency.ID` - Which currency (BGN, EUR, USD)

### Foreign Keys (Incoming - 0):
- **None** - This is a **leaf table** (no child tables reference it)
- No other tables depend on doCashDesk-Entries

### Architecture Pattern:
```
doCashDesk (51 cash desks)
    └─ doCashDesk-Entries (94 entries = 50 desks × ~1.88 currencies/desk)
           ├─ Entry for BGN balance
           ├─ Entry for EUR balance
           └─ Entry for USD balance (mostly unused)
```

**Purpose:** Each cash desk tracks separate balances for each currency it handles.

---

## 📊 Data Analysis

### Total Records: 94
- **Unique Cash Desks:** 50 (98% of 51 total)
- **Missing:** 1 cash desk (likely ID=0 NULL placeholder)
- **Average entries per desk:** 1.88 (confirms multi-currency pattern)

### Multi-Currency Pattern:
- **Most common:** Cash desk has 1-3 currency entries
- Example: "Главна офис" (ID=22) has 3 entries (BGN, EUR, USD)
- Example: Old inactive desks have only 1 entry (BGN only)

---

## 💰 Currency Distribution Analysis

### Currency 19 (BGN) - 42 entries:
| Metric | Value |
|--------|-------|
| **Total Balance** | **36,748,365.45 BGN** |
| Average Balance | 874,961 BGN |
| Positive Balances | 26 (61.9%) |
| Negative Balances | 2 (4.8%) |
| Zero Balances | 14 (33.3%) |
| **Total Overdraft Limit** | **11,746,700 BGN** |

**Interpretation:**
- ✅ **Strong BGN position** - 36.7M BGN across all cash desks
- ✅ Healthy ratio: 26 positive vs 2 negative accounts
- 14 zero balances likely from inactive/old cash desks
- Overdraft of 11.7M BGN provides liquidity cushion

### Currency 20 (EUR) - 30 entries:
| Metric | Value |
|--------|-------|
| **Total Balance** | **-4,833,588.21 EUR** ⚠️ |
| Average Balance | -161,120 EUR |
| Positive Balances | 6 (20%) |
| Negative Balances | 6 (20%) |
| Zero Balances | 18 (60%) |
| **Total Overdraft Limit** | **118,115,000 EUR** 🚨 |

**Critical Findings:**
- ⚠️ **DEFICIT POSITION** - Company owes 4.8M EUR
- 🚨 **MASSIVE OVERDRAFT** - 118M EUR credit line (implies major international operations or debt facility)
- Only 6 accounts with positive EUR balance
- 18 zero balances = most EUR accounts inactive

### Currency 21 (Unknown, likely USD) - 22 entries:
| Metric | Value |
|--------|-------|
| **Total Balance** | **0.00** |
| Positive/Negative | 0 / 0 |
| Zero Balances | 22 (100%) |
| Total Overdraft Limit | 50 |

**Interpretation:**
- 💤 **Completely unused currency** - all balances are zero
- Likely configured for future use or legacy setup
- Minimal overdraft (50) suggests not actively used

---

## 🏦 Top 10 Largest Balances (by absolute value)

### Positive BGN Positions:
| Rank | Cash Desk | Amount | Overdraft | Status |
|------|-----------|--------|-----------|--------|
| 1 | **Райфайзен лева** | 15,164,666 BGN | 100,000 | ✅ Largest BGN account |
| 2 | **Прокредит лева** | 9,848,185 BGN | 0 | ✅ No overdraft needed |
| 3 | **Алианц банк лв** | 4,131,583 BGN | 0 | ✅ Strong position |
| 6 | Юнион Русе | 1,464,720 BGN | 0 | ✅ Regional branch |
| 7 | Юнион Пловдив | 1,265,740 BGN | 0 | ✅ Regional branch |
| 8 | Токуда банк АД лева | 1,213,394 BGN | 5,000,000 | ✅ Large overdraft facility |
| 9 | ТБ Виктория | 1,023,157 BGN | 5,000,000 | ✅ Large overdraft facility |
| 10 | Уникредит Булбанк | 894,573 BGN | 0 | ✅ |

**Top 3 BGN banks hold:** 29.1M BGN (79% of total BGN balance)

### Negative EUR Positions (Deficits):
| Rank | Cash Desk | Amount | Overdraft | Status |
|------|-----------|--------|-----------|--------|
| 4 | **Прокредит EUR** | -1,853,066 EUR | 100,000,000 | ⚠️ DEFICIT + HUGE overdraft |
| 5 | **Райфайзен EUR** | -1,534,225 EUR | 10,000,000 | ⚠️ DEFICIT |

**Critical Alert:**
- These 2 accounts represent -3.4M EUR of the -4.8M EUR total deficit (70%)
- **Прокредит EUR overdraft of 100M EUR** is extremely high - suggests:
  - Major credit line for international purchases
  - Import financing facility
  - Or potential reporting error (100M seems excessive)

---

## 🔍 Business Logic Interpretation

### Purpose of This Table:
1. **Real-time Cash Position Tracking**
   - Not a transaction log (no date fields)
   - Represents "as of now" balances
   - Updated by financial transactions (likely triggers/stored procedures)

2. **Multi-Currency Cash Management**
   - Each cash desk tracks separate balance per currency
   - Enables currency-specific reporting
   - Supports forex operations

3. **Overdraft/Credit Line Management**
   - OverdraftAmount = approved credit limit
   - Enables operations beyond available cash
   - Risk management tool (know exposure limits)

4. **Liquidity Monitoring**
   - Quick view of total available funds
   - Identifies cash-short positions
   - Supports treasury decisions

### How Balances Are Updated:
**Hypothesis:** This table is updated by:
- `doFinanceTransaction-Items` (payments, receipts)
- `doCashDeskAmountTransfer` (transfers between desks)
- `doCashDeskCurrencyChange` (forex operations)

**Update Mechanism:** Likely uses:
- Database triggers on transaction tables
- Stored procedures that recalculate balances
- Application-level balance updates

**Verification Needed:**
- Check for triggers on this table
- Review stored procedures that reference doCashDesk-Entries
- Validate against transaction history (sum of all transactions should equal current balance)

---

## 🏗️ Architecture Pattern

**Balance Tracking Pattern:**
```
Transaction Tables (source of truth)
    ├─ doFinanceTransaction-Items
    ├─ doCashDeskAmountTransfer
    └─ doCashDeskCurrencyChange
           ↓ (updates via triggers/procedures)
    doCashDesk-Entries (derived/calculated balances)
```

**Design Principles:**
1. **Denormalized for Performance** - Pre-calculated balances avoid SUM() queries
2. **Snapshot Architecture** - Current state only, not historical
3. **Multi-Currency Partitioning** - Separate row per currency prevents mixing
4. **Overdraft Tracking** - Built-in credit management

**Alternatives Considered:**
- ❌ Storing balance in doCashDesk table (wouldn't support multi-currency)
- ❌ Calculating balance on-the-fly from transactions (too slow for reporting)
- ✅ Current design: Separate entries table with currency dimension

---

## 🔄 PostgreSQL Migration

### Complexity: 2/5 (Low-Medium)

**Why Low Complexity:**
- ✅ Tiny table (94 records)
- ✅ Simple 5-column schema
- ✅ Clean foreign keys (2 outgoing, 0 incoming)
- ✅ DECIMAL data type (already correct for PostgreSQL)
- ✅ No computed columns
- ✅ Leaf table (no cascading dependencies)

**Why Not Level 1:**
- ⚠️ Balance integrity critical (must preserve exact amounts)
- ⚠️ Must identify and migrate triggers/procedures that update this table
- ⚠️ DECIMAL precision must match exactly

### Migration Strategy:

```sql
-- PostgreSQL Schema
CREATE TABLE cash_desk_entries (
    id BIGSERIAL PRIMARY KEY,
    cash_desk_id BIGINT NOT NULL REFERENCES cash_desks(id),
    currency_id BIGINT NOT NULL REFERENCES currencies(id),
    amount NUMERIC(19,4) NOT NULL DEFAULT 0.0,
    overdraft_amount NUMERIC(19,4) NOT NULL DEFAULT 0.0,
    
    -- Audit fields (recommended additions)
    last_updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    last_transaction_id BIGINT, -- Optional: track last transaction that updated this
    
    -- Constraints
    UNIQUE(cash_desk_id, currency_id), -- One entry per cash desk per currency
    CHECK (overdraft_amount >= 0) -- Overdraft can't be negative
);

-- Indexes
CREATE INDEX idx_cash_desk_entries_cash_desk ON cash_desk_entries(cash_desk_id);
CREATE INDEX idx_cash_desk_entries_currency ON cash_desk_entries(currency_id);
CREATE INDEX idx_cash_desk_entries_negative ON cash_desk_entries(amount) WHERE amount < 0;

-- Function to update timestamp on balance change
CREATE OR REPLACE FUNCTION update_cash_desk_entry_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_cash_desk_entry_timestamp
BEFORE UPDATE ON cash_desk_entries
FOR EACH ROW
EXECUTE FUNCTION update_cash_desk_entry_timestamp();
```

### Schema Changes Required:

1. **Data Types:**
   - ✅ `bigint` → `BIGINT` (same)
   - ✅ `decimal` → `NUMERIC(19,4)` (verify precision first!)
   - ⚠️ **CRITICAL:** Verify SQL Server decimal precision before migration

2. **Naming Conventions:**
   - `Owner` → `cash_desk_id` (clearer semantics)
   - `Currency` → `currency_id` (consistent naming)
   - `Amount` → `amount` (lowercase)
   - `OverdraftAmount` → `overdraft_amount` (snake_case)

3. **Constraints:**
   - ✅ Add UNIQUE constraint on (cash_desk_id, currency_id) - prevents duplicates
   - ✅ Add CHECK constraint: overdraft_amount >= 0
   - ✅ Optional: CHECK constraint for reasonable balance ranges

4. **Enhancements (PostgreSQL):**
   - Add `last_updated_at` timestamp for audit trail
   - Add `last_transaction_id` to trace balance changes
   - Add partial index for negative balances (deficit monitoring)
   - Add trigger for automatic timestamp update

### Data Migration Script:

```sql
-- Step 1: Verify DECIMAL precision in source
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'doCashDesk-Entries'
  AND COLUMN_NAME IN ('Amount', 'OverdraftAmount');
-- Must verify before proceeding!

-- Step 2: Pre-migration validation
SELECT 
    COUNT(*) as total_entries,
    COUNT(CASE WHEN Amount IS NULL THEN 1 END) as null_amounts,
    COUNT(CASE WHEN OverdraftAmount IS NULL THEN 1 END) as null_overdrafts,
    MIN(Amount) as min_amount,
    MAX(Amount) as max_amount,
    SUM(Amount) as total_amount
FROM [doCashDesk-Entries];
-- Expected: 94 total, 0 nulls, sum = 31,914,777.24 (36.7M BGN - 4.8M EUR)

-- Step 3: Migrate data
INSERT INTO cash_desk_entries (id, cash_desk_id, currency_id, amount, overdraft_amount)
SELECT 
    ID,
    Owner,
    Currency,
    Amount,
    OverdraftAmount
FROM [doCashDesk-Entries]
ORDER BY ID;

-- Step 4: Set sequence to max ID + 1
SELECT setval('cash_desk_entries_id_seq', (SELECT MAX(id) FROM cash_desk_entries) + 1);

-- Step 5: Post-migration validation
SELECT 
    COUNT(*) as migrated_entries,
    SUM(amount) as total_amount,
    COUNT(DISTINCT cash_desk_id) as unique_cash_desks,
    COUNT(DISTINCT currency_id) as unique_currencies
FROM cash_desk_entries;
-- Expected: 94 entries, 31.9M total, 50 desks, 3 currencies

-- Step 6: Validate against source
-- Run this in both databases and compare results
SELECT 
    currency_id,
    COUNT(*) as entries,
    SUM(amount) as total_balance,
    SUM(overdraft_amount) as total_overdraft
FROM cash_desk_entries
GROUP BY currency_id
ORDER BY currency_id;

-- Step 7: Check for orphaned references
SELECT 
    ce.id,
    ce.cash_desk_id,
    ce.currency_id
FROM cash_desk_entries ce
LEFT JOIN cash_desks cd ON ce.cash_desk_id = cd.id
LEFT JOIN currencies c ON ce.currency_id = c.id
WHERE cd.id IS NULL OR c.id IS NULL;
-- Expected: 0 rows (all FKs valid)
```

### Estimated Migration Time: 2-3 hours

**Breakdown:**
- DECIMAL precision verification: 30 min
- Schema creation: 30 min
- Data migration: 15 min (94 records)
- Trigger/procedure analysis: 60 min ⚠️ (critical - must find balance update logic)
- Validation & testing: 45 min
- Documentation: 30 min

---

## ❓ Stakeholder Questions

### Critical Business Questions:
1. **EUR Deficit Explanation:**
   - Why is total EUR balance -4.8M EUR?
   - Is this a normal credit line usage or accounting error?
   - What's the business reason for 100M EUR overdraft on Прокредит?

2. **Balance Update Mechanism:**
   - How are balances updated? Triggers? Stored procedures? Application code?
   - Is there a nightly reconciliation process?
   - How often do balances get recalculated?

3. **Historical Tracking:**
   - Where is historical balance data stored?
   - Can we reconstruct balance history from transaction tables?
   - Is there an audit trail for balance changes?

4. **Overdraft Management:**
   - Who approves overdraft limits?
   - How often are limits reviewed?
   - Any alerting when approaching overdraft limit?

### Technical Questions:
5. **DECIMAL Precision:**
   - What is the exact precision/scale of Amount and OverdraftAmount?
   - Has there ever been rounding issues?
   - Do we need more than 2 decimal places for any currency?

6. **Currency 21 (Unknown):**
   - What is Currency ID=21? (USD? CHF? GBP?)
   - Why is it configured but never used?
   - Should we migrate it or exclude zero-balance currencies?

7. **Balance Reconciliation:**
   - Is there a daily balance reconciliation report?
   - How do you verify balance accuracy?
   - What happens if balances don't match transaction sums?

8. **Multi-Currency Operations:**
   - Do physical cash desks (Type=1) actually handle EUR/USD?
   - Or are multi-currency entries only for bank accounts?
   - How do you handle currency exchange in cash registers?

---

## 🚨 Migration Risks

### High Priority:
1. **DECIMAL Precision Loss**
   - **Risk:** If source uses higher precision than target, rounding errors will corrupt financial data
   - **Mitigation:** 
     - Query exact NUMERIC_PRECISION and NUMERIC_SCALE from SQL Server
     - Use same or higher precision in PostgreSQL
     - Run pre/post migration checksum validation: `SUM(Amount)` must match exactly
     - Test with maximum precision values (e.g., 15,164,666.24)

2. **Balance Update Logic Migration**
   - **Risk:** Missing triggers/procedures that update balances = broken financial system
   - **Mitigation:**
     - Search SQL Server for triggers on `doCashDesk-Entries`
     - Search for stored procedures that UPDATE this table
     - Map all balance update paths (transactions → entries)
     - Rewrite triggers/procedures in PostgreSQL before going live
     - Test balance updates thoroughly in staging

3. **EUR Deficit Investigation**
   - **Risk:** -4.8M EUR deficit might be data error, not business reality
   - **Mitigation:**
     - Validate with accounting team BEFORE migration
     - Cross-check with bank statements
     - If error, correct in source before migrating
     - Document as known issue if legitimate business state

### Medium Priority:
4. **Unique Constraint Violation**
   - **Risk:** Adding UNIQUE(cash_desk_id, currency_id) might fail if duplicates exist
   - **Mitigation:**
     - Run duplicate check before migration:
       ```sql
       SELECT Owner, Currency, COUNT(*)
       FROM [doCashDesk-Entries]
       GROUP BY Owner, Currency
       HAVING COUNT(*) > 1;
       ```
     - If duplicates found, investigate and merge before migration

5. **Orphaned Currency References**
   - **Risk:** Currency 21 might not exist in doCurrency table
   - **Mitigation:**
     - Validate all currency FKs before migration
     - Identify Currency 21 in doCurrency table
     - Document unused currencies

6. **Sequence Initialization**
   - **Risk:** If new cash desks created during migration, ID conflicts possible
   - **Mitigation:**
     - Freeze cash desk creation during migration window
     - Set PostgreSQL sequence to MAX(ID) + 1000 for safety buffer
     - Test sequence generation post-migration

### Low Priority:
7. **Negative Balance Alerts**
   - **Risk:** No monitoring for deficit positions after migration
   - **Mitigation:**
     - Create PostgreSQL view for negative balances
     - Set up alerting for balances < 0 or approaching overdraft limit
     - Dashboard for treasury team

---

## 📝 Notes

### Key Insights:
1. **Balance Snapshot Architecture:** This table is NOT a transaction log. It's a pre-calculated snapshot of current balances for fast querying. The true source of truth is transaction tables.

2. **Multi-Currency Design:** The pattern of "one row per cash desk per currency" is clean and scalable. Each entry represents a separate currency position.

3. **EUR Deficit is Critical:** The -4.8M EUR deficit across 30 accounts is a major financial finding. This needs immediate stakeholder validation before migration.

4. **Huge Overdraft Limits:** The 118M EUR total overdraft (especially 100M on Прокредит EUR) suggests either:
   - Major international operations with large credit facilities
   - Data entry error (100M seems excessive for a retail business)
   - Legacy/incorrect configuration

5. **BGN Operations are Healthy:** 36.7M BGN positive balance shows strong domestic currency position. The business is clearly BGN-centric with EUR as secondary (and problematic) currency.

6. **Inactive Entries:** 14 zero-balance BGN entries + 18 zero-balance EUR entries = 32 zero records (34% of table). These likely represent inactive/historical cash desks but are retained for system integrity.

### Technical Debt Observations:
- **Missing Audit Trail:** No timestamp fields to track when balances changed
- **No Balance History:** Can't reconstruct balance over time without re-processing all transactions
- **Unclear Update Mechanism:** Need to find triggers/procedures that maintain balances
- **No Validation Logic:** No CHECK constraints on reasonable balance ranges

### PostgreSQL Improvements:
- Add `last_updated_at` timestamp
- Add `last_transaction_id` for traceability
- Add CHECK constraints for data validation
- Add partial indexes for negative balances (deficit monitoring)
- Consider materialized view for balance history (if needed)

### Migration Priority:
**HIGH** - This table is critical for financial reporting but:
- Must migrate AFTER `doCashDesk` and `doCurrency` (FK dependencies)
- Must migrate BEFORE any transaction processing tables are tested
- Must validate balance update logic works in PostgreSQL before going live

---

## ✅ Analysis Complete

**Status:** ✅ DONE  
**Complexity:** 2/5 (Low-Medium)  
**Time Estimate:** 2-3 hours migration + trigger analysis  
**Priority:** HIGH (critical financial data)  
**Dependencies:** 
  - MUST migrate AFTER: doCurrency, doCashDesk
  - MUST investigate: Triggers and stored procedures that update balances

---

## 🚨 CRITICAL ACTION ITEMS BEFORE MIGRATION

1. **IMMEDIATE:** Investigate -4.8M EUR deficit with finance team
2. **IMMEDIATE:** Verify 100M EUR overdraft on Прокредит is correct
3. **BEFORE MIGRATION:** Find and document all balance update triggers/procedures
4. **BEFORE MIGRATION:** Verify DECIMAL precision in SQL Server
5. **AFTER MIGRATION:** Test balance updates end-to-end in staging

---

**Next Tables in Financial Domain:**
1. ✅ doCashDesk (DONE)
2. ✅ doCashDesk-Entries (DONE)
3. 🔄 doCurrency (prerequisite - should analyze next)
4. 🔄 doFinanceTransaction (main transaction table)
5. 🔄 doFinanceTransaction-Items (transaction line items)

---

**Migration Order Recommendation:**
```
1. doCurrency (prerequisite for both)
2. doCashDesk (master data)
3. doCashDesk-Entries (depends on 1 & 2)
4. Transaction tables (depend on all above)
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-10  
**Validated By:** Светльо + Claude  
**Status:** Ready for stakeholder review of EUR deficit findings

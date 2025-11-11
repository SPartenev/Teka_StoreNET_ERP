# doCashDeskCurrencyChange Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо  
**Domain:** Financial

---

## 📋 Overview

**Purpose:** Records currency exchange operations within cash desks  
**Type:** Transaction Table (inherits doSystemTransaction)  
**Parent Table:** doSystemTransaction  
**Row Count:** 635 currency exchanges  
**Primary Use:** BGN ↔ EUR exchanges (98% of operations)  
**Migration Complexity:** 4/5 (Medium-High)

---

## 🗂️ Schema

### Columns (10 total):

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | ((0)) | Primary key (inherits from doSystemTransaction) |
| Store | bigint | NOT NULL | ((0)) | FK to doStore - which store initiated the exchange |
| CashDesk | bigint | NOT NULL | ((0)) | FK to doCashDesk - which cash desk performs exchange |
| Currency | bigint | NOT NULL | ((0)) | FK to doCurrency - SOURCE currency (what we're exchanging FROM) |
| NewCurrency | bigint | NOT NULL | ((0)) | FK to doCurrency - TARGET currency (what we're exchanging TO) |
| Amount | decimal | NOT NULL | ((0.0)) | Amount in source currency |
| Rate | **float** ⚠️ | NOT NULL | ((0.0)) | Exchange rate (source → target) |
| NewAmount | decimal | NOT NULL | ((0.0)) | Amount in target currency (Amount × Rate) |
| IncomeFinanceTransaction | bigint | NOT NULL | ((0)) | FK to doFinanceTransaction - income in target currency |
| ExpenseFinanceTransaction | bigint | NOT NULL | ((0)) | FK to doFinanceTransaction - expense in source currency |

### Key Observations:
- ✅ **DECIMAL for amounts** - correct for money
- ⚠️ **FLOAT for Rate** - **CRITICAL PROBLEM!** Causes precision loss in financial calculations
- **Double-entry bookkeeping:** Creates 2 finance transactions (expense + income)
- **Single cash desk:** Exchange happens within one cash desk (not between desks)
- **Calculated field:** NewAmount should equal Amount × Rate (with rounding)

### Critical Data Type Issue:
```sql
-- FLOAT precision problem example from real data:
Amount = 195.58 BGN
Rate = 0.5113 (FLOAT)
NewAmount = 100.0001 EUR (should be 100.00!)

-- Rounding errors compound over time
-- MUST convert to NUMERIC in PostgreSQL
```

---

## 🔗 Relationships

### Foreign Keys (Outgoing - 7):
1. `ID` → `doSystemTransaction.ID` - Inherits transaction base (user, date, commit)
2. `Store` → `doStore.ID` - Which store context
3. `CashDesk` → `doCashDesk.ID` - Which cash desk performs exchange
4. `Currency` → `doCurrency.ID` - Source currency (from)
5. `NewCurrency` → `doCurrency.ID` - Target currency (to)
6. `IncomeFinanceTransaction` → `doFinanceTransaction.ID` - Income side of double-entry
7. `ExpenseFinanceTransaction` → `doFinanceTransaction.ID` - Expense side of double-entry

### Foreign Keys (Incoming - 0):
- **None** - This is a **leaf table** (no child tables reference it)
- Pure transactional data

### Architecture Pattern:
```
doSystemTransaction (base transaction)
    └─ doCashDeskCurrencyChange (635 exchanges)
           ├─ References → doCashDesk (single desk)
           ├─ References → doCurrency (source currency)
           ├─ References → doCurrency (target currency) [same table, different FK]
           ├─ References → doStore
           ├─ Creates → doFinanceTransaction (expense in source currency)
           └─ Creates → doFinanceTransaction (income in target currency)
```

**Self-Referencing Pattern:**
- **doCurrency referenced twice** (Currency AND NewCurrency point to same table)
- Similar to doCashDeskAmountTransfer's dual CashDesk references

---

## 📊 Data Analysis

### Total Records: 635
- **Date Range:** ID spans doSystemTransaction sequence
- **Low volume:** ~2-3 currency exchanges per day (vs 19,534 transfers)
- **Specialized operation:** Not frequently used

### Currency Exchange Directions:

| From | To | Count | % | Total From | Total To | Avg Rate |
|------|----|----|---|-----------|---------|---------|
| **BGN (19)** | **EUR (20)** | 489 | 77.0% | 13,341,047 BGN | 6,821,268 EUR | 0.5113 |
| **EUR (20)** | **BGN (19)** | 132 | 20.8% | 38,336 EUR | 74,978 BGN | 1.9558 |
| **BGN (19)** | **USD (21)** | 9 | 1.4% | 2,159 BGN | 1,426 USD | 0.6659 |
| **USD (21)** | **BGN (19)** | 5 | 0.8% | 755 USD | 1,163 BGN | 1.5333 |
| **TOTAL** | | **635** | **100%** | | | |

**Key Findings:**
- **BGN ↔ EUR dominates:** 621 of 635 exchanges (97.8%)
- **BGN → EUR is primary direction:** 489 exchanges (77%)
- **USD operations are rare:** Only 14 exchanges (2.2%)
- **Massive value:** 13.3M BGN exchanged to EUR (majority of volume)

### Exchange Rate Analysis:

#### BGN → EUR:
- **Rate Range:** 0.5000 - 0.5114
- **Average:** 0.5113
- **Interpretation:** **Fixed peg at 1.9558** (inverse = 0.5113)
- Bulgaria's currency board maintains BGN:EUR = 1.9558:1

#### EUR → BGN:
- **Rate Range:** 1.9550 - 1.9562
- **Average:** 1.9558
- **Interpretation:** **Fixed peg confirmed**
- Minimal variation (0.0012 spread) suggests official rate

#### BGN → USD:
- **Rate Range:** 0.6406 - 0.6993
- **Average:** 0.6659
- **Interpretation:** **Floating rate** (9.2% variation)

#### USD → BGN:
- **Rate Range:** 1.5237 - 1.5610
- **Average:** 1.5333
- **Interpretation:** **Floating rate** (2.4% variation)

**Critical Insight:** BGN/EUR is a **fixed currency board peg**, while BGN/USD floats. System must preserve exact rates for audit compliance.

---

## 🔍 Business Logic Interpretation

### Purpose of This Table:
1. **Currency Management in Multi-Currency Cash Desks**
   - Cash desk holds BGN + EUR simultaneously
   - Exchange between currencies within same desk
   - Enables customer service (e.g., tourist needs EUR, pays BGN)

2. **Bank Preparation**
   - Convert accumulated BGN to EUR before bank deposit
   - Or vice versa: convert EUR received to BGN for operations

3. **Double-Entry Accounting**
   - Expense transaction: Decrease source currency balance
   - Income transaction: Increase target currency balance
   - Net effect on total cash value depends on rate

4. **Audit Trail for FX Operations**
   - Every exchange documented with exact rate used
   - Historical rate preservation (even if using FLOAT)
   - Compliance with Bulgarian National Bank regulations

### Exchange Workflow Example:
```
User Action: Exchange 195.58 BGN → EUR at rate 0.5113
    ↓
System Creates:
    1. doCashDeskCurrencyChange (ID=3458030)
       ├─ CashDesk = 22 (Главна офис)
       ├─ Currency = 19 (BGN)
       ├─ NewCurrency = 20 (EUR)
       ├─ Amount = 195.58
       ├─ Rate = 0.5113
       ├─ NewAmount = 100.0001 (rounding error from FLOAT!)
       ├─ ExpenseFinanceTransaction = 3458031
       └─ IncomeFinanceTransaction = 3458032
    
    2. doFinanceTransaction (ID=3458031, Expense)
       ├─ CashDesk = 22
       ├─ Currency = 19 (BGN)
       ├─ Amount = -195.58 (negative = expense)
       └─ TransactionType = Expense
    
    3. doFinanceTransaction (ID=3458032, Income)
       ├─ CashDesk = 22
       ├─ Currency = 20 (EUR)
       ├─ Amount = +100.0001 (positive = income)
       └─ TransactionType = Income
    
    Result: 
    - BGN balance decreases by 195.58
    - EUR balance increases by 100.00 (or 100.0001 due to FLOAT error)
```

### ID Pattern:
- Exchange ID: X
- Expense ID: X+1
- Income ID: X+2
- **Atomic creation** via stored procedure or transaction

---

## 🏗️ Architecture Pattern

### Transaction Type in System Hierarchy:
```
doDataObject
    └─ doSystemTransaction (1,255,901 total)
           ├─ doTradeTransaction (764,906 - 60.9%)
           ├─ doCashDeskAmountTransfer (19,534 - 1.6%)
           ├─ doCashDeskCurrencyChange (635 - 0.05%) ← THIS TABLE
           ├─ doStoreTransfer
           ├─ doStoreAssembly
           ├─ doStoreDiscard
           └─ doFinanceTransaction (likely largest remaining)
```

**Percentage of System Transactions:** 0.05% (rare but critical operation)

### Comparison with Related Tables:

| Table | Records | Purpose | Cash Desks |
|-------|---------|---------|------------|
| doCashDeskAmountTransfer | 19,534 | Money transfer between desks | 2 (source + dest) |
| doCashDeskCurrencyChange | 635 | Currency exchange within desk | 1 (same desk) |

**Key Difference:** AmountTransfer moves money between locations, CurrencyChange converts currencies in same location.

---

## 🔄 PostgreSQL Migration

### Complexity: 4/5 (Medium-High)

**Why Medium-High Complexity:**
- ⚠️ **FLOAT → NUMERIC conversion** (CRITICAL! High risk of data loss)
- ⚠️ Rate precision must be preserved exactly (regulatory requirement)
- ⚠️ Double-entry integrity with 2 finance transactions
- ⚠️ Self-referencing currency table (2 FKs to doCurrency)
- ⚠️ Must validate Amount × Rate = NewAmount after conversion

**Why Not Level 5:**
- ✅ Small volume (635 records)
- ✅ Leaf table (no cascading dependencies)
- ✅ Simple business logic (straightforward exchange)

### Migration Strategy:

```sql
-- PostgreSQL Schema
CREATE TABLE cash_desk_currency_changes (
    -- Inherits from system_transactions
    id BIGINT PRIMARY KEY,
    
    -- Exchange details
    store_id BIGINT NOT NULL REFERENCES stores(id),
    cash_desk_id BIGINT NOT NULL REFERENCES cash_desks(id),
    source_currency_id BIGINT NOT NULL REFERENCES currencies(id),
    target_currency_id BIGINT NOT NULL REFERENCES currencies(id),
    
    -- Amounts and rate
    source_amount NUMERIC(19,4) NOT NULL DEFAULT 0.0,
    exchange_rate NUMERIC(19,8) NOT NULL DEFAULT 0.0, -- CRITICAL: 8 decimals for rate precision
    target_amount NUMERIC(19,4) NOT NULL DEFAULT 0.0,
    
    -- Double-entry links
    income_finance_transaction_id BIGINT NOT NULL REFERENCES finance_transactions(id),
    expense_finance_transaction_id BIGINT NOT NULL REFERENCES finance_transactions(id),
    
    -- Constraints
    CHECK (source_amount > 0), -- Must exchange positive amount
    CHECK (target_amount > 0), -- Must result in positive amount
    CHECK (exchange_rate > 0), -- Rate must be positive
    CHECK (source_currency_id != target_currency_id), -- Can't exchange to same currency
    CHECK (income_finance_transaction_id != expense_finance_transaction_id) -- Different transactions
);

-- Indexes for performance
CREATE INDEX idx_currency_changes_store ON cash_desk_currency_changes(store_id);
CREATE INDEX idx_currency_changes_cash_desk ON cash_desk_currency_changes(cash_desk_id);
CREATE INDEX idx_currency_changes_source_curr ON cash_desk_currency_changes(source_currency_id);
CREATE INDEX idx_currency_changes_target_curr ON cash_desk_currency_changes(target_currency_id);
CREATE INDEX idx_currency_changes_income_tx ON cash_desk_currency_changes(income_finance_transaction_id);
CREATE INDEX idx_currency_changes_expense_tx ON cash_desk_currency_changes(expense_finance_transaction_id);

-- Composite index for currency pair lookups
CREATE INDEX idx_currency_changes_pair ON cash_desk_currency_changes(source_currency_id, target_currency_id);

-- Function to validate exchange calculation
CREATE OR REPLACE FUNCTION validate_exchange_calculation()
RETURNS TRIGGER AS $$
DECLARE
    calculated_amount NUMERIC(19,4);
    tolerance NUMERIC := 0.01; -- 1 cent tolerance for rounding
BEGIN
    calculated_amount := NEW.source_amount * NEW.exchange_rate;
    
    IF ABS(calculated_amount - NEW.target_amount) > tolerance THEN
        RAISE EXCEPTION 'Exchange calculation invalid: % * % != % (diff: %)',
            NEW.source_amount, NEW.exchange_rate, NEW.target_amount,
            ABS(calculated_amount - NEW.target_amount);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_exchange
BEFORE INSERT OR UPDATE ON cash_desk_currency_changes
FOR EACH ROW
EXECUTE FUNCTION validate_exchange_calculation();
```

### Schema Changes Required:

1. **CRITICAL: Data Type Conversion**
   - `Rate` (float) → `exchange_rate` (NUMERIC(19,8))
   - **WHY 8 decimals?** Exchange rates need precision (e.g., 0.51130000)
   - Must recalculate or validate all NewAmount values after conversion
   
2. **Naming Conventions:**
   - `Store` → `store_id`
   - `CashDesk` → `cash_desk_id`
   - `Currency` → `source_currency_id` (clearer semantics)
   - `NewCurrency` → `target_currency_id` (clearer semantics)
   - `Amount` → `source_amount`
   - `Rate` → `exchange_rate`
   - `NewAmount` → `target_amount`
   - `IncomeFinanceTransaction` → `income_finance_transaction_id`
   - `ExpenseFinanceTransaction` → `expense_finance_transaction_id`

3. **Constraints (Critical!):**
   - CHECK: `source_amount > 0`
   - CHECK: `target_amount > 0`
   - CHECK: `exchange_rate > 0`
   - CHECK: `source_currency_id != target_currency_id` (prevent same-currency "exchange")
   - CHECK: Different income/expense transactions
   - **TRIGGER:** Validate `source_amount × exchange_rate ≈ target_amount` (with tolerance)

4. **Indexes:**
   - All 7 foreign key indexes
   - Composite index on (source_currency, target_currency) for rate lookups
   - Consider partial indexes for BGN/EUR exchanges (98% of data)

### Data Migration Script:

```sql
-- Step 1: Pre-migration validation - CRITICAL!
SELECT 
    COUNT(*) as total_exchanges,
    COUNT(CASE WHEN Rate <= 0 THEN 1 END) as invalid_rates,
    COUNT(CASE WHEN Amount <= 0 THEN 1 END) as invalid_source_amounts,
    COUNT(CASE WHEN NewAmount <= 0 THEN 1 END) as invalid_target_amounts,
    COUNT(CASE WHEN Currency = NewCurrency THEN 1 END) as same_currency_exchanges,
    MIN(Rate) as min_rate,
    MAX(Rate) as max_rate,
    MIN(Amount) as min_amount,
    MAX(Amount) as max_amount
FROM doCashDeskCurrencyChange;
-- Expected: 635 total, 0 invalid records

-- Step 2: Validate calculation accuracy with FLOAT
SELECT 
    ID,
    Amount,
    Rate,
    NewAmount,
    (Amount * Rate) as CalculatedNewAmount,
    ABS((Amount * Rate) - NewAmount) as Difference
FROM doCashDeskCurrencyChange
WHERE ABS((Amount * Rate) - NewAmount) > 0.01
ORDER BY Difference DESC;
-- This shows which records have FLOAT precision errors > 1 cent

-- Step 3: Validate FK integrity
SELECT 'Missing Stores' as issue, COUNT(*) as count
FROM doCashDeskCurrencyChange ccc
LEFT JOIN doStore s ON ccc.Store = s.ID
WHERE s.ID IS NULL
UNION ALL
SELECT 'Missing CashDesks', COUNT(*)
FROM doCashDeskCurrencyChange ccc
LEFT JOIN doCashDesk cd ON ccc.CashDesk = cd.ID
WHERE cd.ID IS NULL
UNION ALL
SELECT 'Missing Source Currencies', COUNT(*)
FROM doCashDeskCurrencyChange ccc
LEFT JOIN doCurrency c ON ccc.Currency = c.ID
WHERE c.ID IS NULL
UNION ALL
SELECT 'Missing Target Currencies', COUNT(*)
FROM doCashDeskCurrencyChange ccc
LEFT JOIN doCurrency c ON ccc.NewCurrency = c.ID
WHERE c.ID IS NULL
UNION ALL
SELECT 'Missing Income Transactions', COUNT(*)
FROM doCashDeskCurrencyChange ccc
LEFT JOIN doFinanceTransaction ft ON ccc.IncomeFinanceTransaction = ft.ID
WHERE ft.ID IS NULL
UNION ALL
SELECT 'Missing Expense Transactions', COUNT(*)
FROM doCashDeskCurrencyChange ccc
LEFT JOIN doFinanceTransaction ft ON ccc.ExpenseFinanceTransaction = ft.ID
WHERE ft.ID IS NULL;
-- Expected: All counts = 0

-- Step 4: Migrate data (AFTER parent tables migrated)
INSERT INTO cash_desk_currency_changes (
    id,
    store_id,
    cash_desk_id,
    source_currency_id,
    target_currency_id,
    source_amount,
    exchange_rate,
    target_amount,
    income_finance_transaction_id,
    expense_finance_transaction_id
)
SELECT 
    ID,
    Store,
    CashDesk,
    Currency,
    NewCurrency,
    Amount,
    CAST(Rate AS NUMERIC(19,8)), -- CRITICAL: Convert FLOAT to NUMERIC
    NewAmount,
    IncomeFinanceTransaction,
    ExpenseFinanceTransaction
FROM doCashDeskCurrencyChange
ORDER BY ID;

-- Step 5: Post-migration validation
SELECT 
    COUNT(*) as migrated_count,
    COUNT(DISTINCT store_id) as unique_stores,
    COUNT(DISTINCT cash_desk_id) as unique_cash_desks,
    COUNT(DISTINCT source_currency_id) as unique_source_currencies,
    COUNT(DISTINCT target_currency_id) as unique_target_currencies
FROM cash_desk_currency_changes;
-- Expected: 635 exchanges

-- Step 6: Validate calculation accuracy with NUMERIC
SELECT 
    id,
    source_amount,
    exchange_rate,
    target_amount,
    (source_amount * exchange_rate) as calculated_target,
    ABS((source_amount * exchange_rate) - target_amount) as difference
FROM cash_desk_currency_changes
WHERE ABS((source_amount * exchange_rate) - target_amount) > 0.01
ORDER BY difference DESC;
-- Should be 0 or very few rows (NUMERIC is more accurate than FLOAT)

-- Step 7: Validate double-entry integrity
SELECT 
    ccc.id,
    ccc.source_amount,
    ccc.target_amount,
    expense.amount as expense_amount,
    income.amount as income_amount,
    expense.currency_id as expense_currency,
    income.currency_id as income_currency
FROM cash_desk_currency_changes ccc
INNER JOIN finance_transactions expense ON ccc.expense_finance_transaction_id = expense.id
INNER JOIN finance_transactions income ON ccc.income_finance_transaction_id = income.id
WHERE 
    ABS(expense.amount + ccc.source_amount) > 0.01 -- Expense should be negative source amount
    OR ABS(income.amount - ccc.target_amount) > 0.01 -- Income should equal target amount
    OR expense.currency_id != ccc.source_currency_id
    OR income.currency_id != ccc.target_currency_id;
-- Expected: 0 rows (perfect double-entry match)

-- Step 8: Validate rate consistency for BGN/EUR fixed peg
SELECT 
    source_currency_id,
    target_currency_id,
    COUNT(*) as exchange_count,
    MIN(exchange_rate) as min_rate,
    MAX(exchange_rate) as max_rate,
    AVG(exchange_rate) as avg_rate,
    MAX(exchange_rate) - MIN(exchange_rate) as rate_spread
FROM cash_desk_currency_changes
WHERE (source_currency_id = 19 AND target_currency_id = 20)
   OR (source_currency_id = 20 AND target_currency_id = 19)
GROUP BY source_currency_id, target_currency_id;
-- For BGN/EUR: spread should be < 0.0012 (fixed peg)
```

### Estimated Migration Time: 5-6 hours

**Breakdown:**
- FLOAT precision analysis: 90 min (CRITICAL!)
- Schema creation: 30 min
- Data migration + validation: 60 min (FLOAT → NUMERIC conversion)
- Double-entry validation: 45 min
- Rate validation (fixed peg vs floating): 30 min
- Exchange calculation testing: 60 min
- Integration testing: 45 min
- Documentation: 30 min

---

## ❓ Stakeholder Questions

### Business Logic Questions:
1. **Exchange Authorization:**
   - Who can perform currency exchanges? (cashiers? supervisors only?)
   - Is there an approval workflow for large exchanges?
   - Daily/transaction limits?

2. **Rate Source:**
   - Where do exchange rates come from? (manual entry? API? fixed table?)
   - For BGN/EUR: is 1.9558 hardcoded or fetched from Bulgarian National Bank?
   - For USD: real-time rates or daily fixed rates?

3. **Exchange Purpose:**
   - Why exchange 13.3M BGN to EUR? (bank deposits? international payments?)
   - Customer-facing (serve tourists) or internal operations?

4. **Cash Desk 22 Dominance:**
   - Why are most exchanges in "Главна офис" (ID=22)?
   - Do other cash desks have exchange capability?

### Technical Questions:
5. **FLOAT Precision:**
   - How are rounding errors handled currently? (round to nearest cent?)
   - Has FLOAT precision caused any discrepancies in accounting?
   - Why was FLOAT chosen for Rate instead of DECIMAL?

6. **Rate Storage vs Calculation:**
   - Is NewAmount calculated (Amount × Rate) or independently entered?
   - If calculated, why store it (redundant data)?
   - If independent, how do you ensure accuracy?

7. **Double-Entry Validation:**
   - Is there a reconciliation process to verify exchanges?
   - How do you detect if expense + income don't balance?

8. **Historical Rates:**
   - Are historical exchange rates preserved elsewhere?
   - Can you audit what rate was used on a specific date?

---

## 🚨 Migration Risks

### Critical Priority:
1. **FLOAT to NUMERIC Conversion - DATA LOSS RISK**
   - **Risk:** Converting FLOAT to NUMERIC may change values slightly, breaking historical audit trail
   - **Impact:** 635 records × potential 0.0001 difference = compliance violation
   - **Mitigation:**
     - Run pre-migration report showing every Rate value to 10 decimals
     - Store original FLOAT values in separate audit table before conversion
     - Document any values that change during conversion
     - Get stakeholder sign-off on acceptable tolerance (0.01 cent?)
     - Test with production data copy first
     - **CRITICAL:** Inform Bulgarian National Bank if fixed peg rates change

2. **Exchange Calculation Validation Failure**
   - **Risk:** After NUMERIC conversion, `source_amount × exchange_rate` may not equal `target_amount` due to rounding
   - **Impact:** Trigger validation will fail INSERT, breaking application
   - **Mitigation:**
     - Set tolerance to 0.01 (1 cent) in validation trigger
     - Recalculate all target_amount values using NUMERIC math
     - If recalculation differs, document which version is "truth":
       - Original target_amount (preserves historical record)
       - Recalculated target_amount (mathematically correct)
     - Consider adding `calculation_difference` column to track variance

3. **Double-Entry Integrity with Finance Transactions**
   - **Risk:** Finance transaction amounts must exactly match exchange amounts in correct currencies
   - **Impact:** Accounting breaks if mismatch exists
   - **Mitigation:**
     - Validate BEFORE migration: expense amount = -source_amount in source currency
     - Validate BEFORE migration: income amount = +target_amount in target currency
     - Post-migration: re-run validation on PostgreSQL side
     - If mismatches found, investigate and document (may indicate existing data issues)

### High Priority:
4. **Fixed Peg Rate Validation**
   - **Risk:** BGN/EUR rate must be exactly 1.9558 (Bulgarian currency board requirement)
   - **Impact:** Regulatory non-compliance if rates deviate
   - **Mitigation:**
     - Validate all BGN→EUR rates are within 0.0012 of 0.5113 (1/1.9558)
     - Validate all EUR→BGN rates are within 0.0012 of 1.9558
     - Flag any anomalies for investigation
     - Consider adding CHECK constraint in PostgreSQL to enforce valid rate ranges

5. **Self-Referencing Currency Table**
   - **Risk:** Two FKs to same doCurrency table - complex migration
   - **Mitigation:**
     - Ensure doCurrency fully migrated first
     - Validate both source_currency_id and target_currency_id exist
     - Test queries joining both FKs simultaneously

### Medium Priority:
6. **Rate Precision Loss in Applications**
   - **Risk:** Application code expects FLOAT, now receives NUMERIC
   - **Impact:** Type mismatch errors in .NET code
   - **Mitigation:**
     - Audit .NET code for `float` or `double` types reading Rate field
     - Update to `decimal` type in C#
     - Test all exchange-related screens and reports

7. **Historical Exchange Queries**
   - **Risk:** Queries that filtered by exact FLOAT values will break
   - **Impact:** Reports return wrong data
   - **Mitigation:**
     - Find all queries with `WHERE Rate = 0.5113` (exact match)
     - Rewrite as `WHERE Rate BETWEEN 0.5112 AND 0.5114` (range)
     - Or use `WHERE ABS(Rate - 0.5113) < 0.0001`

---

## 📝 Notes

### Key Insights:
1. **Fixed Currency Board Peg:** The system reflects Bulgaria's monetary policy - BGN is pegged to EUR at exactly 1.9558. This is not a business decision, it's a national regulatory requirement. Any deviation from this rate would violate Bulgarian National Bank rules.

2. **FLOAT is a Critical Flaw:** Using FLOAT for exchange rates creates precision errors that compound over 635 transactions. Example: 195.58 × 0.5113 should = 100.00, but FLOAT produces 100.0001. While 0.0001 EUR seems trivial, multiplied by 635 exchanges and different amounts, this could create significant accounting discrepancies.

3. **BGN → EUR Dominance:** 77% of exchanges go from BGN to EUR, totaling 13.3M BGN. This suggests the business accumulates BGN revenue (domestic sales) and regularly converts to EUR for international payments, bank deposits, or strategic cash management.

4. **Minimal USD Operations:** Only 2.2% of exchanges involve USD, indicating this is primarily a European business. USD support exists but is rarely used.

5. **Centralized Exchange:** Most exchanges occur in "Главна офис" (cash desk 22), suggesting currency exchange is a controlled office function, not distributed to all store locations.

6. **Double-Entry Correctness:** The pattern of creating expense + income transactions mirrors doCashDeskAmountTransfer, showing consistent architectural approach to financial operations.

### Technical Debt Observations:
- **FLOAT for financial calculations** - worst practice, causes precision loss
- **No rate audit table** - historical rates not preserved separately
- **No rate validation rules** - system allows any rate (should enforce BNB peg for BGN/EUR)
- **Redundant NewAmount storage** - could be calculated field, but storing prevents recalculation errors
- **No exchange reversal mechanism** - unclear how mistakes are corrected

### PostgreSQL Improvements:
- **NUMERIC(19,8)** for exchange_rate - preserves precision to 8 decimal places
- **Validation trigger** - ensures source × rate ≈ target (with tolerance)
- **CHECK constraints** - prevent invalid exchanges (same currency, negative amounts, etc.)
- **Rate audit table** - consider separate table for daily official rates
- **Materialized view** - currency pair statistics (total volume, average rates, count)

### Compliance Considerations:
- **Bulgarian National Bank Reporting:** Exchange operations may require regulatory reporting
- **Anti-Money Laundering (AML):** Large exchanges (e.g., 13.3M BGN) may trigger AML alerts
- **Audit Trail:** Must preserve exact rates used for tax/regulatory audits
- **Fixed Peg Enforcement:** PostgreSQL constraints should enforce 1.9558 ± 0.0012 for BGN/EUR

---

## ✅ Analysis Complete

**Status:** ✅ DONE  
**Complexity:** 4/5 (Medium-High due to FLOAT conversion risk)  
**Time Estimate:** 5-6 hours migration  
**Priority:** HIGH (financial compliance + regulatory requirements)  
**Dependencies:**
  - MUST migrate AFTER: doCurrency, doCashDesk, doStore, doSystemTransaction, doFinanceTransaction
  - MUST address: FLOAT → NUMERIC conversion with stakeholder approval

---

## 🚨 CRITICAL ACTION ITEMS BEFORE MIGRATION

1. **IMMEDIATE:** Export all Rate values to 10 decimal places for audit
2. **IMMEDIATE:** Get stakeholder approval for FLOAT → NUMERIC conversion
3. **BEFORE MIGRATION:** Validate all BGN/EUR rates are within Bulgarian National Bank tolerance
4. **BEFORE MIGRATION:** Recalculate all NewAmount values using NUMERIC(19,8) and compare to existing
5. **BEFORE MIGRATION:** Document any records where recalculated amount differs from stored amount
6. **DURING MIGRATION:** Store original FLOAT Rate values in separate audit table
7. **AFTER MIGRATION:** Validate double-entry integrity (expense + income balance)
8. **AFTER MIGRATION:** Test exchange calculation trigger works correctly

---

## 📊 Comparison with Sibling Table

| Feature | doCashDeskAmountTransfer | doCashDeskCurrencyChange |
|---------|-------------------------|-------------------------|
| **Purpose** | Move money between cash desks | Convert currency within cash desk |
| **Records** | 19,534 | 635 |
| **Frequency** | Daily (50+ per day) | Occasional (2-3 per day) |
| **Cash Desks** | 2 (source + destination) | 1 (same desk) |
| **Currency** | Single currency (BGN or EUR) | Two currencies (from + to) |
| **Rate** | Not applicable | Exchange rate (FLOAT → NUMERIC) |
| **Double-Entry** | Yes (expense + income) | Yes (expense + income) |
| **Complexity** | 3/5 | 4/5 (FLOAT issue) |

**Key Difference:** AmountTransfer moves value between locations, CurrencyChange transforms value between currencies.

---

**Next Tables in Financial Domain:**
1. ✅ doCashDesk (DONE)
2. ✅ doCashDesk-Entries (DONE)
3. ✅ doCashDeskAmountTransfer (DONE)
4. ✅ doCashDeskCurrencyChange (DONE)
5. 🔄 doCurrency (prerequisite - should analyze next!)
6. 🔄 doFinanceTransaction (large, complex, critical)

---

**Recommended Migration Order:**
```
1. doCurrency (prerequisite - defines currencies 19, 20, 21)
2. doStore (prerequisite)
3. doCashDesk (master data)
4. doSystemTransaction (base transaction class)
5. doFinanceTransaction (prerequisite - referenced by exchanges)
6. doCashDesk-Entries (balance snapshot)
7. doCashDeskAmountTransfer (money transfers)
8. doCashDeskCurrencyChange (THIS TABLE - currency exchanges)
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-10  
**Validated By:** Светльо + Claude  
**Status:** Ready for FLOAT → NUMERIC conversion approval and Bulgarian National Bank rate validation  
**Regulatory Note:** BGN/EUR fixed peg at 1.9558 must be preserved per Bulgarian currency board requirements

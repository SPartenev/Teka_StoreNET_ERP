# doCashDeskAmountTransfer Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо  
**Domain:** Financial

---

## 📋 Overview

**Purpose:** Records money transfers between cash desks and bank accounts  
**Type:** Transaction Table (inherits doSystemTransaction)  
**Parent Table:** doSystemTransaction  
**Row Count:** 19,534 transfers  
**Coverage:** 39 source cash desks, 38 destination cash desks across 8 stores  
**Migration Complexity:** 3/5 (Medium)

---

## 🗂️ Schema

### Columns (8 total):

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | ((0)) | Primary key (inherits from doSystemTransaction) |
| Store | bigint | NOT NULL | ((0)) | FK to doStore - which store initiated the transfer |
| CashDesk | bigint | NOT NULL | ((0)) | FK to doCashDesk - SOURCE cash desk (money leaving) |
| DestinationCashDesk | bigint | NOT NULL | ((0)) | FK to doCashDesk - DESTINATION cash desk (money entering) |
| Currency | bigint | NOT NULL | ((0)) | FK to doCurrency - which currency is transferred |
| Amount | decimal | NOT NULL | ((0.0)) | Transfer amount (always positive) |
| IncomeFinanceTransaction | bigint | NOT NULL | ((0)) | FK to doFinanceTransaction - income transaction for destination |
| ExpenseFinanceTransaction | bigint | NOT NULL | ((0)) | FK to doFinanceTransaction - expense transaction for source |

### Key Observations:
- ✅ **Uses DECIMAL for money** - correct financial data type
- **Double-entry bookkeeping:** Every transfer creates 2 finance transactions
  - Expense (debit) from source cash desk
  - Income (credit) to destination cash desk
- **Store context:** Transfer is associated with a specific store
- **Amount always positive:** Direction is determined by CashDesk vs DestinationCashDesk
- **Inherits from doSystemTransaction:** Gets user, date, commit status, etc.

### Double-Entry Architecture:
```
1 doCashDeskAmountTransfer (this table)
    ├─ Creates → 1 ExpenseFinanceTransaction (source loses money)
    └─ Creates → 1 IncomeFinanceTransaction (destination gains money)
```

---

## 🔗 Relationships

### Foreign Keys (Outgoing - 7):
1. `ID` → `doSystemTransaction.ID` - **Inherits transaction base** (user, date, commit)
2. `Store` → `doStore.ID` - Which store context
3. `CashDesk` → `doCashDesk.ID` - Source cash desk
4. `DestinationCashDesk` → `doCashDesk.ID` - Destination cash desk
5. `Currency` → `doCurrency.ID` - Transfer currency
6. `IncomeFinanceTransaction` → `doFinanceTransaction.ID` - Income side of double-entry
7. `ExpenseFinanceTransaction` → `doFinanceTransaction.ID` - Expense side of double-entry

### Foreign Keys (Incoming - 0):
- **None** - This is a **leaf table** (no child tables reference it)
- Pure transactional data

### Architecture Pattern:
```
doSystemTransaction (base transaction)
    └─ doCashDeskAmountTransfer (19,534 transfers)
           ├─ References → doCashDesk (source)
           ├─ References → doCashDesk (destination)
           ├─ References → doStore
           ├─ References → doCurrency
           ├─ Creates → doFinanceTransaction (expense)
           └─ Creates → doFinanceTransaction (income)
```

**Complex Multi-Reference Pattern:**
- **Self-referencing table** via doCashDesk (source AND destination point to same table)
- **Bi-directional financial impact** via 2 finance transactions
- **Atomic operation:** 1 transfer record + 2 finance transactions created together

---

## 📊 Data Analysis

### Total Records: 19,534
- **Date Range:** ID 63,212 → 3,487,696 (spans doSystemTransaction sequence)
- **Store Coverage:** 8 stores actively use transfers
- **Cash Desk Coverage:**
  - 39 unique source cash desks (76% of 51 total)
  - 38 unique destination cash desks (75% of 51 total)
  - High participation rate = transfers are core business process

### Transaction Volume by Currency:

| Currency | Count | % of Total | Total Amount | Avg Amount | Min | Max |
|----------|-------|------------|--------------|------------|-----|-----|
| **19 (BGN)** | 19,331 | 99.0% | 46,169,754 BGN | 2,388 BGN | 0.01 | 12,000,000 |
| **20 (EUR)** | 203 | 1.0% | 6,899,177 EUR | 33,986 EUR | 0.09 | 6,568,671 |
| **TOTAL** | 19,534 | 100% | - | - | - | - |

**Key Findings:**
- **BGN dominates:** 99% of all transfers are in BGN
- **EUR transfers are rare but large:** Only 1% of count, but average 14x bigger
- **Huge value range:** From 0.01 (symbolic) to 12M BGN (major bank deposits)
- **Total value moved:** ~46M BGN + ~7M EUR = substantial cash flow

---

## 🔍 Business Logic Interpretation

### Purpose of This Table:
1. **Daily Cash Management**
   - Store registers → Main office cash desk
   - Main office cash desk → Bank accounts
   - Inter-store cash balancing

2. **Bank Deposits**
   - Evidence of large transfers (up to 12M BGN)
   - Store cash accumulation → Bank deposit workflow

3. **Cash Distribution**
   - Reverse flow: Bank → Cash desk (rare but exists)
   - Cash desk → Cash desk (internal balancing)

4. **Audit Trail**
   - Every transfer documented with source, destination, amount
   - Links to 2 finance transactions for double-entry validation
   - Store context for accountability

### Common Transfer Patterns (from sample data):
1. **Store Register → Store Main Cash** (most common)
   - Example: Магазин Люлин → Главна Люлин (183.31 BGN)
   - Daily register closing

2. **Store Main Cash → Bank Account**
   - Example: Главна Гео → Райфайзен лева (4,500 BGN)
   - Weekly/daily bank deposits

3. **Office Cash ↔ Store Cash** (bidirectional)
   - Example: Каса офис Пловдив → Главна Пловдив (818.87 BGN)
   - Cash allocation/rebalancing

### Double-Entry Implementation:
**Hypothesis:** When transfer is created:
```sql
-- Pseudocode
BEGIN TRANSACTION
  -- 1. Create transfer record
  INSERT INTO doCashDeskAmountTransfer (ID, Store, CashDesk, DestinationCashDesk, ...)
  
  -- 2. Create expense transaction (source loses money)
  INSERT INTO doFinanceTransaction (ID as ExpenseID, CashDesk=Source, Amount=-X)
  
  -- 3. Create income transaction (destination gains money)
  INSERT INTO doFinanceTransaction (ID as IncomeID, CashDesk=Destination, Amount=+X)
  
  -- 4. Link back to transfer
  UPDATE doCashDeskAmountTransfer 
  SET ExpenseFinanceTransaction=ExpenseID, IncomeFinanceTransaction=IncomeID
COMMIT TRANSACTION
```

**ID Pattern:** Transfer ID and Finance Transaction IDs are consecutive:
- Transfer ID: 3487696
- Expense ID: 3487697 (ID + 1)
- Income ID: 3487698 (ID + 2)

This suggests atomic creation via shared sequence or stored procedure.

---

## 🏗️ Architecture Pattern

### Transaction Type in System Hierarchy:
```
doDataObject
    └─ doSystemTransaction (1,255,901 total)
           ├─ doTradeTransaction (764,906 - 60.9%)
           ├─ doCashDeskAmountTransfer (19,534 - 1.6%) ← THIS TABLE
           ├─ doCashDeskCurrencyChange
           ├─ doStoreTransfer
           ├─ doStoreAssembly
           ├─ doStoreDiscard
           └─ doFinanceTransaction (likely the largest remaining)
```

**Percentage of System Transactions:** 1.6% of all transactions are cash desk transfers.

### Double-Entry Bookkeeping Pattern:
```
User Action: Transfer 1,000 BGN from Store Cash → Bank
    ↓
System Creates:
    1. doCashDeskAmountTransfer (ID=100, Amount=1000)
       ├─ CashDesk=StoreID
       ├─ DestinationCashDesk=BankID
       ├─ ExpenseFinanceTransaction=101
       └─ IncomeFinanceTransaction=102
    
    2. doFinanceTransaction (ID=101, Expense)
       ├─ CashDesk=StoreID
       ├─ Amount=-1000 (negative = expense)
       └─ TransactionType=Expense
    
    3. doFinanceTransaction (ID=102, Income)
       ├─ CashDesk=BankID
       ├─ Amount=+1000 (positive = income)
       └─ TransactionType=Income
    
    Result: Net effect = 0 (store -1000, bank +1000)
```

**Benefits of This Design:**
- ✅ Atomic operations (all 3 records or none)
- ✅ Audit trail preservation (can't delete one side)
- ✅ Balance validation (expense + income = 0)
- ✅ Transaction history (who, when, why via doSystemTransaction)

---

## 🔄 PostgreSQL Migration

### Complexity: 3/5 (Medium)

**Why Medium Complexity:**
- ⚠️ Large volume (19,534 records)
- ⚠️ Complex multi-table relationships (7 FKs)
- ⚠️ Self-referencing (CashDesk table referenced twice)
- ⚠️ Double-entry integrity critical (must preserve links to 2 finance transactions)
- ⚠️ Inherits from doSystemTransaction (must migrate parent first)

**Why Not Higher:**
- ✅ Simple schema (8 columns)
- ✅ DECIMAL data type (already correct)
- ✅ No computed columns or complex business logic
- ✅ Leaf table (no cascading dependencies)

### Migration Strategy:

```sql
-- PostgreSQL Schema
CREATE TABLE cash_desk_amount_transfers (
    -- Inherits from system_transactions
    id BIGINT PRIMARY KEY,
    
    -- Transfer details
    store_id BIGINT NOT NULL REFERENCES stores(id),
    source_cash_desk_id BIGINT NOT NULL REFERENCES cash_desks(id),
    destination_cash_desk_id BIGINT NOT NULL REFERENCES cash_desks(id),
    currency_id BIGINT NOT NULL REFERENCES currencies(id),
    amount NUMERIC(19,4) NOT NULL DEFAULT 0.0,
    
    -- Double-entry links
    income_finance_transaction_id BIGINT NOT NULL REFERENCES finance_transactions(id),
    expense_finance_transaction_id BIGINT NOT NULL REFERENCES finance_transactions(id),
    
    -- Constraints
    CHECK (amount > 0), -- Amount must be positive
    CHECK (source_cash_desk_id != destination_cash_desk_id), -- Can't transfer to self
    CHECK (income_finance_transaction_id != expense_finance_transaction_id) -- Must be different transactions
);

-- Indexes for performance
CREATE INDEX idx_cash_desk_transfers_store ON cash_desk_amount_transfers(store_id);
CREATE INDEX idx_cash_desk_transfers_source ON cash_desk_amount_transfers(source_cash_desk_id);
CREATE INDEX idx_cash_desk_transfers_destination ON cash_desk_amount_transfers(destination_cash_desk_id);
CREATE INDEX idx_cash_desk_transfers_currency ON cash_desk_amount_transfers(currency_id);
CREATE INDEX idx_cash_desk_transfers_income_tx ON cash_desk_amount_transfers(income_finance_transaction_id);
CREATE INDEX idx_cash_desk_transfers_expense_tx ON cash_desk_amount_transfers(expense_finance_transaction_id);

-- Composite index for common queries (source + destination lookups)
CREATE INDEX idx_cash_desk_transfers_flow ON cash_desk_amount_transfers(source_cash_desk_id, destination_cash_desk_id);
```

### Schema Changes Required:

1. **Data Types:**
   - ✅ `bigint` → `BIGINT` (same)
   - ✅ `decimal` → `NUMERIC(19,4)` (verify precision!)
   
2. **Naming Conventions:**
   - `Store` → `store_id`
   - `CashDesk` → `source_cash_desk_id` (clearer semantics)
   - `DestinationCashDesk` → `destination_cash_desk_id`
   - `Currency` → `currency_id`
   - `Amount` → `amount`
   - `IncomeFinanceTransaction` → `income_finance_transaction_id`
   - `ExpenseFinanceTransaction` → `expense_finance_transaction_id`

3. **Constraints (Important!):**
   - ✅ CHECK: `amount > 0` (transfers can't be zero or negative)
   - ✅ CHECK: `source_cash_desk_id != destination_cash_desk_id` (prevent self-transfers)
   - ✅ CHECK: `income_finance_transaction_id != expense_finance_transaction_id` (must be different)

4. **Indexes:**
   - Primary key on `id`
   - Foreign key indexes on all 7 references
   - Composite index on (source, destination) for flow analysis
   - Consider partial indexes for currency-specific queries

### Data Migration Script:

```sql
-- Step 1: Pre-migration validation
SELECT 
    COUNT(*) as total_transfers,
    COUNT(CASE WHEN Amount <= 0 THEN 1 END) as invalid_amounts,
    COUNT(CASE WHEN CashDesk = DestinationCashDesk THEN 1 END) as self_transfers,
    COUNT(CASE WHEN IncomeFinanceTransaction = ExpenseFinanceTransaction THEN 1 END) as duplicate_transactions,
    MIN(Amount) as min_amount,
    MAX(Amount) as max_amount,
    SUM(Amount) as total_amount_bgn_eur
FROM doCashDeskAmountTransfer;
-- Expected: 19,534 total, 0 invalid/self/duplicate

-- Step 2: Validate FK integrity
SELECT 'Missing Stores' as issue, COUNT(*) as count
FROM doCashDeskAmountTransfer cat
LEFT JOIN doStore s ON cat.Store = s.ID
WHERE s.ID IS NULL
UNION ALL
SELECT 'Missing Source CashDesks', COUNT(*)
FROM doCashDeskAmountTransfer cat
LEFT JOIN doCashDesk cd ON cat.CashDesk = cd.ID
WHERE cd.ID IS NULL
UNION ALL
SELECT 'Missing Destination CashDesks', COUNT(*)
FROM doCashDeskAmountTransfer cat
LEFT JOIN doCashDesk cd ON cat.DestinationCashDesk = cd.ID
WHERE cd.ID IS NULL
UNION ALL
SELECT 'Missing Currencies', COUNT(*)
FROM doCashDeskAmountTransfer cat
LEFT JOIN doCurrency c ON cat.Currency = c.ID
WHERE c.ID IS NULL
UNION ALL
SELECT 'Missing Income Transactions', COUNT(*)
FROM doCashDeskAmountTransfer cat
LEFT JOIN doFinanceTransaction ft ON cat.IncomeFinanceTransaction = ft.ID
WHERE ft.ID IS NULL
UNION ALL
SELECT 'Missing Expense Transactions', COUNT(*)
FROM doCashDeskAmountTransfer cat
LEFT JOIN doFinanceTransaction ft ON cat.ExpenseFinanceTransaction = ft.ID
WHERE ft.ID IS NULL;
-- Expected: All counts = 0

-- Step 3: Migrate data (AFTER parent tables migrated)
INSERT INTO cash_desk_amount_transfers (
    id,
    store_id,
    source_cash_desk_id,
    destination_cash_desk_id,
    currency_id,
    amount,
    income_finance_transaction_id,
    expense_finance_transaction_id
)
SELECT 
    ID,
    Store,
    CashDesk,
    DestinationCashDesk,
    Currency,
    Amount,
    IncomeFinanceTransaction,
    ExpenseFinanceTransaction
FROM doCashDeskAmountTransfer
ORDER BY ID;

-- Step 4: Post-migration validation
SELECT 
    COUNT(*) as migrated_count,
    COUNT(DISTINCT store_id) as unique_stores,
    COUNT(DISTINCT source_cash_desk_id) as unique_sources,
    COUNT(DISTINCT destination_cash_desk_id) as unique_destinations,
    SUM(amount) as total_amount_check
FROM cash_desk_amount_transfers;
-- Expected: 19,534 transfers, 8 stores, 39 sources, 38 destinations

-- Step 5: Validate double-entry integrity
SELECT 
    cat.id,
    cat.amount,
    expense.amount as expense_amount,
    income.amount as income_amount,
    cat.amount + expense.amount + income.amount as net_should_be_zero
FROM cash_desk_amount_transfers cat
INNER JOIN finance_transactions expense ON cat.expense_finance_transaction_id = expense.id
INNER JOIN finance_transactions income ON cat.income_finance_transaction_id = income.id
WHERE ABS(cat.amount + expense.amount + income.amount) > 0.01;
-- Expected: 0 rows (net should always be zero: transfer - expense + income = 0)

-- Step 6: Validate constraint compliance
SELECT 
    COUNT(*) as self_transfer_violations
FROM cash_desk_amount_transfers
WHERE source_cash_desk_id = destination_cash_desk_id;
-- Expected: 0

SELECT 
    COUNT(*) as duplicate_transaction_violations
FROM cash_desk_amount_transfers
WHERE income_finance_transaction_id = expense_finance_transaction_id;
-- Expected: 0
```

### Estimated Migration Time: 4-5 hours

**Breakdown:**
- Schema creation: 30 min
- Data migration: 45 min (19,534 records + validations)
- Double-entry validation: 60 min (critical!)
- Index creation: 30 min
- Integration testing: 90 min (test transfer creation workflow)
- Documentation: 45 min

---

## ❓ Stakeholder Questions

### Business Logic Questions:
1. **Transfer Creation Process:**
   - Who can initiate transfers? (store managers? cashiers? admin only?)
   - Is there an approval workflow?
   - Can transfers be cancelled/reversed?

2. **Self-Transfer Validation:**
   - Should we enforce `CashDesk != DestinationCashDesk` at DB level?
   - Are there legitimate cases for same-source-destination (e.g., currency exchange)?

3. **Large Transfer Thresholds:**
   - 12M BGN and 6.5M EUR max transfers - are these legitimate?
   - Should there be business rules for transfer limits by user role?

4. **Store Context:**
   - Why is Store required? (transfers between stores?)
   - Can cross-store transfers happen? (Store A cashdesk → Store B cashdesk?)

### Technical Questions:
5. **Double-Entry Validation:**
   - How is double-entry integrity enforced? Triggers? Stored procedures?
   - What happens if one of the finance transactions fails to create?
   - Is there a reconciliation process to verify transfer = expense + income?

6. **ID Generation:**
   - Are Transfer ID, Expense ID, Income ID always consecutive? (ID, ID+1, ID+2)
   - How is this atomicity guaranteed?

7. **Finance Transaction Types:**
   - What are the exact values in doFinanceTransaction.TransactionType for these?
   - How do we distinguish transfer-related transactions from other types?

8. **Reverse Transfers:**
   - If a transfer needs to be undone, is a new reverse transfer created?
   - Or is the original transfer deleted/marked invalid?

---

## 🚨 Migration Risks

### High Priority:
1. **Double-Entry Integrity Loss**
   - **Risk:** If finance transactions don't migrate properly, accounting will break
   - **Mitigation:**
     - Migrate doFinanceTransaction BEFORE this table
     - Validate ALL FK references exist post-migration
     - Run double-entry validation script (sum must = 0)
     - Test transfer creation workflow end-to-end in staging

2. **Foreign Key Order Dependencies**
   - **Risk:** This table references 5 parent tables - wrong migration order = FK constraint errors
   - **Mitigation:**
     - **Migration order:**
       1. doCurrency
       2. doCashDesk
       3. doStore
       4. doSystemTransaction
       5. doFinanceTransaction
       6. **THEN** doCashDeskAmountTransfer
     - Document and enforce migration sequence
     - Pre-validate all FK references exist

3. **Large Transfer Amounts**
   - **Risk:** DECIMAL precision loss on 12M BGN transfers
   - **Mitigation:**
     - Verify exact NUMERIC precision in SQL Server
     - Use NUMERIC(19,4) or higher in PostgreSQL
     - Test max value migration: 12,000,000.00 → must match exactly

### Medium Priority:
4. **Self-Referencing Table**
   - **Risk:** doCashDesk referenced twice (source + destination) - complex migration
   - **Mitigation:**
     - Ensure doCashDesk fully migrated and indexed before this table
     - Test queries with both FK joins
     - Verify indexes exist on both CashDesk and DestinationCashDesk

5. **Sequence Initialization**
   - **Risk:** New transfers created during migration = ID conflicts
   - **Mitigation:**
     - Freeze transfer operations during migration window
     - PostgreSQL sequence inherits from system_transactions (shared sequence)
     - Set sequence start to MAX(ID) + 1 after migration

6. **Data Volume Performance**
   - **Risk:** 19,534 records = potential slow migration on large transaction table
   - **Mitigation:**
     - Use COPY or bulk insert for PostgreSQL
     - Disable indexes during import, rebuild after
     - Batch validation queries (don't validate all 19K in one query)

### Low Priority:
7. **Currency Distribution**
   - **Risk:** 99% BGN, 1% EUR - EUR transfers might have special handling
   - **Mitigation:**
     - Test both BGN and EUR transfer workflows
     - Validate currency-specific business rules
     - Check if EUR transfers have different approval process

---

## 📝 Notes

### Key Insights:
1. **Double-Entry Architecture is Robust:** The design with 2 separate finance transactions ensures accounting integrity. Every transfer is automatically balanced (source loses, destination gains).

2. **High Transaction Volume:** 19,534 transfers = active daily cash management. This is a core business process, not occasional admin task.

3. **BGN-Centric Operations:** 99% of transfers are in BGN, confirming this is primarily a domestic Bulgarian business. EUR transfers are rare but very large (14x average).

4. **Atomic Transaction Creation:** ID pattern (Transfer=X, Expense=X+1, Income=X+2) suggests stored procedure or trigger that creates all 3 records atomically. Must preserve this in PostgreSQL.

5. **Store Context Requirement:** Every transfer requires a Store reference, suggesting organizational/accountability tracking. Transfers are not anonymous.

6. **Comprehensive Coverage:** 76% of all cash desks participate in transfers, showing system-wide adoption.

### Technical Debt Observations:
- **No reversal mechanism visible:** Can transfers be cancelled? Reversed? Need to investigate.
- **No approval workflow fields:** Who approves large transfers (12M BGN)?
- **No timestamp on transfer:** Inherits from doSystemTransaction, but not visible in this table
- **No transfer type field:** All transfers treated equally (no priority, urgency, category)

### PostgreSQL Improvements:
- Add CHECK constraints to prevent invalid transfers
- Add trigger to validate double-entry balance on INSERT
- Consider materialized view for transfer flow analysis (source → destination patterns)
- Add partial indexes for currency-specific queries
- Implement transfer reversal procedure (create offsetting transactions)

### Business Process Documentation Needed:
- Document exact transfer creation workflow (UI → stored proc → 3 table inserts)
- Map user roles and permissions for transfers
- Define approval thresholds for large transfers
- Establish reconciliation procedure (daily balance checks)

---

## ✅ Analysis Complete

**Status:** ✅ DONE  
**Complexity:** 3/5 (Medium)  
**Time Estimate:** 4-5 hours migration  
**Priority:** HIGH (critical for daily cash operations)  
**Dependencies:**
  - MUST migrate AFTER: doCurrency, doCashDesk, doStore, doSystemTransaction, doFinanceTransaction
  - MUST validate: Double-entry integrity (transfer = expense + income)

---

## 🚨 CRITICAL ACTION ITEMS BEFORE MIGRATION

1. **BEFORE MIGRATION:** Document transfer creation workflow (stored proc? trigger?)
2. **BEFORE MIGRATION:** Verify DECIMAL precision matches source DB
3. **BEFORE MIGRATION:** Test double-entry validation script
4. **DURING MIGRATION:** Freeze cash desk operations (2-3 hour window)
5. **AFTER MIGRATION:** Validate all 19,534 transfers have valid double-entry links
6. **AFTER MIGRATION:** Test end-to-end transfer creation in staging

---

**Next Tables in Financial Domain:**
1. ✅ doCashDesk (DONE)
2. ✅ doCashDesk-Entries (DONE)
3. ✅ doCashDeskAmountTransfer (DONE)
4. 🔄 doCashDeskCurrencyChange (sibling table - similar pattern?)
5. 🔄 doFinanceTransaction (prerequisite - must analyze next)
6. 🔄 doCurrency (prerequisite - should have been first!)

---

**Recommended Migration Order:**
```
1. doCurrency (prerequisite)
2. doStore (prerequisite)
3. doCashDesk (master data)
4. doSystemTransaction (base transaction class)
5. doFinanceTransaction (prerequisite - referenced by transfers)
6. doCashDesk-Entries (balance snapshot)
7. doCashDeskAmountTransfer (THIS TABLE - depends on all above)
8. doCashDeskCurrencyChange (sibling table)
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-10  
**Validated By:** Светльо + Claude  
**Status:** Ready for double-entry workflow documentation

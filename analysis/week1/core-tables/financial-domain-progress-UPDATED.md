# TASK 1.3.2 - Financial Domain Analysis Progress

**Domain:** Financial Operations (Cash Management)  
**Start Date:** 2025-11-08  
**Status:** 🟢 IN PROGRESS - Part 1 Complete (Core Cash Tables)  
**Progress:** 5/8 tables analyzed (62.5%)

---

## 📊 PROGRESS TRACKER

| # | Table Name | Columns | Status | Complexity | Notes |
|---|------------|---------|--------|------------|-------|
| 1 | doCashDesk | 9 | ✅ DONE | Medium | Main cash register (POS + Bank accounts) |
| 2 | doCashDesk-Entries | 5 | ✅ DONE | Low | Balance tracking per currency |
| 3 | doCashDeskAmountTransfer | 8 | ✅ DONE | Medium | Inter-cashdesk transfers (double-entry) |
| 4 | doCashDeskCurrencyChange | 10 | ✅ DONE | High | FX operations (double-entry) |
| 5 | doCashDesk-Stores | 2 | ✅ DONE | Low | Many-to-many link (CashDesk ↔ Store) |
| 6 | doInvoice-CashDesks | 2 | 🔲 TODO | Low | Link table |
| 7 | Currencies | ? | 🔲 TODO | Low | Currency master data |
| 8 | PaymentTypes | ? | 🔲 TODO | Low | Payment method catalog |

---

## 📋 TABLE DETAILS

### 1️⃣ doCashDesk - Cash Register Master

**Purpose:** Main register of all cash desks (POS terminals + bank accounts)

#### Schema
```sql
ID                 bigint       PK, NOT NULL, DEFAULT 0
Name               nvarchar(50) NOT NULL, DEFAULT ''
Description        nvarchar(100) NULL
Active             bit          NOT NULL, DEFAULT 0
CashDeskType       int          NOT NULL, DEFAULT 1  -- 1=POS, 2=Bank
Currency           bigint       NULL, FK → Currencies
BankName           nvarchar(100) NULL
BankCode           nvarchar(40)  NULL  -- BIC/SWIFT
BankAccountNumber  nvarchar(40)  NULL  -- IBAN
```

#### Business Logic
- **Type 1 (POS):** Physical cash registers (e.g., "Постерминал Пловдив")
  - Currency typically NULL (uses system default)
  - No bank details
  
- **Type 2 (Bank Account):** Bank accounts (e.g., "Алианц EUR")
  - Currency specified (19=BGN, 20=EUR)
  - Full bank details (IBAN, BIC)

#### Statistics
- **Total:** 51 cash desks
- **Active:** 28 cash desks
- **Sample Types:** POS terminals, Bank accounts (Allianz Bank)

#### Relationships
- **→ Currencies:** Optional FK for default currency
- **← doCashDesk-Entries:** 1:N (multi-currency balances)
- **← doCashDeskAmountTransfer:** 1:N (as source/destination)
- **← doCashDeskCurrencyChange:** 1:N (FX operations)

#### Migration Notes
- ✅ Simple structure, direct PostgreSQL mapping
- ⚠️ Validate: CashDeskType enum (1=POS, 2=Bank) - consider using ENUM type
- ⚠️ BankCode/BankAccountNumber validation (IBAN format)
- 🔍 Check: How are POS terminals linked to physical devices?

---

### 2️⃣ doCashDesk-Entries - Balance Tracking

**Purpose:** Tracks current balance per cash desk per currency (with overdraft support)

#### Schema
```sql
ID               bigint  PK, NOT NULL
Owner            bigint  NOT NULL, DEFAULT 0, FK → doCashDesk.ID
Currency         bigint  NOT NULL, DEFAULT 0, FK → Currencies.ID
Amount           decimal NOT NULL, DEFAULT 0.0  -- Current balance
OverdraftAmount  decimal NOT NULL, DEFAULT 0.0  -- Overdraft limit
```

#### Business Logic
- **Multi-currency support:** 1 CashDesk can have multiple entries (1 per currency)
- **Overdraft protection:** Negative balances allowed up to OverdraftAmount
- **Real-time balance:** Updated by FinanceTransaction events

#### Sample Data
| Entry | CashDesk | Currency | Balance | Overdraft |
|-------|----------|----------|---------|-----------|
| 98 | 2322830 | 19 (BGN) | 23,426.24 | 0 |
| 97 | 2231219 | 20 (EUR) | -448,384.13 | 1,000,000.00 |
| 96 | 2231216 | 19 (BGN) | 4,131,583.23 | 0 |

#### Statistics
- **Total Entries:** 94
- **Total CashDesks:** 51
- **Avg Currencies/Desk:** ~1.8

#### Relationships
- **→ doCashDesk:** N:1 (Owner)
- **→ Currencies:** N:1
- **← FinanceTransaction:** Updated by transactions

#### Migration Notes
- ✅ Straightforward PostgreSQL mapping
- ⚠️ decimal precision: Verify financial accuracy (DECIMAL(18,10) → NUMERIC)
- 🔍 Check: How is overdraft limit set/enforced?
- 💡 Consider: Adding timestamp for last update

---

### 3️⃣ doCashDeskAmountTransfer - Inter-CashDesk Transfers

**Purpose:** Records money transfers between cash desks (implements double-entry accounting)

#### Schema
```sql
ID                          bigint  PK, NOT NULL, DEFAULT 0
Store                       bigint  NOT NULL, DEFAULT 0, FK → Stores
CashDesk                    bigint  NOT NULL, DEFAULT 0, FK → doCashDesk (source)
DestinationCashDesk         bigint  NOT NULL, DEFAULT 0, FK → doCashDesk (target)
Currency                    bigint  NOT NULL, DEFAULT 0, FK → Currencies
Amount                      decimal NOT NULL, DEFAULT 0.0
IncomeFinanceTransaction    bigint  NOT NULL, DEFAULT 0, FK → doFinanceTransaction
ExpenseFinanceTransaction   bigint  NOT NULL, DEFAULT 0, FK → doFinanceTransaction
```

#### Business Logic
- **Double-entry pattern:** Each transfer creates 2 transactions:
  1. **Expense:** Debit from source CashDesk
  2. **Income:** Credit to destination CashDesk
  
- **Same currency only:** No FX conversion (use doCashDeskCurrencyChange instead)

- **Audit trail:** Both FinanceTransaction IDs stored for traceability

#### Sample Data
| Transfer | Store | From | To | Currency | Amount |
|----------|-------|------|-----|----------|--------|
| 3487696 | 27126 | 59465 | 111971 | 19 (BGN) | 183.31 |
| 3487689 | 892259 | 892258 | 111972 | 19 (BGN) | 84.60 |
| 3487680 | 27104 | 48504 | 111970 | 19 (BGN) | 1,869.80 |

#### Relationships
- **→ Stores:** N:1 (context/audit)
- **→ doCashDesk (source):** N:1
- **→ doCashDesk (target):** N:1
- **→ Currencies:** N:1
- **→ doFinanceTransaction:** 2:1 (income + expense)

#### Migration Notes
- ✅ Clean double-entry implementation
- ⚠️ Validate: No self-transfers (CashDesk ≠ DestinationCashDesk)
- ⚠️ Ensure: Both FinanceTransactions exist before FK creation
- 🔍 Check: What happens if transfer fails mid-transaction?
- 💡 Consider: Add status field (Pending/Completed/Cancelled)

---

### 4️⃣ doCashDeskCurrencyChange - Foreign Exchange Operations

**Purpose:** Currency exchange operations within cash desks (implements double-entry accounting)

#### Schema
```sql
ID                          bigint  PK, NOT NULL, DEFAULT 0
Store                       bigint  NOT NULL, DEFAULT 0, FK → Stores
CashDesk                    bigint  NOT NULL, DEFAULT 0, FK → doCashDesk
Currency                    bigint  NOT NULL, DEFAULT 0, FK → Currencies (source)
NewCurrency                 bigint  NOT NULL, DEFAULT 0, FK → Currencies (target)
Amount                      decimal NOT NULL, DEFAULT 0.0  -- Source amount
Rate                        float   NOT NULL, DEFAULT 0.0  -- Exchange rate
NewAmount                   decimal NOT NULL, DEFAULT 0.0  -- Target amount
IncomeFinanceTransaction    bigint  NOT NULL, DEFAULT 0, FK → doFinanceTransaction
ExpenseFinanceTransaction   bigint  NOT NULL, DEFAULT 0, FK → doFinanceTransaction
```

#### Business Logic
- **Double-entry FX:** Each exchange creates 2 transactions:
  1. **Expense:** Debit source currency
  2. **Income:** Credit target currency
  
- **Exchange rate:** Stored at transaction time (historical record)

- **Formula validation:** NewAmount = Amount × Rate

#### Sample Data
| Exchange | CashDesk | From | To | Amount | Rate | NewAmount |
|----------|----------|------|-----|--------|------|-----------|
| 1 | 27090 | 22 (GBP) | 19/20 | 195.58 | 0.5113 | 100.00 |
| 2 | 27090 | 22 (GBP) | 19/20 | 391.16 | 0.5113 | 200.00 |
| 3 | 27090 | 22 (EUR) | 19 (BGN) | 200.00 | 1.9558 | 391.16 |

**Interesting Finding:** EUR/BGN fixed rate = 1.9558 (official Bulgarian lev peg!)

#### Relationships
- **→ Stores:** N:1
- **→ doCashDesk:** N:1
- **→ Currencies (source):** N:1
- **→ Currencies (target):** N:1
- **→ doFinanceTransaction:** 2:1
- **→ doCurrencyRates:** Implicit (rate lookup)

#### Migration Notes
- ⚠️ **CRITICAL:** float vs decimal for Rate
  - Current: `Rate float` (precision loss risk!)
  - Recommended: `Rate NUMERIC(18,10)` for financial accuracy
  
- ✅ Double-entry pattern consistent with transfers

- ⚠️ Validate: NewAmount = Amount × Rate (integrity check)

- 🔍 Check: Where does Rate come from? (doCurrencyRates table?)

- 💡 Consider: Add RateSourceID to track rate origin

---

### 5️⃣ doCashDesk-Stores - CashDesk-Store Link Table

**Purpose:** Many-to-many relationship between cash desks and stores (enables multi-store cashdesks and multi-cashdesk stores)

#### Schema
```sql
ID-1  bigint  NOT NULL, DEFAULT 0, FK → doCashDesk.ID
ID-2  bigint  NOT NULL, DEFAULT 0, FK → Stores.ID (or similar)
```

**Composite PK:** Likely (ID-1, ID-2) - standard M:N junction table pattern

#### Business Logic
- **Many-to-Many Relationship:**
  - 1 CashDesk can be associated with **multiple Stores** (e.g., CashDesk 2231219 → 6 stores)
  - 1 Store can have **multiple CashDesks** (e.g., Store 27090 → 39 cashdesks)

- **Use Cases:**
  1. **Central bank accounts** serving multiple stores
  2. **Shared POS terminals** across locations
  3. **Mobile cashdesks** rotating between stores

#### Sample Data
| CashDesk ID | Store ID | Note |
|-------------|----------|------|
| 2322830 | 27092 | Single-store cashdesk |
| 2231219 | 184301 | Multi-store cashdesk (6 total) |
| 2231219 | 66041 | Same cashdesk, different store |
| 2231216 | 892259 | Multi-store cashdesk (11 total) |

#### Statistics
- **Total Links:** 181 relationships
- **Unique CashDesks:** 46 (out of 51 total cashdesks)
- **Unique Stores:** 24
- **Avg Stores/CashDesk:** ~3.9
- **Avg CashDesks/Store:** ~7.5

#### Distribution Analysis
**Top Multi-Store CashDesks:**
| CashDesk | Store Count | Type (hypothesis) |
|----------|-------------|-------------------|
| 86379 | 16 | Central bank account |
| 86264 | 13 | Corporate payment account |
| 99573 | 13 | Shared POS system |
| 2231216 | 11 | Regional bank account |

**Top Multi-CashDesk Stores:**
| Store | CashDesk Count | Type (hypothesis) |
|-------|----------------|-------------------|
| 27090 | 39 | Headquarters/main location |
| 27110 | 11 | Large retail store |
| 27120 | 10 | Distribution center |

#### Relationships
- **→ doCashDesk:** N:1 (ID-1)
- **→ Stores:** N:1 (ID-2)
- **Business Rule:** Associates financial operations with physical locations

#### Migration Notes
- ✅ **Simple junction table** - standard PostgreSQL mapping
- ✅ **No data loss risk** - pure FK relationships
- ⚠️ **Validate cardinality:** Ensure app logic handles M:N correctly
- 🔍 **Check usage:** How does UI display multi-store cashdesks?
- 💡 **PostgreSQL optimization:** Add indexes on both FK columns

```sql
-- Recommended PostgreSQL DDL
CREATE TABLE cashdesk_stores (
    cashdesk_id BIGINT NOT NULL REFERENCES cashdesks(id),
    store_id BIGINT NOT NULL REFERENCES stores(id),
    PRIMARY KEY (cashdesk_id, store_id)
);
CREATE INDEX idx_cashdesk_stores_store ON cashdesk_stores(store_id);
```

**Migration Complexity:** **LOW** (1/5)
- Simple structure
- No business logic
- Standard M:N pattern
- Direct PostgreSQL mapping

---

## 🔗 DOMAIN RELATIONSHIPS

### External Dependencies (TO)
```
Financial Domain → Core Business
├── Stores (all tables reference Store for context)
└── Currencies (CashDesk, Entries, Transfers, FX)

Financial Domain → Documents
└── doFinanceTransaction (Transfers & FX reference)
```

### Internal Relationships
```
doCashDesk (1)
├── has many → doCashDesk-Entries (N) [per currency]
├── linked to → doCashDesk-Stores (N) [many-to-many with Stores]
├── source of → doCashDeskAmountTransfer (N)
├── target of → doCashDeskAmountTransfer (N)
└── performs → doCashDeskCurrencyChange (N)

doCashDesk-Stores (junction)
├── links → doCashDesk (N:M)
└── links → Stores (N:M)

doCashDeskAmountTransfer
└── creates → 2x doFinanceTransaction (Income + Expense)

doCashDeskCurrencyChange
└── creates → 2x doFinanceTransaction (Income + Expense)
```

---

## 🚨 CRITICAL FINDINGS

### 1. Double-Entry Accounting ✅
- Both transfers and FX ops correctly implement double-entry
- Each operation creates 2 FinanceTransaction records
- Excellent audit trail

### 2. Float vs Decimal Issue ⚠️
- **Problem:** `doCashDeskCurrencyChange.Rate` uses `float`
- **Risk:** Precision loss in financial calculations
- **Fix:** Migrate to `NUMERIC(18,10)` in PostgreSQL

### 3. Multi-Currency Architecture ✅
- Clean separation: 1 entry per currency per cashdesk
- Overdraft support per currency
- No mixed-currency transactions (enforced by separate tables)

### 4. Missing Validation Fields ⚠️
- No transaction status (Pending/Completed/Failed)
- No timestamps on transfers/exchanges
- No transaction reversal mechanism

---

## 🎯 MIGRATION COMPLEXITY ASSESSMENT

### Overall Domain: **MEDIUM** (3/5)

| Aspect | Complexity | Reason |
|--------|------------|--------|
| Schema | LOW | Simple structures, clear FKs |
| Data Types | MEDIUM | Float→Numeric conversion needed |
| Business Logic | MEDIUM | Double-entry pattern must be preserved |
| Relationships | MEDIUM | Multiple FK dependencies |
| Data Volume | MEDIUM | ~51 cashdesks, 94 entries, unknown txn count |

### Table-by-Table

| Table | Migration | Data | Logic | Total |
|-------|-----------|------|-------|-------|
| doCashDesk | LOW | LOW | LOW | **LOW** (1/5) |
| doCashDesk-Entries | LOW | LOW | MEDIUM | **LOW** (2/5) |
| doCashDeskAmountTransfer | MEDIUM | MEDIUM | MEDIUM | **MEDIUM** (3/5) |
| doCashDeskCurrencyChange | HIGH | MEDIUM | HIGH | **MEDIUM-HIGH** (4/5) |
| doCashDesk-Stores | LOW | LOW | LOW | **LOW** (1/5) |

---

## ✅ VALIDATION CHECKLIST

### Completed ✅
- [x] Schema extraction for 5 tables (doCashDesk + 4 related)
- [x] Sample data analysis
- [x] Relationship mapping
- [x] Business logic identification
- [x] Data type assessment
- [x] Critical findings documented
- [x] doCashDesk-Stores M:N relationship analyzed

### Pending 🔲
- [ ] Analyze doInvoice-CashDesks (link table)
- [ ] Analyze Currencies (master data)
- [ ] Analyze PaymentTypes (master data)
- [ ] Verify doFinanceTransaction structure
- [ ] Count total transfers/exchanges (data volume)
- [ ] Identify all Views dependencies
- [ ] Map to C# entity classes

---

## 📝 NEXT STEPS

### Immediate (Week 1)
1. ✅ Complete Part 1 (Core Tables) - **DONE**
2. 🟡 Analyze remaining 3 tables (Invoice link, Currencies, PaymentTypes) - **IN PROGRESS**
3. 🔲 Document doFinanceTransaction (referenced by transfers/FX)
4. 🔲 Map 7 Views to base tables

### Week 2
1. Extract C# entity models
2. Identify business rule methods
3. Test data volume queries
4. Create migration scripts (DDL)

### Week 3
1. Map financial reports dependencies
2. Identify UI screens using this domain
3. Document user workflows
4. Plan data migration strategy

---

## 🎓 LESSONS LEARNED

1. **Naming Convention Issue:**
   - Documentation said "CashOperations" (doesn't exist!)
   - Reality: 4 separate tables with "doCashDesk*" prefix
   - **Action:** Always verify DB schema before trusting docs

2. **Double-Entry Pattern:**
   - Clean implementation across transfers & FX
   - Critical to preserve in migration
   - **Action:** Create PostgreSQL triggers or app-level enforcement

3. **Data Type Precision:**
   - Float for exchange rates = precision risk
   - **Action:** Add to technical debt register

4. **M:N Relationships:**
   - Many-to-many between CashDesks and Stores
   - Enables flexible business models (shared terminals, central accounts)
   - **Action:** Ensure new architecture supports this flexibility

---

**Analysis Duration:** ~1.5 hours  
**Tables Analyzed:** 5/8 (62.5%)  
**Next Session:** Part 2 - Support Tables (Invoice link, Currencies, PaymentTypes)

---

*Last Updated: 2025-11-08 by Claude (AI Assistant)*

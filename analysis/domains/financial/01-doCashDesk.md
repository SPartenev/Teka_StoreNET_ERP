# doCashDesk Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо  
**Domain:** Financial

---

## 📋 Overview

**Purpose:** Master registry of all cash desks (physical cash registers) and bank accounts in the system  
**Type:** Reference/Master Data Table  
**Parent Table:** doDataObject  
**Row Count:** 51 records (50 active/inactive + 1 NULL default)  
**Active Records:** 28 (18 cash desks + 10 bank accounts)  
**Migration Complexity:** 2/5 (Low-Medium)

---

## 🗂️ Schema

### Columns (9 total):

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | ((0)) | Primary key (inherits from doDataObject) |
| Name | nvarchar(50) | NOT NULL | ('') | Display name of cash desk/bank account |
| Description | nvarchar(100) | YES | (NULL) | Optional detailed description |
| Active | bit | NOT NULL | ((0)) | Whether cash desk is currently in use |
| CashDeskType | int | NOT NULL | ((1)) | Type: 1=Physical Cash, 2=Bank Account, 3=VAT Account |
| Currency | bigint | YES | (NULL) | FK to doCurrency (used only for bank accounts) |
| BankName | nvarchar(100) | YES | (NULL) | Bank name (for type 2 & 3) |
| BankCode | nvarchar(40) | YES | (NULL) | BIC/SWIFT code |
| BankAccountNumber | nvarchar(40) | YES | (NULL) | IBAN or account number |

### Key Observations:
- **CashDeskType Enum:**
  - `1` = Physical cash register (каси) - 23 records
  - `2` = Bank account (банкови сметки) - 22 records
  - `3` = VAT bank account (ДДС сметки) - 6 records (all inactive)
- Physical cash desks do NOT use Currency field (NULL)
- Bank accounts ALWAYS have Currency, BankName, and BankAccountNumber
- Default record with ID=0 exists (empty placeholder)

---

## 🔗 Relationships

### Foreign Keys (Outgoing):
- `ID` → `doDataObject.ID` - Inherits from base data object class
- `Currency` → `doCurrency.ID` - Currency for bank accounts only

### Foreign Keys (Incoming - 8 child tables):
1. **doCashDesk-Entries** (`Owner`) - Cash desk transaction entries/operations
2. **doCashDesk-Stores** (`ID-1`) - Association between cash desks and stores
3. **doFinanceTransaction-Items** (`CashDesk`) - Financial transaction line items
4. **doInvoice-CashDesks** (`ID-2`) - Invoice payment associations
5. **doCashDeskAmountTransfer** (`CashDesk`, `DestinationCashDesk`) - Money transfers between cash desks (both source and destination)
6. **doCashDeskCurrencyChange** (`CashDesk`) - Currency exchange operations
7. **doTransactionFinance** (`CashDesk`) - Financial transaction headers

**Critical Note:** This is a **central hub table** in the financial domain - referenced by 8 different transaction and operation tables.

---

## 📊 Data Analysis

### Total Records: 51
- **Active:** 28 (54.9%)
- **Inactive:** 23 (45.1%)
- **NULL placeholder:** 1 (ID=0)

### Distribution by Type:

| Type | Active | Inactive | Total | % of Total |
|------|--------|----------|-------|------------|
| **1 - Physical Cash** | 18 | 5 | 23 | 45.1% |
| **2 - Bank Account** | 10 | 12 | 22 | 43.1% |
| **3 - VAT Account** | 0 | 6 | 6 | 11.8% |
| **TOTAL** | 28 | 23 | 51 | 100% |

### Currency Distribution (Bank Accounts Only):
- **Currency 19 (BGN):** 20 accounts
- **Currency 20 (EUR):** 8 accounts
- All 28 bank/VAT accounts have assigned currency

---

## 🏪 Active Cash Desks (Type 1 - 18 total)

### Main Office & Store Cash Registers:
- **Главна офис** (ID: 22) - Main office cash desk
- **Главна Гео** (ID: 111972) - Geo Milev store main cash
- **Главна Люлин** (ID: 111971) - Lulin store main cash
- **Главна Пловдив** (ID: 111973) - Plovdiv store main cash
- **Главна Южен** (ID: 111970) - Yuzhen Park store main cash

### Store Cash Registers:
- **Магазин Гео Милев** (ID: 892258)
- **Магазин Люлин** (ID: 59465)
- **Магазин Южен Парк** (ID: 48504)

### POS Terminals:
- **Постерминал Гео Миле** (ID: 892265)
- **Постерминал ЛЮЛИН** (ID: 86380)
- **Постерминал Пловдив** (ID: 2322830)
- **Постерминал Южен** (ID: 56522)

### Operational Cash Desks:
- **Каса офис оборот** (ID: 48505) - Office turnover cash
- **Каса офис Пловдив** (ID: 210272) - Plovdiv office cash
- **Каса Русе - сервиз** (ID: 1271997) - Ruse service cash
- **Контрол** (ID: 58406) - Control/audit cash
- **Панаир** (ID: 186137) - Trade fair cash
- **Начални прехвърляния** (ID: 48626) - Initial transfers cash

### Geographic Distribution:
- **Sofia:** Geo Milev, Lulin, Yuzhen Park, Main Office
- **Plovdiv:** 1 store
- **Ruse:** Service center

---

## 🏦 Active Bank Accounts (Type 2 - 10 total)

### BGN Accounts (5):
1. **Алианц банк лв** (ID: 2231216)
   - Bank: Алианц банк България
   - IBAN: BG61 BUIN 9561 1000 4599 33

2. **Постерминал офис** (ID: 414836)
   - Bank: Прокредитбанк АД-кл.Бели Брези
   - IBAN: BG92PRCB92301001272411

3. **Прокредит лева** (ID: 86379)
   - Bank: Прокредитбанк АД
   - IBAN: BG92 PRCB 9230 1001 2724 11

4. **Райфайзен лева** (ID: 86373)
   - Bank: Райфайзен банк-София-11
   - IBAN: BG84 RZBB 9155 1066 7089 18

5. **ТБ Виктория** (ID: 1940930)
   - Bank: ТБ ВИКТОРИЯ
   - IBAN: BG20 BINV 9480 0003 0279 42

### EUR Accounts (5):
1. **Banco Popular EUR** (ID: 377290)
   - Bank: Banco Popular (Spain)
   - IBAN: ES9000750323260670000917

2. **Credit Agricole** (ID: 1947124)
   - Bank: Кредит Агрикол EUR
   - IBAN: BG90 BINV 9480 0003 0279 43

3. **Алианц EUR** (ID: 2231219)
   - Bank: Алианц банк България
   - IBAN: BG34 BUIN 9561 1000 4599 34

4. **Прокредит EUR** (ID: 86381)
   - Bank: Прокредитбанк АД-кл.Бели Брези
   - IBAN: BG36 PRCB 9230 1401 2724 16

5. **Райфайзен EUR** (ID: 86378)
   - Bank: Райфайзен банк-София-11
   - IBAN: BG72 RZBB 9155 1466 7089 07

### Banking Partners:
- Райфайзен банк (2 accounts: BGN + EUR)
- Прокредитбанк (3 accounts: 2 EUR + 1 BGN POS)
- Алианц банк (2 accounts: BGN + EUR)
- Credit Agricole (1 EUR)
- ТБ Виктория (1 BGN)
- Banco Popular Spain (1 EUR - international)

---

## 🗄️ Inactive/Historical Data

### Inactive Cash Desks (5):
- Likely old store locations or consolidated operations
- ID=0 is NULL placeholder record

### Inactive Bank Accounts (12 Type 2 + 6 Type 3 = 18):
- Many prefixed with "стара-" (old-)
- Old banks: Райфайзен, Юнион, Прокредит
- All 6 VAT accounts (Type 3) are inactive
- Represents historical banking relationships

**Data Quality Note:** "стара-" prefix indicates deprecated accounts but retained for historical transaction integrity

---

## 🏗️ Architecture Pattern

**Inheritance:**
```
doDataObject
    └─ doCashDesk (51 records - reference data)
           ├─ Physical Cash (Type 1) - 23 records
           ├─ Bank Accounts (Type 2) - 22 records
           └─ VAT Accounts (Type 3) - 6 records
```

**Purpose in System:**
- **Master registry** for all payment instruments
- Supports both cash and bank operations
- Links physical stores to payment methods
- Enables multi-currency operations (BGN/EUR)
- Foundation for cash flow tracking

**Key Business Rules:**
1. Physical cash desks do NOT require currency assignment
2. Bank accounts MUST have currency, bank name, and account number
3. Each store has multiple cash instruments (main cash + POS terminal)
4. System supports dual-currency operations (BGN domestic + EUR international)
5. Historical accounts retained for transaction audit trail

---

## 🔄 PostgreSQL Migration

### Complexity: 2/5 (Low-Medium)

**Why Low Complexity:**
- ✅ Small reference table (51 records)
- ✅ Simple schema (9 columns)
- ✅ No complex data types
- ✅ Straightforward foreign keys
- ✅ No computed columns or triggers
- ✅ Static/semi-static data (low change frequency)

**Why Not Level 1:**
- ⚠️ Central hub with 8 child table dependencies
- ⚠️ Mixed usage pattern (3 distinct types in one table)
- ⚠️ Business-critical reference data

### Migration Strategy:

```sql
-- PostgreSQL Schema
CREATE TABLE cash_desks (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL DEFAULT '',
    description VARCHAR(100),
    active BOOLEAN NOT NULL DEFAULT false,
    cash_desk_type INTEGER NOT NULL DEFAULT 1,
    currency_id BIGINT REFERENCES currencies(id),
    bank_name VARCHAR(100),
    bank_code VARCHAR(40),
    bank_account_number VARCHAR(40),
    
    -- Audit fields (from doDataObject)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Constraints
    CHECK (cash_desk_type IN (1, 2, 3)),
    CHECK (cash_desk_type = 1 OR (currency_id IS NOT NULL AND bank_name IS NOT NULL))
);

-- Indexes for performance
CREATE INDEX idx_cash_desks_active ON cash_desks(active) WHERE active = true;
CREATE INDEX idx_cash_desks_type ON cash_desks(cash_desk_type);
CREATE INDEX idx_cash_desks_currency ON cash_desks(currency_id) WHERE currency_id IS NOT NULL;

-- Enum type for better type safety
CREATE TYPE cash_desk_type_enum AS ENUM ('physical_cash', 'bank_account', 'vat_account');
-- Then alter table to use enum instead of integer
```

### Schema Changes Required:

1. **Data Types:**
   - ✅ `bigint` → `BIGINT` (same)
   - ✅ `nvarchar` → `VARCHAR` (PostgreSQL uses UTF-8 by default)
   - ✅ `bit` → `BOOLEAN` (semantic improvement)
   - ⚠️ Consider `cash_desk_type` as ENUM for type safety

2. **Constraints:**
   - ✅ Add CHECK constraint: bank accounts must have currency + bank info
   - ✅ Add CHECK constraint: physical cash cannot have bank info
   - ✅ Validate IBAN format for bank accounts (optional)

3. **Indexes:**
   - ✅ Primary key on `id`
   - ✅ Partial index on `active = true` (28 out of 51 records)
   - ✅ Index on `cash_desk_type` for type-based queries
   - ✅ Index on `currency_id` for currency filtering

4. **Data Cleanup:**
   - ✅ Remove ID=0 NULL placeholder (not needed in PostgreSQL)
   - ⚠️ Consider archiving inactive "стара-" accounts to separate table
   - ✅ Validate all IBAN formats conform to ISO 13616

### Data Migration Script:

```sql
-- Step 1: Migrate data
INSERT INTO cash_desks (id, name, description, active, cash_desk_type, 
                        currency_id, bank_name, bank_code, bank_account_number)
SELECT 
    ID,
    Name,
    Description,
    CASE WHEN Active = 1 THEN true ELSE false END,
    CashDeskType,
    Currency,
    BankName,
    BankCode,
    BankAccountNumber
FROM doCashDesk
WHERE ID > 0;  -- Skip NULL placeholder

-- Step 2: Set sequence to max ID + 1
SELECT setval('cash_desks_id_seq', (SELECT MAX(id) FROM cash_desks) + 1);

-- Step 3: Validate constraints
SELECT 
    COUNT(*) as invalid_bank_accounts
FROM cash_desks
WHERE cash_desk_type IN (2, 3)
  AND (currency_id IS NULL OR bank_name IS NULL OR bank_account_number IS NULL);
-- Expected: 0

-- Step 4: Validate physical cash
SELECT 
    COUNT(*) as invalid_physical_cash
FROM cash_desks
WHERE cash_desk_type = 1
  AND (currency_id IS NOT NULL OR bank_name IS NOT NULL);
-- Expected: 0
```

### Estimated Migration Time: 2-3 hours

**Breakdown:**
- Schema creation: 30 min
- Data migration: 15 min (51 records)
- Validation & testing: 45 min
- Index creation: 15 min
- Documentation: 45 min

---

## ❓ Stakeholder Questions

### Business Logic:
1. **Cash Desk Types:**
   - Why are Type 3 (VAT accounts) all inactive? Is this account type still needed?
   - Should we consolidate Type 2 and Type 3 into single "Bank Account" type?

2. **Inactive Accounts:**
   - Can we archive/delete 23 inactive records? Or are they needed for historical transactions?
   - What's the retention policy for old bank accounts?

3. **Geographic Expansion:**
   - Are there plans to open new stores/locations?
   - Should we support additional currencies beyond BGN/EUR?

4. **Banking Relationships:**
   - Why both Райфайзен and Прокредит have multiple accounts?
   - Is Banco Popular (Spain) still actively used for international payments?

5. **POS Terminals:**
   - Do POS terminals share the same bank account as main store cash, or separate settlement?
   - How do POS terminals synchronize with cash desk entries?

### Technical Integration:
6. **Multi-Store Operations:**
   - How does "Постерминал офис" (office POS) differ from store POS terminals?
   - Can one cash desk be shared across multiple stores?

7. **Currency Exchange:**
   - How frequently are doCashDeskCurrencyChange operations performed?
   - Is real-time exchange rate required?

8. **Cash Transfers:**
   - What triggers doCashDeskAmountTransfer operations?
   - Any approval workflow for transfers between cash desks?

---

## 🚨 Migration Risks

### High Priority:
1. **Foreign Key Dependencies (8 child tables)**
   - **Risk:** Breaking changes to doCashDesk will cascade to all financial transaction tables
   - **Mitigation:** 
     - Migrate doCashDesk BEFORE all child tables
     - Maintain ID values exactly (no auto-increment reassignment)
     - Extensive foreign key validation post-migration

2. **Active vs Inactive Data**
   - **Risk:** Accidentally archiving active cash desks or losing historical transaction links
   - **Mitigation:**
     - Double-verify Active=true records (28) are correctly identified
     - Test all 8 child table joins with inactive IDs
     - Keep inactive records in production (archive to separate schema later)

### Medium Priority:
3. **IBAN Validation**
   - **Risk:** Invalid IBAN formats may exist (observed: mixed spacing, no checksum validation)
   - **Mitigation:**
     - Run IBAN validation script pre-migration
     - Standardize format: remove spaces, validate country code
     - Add PostgreSQL CHECK constraint with IBAN regex

4. **Currency Assignment Logic**
   - **Risk:** Physical cash desks have Currency=NULL but may need default BGN
   - **Mitigation:**
     - Document business rule: physical cash is always BGN by default
     - Add application-level default (not DB constraint)

5. **Sparse ID Range**
   - **Risk:** ID range 22-2,322,830 for 50 records wastes sequence space
   - **Mitigation:**
     - Accept sparse IDs (preserve historical values)
     - Set PostgreSQL sequence start to MAX(ID) + 1 = 2,322,831
     - No need to compress IDs (breaks FK integrity)

### Low Priority:
6. **Type Enum Consistency**
   - **Risk:** Hardcoded integers (1, 2, 3) make code less readable
   - **Mitigation:**
     - Consider PostgreSQL ENUM type for CashDeskType
     - Document enum values in migration guide
     - Update application layer to use enum constants

---

## 📝 Notes

### Key Insights:
1. **Central Financial Hub:** This table is referenced by 8 different transaction tables, making it a cornerstone of the financial domain. Any schema changes require careful coordination.

2. **Dual Payment Infrastructure:** System supports both cash (Type 1) and bank (Type 2/3) operations seamlessly, with clear separation of concerns (cash desks don't need currency, banks require full info).

3. **Multi-Store Operations:** Evidence of 4-5 physical store locations (Geo Milev, Lulin, Yuzhen Park, Plovdiv, Ruse) with dedicated cash infrastructure per store.

4. **Historical Data Retention:** 45% of records are inactive but preserved, indicating strong audit requirements. The "стара-" prefix system is a good practice for marking deprecated records.

5. **Banking Diversity:** Multiple banking partners (Райфайзен, Прокредит, Алианц, etc.) and dual-currency support (BGN/EUR) suggest sophisticated treasury management.

6. **POS Terminal Integration:** Separate cash desk entries for POS terminals indicate automated payment processing integration (4 active POS terminals).

### Migration Considerations:
- **Sequence Planning:** PostgreSQL sequence should start at 2,322,831 to avoid ID conflicts
- **ID Preservation:** Must maintain exact ID values (no renumbering) due to 8 FK dependencies
- **Enum Type:** Consider converting CashDeskType from INT to PostgreSQL ENUM for type safety
- **IBAN Standardization:** Implement IBAN validation and formatting during migration
- **Archive Strategy:** Evaluate archiving 23 inactive records to separate schema (but keep accessible for historical queries)

### Performance Considerations:
- Small table (51 records) - no performance concerns
- Partial index on `active = true` optimizes current operations queries
- Currency FK index supports financial reporting queries
- Consider materialized view for "active cash desks by store" if frequently queried

---

## ✅ Analysis Complete

**Status:** ✅ DONE  
**Complexity:** 2/5 (Low-Medium)  
**Time Estimate:** 2-3 hours migration  
**Priority:** HIGH (foundational reference data for entire financial domain)  
**Dependencies:** Must migrate BEFORE all financial transaction tables

---

**Next Tables in Financial Domain:**
1. ✅ doCashDesk (DONE)
2. 🔄 doCashDesk-Entries (cash desk operations)
3. 🔄 doFinanceTransaction (financial transactions)
4. 🔄 doFinanceTransaction-Items (transaction line items)
5. 🔄 Additional financial tables...

---

**Migration Order Recommendation:**
```
1. doCurrency (prerequisite)
2. doCashDesk (this table)
3. doCashDesk-Entries (depends on doCashDesk)
4. doFinanceTransaction family (depends on doCashDesk)
```

---

**Document Version:** 1.0  
**Last Updated:** 2025-11-10  
**Validated By:** Светльо + Claude

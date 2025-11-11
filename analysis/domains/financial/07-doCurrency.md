# doCurrency Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо

---

## 📋 Overview

**Purpose:** Master reference table for currency definitions used throughout the system  
**Table Type:** Reference/Lookup Table (Master Data)  
**Row Count:** 4 currencies (3 active + 1 placeholder)  
**Migration Complexity:** 2/5 (Simple structure, but CRITICAL dependencies)

**Business Logic:**
- Defines all currencies supported by the ERP system
- Primary currency: **BGL (Bulgarian Lev)** - used in 99%+ of transactions
- Secondary currencies: **EUR** (Euro), **USD** (US Dollar)
- Referenced by 17+ tables across all business domains
- Foundation for multi-currency operations and exchange rate calculations

---

## 🗂️ Schema

### Columns (4 total):

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | 0 | Primary key (inherits from doDataObject) |
| Name | nvarchar(3) | NOT NULL | '' | ISO 4217 currency code (BGL, EUR, USD) |
| AmountBase | int | NOT NULL | 0 | Base amount for currency calculations (always 1 in current data) |
| Active | bit | NOT NULL | 0 (false) | Whether currency is currently active for use |

**Key Observations:**
- **Name limited to 3 characters** - matches ISO 4217 standard currency codes
- **AmountBase = 1** for all currencies (likely unused or future feature)
- **Active flag** controls which currencies are available for transactions
- **No description field** - relies on standard currency code knowledge
- **No display symbol** (лв, €, $) - likely hardcoded in application
- **No decimal places** config (e.g., JPY has 0, BHD has 3) - assumes 2 decimals

**Design Pattern:**
Minimal reference table - stores only essential currency identifiers, relies on ISO standards.

---

## 🔗 Relationships

### Foreign Keys (Outgoing):
- `ID` → `doDataObject.ID` - Inherits from base entity class

### Foreign Keys (Incoming) - **17 Dependent Tables:**

**Financial Domain (8 tables):**
1. `doCashDesk.Currency` - Cash desk operating currency
2. `doCashDeskAmountTransfer.Currency` - Currency for cash transfers
3. `doCashDeskCurrencyChange.Currency` - Original currency in exchange
4. `doCashDeskCurrencyChange.NewCurrency` - Target currency in exchange
5. `doCashDesk-Entries.Currency` - Currency for each cash entry
6. `doFinanceTransaction.Currency` - Financial transaction currency
7. `doFinanceTransaction-Items.Currency` - Line item currencies
8. `doTransactionFinance.Currency` - Finance transaction currency

**Products Domain (2 tables):**
9. `doProduct-Prices.Currency` - Product pricing currency
10. `doProductPriceType.Currency` - Price type default currency

**Documents Domain (1 table):**
11. `doInvoice.Currency` - Invoice billing currency

**Trade Domain (2 tables):**
12. `doTrade.Currency` - Trade transaction currency
13. `doTradeItem.Currency` - Individual trade item currency

**System Domain (3 tables):**
14. `doCurrency-Rates.BaseCurrency` - Base currency for exchange rate
15. `doCurrency-Rates.RateCurrency` - Target currency for exchange rate
16. `doSystemSettings.Currency` - System default currency
17. `doTransactionFinanceDefinition.Currency` - Finance definition currency

**Architecture Impact:**
⚠️ **CRITICAL REFERENCE TABLE** - Changes to this table affect entire system!

---

## 📊 Data Analysis

### Total Records: 4 currencies

### Complete Currency List:
| ID | Name | AmountBase | Active | Status | Usage |
|----|------|------------|--------|--------|-------|
| 0 | '' (empty) | 0 | false | ❌ Invalid | Placeholder/data quality issue |
| 19 | BGL | 1 | true | ✅ Active | **Primary currency** (99%+ of transactions) |
| 20 | EUR | 1 | true | ✅ Active | Secondary currency (~1% of transactions) |
| 21 | USD | 1 | true | ✅ Active | Rarely used (minimal transactions) |

### Currency Usage Statistics:

**Cash Desk Operations:**
| Currency | Cash Desks | % |
|----------|-----------|---|
| NULL | 23 | 45.1% (data quality issue) |
| BGL (19) | 20 | 39.2% |
| EUR (20) | 8 | 15.7% |
| **Total** | **51** | **100%** |

**Invoice Transactions (173,905 total):**
| Currency | Invoice Count | % |
|----------|--------------|---|
| BGL (19) | 173,904 | 99.999% |
| Invalid (0) | 1 | <0.001% |

**Trade Transactions (365,771 total):**
| Currency | Trade Count | % |
|----------|------------|---|
| BGL (19) | 362,693 | 99.16% |
| EUR (20) | 3,077 | 0.84% |
| Invalid (0) | 1 | <0.001% |

**Key Findings:**
1. **BGL Dominance:** 99%+ of all financial transactions use Bulgarian Lev
2. **EUR Usage:** Limited to 0.84% of trades (likely international purchases or specific suppliers)
3. **USD Usage:** Minimal to none in sample data (configured but not actively used)
4. **Data Quality Issues:**
   - 2 records reference invalid currency ID=0 (doInvoice, doTrade)
   - 23 cash desks have NULL currency (45% of cash desks!)

### Exchange Rate Analysis (from doCurrency-Rates):

**EUR/BGL Rate: 1.9558 (Fixed)**
- Bulgaria operates **Currency Board** arrangement (since 1997)
- BGN is pegged to EUR at fixed rate: **1 EUR = 1.9558 BGN**
- This is **NOT a floating rate** - it's a legal peg maintained by Bulgarian National Bank
- Rate appears consistently in data from 2007-2008

**USD/BGL Rate: 1.57 (as of 2012)**
- Last recorded: October 1, 2012
- ⚠️ **OUTDATED** - needs current market rate (~1.80 as of 2025)

**EUR/USD Rate: 0.803 (as of 2012)**
- Last recorded: October 1, 2012
- ⚠️ **OUTDATED** - needs current market rate (~1.10 as of 2025)

**Critical Issue:** Exchange rates haven't been updated since 2012 (13 years outdated!)

---

## 🏗️ Architecture Pattern

### Purpose in System:
**Master Data Foundation** for multi-currency financial operations across entire ERP.

**Business Rules Implied:**
1. **Primary Currency:** BGL is the operational currency (internal transactions, local suppliers)
2. **Secondary Currencies:** EUR for EU suppliers, USD for international trade
3. **Currency Board:** EUR/BGL rate is fixed by law, not market-driven
4. **Default Behavior:** System defaults to BGL if currency not specified (based on NULL handling)

**Bulgarian Business Context:**
- **Bulgaria uses BGN (ISO code)**, not BGL (old code from pre-1999)
- **BGL = Old Bulgarian Lev** (1 BGN = 1000 BGL, redenomination in 1999)
- System likely built pre-1999 or never updated currency codes
- Modern systems should use **BGN** not BGL

**ISO 4217 Standard:**
- Current Bulgarian currency code: **BGN** (Bulgarian Lev)
- BGL is obsolete/deprecated
- Migration should update to BGN

---

## 🔄 PostgreSQL Migration

### Complexity: 2/5 (Low-Medium Complexity)

**Why Low-Medium Complexity:**
- ✅ Simple 4-row table (minimal data)
- ✅ Straightforward schema
- ⚠️ **17+ dependent tables** (must migrate first!)
- ⚠️ **Outdated currency codes** (BGL → BGN)
- ⚠️ **Outdated exchange rates** (13 years old)
- ⚠️ **Business-critical** (wrong currency = financial errors)

### Migration Strategy:

```sql
-- PostgreSQL Table Definition
CREATE TABLE currencies (
    id BIGINT PRIMARY KEY,
    code VARCHAR(3) NOT NULL UNIQUE, -- Renamed from 'Name' for clarity
    name VARCHAR(100), -- Add full currency name (NEW FIELD)
    symbol VARCHAR(10), -- Add currency symbol (NEW FIELD)
    decimal_places SMALLINT DEFAULT 2 NOT NULL, -- Add decimal precision (NEW FIELD)
    amount_base INTEGER DEFAULT 1 NOT NULL, -- Keep for compatibility
    is_active BOOLEAN DEFAULT FALSE NOT NULL, -- Renamed from 'Active'
    
    -- Audit trail (recommended additions)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    
    -- Validation
    CONSTRAINT chk_code_format CHECK (code ~ '^[A-Z]{3}$'), -- ISO 4217 format
    CONSTRAINT chk_decimal_places CHECK (decimal_places BETWEEN 0 AND 4)
);

-- Indexes
CREATE INDEX idx_currencies_code ON currencies(code);
CREATE INDEX idx_currencies_active ON currencies(is_active) WHERE is_active = TRUE;

-- Comments
COMMENT ON TABLE currencies IS 'Master reference table for currency definitions (ISO 4217)';
COMMENT ON COLUMN currencies.code IS 'ISO 4217 currency code (e.g., BGN, EUR, USD)';
COMMENT ON COLUMN currencies.name IS 'Full currency name (e.g., Bulgarian Lev, Euro)';
COMMENT ON COLUMN currencies.symbol IS 'Currency symbol for display (e.g., лв, €, $)';
COMMENT ON COLUMN currencies.decimal_places IS 'Number of decimal places (2 for most, 0 for JPY, 3 for BHD)';
COMMENT ON COLUMN currencies.amount_base IS 'Base amount for calculations (legacy field, typically 1)';
```

### Data Migration Script:

```sql
-- Phase 1: Migrate existing currencies WITH CORRECTIONS
INSERT INTO currencies (id, code, name, symbol, decimal_places, amount_base, is_active, created_at)
VALUES
    -- Skip ID=0 (invalid placeholder)
    (19, 'BGN', 'Bulgarian Lev', 'лв', 2, 1, TRUE, CURRENT_TIMESTAMP), -- CORRECTED: BGL → BGN
    (20, 'EUR', 'Euro', '€', 2, 1, TRUE, CURRENT_TIMESTAMP),
    (21, 'USD', 'US Dollar', '$', 2, 1, TRUE, CURRENT_TIMESTAMP);

-- Phase 2: Add commonly needed currencies (OPTIONAL ENHANCEMENTS)
INSERT INTO currencies (id, code, name, symbol, decimal_places, amount_base, is_active)
VALUES
    (22, 'GBP', 'British Pound', '£', 2, 1, TRUE),
    (23, 'CHF', 'Swiss Franc', 'CHF', 2, 1, TRUE),
    (24, 'JPY', 'Japanese Yen', '¥', 0, 1, TRUE), -- Note: 0 decimal places
    (25, 'CNY', 'Chinese Yuan', '¥', 2, 1, TRUE);

-- Verify count
SELECT COUNT(*) FROM currencies WHERE is_active = TRUE;
-- Expected: 3 (or 7 with enhancements)
```

### Update Dependent Tables:

```sql
-- Update all references from BGL (19) to use BGN code
-- This is a READ-ONLY change - IDs remain the same, only display code changes
-- Application layer should display currencies.code instead of old Name field

-- Example: Verify currency usage
SELECT 
    c.code AS currency_code,
    c.name AS currency_name,
    COUNT(*) AS usage_count
FROM invoices i
JOIN currencies c ON i.currency_id = c.id
GROUP BY c.code, c.name
ORDER BY usage_count DESC;
```

### Schema Changes:
- [x] Rename table: `doCurrency` → `currencies` (PostgreSQL naming)
- [x] Rename column: `Name` → `code` (clearer intent)
- [x] Rename column: `Active` → `is_active` (boolean naming convention)
- [x] **CRITICAL:** Update BGL → BGN (correct ISO 4217 code)
- [x] Add `name` column (full currency name)
- [x] Add `symbol` column (display symbol)
- [x] Add `decimal_places` column (precision config)
- [x] Add `created_at`, `updated_at` (audit trail)
- [x] Add unique constraint on `code`
- [x] Add validation check on `code` format (3 uppercase letters)

### Validation Queries:

```sql
-- Verify currency codes
SELECT id, code, name, symbol, is_active 
FROM currencies 
ORDER BY id;
-- Expected: 19=BGN, 20=EUR, 21=USD (all active)

-- Check for invalid currency references
SELECT 'invoices' AS table_name, COUNT(*) AS invalid_count
FROM invoices WHERE currency_id NOT IN (SELECT id FROM currencies)
UNION ALL
SELECT 'trades', COUNT(*) 
FROM trades WHERE currency_id NOT IN (SELECT id FROM currencies)
UNION ALL
SELECT 'cash_desks', COUNT(*) 
FROM cash_desks WHERE currency_id NOT IN (SELECT id FROM currencies);
-- Expected: 2 invalid (ID=0 references from old data)

-- Verify EUR/BGL fixed rate still valid
SELECT base_currency_id, rate_currency_id, rate, rate_date
FROM currency_rates
WHERE base_currency_id = 20 AND rate_currency_id = 19
ORDER BY rate_date DESC
LIMIT 1;
-- Expected: 1.9558 (fixed rate)
```

### Critical Data Cleanup:

```sql
-- Fix NULL currency in cash desks (set to default BGL/BGN)
UPDATE cash_desks 
SET currency_id = 19 -- BGN
WHERE currency_id IS NULL;

-- Fix invalid currency ID=0 references
UPDATE invoices SET currency_id = 19 WHERE currency_id = 0;
UPDATE trades SET currency_id = 19 WHERE currency_id = 0;

-- Verify cleanup
SELECT COUNT(*) FROM cash_desks WHERE currency_id IS NULL;
-- Expected: 0
```

### Estimated Migration Time: 2-3 hours
- Schema creation: 30 minutes
- Data migration + corrections: 45 minutes (includes BGL→BGN update)
- Dependent table validation: 60 minutes (17 tables to check)
- Exchange rate update (if needed): 30 minutes
- Testing & validation: 30 minutes

---

## ❓ Stakeholder Questions

### Currency Codes:
1. **BGL vs BGN:**
   - System uses **BGL** (obsolete code from pre-1999)
   - Modern ISO 4217 standard is **BGN** (Bulgarian Lev)
   - Should we update to BGN during migration?
   - **Recommendation:** Yes, update to BGN for standards compliance

2. **Currency Usage:**
   - Why is USD configured but almost never used?
   - Should we add other currencies (GBP, CHF, JPY, CNY)?
   - What determines which currencies are needed?

### Exchange Rates:
3. **EUR/BGN Fixed Rate:**
   - Confirm 1.9558 is still the legal fixed rate (currency board)
   - **Note:** This is Bulgarian law, not market rate
   - Does system enforce this fixed rate or allow manual override?

4. **Outdated Rates:**
   - Last USD/BGN rate from 2012 (13 years old!)
   - How are current exchange rates obtained?
   - Manual entry, API integration, or BNB (Bulgarian National Bank) feed?
   - **CRITICAL:** Need updated rates before production use

### Business Rules:
5. **Default Currency:**
   - What happens when currency is NULL? (23 cash desks)
   - Does system default to BGL/BGN automatically?
   - Should we enforce NOT NULL on currency columns?

6. **Multi-Currency Operations:**
   - How are split-currency transactions handled? (e.g., partial EUR, partial BGN)
   - Are exchange gains/losses tracked?
   - VAT implications for foreign currency transactions?

### Future State:
7. **Next.js/PostgreSQL Enhancements:**
   - Add currency display preferences per user/region?
   - Implement automatic exchange rate updates (ECB API, BNB API)?
   - Add currency conversion calculator in UI?
   - Track exchange rate history for audit?

---

## 🚨 Migration Risks

### High Priority:
1. **Critical Dependency (17+ tables):**
   - Currency table MUST migrate before any dependent tables
   - **Mitigation:** Enforce strict migration order, create dependency graph

2. **BGL → BGN Code Change:**
   - System-wide impact if application hardcodes "BGL"
   - **Mitigation:** Search codebase for "BGL" references, update to "BGN"
   - **Risk:** Display issues if currency codes hardcoded in UI

3. **Outdated Exchange Rates (13 years!):**
   - USD/EUR rates from 2012 are dangerously inaccurate
   - **Mitigation:** Update exchange rates before go-live
   - **Risk:** Financial errors if system uses old rates for new transactions

### Medium Priority:
4. **NULL Currency Values:**
   - 23 cash desks have NULL currency (45% of cash desks)
   - **Mitigation:** Set default to BGN (ID=19) during migration
   - **Risk:** Reporting/aggregation errors if NULL not handled

5. **Invalid Currency References (ID=0):**
   - 2 records reference non-existent currency ID=0
   - **Mitigation:** Set to BGN, log as data quality issue
   - **Risk:** Referential integrity violations in PostgreSQL

### Low Priority:
6. **Missing Metadata:**
   - No currency symbols, names, decimal places
   - **Mitigation:** Add during migration (quality enhancement)
   - **Risk:** Display inconsistencies, manual lookups needed

---

## 📝 Notes

### Key Insights:
1. **BGL is Obsolete:** System uses pre-1999 currency code, should migrate to BGN
2. **EUR/BGN Fixed Rate:** Bulgaria's currency board maintains 1.9558 fixed rate (legal requirement)
3. **99%+ BGL Usage:** Despite multi-currency support, system is effectively single-currency (Bulgarian Lev)
4. **Exchange Rates Abandoned:** Last update 2012, system may not be using them (or using external source)

### Bulgarian Currency Context:
- **1999 Redenomination:** 1 new BGN = 1000 old BGL (removed 3 zeros)
- **1997-Present:** Currency Board with EUR peg at 1.9558
- **EU Member (2007):** Bulgaria in EU but not Eurozone (keeps BGN)
- **Eurozone Target:** Bulgaria aims to adopt EUR (date TBD)

### ISO 4217 Standards:
| Old Code (used in system) | Current ISO Code | Full Name |
|---------------------------|------------------|-----------|
| BGL | **BGN** | Bulgarian Lev (лев) |
| (same) | EUR | Euro (€) |
| (same) | USD | United States Dollar ($) |

### Architectural Observations:
- **Design Pattern:** Classic lookup/reference table with minimal attributes
- **Missing Features:** No currency symbols, names, or decimal precision config
- **Performance:** 4 rows = negligible performance impact
- **Scalability:** Design supports adding more currencies easily

### PostgreSQL Best Practices for Currency:

```sql
-- Use NUMERIC for money, not FLOAT
CREATE TABLE example_with_currency (
    amount NUMERIC(15,2) NOT NULL, -- Use NUMERIC, never FLOAT/REAL
    currency_id BIGINT REFERENCES currencies(id),
    -- Store amount in currency's native precision
    CONSTRAINT chk_amount_positive CHECK (amount > 0)
);

-- Create view for currency conversion
CREATE VIEW amounts_in_bgn AS
SELECT 
    e.id,
    e.amount,
    e.currency_id,
    c.code AS currency_code,
    CASE 
        WHEN c.code = 'BGN' THEN e.amount
        WHEN c.code = 'EUR' THEN e.amount * 1.9558 -- Fixed rate
        ELSE e.amount * cr.rate -- Lookup current rate
    END AS amount_bgn
FROM example_with_currency e
JOIN currencies c ON e.currency_id = c.id
LEFT JOIN currency_rates cr ON c.id = cr.rate_currency_id 
    AND cr.base_currency_id = 19; -- BGN
```

### Business Intelligence Opportunities:

```sql
-- Currency usage report
SELECT 
    c.code,
    c.name,
    COUNT(DISTINCT i.id) AS invoice_count,
    SUM(i.total_amount) AS total_amount,
    AVG(i.total_amount) AS avg_amount
FROM invoices i
JOIN currencies c ON i.currency_id = c.id
GROUP BY c.code, c.name
ORDER BY invoice_count DESC;

-- Multi-currency risk assessment
SELECT 
    'High' AS risk_level,
    COUNT(*) AS count,
    SUM(total_amount) AS exposure
FROM invoices
WHERE currency_id != 19 -- Non-BGN transactions
  AND total_amount > 10000; -- Large amounts
```

### Migration Checklist:
- [ ] Search codebase for hardcoded "BGL" strings
- [ ] Update all "BGL" references to "BGN"
- [ ] Obtain current USD/BGN and EUR/USD exchange rates
- [ ] Validate EUR/BGN rate is still 1.9558 (currency board)
- [ ] Clean up NULL currencies (set to BGN)
- [ ] Fix invalid ID=0 references
- [ ] Add currency metadata (symbols, names, decimal places)
- [ ] Test currency dropdown in UI (should show BGN not BGL)
- [ ] Update exchange rate update process (manual vs API)
- [ ] Document Bulgarian currency board implications

---

## ✅ Analysis Complete

**Status:** ✅ DONE  
**Complexity:** 2/5 (Low-Medium - simple table but critical dependencies)  
**Migration Time Estimate:** 2-3 hours  
**Priority:** **CRITICAL** (master data for 17+ tables, entire financial system)  
**Dependencies:** MUST migrate BEFORE all 17 dependent tables  

**Data Quality:** ⚠️ Issues Found:
- Obsolete currency code (BGL → should be BGN)
- Outdated exchange rates (13 years old)
- NULL currency values (23 cash desks)
- Invalid currency references (ID=0)

**Business Logic:** ✅ Clear - Master currency reference with fixed EUR/BGN rate  
**Migration Risk:** ⚠️ Medium-High - Critical dependency, requires code updates (BGL→BGN)  

**Critical Actions Required:**
1. ✅ Update BGL → BGN (ISO 4217 compliance)
2. ✅ Update exchange rates (13 years outdated!)
3. ✅ Clean NULL/invalid currency references
4. ✅ Add missing metadata (symbols, names)
5. ✅ Search codebase for hardcoded "BGL" strings

---

**Previous:** 06-doInvoice-CashDesks.md  
**Next:** Continue with remaining Financial Domain tables or related currency tables (doCurrency-Rates)

---

## 🔗 Related Tables
- **Parent Table:** doDataObject (base entity)
- **Child Tables (17):** All financial, trade, product, and system tables with currency references
- **Critical Sibling:** doCurrency-Rates (exchange rate history)
- **Business Flow:** Currency Definition → Exchange Rates → All Monetary Transactions

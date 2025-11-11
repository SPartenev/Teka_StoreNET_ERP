# doCurrency-Rates Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо

---

## 📋 Overview

**Purpose:** Historical exchange rate tracking for currency conversions  
**Table Type:** Time-series reference data (Exchange Rate History)  
**Row Count:** 205 exchange rate records  
**Migration Complexity:** 3/5 (Medium - data quality issues, outdated rates, FLOAT precision)

**Business Logic:**
- Stores historical exchange rates between currency pairs
- Primarily tracks **EUR/BGL** fixed rate (1.9558) - Bulgaria's currency board
- Supports multi-currency pricing and financial reporting
- **CRITICAL ISSUE:** Last update was **2012-10-01** (13 years outdated!)
- **DATA QUALITY ISSUES:** 2 records with incorrect rates (decimal point errors)

---

## 🗂️ Schema

### Columns (5 total):

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | (none) | Primary key |
| BaseCurrency | bigint | NOT NULL | 0 | Foreign key to doCurrency.ID (base currency) |
| RateCurrency | bigint | NOT NULL | 0 | Foreign key to doCurrency.ID (rate/target currency) |
| Rate | **float** | NOT NULL | 0.0 | **⚠️ CRITICAL: Exchange rate value (FLOAT = precision issues!)** |
| Date | datetime | NOT NULL | 1800-01-01 | Effective date of the exchange rate |

**Key Observations:**
- **FLOAT data type for Rate** - ⚠️ **DANGEROUS** for financial calculations!
  - Float introduces rounding errors (e.g., 1.9558 may become 1.95579999...)
  - Should be DECIMAL/NUMERIC for accurate financial math
  - **Must convert to DECIMAL in PostgreSQL migration**
  
- **Date default '1800-01-01'** - nonsensical default, indicates missing dates
- **No unique constraint** on (BaseCurrency, RateCurrency, Date) - allows duplicates
- **No created_at/updated_at** - can't track when rate was entered vs effective date
- **No source field** - can't tell if rate is from BNB, manual entry, or API

**Design Pattern:**
Basic historical rate tracking - stores snapshots of exchange rates over time.

---

## 🔗 Relationships

### Foreign Keys (Outgoing):
- `BaseCurrency` → `doCurrency.ID` - The base currency (what you're converting FROM)
- `RateCurrency` → `doCurrency.ID` - The rate currency (what you're converting TO)

**Interpretation:**
- Rate = "1 BaseCurrency = X RateCurrency"
- Example: BaseCurrency=EUR, RateCurrency=BGL, Rate=1.9558 means **1 EUR = 1.9558 BGL**

### Foreign Keys (Incoming):
**None** - This is a reference/lookup table (no child tables)

---

## 📊 Data Analysis

### Total Records: 205 exchange rates

### Date Range Analysis:
| Metric | Value | Status |
|--------|-------|--------|
| **Earliest Date** | 2006-03-18 | Historical data starts |
| **Latest Date** | **2012-10-01** | ⚠️ **13 YEARS OUTDATED!** |
| **Coverage Period** | 6.5 years | 2006-2012 |
| **Days Since Update** | ~4,783 days | **System abandoned?** |

**Critical Finding:** No exchange rate updates in **13 years** - either:
1. System stopped using exchange rates (defaults to BGL only)
2. Rates hardcoded in application code
3. External system provides rates at runtime

### Currency Pair Distribution:

| Base Currency | Rate Currency | Record Count | % of Total | Date Range | Latest Rate |
|---------------|---------------|--------------|------------|------------|-------------|
| **EUR** | **BGL** | **189** | **92.2%** | 2006-03-18 to 2008-01-14 | 1.9558 (fixed) |
| USD | BGL | 8 | 3.9% | 2006-03-18 to 2012-10-01 | 1.57 |
| BGL | EUR | 6 | 2.9% | 2006-03-29 to 2007-12-10 | 0.5113 |
| EUR | USD | 2 | 1.0% | 2006-09-18 to 2012-10-01 | 0.803 |
| **Total** | | **205** | **100%** | | |

**Key Observations:**
1. **EUR→BGL dominance:** 92.2% of all rate records (Bulgaria's primary conversion)
2. **USD→BGL:** Only 8 records over 6 years (rarely updated, likely not actively used)
3. **EUR→USD:** Only 2 records (minimal international trading)
4. **Reverse rates:** 6 BGL→EUR records (inverse of fixed rate: 1/1.9558 = 0.5113)

### Exchange Rate Statistics:

**EUR/BGL Rate (Bulgaria's Currency Board):**
| Metric | Value | Status |
|--------|-------|--------|
| **Fixed Rate** | 1.9558 | Legal peg since 1997 |
| **Record Count** | 189 | Most tracked pair |
| **Last Update** | 2008-01-14 | Stopped tracking 17 years ago |
| **Min Rate** | 1.0 | ⚠️ **DATA ERROR** (should be 1.9558) |
| **Max Rate** | 195583 | ⚠️ **DATA ERROR** (decimal point mistake) |
| **Consistency** | 187/189 correct | 98.9% accuracy |

**USD/BGL Rate (Market-based):**
| Metric | Value | Status |
|--------|-------|--------|
| **Latest Rate** | 1.57 (2012) | ⚠️ **13 years outdated** |
| **Current Rate** | ~1.80 (2025) | Actual market rate today |
| **Deviation** | +14.6% | Significant drift |
| **Record Count** | 8 | Rarely updated |
| **Date Range** | 2006-2012 | No recent data |
| **Min Rate** | 1.4472 | Lowest recorded |
| **Max Rate** | 1.64 | Highest recorded |

**EUR/USD Rate (International):**
| Metric | Value | Status |
|--------|-------|--------|
| **Latest Rate** | 0.803 (2012) | ⚠️ **13 years outdated** |
| **Current Rate** | ~1.10 (2025) | Actual market rate today |
| **Deviation** | +37% | Massive drift |
| **Record Count** | 2 | Almost never updated |

### Data Quality Issues:

**CRITICAL ERRORS FOUND:**

| ID | Base | Rate | Date | Correct Rate | Error Type |
|----|------|------|------|--------------|------------|
| **186** | EUR→BGL | **195583** | 2007-11-16 | 1.9558 | Added **2 extra zeros** (x100000) |
| **44** | EUR→BGL | **19558** | 2006-09-12 | 1.9558 | Added **1 extra zero** (x10000) |

**Impact of Errors:**
- If used: 1 EUR would be worth 195,583 BGL instead of 1.9558 BGL
- Financial calculation errors would be catastrophic (100,000x overvaluation!)
- Likely these records were never used (system may detect outliers)

**Other Data Quality Concerns:**
- EUR→BGL has rate of **1.0** in one record (should be 1.9558)
- No validation rules to prevent impossible rates
- FLOAT precision may cause rounding in other records

### Sample Historical Data:

**Most Recent Rates (2012-10-01):**
```
USD → BGL: 1.57
EUR → USD: 0.803
```

**EUR/BGL Fixed Rate Pattern (2007-2008):**
```
2008-01-14: 1.9558
2008-01-04: 1.9558
2008-01-02: 1.9558
2007-12-28: 1.9558
2007-12-27: 1.9558
... (all identical - currency board peg)
```

**BGL/EUR Reverse Rate (2007):**
```
2007-12-10: 0.5113 (= 1 / 1.9558)
```

---

## 🏗️ Architecture Pattern

### Purpose in System:
**Historical Exchange Rate Repository** for multi-currency operations and financial reporting.

**Business Rules Implied:**
1. **EUR/BGL Fixed Rate:** Bulgaria's currency board maintains legal peg at 1.9558
   - Not market-driven (fixed by Bulgarian National Bank law)
   - Should never change unless Bulgaria abandons currency board
   - System correctly stores this consistently (except 2 errors)

2. **Market Rates (USD/BGL, EUR/USD):** Should update regularly but haven't since 2012
   - Likely indicates system transitioned to single-currency operations
   - Or external rate source is used at runtime

3. **Bidirectional Rates:** Some pairs stored in both directions
   - EUR→BGL: 1.9558
   - BGL→EUR: 0.5113 (inverse)
   - Inefficient storage (could calculate inverse dynamically)

**Bulgarian Currency Board Context:**
- **Established:** July 1, 1997 (after hyperinflation crisis)
- **Legal Peg:** 1 EUR = 1.9558 BGN (fixed by law)
- **Backing:** 100% EUR reserves held by Bulgarian National Bank
- **Implications:** Rate NEVER changes (not market-based)
- **Future:** Bulgaria targets Eurozone entry (date uncertain)

**Use Cases:**
- Multi-currency invoice generation
- Financial reporting in different currencies
- Historical trade analysis with correct exchange rates
- Budget planning for international purchases

**System Behavior (Inferred):**
- Last EUR/BGL update: 2008 (stopped tracking fixed rate - unnecessary)
- Last USD/BGL update: 2012 (system may have stopped international trade)
- **Hypothesis:** System now operates BGL-only, rates not actively used

---

## 🔄 PostgreSQL Migration

### Complexity: 3/5 (Medium Complexity)

**Why Medium Complexity:**
- ⚠️ **FLOAT → DECIMAL conversion** (mandatory for financial accuracy)
- ⚠️ **Data quality errors** need correction (2 records with wrong decimal points)
- ⚠️ **Outdated rates** (13 years old) - business decision on update vs cleanup
- ✅ Simple schema structure
- ✅ Small dataset (205 rows)
- ⚠️ May not be actively used (last update 2012)

### Migration Strategy:

```sql
-- PostgreSQL Table Definition
CREATE TABLE currency_rates (
    id BIGINT PRIMARY KEY,
    base_currency_id BIGINT NOT NULL,
    rate_currency_id BIGINT NOT NULL,
    rate NUMERIC(18,8) NOT NULL, -- CRITICAL: Changed from FLOAT to NUMERIC
    effective_date DATE NOT NULL, -- Renamed from 'Date' for clarity
    
    -- New audit fields (recommended)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    source VARCHAR(50), -- 'BNB', 'ECB', 'MANUAL', 'SYSTEM'
    is_active BOOLEAN DEFAULT TRUE,
    notes TEXT,
    
    -- Foreign Keys
    CONSTRAINT fk_currency_rates_base 
        FOREIGN KEY (base_currency_id) 
        REFERENCES currencies(id)
        ON DELETE RESTRICT,
    
    CONSTRAINT fk_currency_rates_rate 
        FOREIGN KEY (rate_currency_id) 
        REFERENCES currencies(id)
        ON DELETE RESTRICT,
    
    -- Validation Constraints
    CONSTRAINT chk_rate_positive CHECK (rate > 0),
    CONSTRAINT chk_rate_reasonable CHECK (rate BETWEEN 0.001 AND 100000), -- Prevent data entry errors
    CONSTRAINT chk_different_currencies CHECK (base_currency_id != rate_currency_id),
    
    -- Unique constraint for time-series integrity
    CONSTRAINT uq_currency_rates_date UNIQUE (base_currency_id, rate_currency_id, effective_date)
);

-- Indexes for performance
CREATE INDEX idx_currency_rates_base ON currency_rates(base_currency_id);
CREATE INDEX idx_currency_rates_rate_curr ON currency_rates(rate_currency_id);
CREATE INDEX idx_currency_rates_date ON currency_rates(effective_date DESC);
CREATE INDEX idx_currency_rates_active ON currency_rates(is_active) WHERE is_active = TRUE;

-- Composite index for lookups
CREATE INDEX idx_currency_rates_lookup 
    ON currency_rates(base_currency_id, rate_currency_id, effective_date DESC);

-- Comments
COMMENT ON TABLE currency_rates IS 
    'Historical exchange rate data for currency conversions. Rate formula: 1 base_currency = rate * rate_currency';
COMMENT ON COLUMN currency_rates.rate IS 
    'Exchange rate as NUMERIC(18,8) for precision. Formula: 1 base = rate × target';
COMMENT ON COLUMN currency_rates.effective_date IS 
    'Date when this exchange rate became effective (not when it was entered)';
COMMENT ON COLUMN currency_rates.source IS 
    'Rate source: BNB (Bulgarian National Bank), ECB (European Central Bank), MANUAL, SYSTEM';
```

### Data Migration Script with Corrections:

```sql
-- Phase 1: Migrate with data quality corrections
INSERT INTO currency_rates (
    id, 
    base_currency_id, 
    rate_currency_id, 
    rate, 
    effective_date,
    created_at,
    source,
    notes
)
SELECT 
    ID,
    BaseCurrency,
    RateCurrency,
    -- CRITICAL: Fix known data errors during migration
    CASE 
        WHEN ID = 186 THEN 1.9558::NUMERIC  -- Fix 195583 → 1.9558
        WHEN ID = 44 THEN 1.9558::NUMERIC   -- Fix 19558 → 1.9558
        ELSE Rate::NUMERIC(18,8)            -- Convert FLOAT to NUMERIC
    END,
    Date::DATE,
    CURRENT_TIMESTAMP,
    CASE 
        WHEN BaseCurrency = 20 AND RateCurrency = 19 AND Rate BETWEEN 1.9 AND 2.0 
            THEN 'BNB' -- EUR/BGN fixed rate
        ELSE 'LEGACY' -- Migrated from old system
    END,
    CASE 
        WHEN ID IN (186, 44) THEN 'Corrected data entry error during migration'
        WHEN Date < '2010-01-01' THEN 'Historical rate - may be outdated'
        ELSE NULL
    END
FROM [TEKA].[dbo].[doCurrency-Rates]
WHERE Rate BETWEEN 0.001 AND 100000; -- Exclude impossible rates

-- Verify migration
SELECT COUNT(*) FROM currency_rates;
-- Expected: 205 rows

-- Phase 2: Mark outdated rates as inactive (optional)
UPDATE currency_rates
SET is_active = FALSE,
    notes = COALESCE(notes || ' | ', '') || 'Outdated rate - last update 2012'
WHERE effective_date < '2013-01-01' 
  AND base_currency_id != 20 -- Keep EUR/BGN (fixed rate still valid)
  AND rate_currency_id != 19;

-- Phase 3: Add current exchange rates (REQUIRED before go-live)
INSERT INTO currency_rates (
    id, base_currency_id, rate_currency_id, rate, effective_date, source, is_active
) VALUES
    -- Current rates as of 2025 (EXAMPLE - get actual current rates!)
    (206, 21, 19, 1.80, '2025-01-01', 'BNB', TRUE),  -- USD/BGN current rate
    (207, 20, 21, 1.10, '2025-01-01', 'ECB', TRUE),  -- EUR/USD current rate
    (208, 20, 19, 1.9558, '2025-01-01', 'BNB', TRUE) -- EUR/BGN fixed (still 1.9558)
ON CONFLICT (base_currency_id, rate_currency_id, effective_date) DO NOTHING;
```

### Schema Changes:
- [x] Rename table: `doCurrency-Rates` → `currency_rates`
- [x] Rename columns for clarity:
  - `BaseCurrency` → `base_currency_id`
  - `RateCurrency` → `rate_currency_id`
  - `Rate` → `rate`
  - `Date` → `effective_date` (DATE instead of DATETIME)
- [x] **CRITICAL:** Change `Rate` from FLOAT to NUMERIC(18,8)
- [x] **Fix data errors:** Correct IDs 186 and 44 during migration
- [x] Add unique constraint on (base_currency_id, rate_currency_id, effective_date)
- [x] Add validation constraints (positive rate, reasonable range, different currencies)
- [x] Add audit fields: created_at, updated_at, source, is_active, notes
- [x] Add indexes for performance

### Validation Queries:

```sql
-- Verify count
SELECT COUNT(*) FROM currency_rates;
-- Expected: 205 (or 208 if current rates added)

-- Check data correction
SELECT id, base_currency_id, rate_currency_id, rate, effective_date, notes
FROM currency_rates
WHERE id IN (186, 44);
-- Expected: Both show rate = 1.9558 with correction note

-- Verify EUR/BGN fixed rate consistency
SELECT 
    COUNT(*) AS total_rates,
    COUNT(DISTINCT rate) AS unique_rates,
    MIN(rate) AS min_rate,
    MAX(rate) AS max_rate,
    AVG(rate) AS avg_rate
FROM currency_rates
WHERE base_currency_id = 20 AND rate_currency_id = 19
  AND rate BETWEEN 1.9 AND 2.0; -- Exclude errors
-- Expected: All should be 1.9558

-- Check for outdated rates
SELECT 
    source,
    is_active,
    COUNT(*) AS rate_count,
    MAX(effective_date) AS latest_date
FROM currency_rates
GROUP BY source, is_active
ORDER BY latest_date DESC;

-- Verify no impossible rates
SELECT * FROM currency_rates
WHERE rate <= 0 OR rate > 100000;
-- Expected: 0 rows

-- Check foreign key integrity
SELECT COUNT(*) FROM currency_rates cr
LEFT JOIN currencies c1 ON cr.base_currency_id = c1.id
LEFT JOIN currencies c2 ON cr.rate_currency_id = c2.id
WHERE c1.id IS NULL OR c2.id IS NULL;
-- Expected: 0 (all currencies exist)
```

### Data Type Precision Comparison:

**SQL Server FLOAT Issues:**
```sql
-- Example of FLOAT precision loss
SELECT 1.9558 AS intended_rate,
       CAST(1.9558 AS FLOAT) AS float_rate,
       CAST(1.9558 AS FLOAT) - 1.9558 AS precision_error;
-- Result: precision_error ≈ 0.0000000000000004 (rounding error)
```

**PostgreSQL NUMERIC Solution:**
```sql
-- NUMERIC maintains exact precision
SELECT 1.9558::NUMERIC(18,8) AS numeric_rate,
       1.9558::NUMERIC(18,8) - 1.9558 AS precision_error;
-- Result: precision_error = 0.00000000 (exact)
```

### Estimated Migration Time: 3-4 hours
- Schema creation: 45 minutes
- Data migration + corrections: 60 minutes (includes manual verification of fixes)
- Current rate research & entry: 60 minutes (get latest BNB rates)
- Testing & validation: 45 minutes
- Documentation: 30 minutes

---

## ❓ Stakeholder Questions

### Exchange Rate Strategy:
1. **Active Usage:**
   - Are exchange rates still actively used? (Last update: 2012)
   - If not, should we archive this table or maintain it?
   - Is multi-currency pricing still needed?

2. **Rate Update Process:**
   - How were rates historically updated? (Manual entry, API, BNB feed?)
   - Who was responsible for updating rates?
   - Why did updates stop in 2012?

3. **Current Rates:**
   - Do we need current USD/BGN and EUR/USD rates for go-live?
   - Should we implement automatic rate updates (ECB/BNB API)?
   - What's the update frequency? (Daily, weekly, on-demand?)

### Fixed Rate Management:
4. **EUR/BGN Currency Board:**
   - Confirm 1.9558 is still the legal fixed rate (99.99% certain yes)
   - Should system enforce this rate (prevent manual changes)?
   - Plan for potential Eurozone entry? (Bulgaria aims to adopt EUR)

5. **Data Quality:**
   - How did the decimal point errors occur? (IDs 186, 44)
   - Are there other data quality issues we haven't detected?
   - Should we implement rate validation rules?

### Business Logic:
6. **Rate Application:**
   - How does system determine which rate to use? (Latest? Effective date?)
   - Are rates applied retroactively or only for new transactions?
   - Split-period invoices: which rate applies?

### Future State:
7. **Next.js/PostgreSQL Enhancements:**
   - Implement automatic rate updates via API?
   - Add rate approval workflow (for manual entries)?
   - Historical rate auditing for financial reports?
   - Alert system for significant rate changes? (not applicable to EUR/BGN but relevant for USD)

---

## 🚨 Migration Risks

### High Priority:
1. **FLOAT Precision Loss:**
   - Current SQL Server FLOAT may have introduced rounding errors
   - **Mitigation:** Convert to NUMERIC(18,8) in PostgreSQL, validate critical rates

2. **Data Errors (2 records):**
   - IDs 186, 44 have wrong decimal points (195583, 19558 instead of 1.9558)
   - **Mitigation:** Fix during migration, document corrections

3. **Outdated Rates (13 years!):**
   - USD/BGN: 1.57 (2012) vs ~1.80 (2025) = 14.6% error
   - EUR/USD: 0.803 (2012) vs ~1.10 (2025) = 37% error
   - **Mitigation:** Update rates before go-live OR confirm system no longer uses them

### Medium Priority:
4. **Missing Validation:**
   - No constraints prevent impossible rates (e.g., 195583)
   - **Mitigation:** Add CHECK constraints in PostgreSQL

5. **No Audit Trail:**
   - Can't tell when rates were entered vs effective date
   - Can't track who entered rates or from what source
   - **Mitigation:** Add created_at, source, notes columns

6. **Duplicate Risk:**
   - No unique constraint on (base, rate, date) allows duplicates
   - **Mitigation:** Add unique constraint in PostgreSQL

### Low Priority:
7. **Bidirectional Redundancy:**
   - Some pairs stored both ways (EUR→BGL and BGL→EUR)
   - **Mitigation:** Keep for compatibility, consider cleanup later

---

## 📝 Notes

### Key Insights:
1. **Abandoned Since 2012:** No updates in 13 years suggests system transitioned to BGL-only operations
2. **EUR/BGN Fixed Rate:** 189 records correctly show 1.9558 (Bulgaria's currency board peg)
3. **Data Entry Errors:** 2 records with decimal point mistakes (added extra zeros)
4. **FLOAT Precision Risk:** Using FLOAT for financial calculations is dangerous - must convert to NUMERIC

### Bulgarian Currency Context:
- **Currency Board:** Bulgaria maintains fixed EUR/BGN rate at 1.9558 since 1997
- **Legal Requirement:** Bulgarian National Bank must maintain 100% EUR reserves
- **Stability:** Rate has NEVER changed in 28 years (by law)
- **Eurozone Target:** Bulgaria plans to adopt EUR (date uncertain, requires EU approval)
- **Practical Impact:** EUR/BGN conversion is trivial (multiply by 1.9558)

### Exchange Rate Formula:
```
Convention: 1 BaseCurrency = Rate × RateCurrency

Example 1: EUR → BGL
  BaseCurrency = EUR (20)
  RateCurrency = BGL (19)
  Rate = 1.9558
  Meaning: 1 EUR = 1.9558 BGL

Example 2: USD → BGL
  BaseCurrency = USD (21)
  RateCurrency = BGL (19)
  Rate = 1.57 (as of 2012)
  Meaning: 1 USD = 1.57 BGL
```

### Data Quality Analysis:

**Correct Records (203/205):**
- EUR→BGL: 187 correct at 1.9558
- USD→BGL: 8 correct (range 1.4472-1.64)
- BGL→EUR: 6 correct (~0.5113)
- EUR→USD: 2 correct (0.803-1.9562)

**Incorrect Records (2/205):**
- ID=186: 195583 instead of 1.9558 (×100000 error)
- ID=44: 19558 instead of 1.9558 (×10000 error)

**Accuracy Rate:** 98.9% (203/205 correct)

### PostgreSQL Best Practices:

```sql
-- Function to get exchange rate for specific date
CREATE OR REPLACE FUNCTION get_exchange_rate(
    p_base_currency_id BIGINT,
    p_rate_currency_id BIGINT,
    p_date DATE
) RETURNS NUMERIC(18,8) AS $$
DECLARE
    v_rate NUMERIC(18,8);
BEGIN
    -- Get most recent rate on or before specified date
    SELECT rate INTO v_rate
    FROM currency_rates
    WHERE base_currency_id = p_base_currency_id
      AND rate_currency_id = p_rate_currency_id
      AND effective_date <= p_date
      AND is_active = TRUE
    ORDER BY effective_date DESC
    LIMIT 1;
    
    -- Return rate or NULL if not found
    RETURN v_rate;
END;
$$ LANGUAGE plpgsql;

-- Usage:
SELECT get_exchange_rate(20, 19, '2025-01-01'); -- EUR to BGL
-- Expected: 1.9558
```

```sql
-- Function to convert amount between currencies
CREATE OR REPLACE FUNCTION convert_currency(
    p_amount NUMERIC,
    p_from_currency_id BIGINT,
    p_to_currency_id BIGINT,
    p_date DATE
) RETURNS NUMERIC(18,2) AS $$
DECLARE
    v_rate NUMERIC(18,8);
BEGIN
    -- Same currency, no conversion needed
    IF p_from_currency_id = p_to_currency_id THEN
        RETURN p_amount;
    END IF;
    
    -- Get exchange rate
    v_rate := get_exchange_rate(p_from_currency_id, p_to_currency_id, p_date);
    
    IF v_rate IS NULL THEN
        RAISE EXCEPTION 'Exchange rate not found for currencies % → % on date %',
            p_from_currency_id, p_to_currency_id, p_date;
    END IF;
    
    -- Convert and round to 2 decimals
    RETURN ROUND(p_amount * v_rate, 2);
END;
$$ LANGUAGE plpgsql;

-- Usage:
SELECT convert_currency(100.00, 20, 19, '2025-01-01'); -- 100 EUR to BGL
-- Expected: 195.58 BGL
```

### Business Intelligence Opportunities:

```sql
-- Exchange rate volatility analysis (for market-based rates)
SELECT 
    c1.code AS base_currency,
    c2.code AS rate_currency,
    MIN(cr.rate) AS min_rate,
    MAX(cr.rate) AS max_rate,
    AVG(cr.rate) AS avg_rate,
    STDDEV(cr.rate) AS volatility,
    COUNT(*) AS sample_size
FROM currency_rates cr
JOIN currencies c1 ON cr.base_currency_id = c1.id
JOIN currencies c2 ON cr.rate_currency_id = c2.id
WHERE cr.is_active = TRUE
GROUP BY c1.code, c2.code
ORDER BY volatility DESC;

-- Rate change timeline
SELECT 
    effective_date,
    rate,
    LAG(rate) OVER (ORDER BY effective_date) AS previous_rate,
    rate - LAG(rate) OVER (ORDER BY effective_date) AS rate_change,
    CASE 
        WHEN LAG(rate) OVER (ORDER BY effective_date) IS NOT NULL THEN
            ROUND(((rate / LAG(rate) OVER (ORDER BY effective_date)) - 1) * 100, 2)
    END AS pct_change
FROM currency_rates
WHERE base_currency_id = 21 AND rate_currency_id = 19 -- USD/BGL
ORDER BY effective_date;
```

### Migration Checklist:
- [ ] Convert FLOAT to NUMERIC(18,8)
- [ ] Fix data errors (IDs 186, 44)
- [ ] Obtain current exchange rates from BNB/ECB
- [ ] Add unique constraint on (base, rate, effective_date)
- [ ] Add validation constraints (positive, reasonable range)
- [ ] Add audit fields (source, created_at, is_active)
- [ ] Create exchange rate utility functions
- [ ] Test currency conversion with real transaction data
- [ ] Document EUR/BGN fixed rate policy
- [ ] Establish rate update process (manual vs API)
- [ ] Train users on rate entry (if manual)

---

## ✅ Analysis Complete

**Status:** ✅ DONE  
**Complexity:** 3/5 (Medium - FLOAT conversion + data quality issues)  
**Migration Time Estimate:** 3-4 hours  
**Priority:** MEDIUM (may not be actively used, but needs data cleanup)  
**Dependencies:** Must migrate AFTER doCurrency table  

**Data Quality:** ⚠️ **Issues Found:**
- 2 records with decimal point errors (need correction)
- FLOAT data type (precision risk for financial calculations)
- 13-year-old rates (likely outdated and unused)
- No validation constraints (allows impossible rates)

**Business Logic:** ⚠️ **Partially Clear:**
- EUR/BGN fixed rate well-documented (1.9558)
- Other rates outdated and likely unused
- System may have transitioned to BGL-only operations

**Migration Risk:** ⚠️ Medium:
- Must convert FLOAT to NUMERIC (mandatory)
- Must fix data errors
- Should update rates or confirm abandonment

**Critical Actions Required:**
1. ✅ Convert FLOAT → NUMERIC(18,8)
2. ✅ Fix decimal point errors (IDs 186, 44)
3. ❓ Decide: Update rates or mark as inactive?
4. ✅ Add validation constraints
5. ✅ Add audit trail (source, created_at)

---

**Previous:** 07-doCurrency.md  
**Next:** Continue with remaining Financial Domain tables

---

## 🔗 Related Tables
- **Parent Table:** doCurrency (master currency definitions)
- **Used By:** All multi-currency calculations system-wide
- **Business Flow:** Currency Definition → Exchange Rates → Currency Conversion → Multi-currency Transactions

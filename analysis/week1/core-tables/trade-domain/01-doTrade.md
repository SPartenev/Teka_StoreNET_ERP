# doTrade - Main Sales Transaction Entity

**Domain:** Trade  
**Table Type:** Main Transaction Entity  
**Analysis Date:** 2025-11-10  
**Status:** ✅ COMPLETE

---

## 📊 QUICK SUMMARY

- **Volume:** 365,771 trade records
- **Date Range:** 2006-03-20 to 3013-05-30 (⚠️ **FUTURE DATE BUG!**)
- **Total Revenue:** 98,246,252.21 BGN
- **Average Trade Value:** 268.62 BGN
- **Unique Customers:** 14,296 contractors
- **Currencies Used:** 3 (likely BGN, EUR, USD)

### Key Metrics:
- ✅ **Paid Off:** 364,129 trades (99.55%)
- ✅ **Delivered:** 365,613 trades (99.96%)
- ⚠️ **Canceled:** 24,225 trades (6.62%)
- ⚠️ **Returned:** 331 trades (0.09%)

---

## 📋 SCHEMA (50 columns)

| # | Column | Type | Nullable | Default | Description |
|---|--------|------|----------|---------|-------------|
| 1 | **ID** | bigint | NO | 0 | Primary key |
| 2 | TradeId | int | NO | 0 | Business trade number |
| 3 | Operation | int | NO | 1 | Operation type (1=Sale, 2=?) |
| 4 | PaymentType | int | NO | 1 | Payment method enum |
| 5 | IsFormal | bit | NO | 0 | Formal/informal transaction flag |
| 6 | **Contractor** | bigint | NO | 0 | FK → doContractor (customer) |
| 7 | **Currency** | bigint | NO | 0 | FK → doCurrency |
| 8 | TotalAmount | decimal | YES | NULL | Total trade amount (pre-tax) |
| 9 | HasTaxPercent | bit | NO | 0 | Whether tax applies |
| 10 | TotalTaxAmount | decimal | YES | NULL | Total VAT amount |
| 11 | TaxPercent | float | NO | 0.0 | Tax percentage (e.g., 0.2 = 20%) |
| 12 | TotalPrimeCost | decimal | NO | 0.0 | Cost of goods sold |
| 13 | AffectsStoreRequest | bit | NO | 0 | Impacts inventory requests |
| 14 | AffectsStoreRequestRollback | bit | NO | 0 | Rollback inventory changes |
| 15 | PrimeCostFinanceAmount | decimal | NO | 0.0 | Financial prime cost |
| 16 | EnableCompletion | bit | NO | 0 | Can be marked complete |
| 17 | **IsCompleted** | bit | NO | 0 | Trade completion status |
| 18 | UserCompleted | bigint | YES | NULL | FK → doUserAccount (who completed) |
| 19 | TimeCompleted | datetime | YES | NULL | When completed |
| 20 | IsCompletionConfirmed | bit | NO | 0 | Completion confirmed |
| 21 | UserCompletionConfirmed | bigint | YES | NULL | FK → doUserAccount (who confirmed) |
| 22 | TimeCompletionConfirmed | datetime | YES | NULL | When confirmed |
| 23 | **DateOfPayment** | datetime | YES | NULL | Payment date |
| 24 | PaidAmount | decimal | NO | 0.0 | Amount paid |
| 25 | PaidTaxAmount | decimal | NO | 0.0 | Tax paid |
| 26 | ActualPaidCost | decimal | NO | 0.0 | Total paid (amount + tax) |
| 27 | **IsPaidoff** | bit | NO | 0 | Payment complete flag |
| 28 | TimePaidoff | datetime | YES | NULL | When paid off |
| 29 | DatePaidoff | smalldatetime | YES | NULL | Date paid off |
| 30 | DeliveredAmount | decimal | NO | 0.0 | Amount delivered |
| 31 | DeliveredTaxAmount | decimal | NO | 0.0 | Tax on delivered |
| 32 | **IsDelivered** | bit | NO | 0 | Delivery complete flag |
| 33 | TimeDelivered | datetime | YES | NULL | When delivered |
| 34 | DateDelivered | datetime | YES | NULL | Date delivered |
| 35 | CanceledAmount | decimal | NO | 0.0 | Amount canceled |
| 36 | CanceledTaxAmount | decimal | NO | 0.0 | Tax on canceled |
| 37 | CanceledPaidAmount | decimal | NO | 0.0 | Paid amount canceled |
| 38 | CanceledPaidTaxAmount | decimal | NO | 0.0 | Paid tax canceled |
| 39 | **IsCanceled** | bit | NO | 0 | Cancellation flag |
| 40 | TimeCanceled | datetime | YES | NULL | When canceled |
| 41 | DateCanceled | datetime | YES | NULL | Date canceled |
| 42 | ReturnedAmount | decimal | NO | 0.0 | Amount returned |
| 43 | ReturnedTaxAmount | decimal | NO | 0.0 | Tax on returned |
| 44 | ReturnedPaidAmount | decimal | NO | 0.0 | Paid amount returned |
| 45 | ReturnedPaidTaxAmount | decimal | NO | 0.0 | Paid tax returned |
| 46 | **IsReturned** | bit | NO | 0 | Return flag |
| 47 | TimeReturned | datetime | YES | NULL | When returned |
| 48 | DateReturned | datetime | YES | NULL | Date returned |
| 49 | ProductReceipt | bigint | YES | NULL | FK → doProductReceipt (linked receipt) |
| 50 | AutomaticAssembly | bigint | YES | NULL | FK → doAutomaticStoreAssembly |

---

## 🔗 RELATIONSHIPS (7 Foreign Keys)

| FK Name | Column | → Referenced Table | Referenced Column |
|---------|--------|-------------------|-------------------|
| FK_doTrade_AutomaticAssembly | AutomaticAssembly | doAutomaticStoreAssembly | ID |
| FK_doTrade_Contractor | Contractor | doContractor | ID |
| FK_doTrade_Currency | Currency | doCurrency | ID |
| FK_doTrade_ID | ID | doTradeTransaction | ID |
| FK_doTrade_ProductReceipt | ProductReceipt | doProductReceipt | ID |
| FK_doTrade_UserCompleted | UserCompleted | doUserAccount | ID |
| FK_doTrade_UserCompletionConfirmed | UserCompletionConfirmed | doUserAccount | ID |

### Key Dependencies:
- **doTradeTransaction** (1:1 relationship via ID) - transaction metadata
- **doContractor** - customer/supplier information
- **doCurrency** - financial currency
- **doProductReceipt** - optional receipt linkage
- **doUserAccount** - audit trail (completion, confirmation)

---

## 🔍 KEY FINDINGS

### ✅ Strengths:
1. **High completion rate:** 99.55% trades paid off, 99.96% delivered
2. **Comprehensive audit trail:** Tracks completion, confirmation, payment, delivery, cancellation, return
3. **Proper financial tracking:** Separate amounts for base, tax, paid, delivered, canceled, returned
4. **Low return rate:** Only 0.09% returns (331 out of 365K)

### ⚠️ Issues & Risks:

#### 1. **CRITICAL: Future Date Bug**
```
Max Date: 3013-05-30 (989 years in the future!)
```
- **Impact:** Data quality issue, likely input error or default value problem
- **Action Required:** Investigate dates > 2025, identify root cause

#### 2. **Float Data Type for Tax**
```sql
TaxPercent float -- Should be decimal(5,4)
```
- **Risk:** Precision errors in financial calculations
- **Migration Fix:** Convert to `NUMERIC(5,4)` in PostgreSQL

#### 3. **Complex State Management**
- 8 boolean flags (IsCompleted, IsPaidoff, IsDelivered, IsCanceled, IsReturned, etc.)
- Potential for inconsistent states (e.g., Delivered=1 but Canceled=1)
- **Recommendation:** Add CHECK constraints or state machine validation

#### 4. **Redundant Date Columns**
```sql
TimePaidoff (datetime)
DatePaidoff (smalldatetime)
```
- Two columns for same data, different precision
- **Migration:** Consolidate to single TIMESTAMPTZ column

#### 5. **High Cancellation Rate**
- 6.62% cancellation rate (24,225 trades) is significant
- **Business Question:** Why are so many trades canceled? Process improvement needed?

#### 6. **Missing Store Reference**
- No direct FK to doStore (location where trade occurred)
- Likely linked via doTradeTransaction or another table
- **Verify:** Check doTradeTransaction for Store column

---

## 📊 SAMPLE DATA ANALYSIS

From TOP 20 records:
- **TradeId values:** 0, 27613-343370 (business ID, not sequential)
- **Operation:** 1 (majority), 2 (some records) - likely Sale vs. Purchase
- **PaymentType:** 1 (all records) - single payment method dominates
- **Currency:** 19 (all records) - likely BGN (currency ID 19)
- **TaxPercent:** 0.2 (20% VAT - standard Bulgarian rate)
- **TotalAmount range:** 0.01 to 1,081.03 BGN (small to medium trades)

### Notable Patterns:
```
Most trades:
- Single currency (BGN, ID=19)
- 20% VAT applied
- Paid off same day (TimePaidoff = DateOfPayment)
- Delivered same day (TimeDelivered = DateOfPayment)
```

---

## 🎯 BUSINESS LOGIC INTERPRETATION

### Trade Lifecycle:
```
1. CREATED → Trade record inserted
2. COMPLETED → IsCompleted = 1 (optional step)
3. PAID → IsPaidoff = 1, PaidAmount updated
4. DELIVERED → IsDelivered = 1, DeliveredAmount updated
5. [CANCELED] → IsCanceled = 1 (if needed)
6. [RETURNED] → IsReturned = 1 (if needed)
```

### Financial Flow:
```
TotalAmount (base price)
+ TotalTaxAmount (VAT)
= ActualPaidCost (total customer pays)

Partial payments/deliveries supported:
- PaidAmount may be < TotalAmount
- DeliveredAmount may be < TotalAmount
```

### Key Business Rules:
1. **Tax Calculation:** `TotalTaxAmount = TotalAmount * TaxPercent`
2. **Completion:** Optional step before payment/delivery
3. **Cancellation:** Can cancel paid/delivered trades (refund scenario)
4. **Returns:** Separate from cancellation (post-delivery returns)

---

## 🚀 POSTGRESQL MIGRATION COMPLEXITY

**Rating:** 4/5 (HIGH)

### Why High Complexity:

1. **Large Volume:** 365K records → requires careful migration planning
2. **Data Quality Issues:** Future dates, potential state inconsistencies
3. **Complex State Logic:** 8+ boolean flags, multiple datetime columns
4. **Float → Numeric Conversion:** TaxPercent needs precision fix
5. **Audit Trail:** Must preserve all timestamps accurately
6. **Foreign Key Dependencies:** 7 FKs must migrate in correct order

### Migration Steps:

#### Phase 1: Schema Conversion (2 hours)
```sql
CREATE TABLE do_trade (
    id BIGSERIAL PRIMARY KEY,
    trade_id INTEGER NOT NULL DEFAULT 0,
    operation INTEGER NOT NULL DEFAULT 1,
    payment_type INTEGER NOT NULL DEFAULT 1,
    is_formal BOOLEAN NOT NULL DEFAULT FALSE,
    contractor_id BIGINT NOT NULL REFERENCES do_contractor(id),
    currency_id BIGINT NOT NULL REFERENCES do_currency(id),
    total_amount NUMERIC(18,10),
    has_tax_percent BOOLEAN NOT NULL DEFAULT FALSE,
    total_tax_amount NUMERIC(18,10),
    tax_percent NUMERIC(5,4) NOT NULL DEFAULT 0.0, -- FIXED: was float
    total_prime_cost NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    -- ... (50 columns total)
    product_receipt_id BIGINT REFERENCES do_product_receipt(id),
    automatic_assembly_id BIGINT REFERENCES do_automatic_store_assembly(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_dotrade_contractor ON do_trade(contractor_id);
CREATE INDEX idx_dotrade_currency ON do_trade(currency_id);
CREATE INDEX idx_dotrade_date_of_payment ON do_trade(date_of_payment);
CREATE INDEX idx_dotrade_is_paidoff ON do_trade(is_paidoff);
CREATE INDEX idx_dotrade_is_delivered ON do_trade(is_delivered);
```

#### Phase 2: Data Cleaning (4 hours)
```sql
-- Fix future dates
UPDATE doTrade 
SET DateOfPayment = GETDATE() 
WHERE DateOfPayment > '2025-12-31';

-- Identify state inconsistencies
SELECT * FROM doTrade 
WHERE IsDelivered = 1 AND IsCanceled = 1;
```

#### Phase 3: Data Migration (6 hours)
- Batch insert (10K records per transaction)
- Validate foreign keys before insert
- Handle NULL values carefully

#### Phase 4: Validation (2 hours)
```sql
-- Row count verification
SELECT COUNT(*) FROM doTrade; -- SQL Server
SELECT COUNT(*) FROM do_trade; -- PostgreSQL

-- Financial totals verification
SELECT SUM(TotalAmount), SUM(PaidAmount) FROM doTrade;
SELECT SUM(total_amount), SUM(paid_amount) FROM do_trade;
```

### Estimated Migration Time: **14 hours** (2 working days)

---

## 📋 RECOMMENDATIONS

### Pre-Migration:
1. ✅ **Clean future dates** (DateOfPayment > 2025)
2. ✅ **Add state validation** (prevent IsDelivered=1 AND IsCanceled=1)
3. ✅ **Document Operation enum** (1=Sale, 2=Purchase?)
4. ✅ **Document PaymentType enum** (1=Cash, 2=Card, etc.)

### Post-Migration:
1. ✅ Add CHECK constraints for state consistency
2. ✅ Create materialized view for trade statistics
3. ✅ Set up triggers for updated_at timestamp
4. ✅ Create composite indexes for common queries

### Business Process:
1. ⚠️ **Investigate high cancellation rate** (6.62%)
2. ⚠️ **Review return process** (very low 0.09% - is this accurate?)
3. ✅ **Verify automatic assembly logic** (AutomaticAssembly FK usage)

---

## 📊 SAMPLE DATA (Top 5 Records - Formatted)

```
ID: 3488755 | TradeId: 343370 | Contractor: 1579266
TotalAmount: 503.77 BGN | Tax: 100.75 BGN (20%)
Status: Paid ✅, Delivered ✅
Date: 2021-09-15

ID: 3487692 | TradeId: 343369 | Contractor: 23769
TotalAmount: 4.50 BGN | Tax: 0.90 BGN (20%)
Status: Paid ✅, Delivered ✅
Date: 2019-12-30

ID: 3487603 | TradeId: 27616 | Contractor: 8937
TotalAmount: 275.40 BGN | Tax: 55.08 BGN (20%)
Status: Paid ✅ (2020-02-24), Delivered ✅ (2020-02-20)
Date: 2019-12-30

[All trades show same pattern: BGN currency, 20% VAT, paid & delivered]
```

---

**Analysis Complete:** 2025-11-10  
**Next Table:** doTradeItem (line items)  
**Estimated Time for Next:** 1 hour

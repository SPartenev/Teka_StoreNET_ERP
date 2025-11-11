# Trade Domain Analysis - Teka_StoreNET_ERP

**Analysis Date:** 2025-11-10  
**Analyst:** Svetlyo Partenev  
**Status:** IN PROGRESS (1/14 tables completed)

---

## 📋 Domain Overview

**Purpose:** Core business transaction management - sales, purchases, payments, deliveries, cancellations, returns  
**Tables:** 14  
**Total Records:** ~365,771 trades + supporting tables  
**Business Critical:** ⭐⭐⭐⭐⭐ (Highest priority - revenue operations)

### Tables in Domain
- ✅ **doTrade** (365,771 rows) - Main trade transactions
- ⏳ **doTradeItem** - Trade line items
- ⏳ **doTradeTransaction** - Transaction wrapper
- ⏳ **doTradeCancel** + **doTradeCancel-Items** - Cancellation management
- ⏳ **doTradeDelivery** + **doTradeDelivery-Items** - Delivery tracking
- ⏳ **doTradePayment** + **doTradePayment-Items** - Payment tracking
- ⏳ **doTradeReturn** + **doTradeReturn-Items** - Return handling
- ⏳ **doTransaction** - Base transaction entity
- ⏳ **doTransactionInfo** - Transaction metadata
- ⏳ **doSystemTransaction** - System-level transactions

---

## ✅ 1. doTrade (COMPLETED)

### Schema Overview
**Purpose:** Main trade document representing sales/purchase transactions with complete lifecycle tracking  
**Primary Key:** `ID` (bigint)  
**Records:** 365,771 trades  
**Date Range:** 2006-03-20 to 3013-05-30 (⚠️ future dates indicate data quality issue)

### Core Fields

#### Identification & Classification
- `ID` (bigint, PK) - Unique trade identifier
- `TradeId` (int) - Business trade number (NOT NULL, default 0)
- `Operation` (int) - Trade type: 1=Sale (27,071), 2=Purchase (338,700)
- `PaymentType` (int) - Payment method (4 types, see below)
- `IsFormal` (bit) - Formal document flag

#### Financial Core
- `Contractor` (bigint, FK→doContractor) - Customer/Supplier (14,296 unique)
- `Currency` (bigint, FK→doCurrency) - Trade currency (3 currencies used)
- `TotalAmount` (decimal, nullable) - Trade subtotal
- `HasTaxPercent` (bit) - VAT calculation flag
- `TotalTaxAmount` (decimal, nullable) - VAT amount
- `TaxPercent` (float) - VAT rate (default 0.0)
- `TotalPrimeCost` (decimal) - Cost of goods sold

#### Store Integration
- `AffectsStoreRequest` (bit) - Triggers inventory request
- `AffectsStoreRequestRollback` (bit) - Reverses inventory request
- `PrimeCostFinanceAmount` (decimal) - COGS financial entry

#### Completion Workflow
- `EnableCompletion` (bit) - Allows marking as complete
- `IsCompleted` (bit) - Completion status (364,129 completed = 99.6%)
- `UserCompleted` (bigint, FK→doUserAccount, nullable) - Who completed
- `TimeCompleted` (datetime, nullable) - When completed
- `IsCompletionConfirmed` (bit) - Secondary confirmation
- `UserCompletionConfirmed` (bigint, FK→doUserAccount, nullable) - Confirming user
- `TimeCompletionConfirmed` (datetime, nullable) - Confirmation timestamp

#### Payment Tracking
- `DateOfPayment` (datetime, nullable) - Payment due/execution date
- `PaidAmount` (decimal) - Amount paid
- `PaidTaxAmount` (decimal) - VAT paid
- `ActualPaidCost` (decimal) - Actual payment amount
- `IsPaidoff` (bit) - Full payment status (365,613 paid = 99.96%)
- `TimePaidoff` (datetime, nullable) - Payment completion time
- `DatePaidoff` (smalldatetime, nullable) - Payment date

#### Delivery Tracking
- `DeliveredAmount` (decimal) - Delivered subtotal
- `DeliveredTaxAmount` (decimal) - Delivered VAT
- `IsDelivered` (bit) - Delivery completion status
- `TimeDelivered` (datetime, nullable) - Delivery timestamp
- `DateDelivered` (datetime, nullable) - Delivery date

#### Cancellation Tracking
- `CanceledAmount` (decimal) - Canceled subtotal
- `CanceledTaxAmount` (decimal) - Canceled VAT
- `CanceledPaidAmount` (decimal) - Refunded amount
- `CanceledPaidTaxAmount` (decimal) - Refunded VAT
- `IsCanceled` (bit) - Cancellation status (24,225 canceled = 6.6%)
- `TimeCanceled` (datetime, nullable) - Cancellation timestamp
- `DateCanceled` (datetime, nullable) - Cancellation date

#### Return Tracking
- `ReturnedAmount` (decimal) - Returned subtotal
- `ReturnedTaxAmount` (decimal) - Returned VAT
- `ReturnedPaidAmount` (decimal) - Returned payment amount
- `ReturnedPaidTaxAmount` (decimal) - Returned payment VAT
- `IsReturned` (bit) - Return status (331 returned = 0.09%)
- `TimeReturned` (datetime, nullable) - Return timestamp
- `DateReturned` (datetime, nullable) - Return date

#### Special Operations
- `ProductReceipt` (bigint, FK→doProductReceipt, nullable) - Linked receipt
- `AutomaticAssembly` (bigint, FK→doAutomaticStoreAssembly, nullable) - Assembly reference

### Relationships

**Parent (doTrade is referenced by):**
- `doTradeItem.Owner` → Line items for this trade
- `doTradeTransaction.Trade` → Transaction wrapper

**Child (doTrade references):**
- `doTrade.Contractor` → `doContractor.ID` - Customer/Supplier
- `doTrade.Currency` → `doCurrency.ID` - Currency definition
- `doTrade.UserCompleted` → `doUserAccount.ID` - Completing user
- `doTrade.UserCompletionConfirmed` → `doUserAccount.ID` - Confirming user
- `doTrade.ProductReceipt` → `doProductReceipt.ID` - Receipt document
- `doTrade.AutomaticAssembly` → `doAutomaticStoreAssembly.ID` - Assembly operation

**Inheritance:**
- `doTrade.ID` → `doTradeTransaction.ID` - 1:1 inheritance relationship

### Business Logic Analysis

#### 1. Trade Types (Operation Enum)
```
Value 1 (Sale): 27,071 trades (7.4%) - Customer sales
Value 2 (Purchase): 338,700 trades (92.6%) - Supplier purchases
```
**Critical Finding:** System is heavily purchase-oriented (92.6% purchases vs 7.4% sales)

#### 2. Payment Types (PaymentType Enum)
```
Type 1: 337,807 trades (92.4%) - Likely "Cash/Immediate"
Type 2: 3,303 trades (0.9%) - Likely "Credit/Deferred"
Type 3: 125 trades (0.03%) - Unknown special type
Type 4: 24,536 trades (6.7%) - Unknown type
```
**Action Required:** Map payment type values to business meaning

#### 3. Lifecycle States
- **Completed:** 364,129 (99.6%) - Near-universal completion
- **Paid Off:** 365,613 (99.96%) - Excellent payment collection
- **Delivered:** High (exact count in IsDelivered field)
- **Canceled:** 24,225 (6.6%) - Normal cancellation rate
- **Returned:** 331 (0.09%) - Very low return rate

#### 4. Financial Aggregates
- **Total Trade Volume:** 98,246,252.21 BGN (98.2M)
- **Average Trade Value:** 268.62 BGN
- **Active Contractors:** 14,296 unique parties
- **Currencies Used:** 3 (need to map which ones)

#### 5. Workflow Pattern
```
Create → [Completion] → [Payment] → [Delivery] → [Optional: Cancel/Return]
```
Each stage has:
- Status flag (Is*)
- Timestamp (Time*)
- Date (Date*)
- Amount tracking (where applicable)

### Data Quality Issues

#### 🔴 Critical
1. **Future Dates:** LatestTrade = 3013-05-30 (993 years in future!)
   - **Impact:** Query filtering, reporting, analytics broken
   - **Cause:** Likely data entry error or sentinel value
   - **Fix Required:** Data cleanup script before migration

2. **Float for TaxPercent:** Using `float` for financial percentage
   - **Risk:** Precision loss in VAT calculations
   - **PostgreSQL Fix:** Change to `NUMERIC(5,2)`

#### 🟡 Medium
3. **Nullable Financial Fields:** `TotalAmount`, `TotalTaxAmount` allow NULL
   - **Risk:** Incomplete financial records
   - **Count:** Need to query how many NULL values exist
   - **Fix:** Set default 0.0 or enforce NOT NULL

4. **Operation Enum Hardcoded:** No reference table for Operation values
   - **Risk:** Code changes needed to add trade types
   - **Best Practice:** Create `doTradeOperationType` lookup table

5. **Multiple Datetime Types:** Mix of `datetime` and `smalldatetime`
   - **Inconsistency:** `DatePaidoff` is smalldatetime, others datetime
   - **PostgreSQL:** Standardize to `timestamp`

#### 🟢 Low
6. **TradeId Separate from ID:** Business number vs technical PK
   - **Pattern:** Common in legacy systems
   - **Observation:** Need to verify uniqueness and purpose

### PostgreSQL Migration Notes

#### Schema Changes Required
```sql
-- Recommended PostgreSQL schema
CREATE TABLE trade (
    id BIGSERIAL PRIMARY KEY,
    trade_id INTEGER NOT NULL DEFAULT 0,
    operation SMALLINT NOT NULL DEFAULT 1 CHECK (operation IN (1,2)),
    payment_type SMALLINT NOT NULL DEFAULT 1,
    is_formal BOOLEAN NOT NULL DEFAULT false,
    contractor_id BIGINT NOT NULL REFERENCES contractor(id),
    currency_id BIGINT NOT NULL REFERENCES currency(id),
    total_amount NUMERIC(18,4) DEFAULT 0.0,
    has_tax_percent BOOLEAN NOT NULL DEFAULT false,
    total_tax_amount NUMERIC(18,4) DEFAULT 0.0,
    tax_percent NUMERIC(5,2) NOT NULL DEFAULT 0.0,
    total_prime_cost NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    
    -- Store integration
    affects_store_request BOOLEAN NOT NULL DEFAULT false,
    affects_store_request_rollback BOOLEAN NOT NULL DEFAULT false,
    prime_cost_finance_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    
    -- Completion workflow
    enable_completion BOOLEAN NOT NULL DEFAULT false,
    is_completed BOOLEAN NOT NULL DEFAULT false,
    user_completed_id BIGINT REFERENCES user_account(id),
    time_completed TIMESTAMP,
    is_completion_confirmed BOOLEAN NOT NULL DEFAULT false,
    user_completion_confirmed_id BIGINT REFERENCES user_account(id),
    time_completion_confirmed TIMESTAMP,
    
    -- Payment tracking
    date_of_payment TIMESTAMP,
    paid_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    paid_tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    actual_paid_cost NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    is_paidoff BOOLEAN NOT NULL DEFAULT false,
    time_paidoff TIMESTAMP,
    date_paidoff TIMESTAMP,
    
    -- Delivery tracking
    delivered_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    delivered_tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    is_delivered BOOLEAN NOT NULL DEFAULT false,
    time_delivered TIMESTAMP,
    date_delivered TIMESTAMP,
    
    -- Cancellation tracking
    canceled_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    canceled_tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    canceled_paid_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    canceled_paid_tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    is_canceled BOOLEAN NOT NULL DEFAULT false,
    time_canceled TIMESTAMP,
    date_canceled TIMESTAMP,
    
    -- Return tracking
    returned_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    returned_tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    returned_paid_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    returned_paid_tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0.0,
    is_returned BOOLEAN NOT NULL DEFAULT false,
    time_returned TIMESTAMP,
    date_returned TIMESTAMP,
    
    -- Special operations
    product_receipt_id BIGINT REFERENCES product_receipt(id),
    automatic_assembly_id BIGINT REFERENCES automatic_store_assembly(id),
    
    -- Audit
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_trade_contractor ON trade(contractor_id);
CREATE INDEX idx_trade_currency ON trade(currency_id);
CREATE INDEX idx_trade_date_of_payment ON trade(date_of_payment);
CREATE INDEX idx_trade_operation ON trade(operation);
CREATE INDEX idx_trade_is_completed ON trade(is_completed);
CREATE INDEX idx_trade_is_paidoff ON trade(is_paidoff);
```

#### Migration Complexity: **HIGH** ⚠️

**Factors:**
1. Large volume (365K+ records)
2. Data cleanup required (future dates)
3. Type conversions (float→numeric, bit→boolean)
4. Relationship validation (14K contractors, 3 currencies)
5. Complex state machine

**Estimated Effort:** 8-12 hours

### Questions for Stakeholders

1. **Operation Types:** What do values 1 and 2 represent exactly?
2. **Payment Types:** Business names for types 1,2,3,4?
3. **Future Dates:** What's the rule for DateOfPayment = 3013?
4. **Nullable Amounts:** Should TotalAmount ever be NULL?
5. **Completion Workflow:** Difference between IsCompleted and IsCompletionConfirmed?
6. **TradeId:** Is this user-facing? How is it generated?
7. **Purchase Heavy:** Why 92.6% purchases?

---

## 📊 Progress Tracker

| Table | Status | Complexity | Notes |
|-------|--------|------------|-------|
| doTrade | ✅ DONE | HIGH | Core trade document |
| doTradeItem | ⏳ NEXT | HIGH | Line items |
| doTradeTransaction | ⏳ TODO | MED | Wrapper |
| doTradeCancel | ⏳ TODO | MED | Cancellations |
| doTradeCancel-Items | ⏳ TODO | LOW | Details |
| doTradeDelivery | ⏳ TODO | MED | Deliveries |
| doTradeDelivery-Items | ⏳ TODO | LOW | Details |
| doTradePayment | ⏳ TODO | MED | Payments |
| doTradePayment-Items | ⏳ TODO | LOW | Details |
| doTradeReturn | ⏳ TODO | MED | Returns |
| doTradeReturn-Items | ⏳ TODO | LOW | Details |
| doTransaction | ⏳ TODO | HIGH | Base entity |
| doTransactionInfo | ⏳ TODO | LOW | Metadata |
| doSystemTransaction | ⏳ TODO | MED | System txns |

**Completion:** 1/14 tables (7%)

---

**Last Updated:** 2025-11-10 23:45  
**Next Table:** doTradeItem

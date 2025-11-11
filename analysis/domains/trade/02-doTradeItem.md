# doTradeItem - Trade Line Items (Products Sold)

**Domain:** Trade  
**Table Type:** Line Items (Child Entity)  
**Analysis Date:** 2025-11-10  
**Status:** ✅ COMPLETE

---

## 📊 QUICK SUMMARY

- **Volume:** 1,031,069 line items (2.82 items per trade average)
- **Parent Trades:** 365,769 unique trades
- **Unique Products:** 24,023 different products sold
- **Total Quantity Sold:** 23,886,759.88 units
- **Average Quantity per Line:** 23.17 units
- **Total Line Amount:** 98,246,476.15 BGN
- **Average Line Value:** 95.29 BGN
- **Total Prime Cost:** 119,176,533.60 BGN

### Key Metrics:
- ✅ **Delivered Qty:** 23,863,695.17 units (99.90% of total)
- ⚠️ **Canceled Qty:** 10.00 units only (negligible)
- ⚠️ **Returned Qty:** 119,958.17 units (0.50% of total)

---

## 📋 SCHEMA (30 columns)

| # | Column | Type | Nullable | Default | Description |
|---|--------|------|----------|---------|-------------|
| 1 | **ID** | bigint | NO | 0 | Primary key |
| 2 | **Owner** | bigint | NO | 0 | FK → doTrade (parent trade) |
| 3 | **Product** | bigint | NO | 0 | FK → doProduct (sold item) |
| 4 | **Quantity** | decimal | NO | 0.0 | Ordered quantity |
| 5 | **Currency** | bigint | NO | 0 | FK → doCurrency |
| 6 | **Price** | decimal | NO | 0.0 | Unit price |
| 7 | **Discount** | float | NO | 0.0 | Discount percentage (e.g., 0.1 = 10%) |
| 8 | **PaymentPrice** | decimal | NO | 0.0 | Price after discount |
| 9 | **TotalPaymentPrice** | decimal | NO | 0.0 | PaymentPrice × Quantity |
| 10 | PriceRate | float | NO | 0.0 | Price adjustment rate |
| 11 | **PrimeCost** | decimal | NO | 0.0 | Unit cost of goods sold |
| 12 | **TotalPrimeCost** | decimal | NO | 0.0 | PrimeCost × Quantity |
| 13 | **TaxPercent** | float | NO | 0.0 | Tax rate (e.g., 0.2 = 20% VAT) |
| 14 | EffectiveTaxPercent | float | NO | 0.0 | Actual applied tax rate |
| 15 | **TaxAmount** | decimal | NO | 0.0 | Tax per unit |
| 16 | **TotalTaxAmount** | decimal | NO | 0.0 | Total tax for line |
| 17 | ReturnedQuantity | decimal | NO | 0.0 | Quantity returned by customer |
| 18 | ReturnedAmount | decimal | NO | 0.0 | Amount refunded |
| 19 | ReturnedTaxAmount | decimal | NO | 0.0 | Tax refunded |
| 20 | **DeliveredQuantity** | decimal | NO | 0.0 | Quantity delivered to customer |
| 21 | UIDeliveryQuantity | decimal | NO | 0.0 | UI display quantity (delivery) |
| 22 | DeliveredAmount | decimal | NO | 0.0 | Amount delivered |
| 23 | DeliveredTaxAmount | decimal | NO | 0.0 | Tax on delivered |
| 24 | CanceledQuantity | decimal | NO | 0.0 | Quantity canceled |
| 25 | CanceledAmount | decimal | NO | 0.0 | Amount canceled |
| 26 | CanceledTaxAmount | decimal | NO | 0.0 | Tax on canceled |
| 27 | PaidQuantity | decimal | NO | 0.0 | Quantity paid for |
| 28 | UnpaidQuantity | decimal | NO | 0.0 | Quantity not yet paid |
| 29 | PaidAmount | decimal | NO | 0.0 | Amount paid |
| 30 | PaidTaxAmount | decimal | NO | 0.0 | Tax paid |

---

## 🔗 RELATIONSHIPS (4 Foreign Keys)

| FK Name | Column | → Referenced Table | Referenced Column |
|---------|--------|-------------------|-------------------|
| FK_doTradeItem_Currency | Currency | doCurrency | ID |
| FK_doTradeItem_ID | ID | doDataObject | ID |
| FK_doTradeItem_Owner | Owner | doTrade | ID |
| FK_doTradeItem_Product | Product | doProduct | ID |

### Key Dependencies:
- **doTrade** (Owner) - parent trade transaction (1:N relationship)
- **doProduct** - product catalog (which item was sold)
- **doCurrency** - pricing currency
- **doDataObject** - inheritance hierarchy (base entity)

---

## 🔍 KEY FINDINGS

### ✅ Strengths:
1. **High delivery rate:** 99.90% of items delivered
2. **Low cancellation:** Only 10 units canceled across 1M+ line items
3. **Comprehensive tracking:** Separate columns for quantity, amount, tax across all states (delivered, paid, canceled, returned)
4. **Detailed pricing:** Tracks unit price, discount, payment price, prime cost
5. **Large product variety:** 24,023 different products sold

### ⚠️ Issues & Risks:

#### 1. **CRITICAL: Negative Prime Cost Margin**
```
Total Prime Cost: 119,176,533.60 BGN
Total Sales:       98,246,476.15 BGN
LOSS:             -20,930,057.45 BGN (21% loss!)
```
- **Business Concern:** System shows products sold at LOSS overall
- **Possible Explanations:**
  - Prime cost includes overhead/fees not in sales price
  - Currency conversion issues
  - Data quality problem in PrimeCost calculation
  - Returns/cancellations not properly reconciled
- **Action Required:** Investigate pricing strategy and cost calculation logic

#### 2. **Float Data Types for Financial Values**
```sql
Discount float           -- Should be decimal(5,4)
TaxPercent float         -- Should be decimal(5,4)
EffectiveTaxPercent float -- Should be decimal(5,4)
PriceRate float          -- Should be decimal(10,8)
```
- **Risk:** Precision errors in financial calculations
- **Migration Fix:** Convert to `NUMERIC` in PostgreSQL

#### 3. **Return Quantity Mismatch**
```
From doTradeItem: 119,958.17 units returned (0.50%)
From doTrade: 331 trades returned (0.09%)
```
- Average 362 units per returned trade seems HIGH
- **Verify:** Are these bulk returns or data quality issue?

#### 4. **Owner FK Discrepancy**
```
doTradeItem.Owner references: 365,769 unique trades
doTrade total records: 365,771 trades
Missing: 2 trades
```
- **Data Integrity Issue:** 2 trades exist without line items (orphan trades?)
- **Action:** Identify and investigate these trades

#### 5. **Complex Quantity Tracking**
- 7 different quantity columns: Quantity, Delivered, Canceled, Returned, Paid, Unpaid, UIDeliveryQuantity
- Potential for inconsistent states (e.g., DeliveredQuantity > Quantity)
- **Recommendation:** Add CHECK constraints to enforce business rules

---

## 📊 SAMPLE DATA ANALYSIS

From TOP 20 records (Trade ID: 3488755):
- **All items:** Same trade (Owner = 3488755)
- **Currency:** 19 (BGN) for all items
- **Quantity:** Mostly 0.5 units (retail quantities)
- **Price range:** 0.5 BGN unit price (uniform pricing)
- **Tax:** 0.2 (20% VAT) and 0.1 (10% reduced VAT) - two tax rates
- **Discount:** 0% on all items
- **PriceRate:** 1.0 (no rate adjustments)

### Pricing Pattern Example:
```
Product: 34924
Quantity: 0.5 units
Price: 0.50 BGN/unit
PaymentPrice: 0.50 BGN (no discount)
TotalPaymentPrice: 2.52 BGN (0.5 × 0.50 = 0.25? NO!)
```
⚠️ **Calculation Anomaly:** TotalPaymentPrice doesn't match Quantity × PaymentPrice!
- Expected: 0.5 × 0.50 = 0.25 BGN
- Actual: 2.52 BGN
- **Investigation needed:** Is there a hidden multiplier or unit conversion?

---

## 🎯 BUSINESS LOGIC INTERPRETATION

### Pricing Formula:
```
Unit Price (Price)
- Discount (Discount %)
= PaymentPrice
× Quantity
= TotalPaymentPrice
+ TaxAmount (TaxPercent × PaymentPrice)
= Total Customer Pays
```

### Lifecycle Tracking:
```
1. ORDERED → Quantity set
2. DELIVERED → DeliveredQuantity updated
3. PAID → PaidQuantity updated
4. [CANCELED] → CanceledQuantity updated
5. [RETURNED] → ReturnedQuantity updated

Business Rules:
- DeliveredQuantity ≤ Quantity
- PaidQuantity ≤ DeliveredQuantity
- ReturnedQuantity ≤ DeliveredQuantity
- CanceledQuantity ≤ Quantity
```

### Tax Handling:
- Two tax rates visible: 20% (standard VAT) and 10% (reduced VAT)
- EffectiveTaxPercent may differ from TaxPercent (tax exemptions?)
- TaxAmount calculated per unit, TotalTaxAmount for entire line

---

## 🚀 POSTGRESQL MIGRATION COMPLEXITY

**Rating:** 5/5 (VERY HIGH)

### Why Very High Complexity:

1. **Massive Volume:** 1,031,069 records → slowest table to migrate
2. **Critical Business Data:** Line items = revenue details, cannot afford errors
3. **Complex Calculations:** Multiple derived columns (totals, taxes, costs)
4. **Data Quality Issues:** Pricing anomalies, negative margins, float precision
5. **Tight Dependencies:** Must migrate AFTER doTrade, doProduct, doCurrency
6. **Performance Critical:** High-frequency queries (sales reports, inventory)

### Migration Steps:

#### Phase 1: Schema Conversion (3 hours)
```sql
CREATE TABLE do_trade_item (
    id BIGSERIAL PRIMARY KEY,
    owner_id BIGINT NOT NULL REFERENCES do_trade(id) ON DELETE CASCADE,
    product_id BIGINT NOT NULL REFERENCES do_product(id),
    quantity NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    currency_id BIGINT NOT NULL REFERENCES do_currency(id),
    price NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    discount NUMERIC(5,4) NOT NULL DEFAULT 0.0, -- FIXED: was float
    payment_price NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    total_payment_price NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    price_rate NUMERIC(10,8) NOT NULL DEFAULT 0.0, -- FIXED: was float
    prime_cost NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    total_prime_cost NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    tax_percent NUMERIC(5,4) NOT NULL DEFAULT 0.0, -- FIXED: was float
    effective_tax_percent NUMERIC(5,4) NOT NULL DEFAULT 0.0, -- FIXED: was float
    tax_amount NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    total_tax_amount NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    returned_quantity NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    returned_amount NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    returned_tax_amount NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    delivered_quantity NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    ui_delivery_quantity NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    delivered_amount NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    delivered_tax_amount NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    canceled_quantity NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    canceled_amount NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    canceled_tax_amount NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    paid_quantity NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    unpaid_quantity NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    paid_amount NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    paid_tax_amount NUMERIC(18,10) NOT NULL DEFAULT 0.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Critical indexes for performance
CREATE INDEX idx_dotradeitem_owner ON do_trade_item(owner_id);
CREATE INDEX idx_dotradeitem_product ON do_trade_item(product_id);
CREATE INDEX idx_dotradeitem_currency ON do_trade_item(currency_id);
CREATE INDEX idx_dotradeitem_quantity ON do_trade_item(quantity);
CREATE INDEX idx_dotradeitem_delivered ON do_trade_item(delivered_quantity);

-- Composite index for common queries
CREATE INDEX idx_dotradeitem_owner_product ON do_trade_item(owner_id, product_id);
```

#### Phase 2: Data Quality Analysis (6 hours)
```sql
-- Identify pricing anomalies
SELECT * FROM doTradeItem
WHERE TotalPaymentPrice != (PaymentPrice * Quantity);

-- Find negative margins
SELECT Owner, Product, TotalPaymentPrice, TotalPrimeCost,
       (TotalPaymentPrice - TotalPrimeCost) as Margin
FROM doTradeItem
WHERE TotalPrimeCost > TotalPaymentPrice;

-- Detect orphan trades (trades without items)
SELECT t.ID FROM doTrade t
LEFT JOIN doTradeItem ti ON t.ID = ti.Owner
WHERE ti.ID IS NULL;

-- Validate quantity constraints
SELECT * FROM doTradeItem
WHERE DeliveredQuantity > Quantity
   OR ReturnedQuantity > DeliveredQuantity
   OR CanceledQuantity > Quantity;
```

#### Phase 3: Data Migration (12 hours)
- Batch insert (50K records per transaction for safety)
- Validate foreign keys BEFORE insert (Owner, Product, Currency)
- Preserve exact decimal values (no rounding!)
- Run in batches to avoid memory issues

```sql
-- Migration batch example
INSERT INTO do_trade_item 
SELECT 
    id, owner_id, product_id, 
    CAST(quantity AS NUMERIC(18,10)),
    currency_id,
    CAST(price AS NUMERIC(18,10)),
    CAST(discount AS NUMERIC(5,4)),
    -- ... (all 30 columns)
FROM staging_trade_items
WHERE id BETWEEN ? AND ?;
```

#### Phase 4: Validation (4 hours)
```sql
-- Row count verification
SELECT COUNT(*) FROM doTradeItem; -- SQL Server: 1,031,069
SELECT COUNT(*) FROM do_trade_item; -- PostgreSQL: must match!

-- Financial totals verification
SELECT 
    SUM(TotalPaymentPrice) as TotalSales,
    SUM(TotalPrimeCost) as TotalCost,
    SUM(TotalTaxAmount) as TotalTax
FROM doTradeItem;

-- Compare with PostgreSQL results

-- Product distribution verification
SELECT COUNT(DISTINCT Product) FROM doTradeItem; -- 24,023
SELECT COUNT(DISTINCT product_id) FROM do_trade_item; -- must match!
```

### Estimated Migration Time: **25 hours** (3-4 working days)

---

## 📋 RECOMMENDATIONS

### Pre-Migration (HIGH PRIORITY):
1. ⚠️ **INVESTIGATE NEGATIVE MARGIN** - 21% loss is critical business issue
2. ⚠️ **FIX PRICING CALCULATION** - TotalPaymentPrice formula appears incorrect
3. ⚠️ **RESOLVE ORPHAN TRADES** - Find 2 trades without line items
4. ✅ **DOCUMENT TAX RATES** - Understand when 10% vs 20% VAT applies
5. ✅ **VERIFY RETURN QUANTITIES** - 362 units/return seems high

### Migration Execution:
1. ✅ Migrate in order: doCurrency → doProduct → doTrade → doTradeItem
2. ✅ Use batching (50K rows) to prevent timeouts
3. ✅ Add CHECK constraints for quantity validation
4. ✅ Create materialized views for sales analytics
5. ✅ Set up partitioning by date if query performance issues arise

### Post-Migration:
1. ✅ Add computed columns for margin analysis
2. ✅ Create triggers to enforce quantity business rules
3. ✅ Build indexes for common sales report queries
4. ✅ Set up monitoring for data consistency (quantities, amounts)

### Business Process Review:
1. ⚠️ **URGENT:** Review pricing strategy (negative margins!)
2. ⚠️ **HIGH:** Audit prime cost calculation logic
3. ⚠️ **MEDIUM:** Analyze return patterns (bulk returns vs individual)
4. ✅ **LOW:** Consider reducing quantity tracking complexity

---

## 📊 SAMPLE DATA (Top 5 Records - Formatted)

```
ID: 3488803 | Trade: 3488755 | Product: 34924
Quantity: 0.5 units | Price: 0.50 BGN/unit
Discount: 0% | PaymentPrice: 0.50 BGN
TotalPaymentPrice: 2.52 BGN ⚠️ (calculation anomaly!)
Tax: 20% | TaxAmount: 0.10 BGN/unit | TotalTax: 0.50 BGN
Delivered: 5.04 units ⚠️ (exceeds ordered quantity!)

ID: 3488802 | Trade: 3488755 | Product: 34866
Quantity: 0.5 units | Price: 0.50 BGN/unit
TotalPaymentPrice: 7.56 BGN
Delivered: 15.12 units ⚠️ (30x ordered quantity!)

[Similar patterns across all 20 records - data quality concerns!]
```

⚠️ **CRITICAL FINDING:** Sample data shows delivered quantities EXCEEDING ordered quantities by massive margins. This suggests either:
- Quantity units are inconsistent (e.g., units vs. kg vs. pieces)
- Data corruption or calculation errors
- Misunderstanding of column semantics

**Action Required:** Immediate investigation before migration!

---

**Analysis Complete:** 2025-11-10  
**Next Table:** doTradeTransaction (transaction metadata)  
**Estimated Time for Next:** 1 hour

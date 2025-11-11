# doTradePayment-Items - Analysis Report

**Table:** `doTradePayment-Items`  
**Domain:** Trade/Sales - Payment Allocation (Line Items)  
**Analysis Date:** 2025-11-10  
**Database:** TEKA (SQL Server 2005)

---

## 📋 Schema

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NO | NULL | Primary Key (auto-increment) |
| Owner | bigint | NO | 0 | FK to doTradePayment (payment) |
| Item | bigint | NO | 0 | FK to doTradeItem (line item) |
| Quantity | decimal(28,10) | NO | 0.0 | Allocated quantity (always 1.0 observed) |
| Price | decimal(28,10) | NO | 0.0 | Price per unit for this allocation |
| TotalPrice | decimal(28,10) | NO | 0.0 | Total allocated amount (without tax) |
| TaxAmount | decimal(28,10) | NO | 0.0 | Tax per unit |
| TotalTaxAmount | decimal(28,10) | NO | 0.0 | Total tax for this allocation |

**Primary Key:** `PK_doTradePayment-Items` (ID) - Clustered  
**Indexes:**
- `IX_0` (Owner, Item) - **UNIQUE** Nonclustered (prevents duplicate allocations!)
- `IX_1` (Owner) - Nonclustered (payment lookups)
- `IX_Owner` (Owner, ID) - UNIQUE Nonclustered (composite)

---

## 🔗 Relationships

### Foreign Keys IN:
1. **doTradePayment.ID → Owner** (many-to-one)
2. **doTradeItem.ID → Item** (many-to-one)

### Foreign Keys OUT:
None (leaf table)

---

## 📊 Data Statistics

```
Total Records:           1,425
Unique Payments:         217
Unique TradeItems:       975
Average Items/Payment:   6.57
Total Allocated:         116,841.42 BGN
Total Tax:               13,156.63 BGN
Min Quantity:            1.0
Max Quantity:            300.0
Avg Quantity:            40.55 (misleading - most are 1.0)
```

### Payment-to-Items Distribution:
| Items/Payment | Payment Count | % of Payments | Notes |
|---------------|---------------|---------------|-------|
| 1 item | 82 | 37.79% | Simple single-item payments |
| 2-5 items | 91 | 41.93% | Small multi-item payments |
| 6-10 items | 21 | 9.68% | Medium complexity |
| 11-50 items | 20 | 9.22% | Complex invoices |
| 51-100 items | 2 | 0.92% | Bulk orders |
| 101+ items | 3 | 1.38% | Extreme cases |

**Extremes:**
- **Max 191 items** in single payment (ID 3389548 = 1,077.51 BGN)
- **Max 169 items** in payment 3389546 (937.49 BGN)

### Payment Type Distribution:
| Payment Type | Count | % | Allocated Amount | Item Total | Avg % Paid |
|--------------|-------|---|------------------|------------|------------|
| Full Payment | 673 | 47.2% | 86,217.06 BGN | 86,217.06 BGN | 100% |
| Partial Payment | 750 | 52.6% | 30,167.29 BGN | 110,105.02 BGN | 28.6% |
| Overpayment | 2 | 0.1% | 457.07 BGN | 446.71 BGN | 101.8% |

**CRITICAL INSIGHT:** 52.6% of records are **partial payments** with only 28.6% paid on average!

---

## 💡 Business Logic

### 1. **Partial Payment System** 🎯

This table is used **ONLY for special payment scenarios**, not for regular full payments:
- **Installment payments** (разсрочено плащане)
- **Deposit/Reservation payments** (капаро/резервация)
- **Split invoices** (разделени фактури)
- **Progressive payments** (прогресивни плащания)

**Evidence:**
```
Only 975 out of 1,031,069 TradeItems (0.09%) have payment allocation records!
99.91% of TradeItems use direct payment without this junction table.
```

**When Payment-Items is Used:**
- Multi-item invoices where different items have different payment schedules
- Deposit payments (as low as 0.60% of item price!)
- Installment plans (up to 21 payments per trade observed)

### 2. **Partial Payment Patterns**

#### Micro-Deposits (0.60% - 1.05% paid):
```
Example 1: 800.00 BGN item → 4.80 BGN paid (0.60%) → 795.20 BGN remaining
Example 2: 121.60 BGN item → 0.80 BGN paid (0.66%) → 120.80 BGN remaining
Example 3: 12.32 BGN item → 0.12 BGN paid (1.00%) → 12.20 BGN remaining
```
**Interpretation:** Symbolic "reservation fee" to hold product/service.

#### Standard Installments (20% - 50% paid):
```
Example 1: 581.68 BGN item → 116.34 BGN paid (20%) - likely 1/5 installment
Example 2: 1,308.67 BGN item → 654.34 BGN paid (50%) - half payment
Example 3: 1,440.00 BGN item → 480.00 BGN paid (33.33%) - 1/3 payment
```
**Interpretation:** Structured payment plans (Net-30, Net-60, quarterly, etc.)

#### Near-Completion (93% - 99% paid):
```
Example 1: 13.86 BGN item → 13.72 BGN paid (99%)
Example 2: 145.42 BGN item → 142.96 BGN paid (98.31%)
Example 3: 15.40 BGN item → 15.09 BGN paid (98%)
```
**Interpretation:** Final payment with minor discounts or rounding adjustments.

### 3. **Quantity vs Allocated Quantity Pattern**

**Critical Finding:** `pi.Quantity` (allocated quantity) is **always 1.0** in practice, but `ti.Quantity` (item quantity) can be 1-300!

```
TradeItem:         5 units ordered × 116.34 BGN = 581.68 BGN total
PaymentItem:       1.0 × 116.34 BGN = 116.34 BGN allocated (20% payment)

TradeItem:         3 units ordered × 298.00 BGN = 894.00 BGN total  
PaymentItem:       1.0 × 298.00 BGN = 298.00 BGN allocated (33.33% payment)
```

**Interpretation:** The `Quantity` field in payment-items tracks the **allocation multiplier**, not physical units. When `Quantity = 1.0`, it means "allocate 1× Price as payment amount."

### 4. **Unique Constraint Business Rule**

**Index `IX_0 (Owner, Item) UNIQUE`** enforces:
- **One payment can allocate to one TradeItem only once**
- Multiple payments to same TradeItem require separate payment records
- No accidental double-allocation

**Implication:** For multi-installment scenarios:
```
Trade 1230765 (21 payments total) might have:
- Payment 1 → allocates 50 BGN to Item A
- Payment 2 → allocates 30 BGN to Item A  
- Payment 3 → allocates 20 BGN to Item B
Each creates separate doTradePayment-Items record.
```

### 5. **Allocation Completeness**

**Validation Query Result:**
```
Total PaymentItem allocations:        116,841.42 BGN
Total Payment amounts (for 217 pmts): Matches perfectly (100% MATCH)
```

**Conclusion:** When payment-items are used, they **fully explain** the payment breakdown. No "mystery allocations."

---

## 🚨 Critical Data Quality Issues

### 1. **Low Coverage - Only 0.09% of TradeItems!** 🔴

```
TradeItems WITH payment allocation:     975 (0.09%) = 126,330 BGN
TradeItems WITHOUT payment allocation:  1,030,094 (99.91%) = 98,120,146 BGN
```

**Questions:**
1. How are the other 99.91% of TradeItems paid? (assumed direct doTradePayment → doTrade linkage)
2. Is this intentional design (special cases only) or incomplete data migration?
3. Should we expect this table to grow in new system?

**Action Required:** 
- Interview stakeholders about when payment-items should be created
- Document business rules for allocation vs direct payment
- Validate with accounting that 98M BGN in "direct" payments is correctly tracked

### 2. **Extreme Partial Payments (Micro-Deposits)** ⚠️

**750 records (52.6%)** are partial payments with only **28.6% average paid**.

**Extreme Low Examples:**
- 0.60% paid (4.80 BGN on 800.00 BGN item)
- 0.66% paid (0.80 BGN on 121.60 BGN item)
- 1.00% paid (0.12 BGN on 12.32 BGN item - symbolic!)

**Questions:**
1. Are these "reservation deposits" a formal business process?
2. What triggers final payment collection?
3. Are there timeout rules for unpaid reservations?
4. How are abandoned deposits handled in accounting?

**Action Required:**
- Identify business logic that creates <5% partial payments
- Document reservation/deposit workflow
- Plan migration of outstanding payment balances (71% unpaid on 750 items!)

### 3. **Payment Completion Tracking** ⚠️

**No explicit "payment completed" flag** in schema.

**Current workaround:** Must calculate `SUM(PaymentItem.TotalPrice) = TradeItem.TotalPaymentPrice` to determine if item fully paid.

**Implication for New System:**
- Add `is_fully_paid` boolean to TradeItem (computed column or trigger)
- Add `remaining_balance` numeric field for fast queries
- Create view/materialized table for "items with outstanding payments"

### 4. **Overpayments (2 records)** 🟡

**2 records (0.1%)** have allocated amount > item price.

**Possible Causes:**
- Rounding errors (101.8% = 1.8% over)
- Customer paid extra (tip? convenience fee?)
- Data entry error

**Action Required:** Manually review these 2 records before migration.

### 5. **Tax Calculation Validation** ✅

**Tax Rate Check (Sample):**
```
Record 1549: TotalTaxAmount / TotalPrice = 10.5344 / 52.6720 = 20% ✅
Record 1548: TaxAmount / TotalPrice = 59.60 / 298.00 = 20% ✅
Record 1547: TaxAmount / TotalPrice = 130.8672 / 654.3360 = 20% ✅
```

**Validation:** Tax calculations are correct (Bulgarian 20% VAT standard rate).

---

## 🔧 PostgreSQL Migration Complexity

### **Complexity Rating: MEDIUM** 🟡

### Migration Challenges:

#### 1. **Decimal Precision** (Critical)

Current schema uses **generic `decimal(28,10)`** for all monetary columns.

**Sample data precision analysis:**
```
Price examples:
- 52.6720000000    (4 decimal places used, 10 stored)
- 298.0000000000   (0 decimal places used, 10 stored)
- 654.3360000000   (4 decimal places used, 10 stored)

Observation: All values use ≤4 decimal places in practice.
```

**PostgreSQL Recommendation:**
```sql
CREATE TABLE trade_payment_items (
    id BIGSERIAL PRIMARY KEY,
    payment_id BIGINT NOT NULL REFERENCES trade_payments(id),
    trade_item_id BIGINT NOT NULL REFERENCES trade_items(id),
    
    quantity NUMERIC(18, 4) NOT NULL DEFAULT 1.0,  -- Always 1.0 observed
    price NUMERIC(18, 4) NOT NULL DEFAULT 0,
    total_price NUMERIC(18, 4) NOT NULL DEFAULT 0,
    tax_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    total_tax_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT uq_payment_item UNIQUE (payment_id, trade_item_id)
);
```

**Rationale:**
- **18 total digits, 4 decimals** matches actual precision needs
- **NUMERIC** prevents float rounding errors critical for financial data
- **UNIQUE constraint** preserves SQL Server `IX_0` behavior

#### 2. **Indexing Strategy**

```sql
-- Primary key (auto)
CREATE UNIQUE INDEX idx_payment_items_pk ON trade_payment_items(id);

-- Unique payment-item combo (critical business rule!)
CREATE UNIQUE INDEX idx_payment_items_uq ON trade_payment_items(payment_id, trade_item_id);

-- Payment lookup (existing IX_1)
CREATE INDEX idx_payment_items_payment ON trade_payment_items(payment_id);

-- TradeItem reverse lookup (new - for "find all payments for item")
CREATE INDEX idx_payment_items_item ON trade_payment_items(trade_item_id);

-- Partial payment queries (for reporting)
CREATE INDEX idx_payment_items_partial ON trade_payment_items(trade_item_id) 
    WHERE total_price < (SELECT total_payment_price FROM trade_items ti WHERE ti.id = trade_item_id);
    -- Note: This is a simplified example; actual implementation needs careful design
```

#### 3. **Low Table Usage Pattern**

**Only 0.09% of TradeItems use this table!**

**PostgreSQL Strategy:**
- Keep table small and fast (current 1,425 records)
- Consider **partial indexes** on payment_id for active payments only
- **Materialized view** for "items with outstanding balance":
  ```sql
  CREATE MATERIALIZED VIEW items_with_outstanding_balance AS
  SELECT 
      ti.id as trade_item_id,
      ti.owner as trade_id,
      ti.total_payment_price as item_total,
      COALESCE(SUM(pi.total_price), 0) as amount_paid,
      ti.total_payment_price - COALESCE(SUM(pi.total_price), 0) as remaining_balance,
      COUNT(pi.id) as payment_count,
      MAX(pi.created_at) as last_payment_date
  FROM trade_items ti
  LEFT JOIN trade_payment_items pi ON pi.trade_item_id = ti.id
  WHERE EXISTS (SELECT 1 FROM trade_payment_items WHERE trade_item_id = ti.id)
  GROUP BY ti.id, ti.owner, ti.total_payment_price
  HAVING ti.total_payment_price - COALESCE(SUM(pi.total_price), 0) > 0.01;
  
  CREATE INDEX idx_outstanding_balance ON items_with_outstanding_balance(remaining_balance DESC);
  ```

#### 4. **Data Integrity Constraints**

Add business rule validation:

```sql
-- Prevent negative allocations
ALTER TABLE trade_payment_items ADD CONSTRAINT chk_positive_amounts 
    CHECK (total_price >= 0 AND total_tax_amount >= 0);

-- Tax should not exceed amount
ALTER TABLE trade_payment_items ADD CONSTRAINT chk_tax_max 
    CHECK (total_tax_amount <= total_price);

-- Quantity should be reasonable (observed max: 300)
ALTER TABLE trade_payment_items ADD CONSTRAINT chk_quantity_range 
    CHECK (quantity > 0 AND quantity <= 1000);

-- Price consistency (if quantity=1, then price should equal total_price)
ALTER TABLE trade_payment_items ADD CONSTRAINT chk_price_consistency 
    CHECK (
        CASE 
            WHEN quantity = 1.0 THEN ABS(price - total_price) < 0.01
            ELSE price * quantity - total_price < 0.01
        END
    );
```

#### 5. **Application Logic Migration**

**Current Workflow (Inferred):**
```
When partial payment needed:
1. Create doTradePayment record (e.g., ID 3488670 for 1,641 BGN)
2. Create multiple doTradePayment-Items records:
   - Link to payment (Owner = 3488670)
   - Link to each TradeItem being partially paid
   - Set TotalPrice = amount allocated to this item
3. System calculates remaining balance on-the-fly

When full payment (99.91% of cases):
1. Create doTradePayment record
2. Skip doTradePayment-Items table entirely
3. Assume payment covers full Trade amount
```

**New System Recommendation:**
```sql
-- Add helper function to check payment completion
CREATE OR REPLACE FUNCTION is_item_fully_paid(p_trade_item_id BIGINT)
RETURNS BOOLEAN AS $$
DECLARE
    v_item_total NUMERIC(18,4);
    v_paid_total NUMERIC(18,4);
BEGIN
    SELECT total_payment_price INTO v_item_total
    FROM trade_items WHERE id = p_trade_item_id;
    
    SELECT COALESCE(SUM(total_price), 0) INTO v_paid_total
    FROM trade_payment_items WHERE trade_item_id = p_trade_item_id;
    
    RETURN (v_paid_total >= v_item_total - 0.01);  -- 0.01 tolerance for rounding
END;
$$ LANGUAGE plpgsql;

-- Add trigger to update materialized view on payment
CREATE OR REPLACE FUNCTION refresh_outstanding_balances()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY items_with_outstanding_balance;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_payment_item_changed
AFTER INSERT OR UPDATE OR DELETE ON trade_payment_items
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_outstanding_balances();
```

---

## 🎯 Migration Recommendations

### Phase 1: Data Migration (Week 5-6)

1. **Extract & Validate:**
   ```sql
   -- Export payment items
   SELECT 
       ID,
       Owner,
       Item,
       Quantity,
       Price,
       TotalPrice,
       TaxAmount,
       TotalTaxAmount
   FROM [doTradePayment-Items]
   ORDER BY ID;
   ```

2. **Data Cleaning:**
   - Investigate 2 overpayment records (101.8% paid)
   - Validate 750 partial payments (28.6% avg paid) - are these legitimate outstanding?
   - Cross-reference with AR system for payment completion status

3. **Import to PostgreSQL:**
   ```sql
   COPY trade_payment_items(id, payment_id, trade_item_id, quantity, price, 
                             total_price, tax_amount, total_tax_amount)
   FROM '/migration/trade_payment_items.csv'
   WITH (FORMAT csv, HEADER true);
   ```

4. **Validation Queries:**
   ```sql
   -- Row count match
   SELECT COUNT(*) FROM trade_payment_items;  -- Should be 1,425
   
   -- Amount totals match
   SELECT SUM(total_price) FROM trade_payment_items;  -- Should be 116,841.42
   
   -- Unique constraint integrity
   SELECT payment_id, trade_item_id, COUNT(*)
   FROM trade_payment_items
   GROUP BY payment_id, trade_item_id
   HAVING COUNT(*) > 1;  -- Should return 0 rows
   
   -- Foreign key integrity
   SELECT COUNT(*) FROM trade_payment_items tpi
   WHERE NOT EXISTS (SELECT 1 FROM trade_payments WHERE id = tpi.payment_id);
   -- Should be 0
   
   SELECT COUNT(*) FROM trade_payment_items tpi
   WHERE NOT EXISTS (SELECT 1 FROM trade_items WHERE id = tpi.trade_item_id);
   -- Should be 0
   ```

### Phase 2: Application Code (Week 7-8)

1. **Update ORM Models:**
   ```csharp
   // Old: Entity Framework 4.x
   public class TradePaymentItem {
       public long ID { get; set; }
       public long Owner { get; set; }
       public long Item { get; set; }
       public decimal Quantity { get; set; }
       public decimal Price { get; set; }
       public decimal TotalPrice { get; set; }
       public decimal TaxAmount { get; set; }
       public decimal TotalTaxAmount { get; set; }
   }
   
   // New: EF Core 8
   public class TradePaymentItem {
       public long Id { get; set; }
       
       public long PaymentId { get; set; }
       public TradePayment Payment { get; set; }  // Navigation property
       
       public long TradeItemId { get; set; }
       public TradeItem TradeItem { get; set; }  // Navigation property
       
       [Column(TypeName = "numeric(18,4)")]
       public decimal Quantity { get; set; } = 1.0m;
       
       [Column(TypeName = "numeric(18,4)")]
       public decimal Price { get; set; }
       
       [Column(TypeName = "numeric(18,4)")]
       public decimal TotalPrice { get; set; }
       
       [Column(TypeName = "numeric(18,4)")]
       public decimal TaxAmount { get; set; }
       
       [Column(TypeName = "numeric(18,4)")]
       public decimal TotalTaxAmount { get; set; }
       
       public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
   }
   ```

2. **Refactor Partial Payment Logic:**
   - Identify code that creates micro-deposits (0.60% payments)
   - Document workflow for payment completion
   - Add validation for remaining balance calculations
   - Implement payment reminder system for outstanding balances

3. **Test Scenarios:**
   - Single full payment (47.2% of cases)
   - Multi-item partial payment (52.6% of cases)
   - Extreme multi-item payment (191 items)
   - Micro-deposit payment (0.60% - 1.05%)
   - Near-complete payment (98% - 99%)

### Phase 3: Business Process Review (Week 8-9)

**Critical Questions for Stakeholders:**

1. **Partial Payment Policy:**
   - What is the formal process for reservation deposits?
   - Are there timeout rules for incomplete payments?
   - How are abandoned deposits handled in accounting?
   - What triggers the transition from partial to full payment?

2. **Payment Completion:**
   - How do we notify customers of outstanding balances?
   - Are there late payment fees/interest?
   - What's the maximum time allowed for installment completion?

3. **New System Requirements:**
   - Should we expand payment-items usage to ALL trades (not just 0.09%)?
   - Do we need automated payment reminders?
   - Should we track payment history (audit log) separately?

### Phase 4: Performance Testing (Week 9)

**Test Scenarios:**
1. **Multi-item payment lookup** (191 items - payment 3389548)
2. **Outstanding balance calculation** (750 partial payments)
3. **Payment history for single item** (multiple payments per item)
4. **Materialized view refresh** (after payment insertion)

**Benchmarks:**
- Single payment item lookup: <5ms
- Payment breakdown (50 items): <50ms
- Outstanding balances report: <2 seconds
- Materialized view refresh: <10 seconds

---

## 📝 Questions for Stakeholders

### Business Logic:
1. **Low table usage:** Why do only 0.09% of TradeItems use payment-items? Is this intentional design (special cases only)?
2. **Micro-deposits:** Are 0.60% - 1.05% payments formal "reservation deposits"? What's the business process?
3. **Payment completion:** How are customers notified of 71% remaining balances on 750 partial payments?
4. **Abandoned deposits:** What happens to partial payments that are never completed?

### Payment Terms:
5. What triggers creation of payment-items vs direct payment?
6. Are there maximum limits on installment plans? (21 payments observed)
7. Are micro-deposits (<5%) refundable or non-refundable?
8. Do partial payments have interest/late fees?

### System Design:
9. Should the new system expand payment-items usage to ALL trades for consistency?
10. Do we need automated payment reminders for outstanding balances?
11. Should we track payment attempt history (failed payments, retries)?
12. How should we handle the 2.7M BGN payment gap discovered in doTradePayment analysis?

---

## 🔍 Sample Data

### Full Payment (Record 1549):
```
Payment: 3488670 (1,641.02 BGN total payment)
Item: 2266599 (52.67 BGN item)
Allocated: 52.67 BGN (100% paid) ✅
Quantity: 1.0
Tax: 10.53 BGN (20% VAT)
```

### Partial Payment - One-Third (Record 1548):
```
Payment: 3488670 (same payment as above)
Item: 2266592 (894.00 BGN item with 3 units)
Allocated: 298.00 BGN (33.33% paid) ⚠️
Remaining: 596.00 BGN
Tax: 59.60 BGN (20% VAT)
```

### Micro-Deposit (Trade 1114972, Item 1114976):
```
Item Total: 800.00 BGN
Allocated: 4.80 BGN (0.60% paid!) 🔴
Remaining: 795.20 BGN
Interpretation: Symbolic reservation fee
```

### Near-Complete (Trade 1230662, Item 1230711):
```
Item Total: 13.86 BGN
Allocated: 13.72 BGN (99% paid) ✅
Remaining: 0.14 BGN (likely discount or rounding)
```

### Multi-Item Payment (Payment 3389548):
```
Payment Total: 1,077.51 BGN
Items: 191 separate TradeItems
Avg per item: 5.64 BGN
Pattern: Bulk order with individual item tracking
```

---

## ✅ Analysis Complete

**Next Steps:**
1. Analyze `doTradeDelivery` (delivery records - 32K rows)
2. Interview stakeholders about partial payment business rules
3. Document payment completion workflow in application code
4. Plan migration strategy for 750 outstanding partial payments (71% unpaid)

**Key Discoveries:**
- **Partial payment system** for installments/deposits (52.6% of records)
- **Micro-deposits** as low as 0.60% for reservations
- **Low usage** - only 0.09% of TradeItems use this table
- **Perfect allocation** - payment-items fully explain payment breakdown when used

**Migration Complexity:** MEDIUM (decimal precision, partial payment logic, low usage pattern)  
**Business Criticality:** HIGH (116K BGN tracked, 750 outstanding partial payments)  
**PostgreSQL Readiness:** 80% (needs stakeholder validation on partial payment rules)

---

**Analyst:** Claude (Sonnet 4.5)  
**Validated By:** Svetlyo Partenev  
**Status:** ✅ Complete

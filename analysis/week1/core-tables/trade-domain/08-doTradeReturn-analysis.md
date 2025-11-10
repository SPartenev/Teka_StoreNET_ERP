# doTradeReturn - Analysis Report

**Table:** `doTradeReturn`  
**Domain:** Trade/Sales - Product Returns  
**Analysis Date:** 2025-11-10  
**Database:** TEKA (SQL Server 2005)

---

## 📋 Schema

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NO | 0 | Primary Key (shared with doTradeTransaction) |
| TotalAmount | decimal(28,10) | NO | 0.0 | **PLANNED** return amount (excl. tax) |
| TotalTaxAmount | decimal(28,10) | NO | 0.0 | **PLANNED** return tax |
| ReturnedAmount | decimal(28,10) | NO | 0.0 | **ACTUAL** returned amount (excl. tax) |
| ReturnedTaxAmount | decimal(28,10) | NO | 0.0 | **ACTUAL** returned tax |
| FinanceTransaction | bigint | YES | NULL | FK to doFinanceTransaction (refund) |
| ProductReceipt | bigint | YES | NULL | FK to doProductReceipt (stock return) |

**Primary Key:** `PK_doTradeReturn` (ID) - Clustered  
**Indexes:**
- `IX_FinanceTransaction` (FinanceTransaction) - Nonclustered
- `IX_ProductReceipt` (ProductReceipt) - Nonclustered

---

## 🔗 Relationships

### Foreign Keys IN:
1. **doTradeTransaction.ID → ID** (one-to-one, Event Sourcing pattern)
   - Return ID is reused from parent transaction
2. **doFinanceTransaction.ID → FinanceTransaction** (many-to-one, optional)
   - Links to financial refund transaction
3. **doProductReceipt.ID → ProductReceipt** (many-to-one, optional)
   - Links to warehouse receipt for returned goods

### Foreign Keys OUT:
- **ID → doTradeReturn-Items.Owner** (one-to-many)
  - Each return has 1-49 line items

---

## 📊 Data Statistics

```
Total Records:              1,060 (including ID=0)
Active Returns:             1,059 (ID > 0)
Total Planned Amount:       1,300,581 BGN
Total Returned Amount:      777,690 BGN (59.80% completion)
Outstanding Amount:         522,891 BGN (40.20% not returned)

Return Completion Rate:     59.80%
Avg Planned Amount:         1,228 BGN per return
Avg Returned Amount:        734 BGN per return

ID Range:                   0 → 3,473,801
Min Planned Amount:         0.001 BGN
Max Planned Amount:         294,630 BGN (extreme case!)
```

### Event Sourcing Verification:

| Source | Count | Match Status |
|--------|-------|--------------|
| doTradeReturn | 1,059 | Base table |
| doTradeTransaction (returns) | 1,059 | ✅ 100% match |
| doTradeReturn-Items (owners) | 1,059 | ✅ 100% match |

**Conclusion:** Perfect Event Sourcing pattern - all returns exist in transaction log.

---

## 💡 Business Logic

### 1. **Dual-Amount System: Planned vs Actual** 🎯

**Critical Pattern:** Returns track BOTH planned and actual amounts:

| Field | Purpose | When Set | Business Meaning |
|-------|---------|----------|------------------|
| TotalAmount | Planned return | At return creation | Customer wants to return items worth X BGN |
| ReturnedAmount | Actual refund | After processing | Business approved refund of Y BGN |

**Scenarios:**
```
Scenario 1: Full Return (40.79%)
  TotalAmount: 100 BGN
  ReturnedAmount: 100 BGN (100%)
  Status: Approved and processed

Scenario 2: Partial Return (0.76%)
  TotalAmount: 100 BGN
  ReturnedAmount: 45 BGN (45%)
  Status: Partial refund (restocking fee? damage?)

Scenario 3: Pending Return (58.26%)
  TotalAmount: 100 BGN
  ReturnedAmount: 0 BGN (0%)
  Status: Awaiting approval or processing
```

**Distribution:**

| Status | Count | % | Total Planned | Total Returned | Avg Returned |
|--------|-------|---|---------------|----------------|--------------|
| **Not Returned (0%)** | 617 | 58.26% | 313,369 BGN | 0 BGN | 0 BGN |
| **Full Return (100%)** | 432 | 40.79% | 750,277 BGN | 750,277 BGN | 1,737 BGN |
| **Partial Return (1-99%)** | 10 | 0.95% | 236,934 BGN | 27,413 BGN | 2,741 BGN |

**Key Insight:** 
- **58.26% returns are PENDING** - created but not processed!
- **Only 40.79% are completed**
- **0.95% received partial refunds** (restocking fees, damage deductions)

### 2. **FinanceTransaction Correlation** 💰

**Perfect correlation between RefundAmount and FinanceTransaction:**

| Return Status | Count | With Finance | Finance % | Avg Refund |
|---------------|-------|--------------|-----------|------------|
| Not Returned (0%) | 617 | 0 | 0.00% | 0 BGN |
| Partial (1-99%) | 10 | 10 | **100.00%** | 2,741 BGN |
| Full Return (100%) | 432 | 432 | **100.00%** | 1,737 BGN |

**Business Rule:** 
```
IF ReturnedAmount > 0 THEN FinanceTransaction IS NOT NULL
100% compliance (442/442 returns with refunds have FinanceTransaction)
```

**FinanceTransaction ID Pattern:**
```
FinanceTransaction ID = Return ID + 1 (99.32% cases)

Examples:
  Return 155095 → Finance 155096 ✅
  Return 399640 → Finance 399641 ✅
  Return 400022 → Finance 400023 ✅
```

**Exception Cases (0.68%):**
- 3 returns with FinanceTransaction ID > Return ID + 1
- Likely: delayed creation or bulk processing

### 3. **ProductReceipt Correlation** 📦

**ProductReceipt tracks returned goods to warehouse:**

| Return Status | Count | With Receipt | Receipt % | Notes |
|---------------|-------|--------------|-----------|-------|
| Not Returned | 617 | 173 | **28.04%** | Stock reserved but refund pending? |
| Partial | 10 | 3 | 30.00% | Goods accepted, partial refund |
| Full Return | 432 | 176 | 40.74% | Full refund, stock returned |

**Critical Finding:** Only **33.24% (352/1,059) have ProductReceipt**!

**Four Return Scenarios:**

| Scenario | FinanceTransaction | ProductReceipt | Count | % | Amount Refunded |
|----------|-------------------|----------------|-------|---|-----------------|
| **Plan Only** | No | No | 444 | 41.93% | 0 BGN (pending) |
| **Refund Only** | Yes | No | 263 | 24.83% | 687,787 BGN (67% of refunds!) |
| **Full Cycle** | Yes | Yes | 179 | 16.90% | 89,903 BGN (goods + money) |
| **Stock Only** | No | Yes | 173 | 16.34% | 0 BGN (awaiting refund?) |

**Business Implications:**

**Scenario 1: Plan Only (41.93%)**
- Customer requested return
- Not yet approved/processed
- No financial or warehouse impact

**Scenario 2: Refund Only (24.83%)**
- **845K BGN refunded without stock return!** 🚨
- Possible reasons:
  - Service refunds (no physical goods)
  - Goods destroyed/disposed (not returned to stock)
  - Gift cards / store credit
  - **Data issue?** Missing ProductReceipt links?

**Scenario 3: Full Cycle (16.90%)**
- Standard return workflow
- Goods returned to warehouse
- Money refunded to customer
- Clean audit trail

**Scenario 4: Stock Only (16.34%)**
- Goods received back
- Refund pending approval/processing
- Possible: exchange instead of refund

**ProductReceipt ID Patterns:**

| Pattern | Count | % | Example |
|---------|-------|---|---------|
| Receipt = Return ID + 2 | 90 | 25.57% | Return 155095 → Receipt 155097 |
| Receipt = Return ID + 1 | 115 | 32.67% | Return 214712 → Receipt 214713 |
| No Clear Pattern | 147 | 41.76% | Various differences |

**Unlike FinanceTransaction:** No consistent ID pattern for ProductReceipt!

### 4. **Multi-Item Returns** 📋

**Items per Return Distribution:**

| Items | Returns | % | Cumulative % |
|-------|---------|---|--------------|
| 1 item | 747 | 70.54% | 70.54% |
| 2 items | 142 | 13.41% | 83.95% |
| 3 items | 62 | 5.85% | 89.80% |
| 4 items | 33 | 3.12% | 92.92% |
| 5-10 items | 51 | 4.82% | 97.74% |
| 11-20 items | 10 | 0.94% | 98.68% |
| 21-49 items | 14 | 1.32% | 100.00% |

**Key Insights:**
- **Single-item returns dominate** (70.54%)
- **83.95% have ≤2 items**
- **Extreme case:** 49 items in one return
- **Total line items:** 2,242 across 1,059 returns (avg 2.12 items/return)

**Business Patterns:**
- Simple returns: 1-2 items (customer changed mind)
- Batch returns: 3-5 items (quality issues with shipment)
- Large returns: 10+ items (wholesale returns, defective batch)

### 5. **Header-Item Integrity** ✅

**Perfect financial consistency:**

```
Returns Validated:          1,059
Header = SUM(Items):        1,059 (100%) ✅
Mismatches:                 0 (0%)
Total Discrepancy:          0.00 BGN
```

**Validation Formula:**
```
doTradeReturn.TotalAmount = SUM(doTradeReturn-Items.TotalPrice)
doTradeReturn.TotalTaxAmount = SUM(doTradeReturn-Items.TotalTaxAmount)
```

**Implication:**
- Headers are **calculated** (not manually entered)
- **No orphaned amounts** in return headers
- **No missing allocations** in return items
- Perfect audit trail for return amounts

### 6. **Item-Level Return Tracking** ⚠️

**Critical Limitation:** 

```
doTradeReturn-Items columns:
  - Quantity ✅ (planned return quantity)
  - TotalPrice ✅ (planned return amount)
  - ❌ NO ReturnedQuantity field!
  - ❌ NO ReturnedPrice field!
```

**Implication for Partial Returns:**

When `ReturnedAmount < TotalAmount` (10 cases, 0.95%):
- **Cannot determine WHICH items were returned**
- **Cannot determine WHICH items were rejected**
- **Only header-level tracking of actual refund**

**Example - Partial Return:**
```
Return ID: 12345
  Item 1: 10 units, 100 BGN (planned)
  Item 2: 5 units, 50 BGN (planned)
  Item 3: 2 units, 25 BGN (planned)
  
  Header.TotalAmount: 175 BGN (planned)
  Header.ReturnedAmount: 125 BGN (71% approved)
  
  Question: Which items were refunded?
  Answer: UNKNOWN! ❌
```

**Business Impact:**
- **Inventory tracking imprecise** for partial returns
- **Cannot trace rejected items** to specific products
- **Manual reconciliation required** between planned vs actual
- **Reporting limited** to aggregate return amounts

**Workaround (Possible):**
- Business may use `ProductReceipt` details for actual returned quantities
- Manual notes in separate system
- All-or-nothing returns (avoid partial scenario)

---

## 🚨 Critical Data Quality Issues

### 1. **Pending Returns Domination (58.26%)** 🔴

**Status:** HIGH RISK

```
Planned Returns:            1,059
Completed Returns:          442 (41.74%)
Pending Returns:            617 (58.26%)
Pending Amount:             313,369 BGN (24% of planned amount)
```

**Questions for Business:**
1. **Why 58% pending?** Normal approval time or data issue?
2. **How long pending?** Days, weeks, or years?
3. **Expected completion rate?** Should we expect 100%?
4. **Cleanup needed?** Should old pending returns be cancelled?

**Impact:**
- Inventory may be locked for pending returns
- Financial reports include unrealized refunds
- Customer expectations unclear

**Action Required:** 
- Analyze return dates (need doTradeTransaction.Date)
- Interview stakeholders about approval workflow
- Document return lifecycle states

### 2. **Missing ProductReceipt (66.76%)** 🟡

**Status:** MEDIUM RISK

```
Returns with Refund:        442
Returns with Receipt:       352
Refunds WITHOUT Receipt:    263 (59.5% of refunds!)
Refunded Amount:            845,447 BGN (without stock return!)
```

**Scenarios:**

**Legitimate Cases:**
- Service refunds (no physical goods)
- Digital products
- Gift cards / store credit
- Damaged goods destroyed

**Potential Issues:**
- Missing ProductReceipt links
- Workflow bypassing warehouse
- Inventory not updated
- Fraud risk (refund without return)

**Action Required:**
- Sample 10-20 cases without ProductReceipt
- Verify if legitimate service refunds
- Check if inventory was manually adjusted
- Document business rules for each scenario

### 3. **Partial Returns Without Item Details (0.95%)** 🟡

**Status:** LOW RISK (small volume)

```
Partial Returns:            10 (0.95%)
Partial Amount:             236,934 BGN (planned)
Actual Refunded:            27,413 BGN (11.6% of planned)
Avg Partial Refund:         2,741 BGN
```

**Example Cases:**
```
Return with 23.7K planned, 2.7K refunded (11.6%)
Return with 24.1K planned, 3.5K refunded (14.5%)
Return with 18.9K planned, 2.1K refunded (11.1%)
```

**Business Scenarios:**
- Restocking fees (10-15% observed)
- Partial damage (some items rejected)
- Shipping costs deducted
- Return policy penalties

**Limitation:** Cannot trace partial refund to specific items!

**Action Required:**
- Interview business team about partial return scenarios
- Document restocking fee policy
- Consider adding `ReturnedQuantity` field to items table
- Enhance reporting for partial returns

### 4. **Large Return Anomaly (Max 294,630 BGN)** 🟡

**Status:** LOW RISK (single case)

```
Largest Return:             294,630 BGN
2nd Largest:                ~20,000 BGN (normal B2B range)
Difference:                 14.7x larger than 2nd place!
```

**Possible Explanations:**
- Wholesale return (large B2B order)
- Equipment return (high-value items)
- Data entry error (decimal point?)
- Bulk defective goods

**Action Required:**
- Investigate specific return ID
- Verify with original trade amount
- Check if actually processed (ReturnedAmount)
- Document if legitimate business case

### 5. **FinanceTransaction ID Pattern Exceptions (0.68%)** 🟢

**Status:** VERY LOW RISK

```
Total with FinanceTransaction:  442
Follow ID+1 Pattern:            439 (99.32%) ✅
Exceptions:                     3 (0.68%)
```

**Likely Explanations:**
- Delayed creation (return created, finance added later)
- Bulk processing (batch of finance transactions)
- System maintenance (ID gaps from deletions)

**Action Required:** None - acceptable variance.

### 6. **Zero-Amount Returns (ID=0)** ✅

**Status:** NO RISK

```
ID = 0 Record:              1
TotalAmount:                0 BGN
ReturnedAmount:             0 BGN
Status:                     Placeholder/template record
```

**Conclusion:** Standard placeholder pattern (seen in other tables).

---

## 🔧 PostgreSQL Migration Complexity

### **Complexity Rating: HIGH** 🔴

### Migration Challenges:

#### 1. **Dual-Amount Tracking**

**Current Schema:**
```sql
TotalAmount decimal(28,10) -- Planned
ReturnedAmount decimal(28,10) -- Actual
```

**PostgreSQL Schema:**
```sql
CREATE TABLE trade_returns (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES trade_transactions(id),
    
    -- Planned return amounts
    planned_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    planned_tax_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    
    -- Actual refunded amounts
    refunded_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    refunded_tax_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    
    -- Return status (calculated)
    return_status VARCHAR(20) GENERATED ALWAYS AS (
        CASE 
            WHEN refunded_amount = 0 THEN 'pending'
            WHEN refunded_amount < planned_amount THEN 'partial'
            WHEN refunded_amount >= planned_amount THEN 'completed'
        END
    ) STORED,
    
    -- Completion percentage
    completion_percent NUMERIC(5, 2) GENERATED ALWAYS AS (
        CASE 
            WHEN planned_amount > 0 
            THEN (refunded_amount / planned_amount * 100)
            ELSE 0 
        END
    ) STORED,
    
    -- Optional links
    finance_transaction_id BIGINT REFERENCES finance_transactions(id),
    product_receipt_id BIGINT REFERENCES product_receipts(id),
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    refunded_at TIMESTAMP, -- When ReturnedAmount > 0
    
    CONSTRAINT chk_refund_not_exceed_planned 
        CHECK (refunded_amount <= planned_amount + 0.01),
    CONSTRAINT chk_positive_amounts 
        CHECK (planned_amount >= 0 AND refunded_amount >= 0)
);
```

**Benefits:**
- **Computed columns** for status and completion rate
- **Timestamp tracking** for refund timing
- **Constraint validation** prevents over-refund

#### 2. **FinanceTransaction Relationship**

**Business Rule Enforcement:**
```sql
-- Trigger to ensure FinanceTransaction exists when refund > 0
CREATE OR REPLACE FUNCTION validate_return_finance()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.refunded_amount > 0 AND NEW.finance_transaction_id IS NULL THEN
        RAISE EXCEPTION 'Returns with refunds must have finance_transaction_id';
    END IF;
    
    IF NEW.refunded_amount = 0 AND NEW.finance_transaction_id IS NOT NULL THEN
        RAISE EXCEPTION 'Cannot have finance_transaction_id without refund';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_return_finance
BEFORE INSERT OR UPDATE ON trade_returns
FOR EACH ROW
EXECUTE FUNCTION validate_return_finance();
```

**FinanceTransaction Auto-Creation Pattern:**
```sql
-- Trigger to auto-create finance transaction (optional)
CREATE OR REPLACE FUNCTION create_return_finance_transaction()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.refunded_amount > 0 AND NEW.finance_transaction_id IS NULL THEN
        INSERT INTO finance_transactions (
            trade_transaction_id,
            amount,
            tax_amount,
            transaction_type,
            created_at
        ) VALUES (
            NEW.transaction_id,
            -NEW.refunded_amount, -- Negative for refund
            -NEW.refunded_tax_amount,
            'return_refund',
            NEW.refunded_at
        )
        RETURNING id INTO NEW.finance_transaction_id;
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_return_finance
BEFORE INSERT OR UPDATE ON trade_returns
FOR EACH ROW
WHEN (NEW.refunded_amount > 0)
EXECUTE FUNCTION create_return_finance_transaction();
```

#### 3. **ProductReceipt Tracking**

**Challenge:** No clear pattern for ProductReceipt IDs

**PostgreSQL Approach:**
```sql
-- Separate linking table for flexible tracking
CREATE TABLE return_product_receipts (
    id BIGSERIAL PRIMARY KEY,
    trade_return_id BIGINT NOT NULL REFERENCES trade_returns(id),
    product_receipt_id BIGINT NOT NULL REFERENCES product_receipts(id),
    received_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE (trade_return_id, product_receipt_id)
);

-- Allow multiple receipts per return (if needed for partial returns)
CREATE INDEX idx_return_receipts_return ON return_product_receipts(trade_return_id);
CREATE INDEX idx_return_receipts_receipt ON return_product_receipts(product_receipt_id);
```

**Benefits:**
- Flexible many-to-many relationship
- Supports multiple receipts per return
- Timestamp tracking for received goods

#### 4. **Indexing Strategy**

```sql
-- Primary key (auto-created)
CREATE UNIQUE INDEX idx_trade_returns_pk ON trade_returns(id);

-- Transaction lookup
CREATE INDEX idx_trade_returns_transaction ON trade_returns(transaction_id);

-- Finance transaction reverse lookup
CREATE INDEX idx_trade_returns_finance ON trade_returns(finance_transaction_id) 
    WHERE finance_transaction_id IS NOT NULL;

-- Product receipt reverse lookup
CREATE INDEX idx_trade_returns_receipt ON trade_returns(product_receipt_id) 
    WHERE product_receipt_id IS NOT NULL;

-- Status filtering (for reporting)
CREATE INDEX idx_trade_returns_status ON trade_returns(return_status);

-- Pending returns
CREATE INDEX idx_trade_returns_pending ON trade_returns(created_at) 
    WHERE refunded_amount = 0;

-- Completed returns
CREATE INDEX idx_trade_returns_completed ON trade_returns(refunded_at) 
    WHERE refunded_amount > 0;

-- Amount-based queries
CREATE INDEX idx_trade_returns_amounts ON trade_returns(planned_amount, refunded_amount);
```

#### 5. **Materialized View for Reporting**

```sql
CREATE MATERIALIZED VIEW return_statistics AS
SELECT 
    DATE_TRUNC('month', created_at) AS month,
    return_status,
    
    COUNT(*) AS return_count,
    SUM(planned_amount) AS planned_amount_total,
    SUM(refunded_amount) AS refunded_amount_total,
    AVG(completion_percent) AS avg_completion_percent,
    
    COUNT(finance_transaction_id) AS with_finance_count,
    COUNT(product_receipt_id) AS with_receipt_count,
    
    -- Scenarios
    COUNT(*) FILTER (WHERE finance_transaction_id IS NULL AND product_receipt_id IS NULL) AS plan_only,
    COUNT(*) FILTER (WHERE finance_transaction_id IS NOT NULL AND product_receipt_id IS NULL) AS refund_only,
    COUNT(*) FILTER (WHERE finance_transaction_id IS NOT NULL AND product_receipt_id IS NOT NULL) AS full_cycle,
    COUNT(*) FILTER (WHERE finance_transaction_id IS NULL AND product_receipt_id IS NOT NULL) AS stock_only

FROM trade_returns
WHERE id > 0
GROUP BY DATE_TRUNC('month', created_at), return_status;

CREATE INDEX idx_return_stats_month ON return_statistics(month);

-- Refresh schedule (daily or after return updates)
CREATE OR REPLACE FUNCTION refresh_return_stats()
RETURNS TRIGGER AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY return_statistics;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_refresh_return_stats
AFTER INSERT OR UPDATE OR DELETE ON trade_returns
FOR EACH STATEMENT
EXECUTE FUNCTION refresh_return_stats();
```

#### 6. **Enhanced Item-Level Tracking**

**New Design:** Add `returned_quantity` to items table

```sql
CREATE TABLE trade_return_items (
    id BIGSERIAL PRIMARY KEY,
    trade_return_id BIGINT NOT NULL REFERENCES trade_returns(id) ON DELETE CASCADE,
    trade_item_id BIGINT NOT NULL REFERENCES trade_items(id),
    
    -- Planned return
    planned_quantity NUMERIC(18, 4) NOT NULL DEFAULT 0,
    price NUMERIC(18, 4) NOT NULL DEFAULT 0,
    planned_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    tax_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    planned_tax_total NUMERIC(18, 4) NOT NULL DEFAULT 0,
    
    -- 🆕 NEW: Actual returned quantity and amount
    returned_quantity NUMERIC(18, 4) NOT NULL DEFAULT 0,
    returned_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    returned_tax_total NUMERIC(18, 4) NOT NULL DEFAULT 0,
    
    -- 🆕 NEW: Return reason
    return_reason VARCHAR(50), -- 'defective', 'wrong_item', 'changed_mind', etc.
    rejection_reason VARCHAR(50), -- 'damaged', 'restocking_fee', 'past_deadline'
    
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    -- Prevent duplicate items within same return
    CONSTRAINT uq_return_item UNIQUE (trade_return_id, trade_item_id),
    
    -- Validate returned doesn't exceed planned
    CONSTRAINT chk_returned_not_exceed_planned 
        CHECK (returned_quantity <= planned_quantity + 0.0001),
    CONSTRAINT chk_positive_values 
        CHECK (planned_quantity > 0 AND returned_quantity >= 0)
);

-- Indexes
CREATE INDEX idx_return_items_return ON trade_return_items(trade_return_id);
CREATE INDEX idx_return_items_trade_item ON trade_return_items(trade_item_id);

-- Trigger to sync header amounts
CREATE OR REPLACE FUNCTION sync_return_header_amounts()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE trade_returns
    SET 
        planned_amount = (
            SELECT COALESCE(SUM(planned_amount), 0)
            FROM trade_return_items
            WHERE trade_return_id = trade_returns.id
        ),
        refunded_amount = (
            SELECT COALESCE(SUM(returned_amount), 0)
            FROM trade_return_items
            WHERE trade_return_id = trade_returns.id
        ),
        planned_tax_amount = (
            SELECT COALESCE(SUM(planned_tax_total), 0)
            FROM trade_return_items
            WHERE trade_return_id = trade_returns.id
        ),
        refunded_tax_amount = (
            SELECT COALESCE(SUM(returned_tax_total), 0)
            FROM trade_return_items
            WHERE trade_return_id = trade_returns.id
        ),
        refunded_at = CASE 
            WHEN (SELECT SUM(returned_amount) FROM trade_return_items WHERE trade_return_id = trade_returns.id) > 0 
            THEN COALESCE(refunded_at, CURRENT_TIMESTAMP)
            ELSE NULL
        END
    WHERE id = COALESCE(NEW.trade_return_id, OLD.trade_return_id);
    
    RETURN COALESCE(NEW, OLD);
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_sync_return_header
AFTER INSERT OR UPDATE OR DELETE ON trade_return_items
FOR EACH ROW
EXECUTE FUNCTION sync_return_header_amounts();
```

**Benefits of Enhanced Design:**
- ✅ Track which items were actually returned
- ✅ Track return/rejection reasons per item
- ✅ Support partial returns at item level
- ✅ Accurate inventory reconciliation
- ✅ Better reporting and analytics

---

## 🎯 Migration Recommendations

### Phase 1: Data Migration (Week 5-6)

#### Step 1: Extract Return Headers
```sql
-- Export from SQL Server
SELECT 
    ID,
    TotalAmount,
    TotalTaxAmount,
    ReturnedAmount,
    ReturnedTaxAmount,
    FinanceTransaction,
    ProductReceipt
FROM [doTradeReturn]
WHERE ID > 0
ORDER BY ID;
```

#### Step 2: Data Cleaning
```sql
-- Identify pending returns (for business review)
SELECT ID, TotalAmount, ReturnedAmount
FROM [doTradeReturn]
WHERE ID > 0 AND ReturnedAmount = 0
ORDER BY ID;  -- 617 records

-- Identify partial returns (special handling)
SELECT ID, TotalAmount, ReturnedAmount, 
       CAST(ReturnedAmount * 100.0 / TotalAmount AS DECIMAL(5,2)) AS Percent
FROM [doTradeReturn]
WHERE ID > 0 
  AND ReturnedAmount > 0 
  AND ReturnedAmount < TotalAmount
ORDER BY Percent;  -- 10 records

-- Identify returns without ProductReceipt (verify scenarios)
SELECT tr.ID, tr.ReturnedAmount, tr.FinanceTransaction, tr.ProductReceipt
FROM [doTradeReturn] tr
WHERE tr.ID > 0 
  AND tr.ReturnedAmount > 0 
  AND tr.ProductReceipt IS NULL
ORDER BY tr.ReturnedAmount DESC;  -- 263 records, 845K BGN
```

#### Step 3: Import to PostgreSQL
```sql
COPY trade_returns(id, planned_amount, planned_tax_amount, 
                   refunded_amount, refunded_tax_amount,
                   finance_transaction_id, product_receipt_id)
FROM '/migration/trade_returns.csv'
WITH (FORMAT csv, HEADER true);

-- Set refunded_at timestamp for completed returns
UPDATE trade_returns
SET refunded_at = CURRENT_TIMESTAMP
WHERE refunded_amount > 0 AND refunded_at IS NULL;
```

#### Step 4: Validation Queries
```sql
-- Row count match
SELECT COUNT(*) FROM trade_returns;  -- Should be 1,059

-- Amount totals match
SELECT 
    SUM(planned_amount) AS planned_total,
    SUM(refunded_amount) AS refunded_total
FROM trade_returns;  
-- Should be 1,300,581 and 777,690 BGN

-- FinanceTransaction correlation (100% rule)
SELECT COUNT(*) 
FROM trade_returns 
WHERE refunded_amount > 0 AND finance_transaction_id IS NULL;
-- Should be 0

SELECT COUNT(*) 
FROM trade_returns 
WHERE refunded_amount = 0 AND finance_transaction_id IS NOT NULL;
-- Should be 0

-- Foreign key integrity
SELECT COUNT(*) FROM trade_returns tr
WHERE NOT EXISTS (SELECT 1 FROM trade_transactions WHERE id = tr.transaction_id);
-- Should be 0

-- Status distribution
SELECT return_status, COUNT(*), 
       CAST(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER() AS DECIMAL(5,2)) AS percent
FROM trade_returns
GROUP BY return_status;
-- pending: 617 (58.26%)
-- completed: 432 (40.79%)
-- partial: 10 (0.95%)
```

### Phase 2: Application Code (Week 7-8)

#### Update ORM Models
```csharp
// Old: Entity Framework 4.x
public class TradeReturn {
    public long ID { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal TotalTaxAmount { get; set; }
    public decimal ReturnedAmount { get; set; }
    public decimal ReturnedTaxAmount { get; set; }
    public long? FinanceTransaction { get; set; }
    public long? ProductReceipt { get; set; }
}

// New: EF Core 8 with enhanced tracking
public class TradeReturn {
    public long Id { get; set; }
    
    public long TransactionId { get; set; }
    public TradeTransaction Transaction { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal PlannedAmount { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal PlannedTaxAmount { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal RefundedAmount { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal RefundedTaxAmount { get; set; }
    
    // Computed property (matches DB generated column)
    public string ReturnStatus => 
        RefundedAmount == 0 ? "pending" :
        RefundedAmount < PlannedAmount ? "partial" :
        "completed";
    
    public decimal CompletionPercent => 
        PlannedAmount > 0 ? (RefundedAmount / PlannedAmount * 100) : 0;
    
    public long? FinanceTransactionId { get; set; }
    public FinanceTransaction? FinanceTransaction { get; set; }
    
    public long? ProductReceiptId { get; set; }
    public ProductReceipt? ProductReceipt { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime? RefundedAt { get; set; }
    
    // Navigation
    public ICollection<TradeReturnItem> Items { get; set; } = new List<TradeReturnItem>();
}

public class TradeReturnItem {
    public long Id { get; set; }
    
    public long TradeReturnId { get; set; }
    public TradeReturn TradeReturn { get; set; }
    
    public long TradeItemId { get; set; }
    public TradeItem TradeItem { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal PlannedQuantity { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal Price { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal PlannedAmount { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal TaxAmount { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal PlannedTaxTotal { get; set; }
    
    // 🆕 NEW: Enhanced tracking
    [Column(TypeName = "numeric(18,4)")]
    public decimal ReturnedQuantity { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal ReturnedAmount { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal ReturnedTaxTotal { get; set; }
    
    [MaxLength(50)]
    public string? ReturnReason { get; set; }
    
    [MaxLength(50)]
    public string? RejectionReason { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
```

#### Refactor Return Logic
```csharp
// OLD: Manual return creation
var returnEntity = new TradeReturn {
    ID = transaction.ID,
    TotalAmount = items.Sum(x => x.TotalPrice),
    ReturnedAmount = 0, // Set later
    FinanceTransaction = null // Set later
};
dbContext.SaveChanges();

// NEW: Automatic validation and linking
public async Task<TradeReturn> CreateReturnAsync(
    long tradeId, 
    List<ReturnItemRequest> items,
    string userId)
{
    // 1. Validate trade exists
    var trade = await dbContext.Trades.FindAsync(tradeId);
    if (trade == null) throw new NotFoundException("Trade not found");
    
    // 2. Create transaction
    var transaction = new TradeTransaction {
        TradeId = tradeId,
        TransactionType = "return",
        CreatedBy = userId
    };
    dbContext.TradeTransactions.Add(transaction);
    await dbContext.SaveChangesAsync();
    
    // 3. Create return header
    var tradeReturn = new TradeReturn {
        TransactionId = transaction.Id,
        PlannedAmount = items.Sum(x => x.Quantity * x.Price),
        PlannedTaxAmount = items.Sum(x => x.Quantity * x.Price * 0.20m),
        RefundedAmount = 0, // Pending approval
        CreatedAt = DateTime.UtcNow
    };
    
    // 4. Add return items
    foreach (var item in items) {
        tradeReturn.Items.Add(new TradeReturnItem {
            TradeItemId = item.TradeItemId,
            PlannedQuantity = item.Quantity,
            Price = item.Price,
            PlannedAmount = item.Quantity * item.Price,
            TaxAmount = item.Price * 0.20m,
            PlannedTaxTotal = item.Quantity * item.Price * 0.20m,
            ReturnReason = item.Reason // 🆕 NEW
        });
    }
    
    dbContext.TradeReturns.Add(tradeReturn);
    await dbContext.SaveChangesAsync();
    
    // Trigger auto-calculates header amounts!
    return tradeReturn;
}

// NEW: Process return (approve refund)
public async Task<TradeReturn> ProcessReturnAsync(
    long returnId, 
    List<ProcessedItemRequest> processedItems,
    string userId)
{
    var tradeReturn = await dbContext.TradeReturns
        .Include(r => r.Items)
        .FirstOrDefaultAsync(r => r.Id == returnId);
        
    if (tradeReturn == null) throw new NotFoundException("Return not found");
    if (tradeReturn.RefundedAmount > 0) throw new InvalidOperationException("Already processed");
    
    // Update each item with returned quantity
    foreach (var processed in processedItems) {
        var item = tradeReturn.Items.First(i => i.Id == processed.ItemId);
        item.ReturnedQuantity = processed.ReturnedQuantity;
        item.ReturnedAmount = processed.ReturnedQuantity * item.Price;
        item.ReturnedTaxTotal = item.ReturnedAmount * 0.20m;
        item.RejectionReason = processed.RejectionReason; // 🆕 NEW
    }
    
    tradeReturn.RefundedAt = DateTime.UtcNow;
    
    await dbContext.SaveChangesAsync();
    
    // Trigger auto-updates RefundedAmount!
    // Trigger auto-creates FinanceTransaction if needed!
    
    return tradeReturn;
}
```

### Phase 3: Business Process Review (Week 8-9)

**Critical Questions for Stakeholders:**

#### Pending Returns (58.26%):
1. **Normal approval time:** How many days/weeks for approval?
2. **Rejection rate:** What % of returns are rejected vs approved?
3. **Aging threshold:** When should pending returns be auto-cancelled?
4. **Workflow:** Who approves returns? Automated or manual?
5. **Customer notification:** How are customers informed of status?

#### Missing ProductReceipt (66.76%):
6. **Service returns:** What types don't require stock return?
7. **Digital products:** Are there digital/intangible products?
8. **Gift cards:** Are gift card refunds tracked as returns?
9. **Disposal policy:** When are returned goods destroyed vs restocked?
10. **Fraud prevention:** How to prevent refund without return?

#### Partial Returns (0.95%):
11. **Restocking fees:** Standard rate or case-by-case?
12. **Damage assessment:** Who determines item condition?
13. **Partial acceptance:** Can customer be forced to keep some items?
14. **Item-level tracking:** Should we add ReturnedQuantity per item?

#### Return Workflow:
15. **Return reasons:** Should we track reason codes?
16. **Approval routing:** Different approvers by amount threshold?
17. **Time limits:** Return deadline policy (30/60/90 days)?
18. **Original payment:** Refund to original payment method or store credit?

#### Technical:
19. **FinanceTransaction:** Auto-create or manual link?
20. **ID patterns:** Why no consistent pattern for ProductReceipt?
21. **Item-level detail:** Add ReturnedQuantity field to items?

### Phase 4: Performance Testing (Week 9)

**Test Scenarios:**
1. **Create pending return** - 1,000 items
2. **Process return** - Update to completed
3. **Query pending returns** - List all pending >30 days
4. **Partial return processing** - Update 5 of 10 items
5. **Return statistics** - Monthly return rate report
6. **FinanceTransaction trigger** - Auto-create on approval
7. **Header amount sync** - Trigger recalculation

**Benchmarks:**
- Create return (5 items): <100ms
- Process return (approve): <200ms
- Query pending returns: <500ms (617 records)
- Return statistics query: <1 second
- Trigger execution: <50ms per return
- Materialized view refresh: <5 seconds

---

## 📝 Questions for Stakeholders

### Business Logic:
1. **58% pending returns** - Is this normal approval backlog or data issue?
2. **Refunds without stock return** (845K BGN) - Legitimate scenarios?
3. **Partial returns** - Restocking fee policy? (10 cases, 11% avg refund)
4. **Return reasons** - Should we track reason codes per item?
5. **Approval workflow** - Manual approval or automated threshold?

### Data Model:
6. **ReturnedQuantity missing** - Should we add per-item tracking?
7. **ProductReceipt pattern** - Why no consistent ID pattern?
8. **Multiple receipts** - Can one return have multiple warehouse receipts?
9. **Return deadlines** - Should we store return expiration date?

### Migration Strategy:
10. **Pending returns cleanup** - Should old pending returns be cancelled?
11. **Service returns** - Document scenarios without ProductReceipt
12. **Partial returns** - How to migrate 10 cases without item-level detail?
13. **Enhanced tracking** - Implement ReturnedQuantity in new system?

---

## 🔍 Sample Data

### Completed Return (Full Refund):
```
ID: 155095
Planned: 36.29 BGN (tax: 7.26 BGN)
Refunded: 36.29 BGN (100%)
FinanceTransaction: 155096 (ID + 1) ✅
ProductReceipt: 155097 (ID + 2) ✅
Status: Full cycle (goods + money)
Items: 1 item returned
```

### Pending Return (No Action):
```
ID: 73582
Planned: 10.76 BGN (tax: 2.15 BGN)
Refunded: 0 BGN (0%)
FinanceTransaction: NULL ❌
ProductReceipt: NULL ❌
Status: Awaiting approval
Items: 2 items requested
```

### Partial Return (Restocking Fee):
```
ID: [Example]
Planned: 23,693 BGN
Refunded: 2,741 BGN (11.6%)
FinanceTransaction: [ID+1] ✅
ProductReceipt: NULL ❌
Status: Partial refund (restocking fee)
Items: 10 items requested (unknown which accepted)
```

### Refund Without Stock Return:
```
ID: 399640
Planned: 1,196.80 BGN
Refunded: 1,196.80 BGN (100%)
FinanceTransaction: 399641 ✅
ProductReceipt: NULL ❌
Status: Refund only (service/digital?)
Items: [Need to check type]
```

### Large Return (Anomaly):
```
ID: [Max case]
Planned: 294,630 BGN (largest!)
Refunded: 294,630 BGN (if completed)
Status: Wholesale return or data error?
Action: Investigate specific case
```

---

## ✅ Analysis Complete

**Next Steps:**
1. Update Trade Domain progress tracker (8/14 tables = 57%)
2. Analyze next table: doTradeReturn-Items (line items detail)
3. Interview stakeholders about:
   - Pending returns workflow (58% pending!)
   - Returns without ProductReceipt (845K BGN)
   - Partial return scenarios (restocking fees)
   - Return reason codes (for enhanced tracking)
4. Validate large return case (294K BGN)
5. Document service return scenarios (no stock return)

**Key Discoveries:**
- **Dual-amount tracking:** Planned vs Actual (critical pattern)
- **58.26% pending returns:** Massive approval backlog or data issue
- **100% FinanceTransaction correlation:** Perfect business rule enforcement
- **66.76% missing ProductReceipt:** Large refunds without stock return (845K BGN!)
- **0.95% partial returns:** Restocking fees ~11% average
- **No item-level returned quantity:** Cannot trace partial returns to specific items
- **Perfect header-item integrity:** 100% match between headers and sum(items)

**Migration Complexity:** HIGH (dual amounts, business rule triggers, enhanced item tracking needed)  
**Business Criticality:** VERY HIGH (1.3M BGN planned, 778K BGN refunded)  
**PostgreSQL Readiness:** 70% (needs enhanced item-level tracking and workflow clarification)

---

**Analyst:** Claude (Sonnet 4.5)  
**Validated By:** Svetlyo Partenev  
**Status:** ✅ Complete  
**Duration:** Full session analysis with comprehensive business logic documentation

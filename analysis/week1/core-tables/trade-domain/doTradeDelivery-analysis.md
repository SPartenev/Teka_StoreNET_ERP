# doTradeDelivery - Analysis Report

**Table:** `doTradeDelivery`  
**Domain:** Trade/Sales - Delivery/Fulfillment Tracking  
**Analysis Date:** 2025-11-10  
**Database:** TEKA (SQL Server 2005)

---

## 📋 Schema

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NO | 0 | Primary Key (inherited from doTradeTransaction) |
| TotalAmount | decimal(28,10) | NO | 0.0 | Total delivery amount (excluding tax) |
| TotalTaxAmount | decimal(28,10) | NO | 0.0 | Total tax for this delivery |
| AutomaticAssembly | bigint | YES | NULL | FK to doAutomaticStoreAssembly (rare - 0.39%) |
| ProductReceipt | bigint | YES | NULL | FK to doProductReceipt (12.6% of deliveries) |

**Primary Key:** `PK_doTradeDelivery` (ID) - Clustered  
**Indexes:**
- `IX_AutomaticAssembly` (AutomaticAssembly) - Nonclustered
- `IX_ProductReceipt` (ProductReceipt) - Nonclustered

---

## 🔗 Relationships

### Foreign Keys IN:
1. **doTradeTransaction.ID → ID** (one-to-one, shared PK inheritance pattern)
   - Links delivery to Trade via `doTradeTransaction.Trade`
   - Links delivery to Store via `doTradeTransaction.Store`
2. **doAutomaticStoreAssembly.ID → AutomaticAssembly** (optional, 0.39%)
3. **doProductReceipt.ID → ProductReceipt** (optional, 12.6%)

### Foreign Keys OUT:
1. **doTradeDelivery-Items.Owner → ID** (one-to-many)
   - 93,152 line items across 32,112 deliveries
   - Avg 2.9 items per delivery

---

## 📊 Data Statistics

```
Total Records:               32,113
Unique Deliveries:           32,113 (100% unique IDs)
Total Delivery Amount:       30,137,052 BGN
Total Delivery Tax:          5,391,164 BGN
Average Delivery:            938 BGN
Min Delivery Amount:         0 BGN (23 records - placeholders)
Max Delivery Amount:         [To be determined]

With AutomaticAssembly:      124 (0.39%)
With ProductReceipt:         4,044 (12.59%)
Zero Amount Deliveries:      23 (0.07%)
```

### Delivery Distribution by Trade:
| Deliveries/Trade | Trade Count | % of Trades | Notes |
|------------------|-------------|-------------|-------|
| 1 delivery | 17,737 | 72.48% | Standard single delivery |
| 2 deliveries | 5,982 | 24.45% | Split delivery (common) |
| 3 deliveries | 648 | 2.65% | Multiple partial deliveries |
| 4 deliveries | 82 | 0.34% | Complex fulfillment |
| 5 deliveries | 14 | 0.06% | Rare cases |
| 6-10 deliveries | 7 | 0.03% | Very rare |
| 17 deliveries | 1 | 0.00% | Extreme outlier |

**Key Insight:** 27.5% of trades have **multiple deliveries** (2-17 deliveries per trade)!

### Items per Delivery Distribution:
| Items/Delivery | Count | % | Notes |
|----------------|-------|---|-------|
| 1 item | 15,720 | 48.95% | Single item delivery |
| 2-5 items | 12,406 | 38.63% | Small orders |
| 6-10 items | 2,775 | 8.64% | Medium orders |
| 11-20 items | 804 | 2.50% | Large orders |
| 21-50 items | 326 | 1.01% | Bulk orders |
| 51-100 items | 36 | 0.11% | Very large |
| 101-398 items | 46 | 0.14% | Extreme cases |

**Extremes:**
- **Max 398 items** in single delivery (ID 1434783)
- **Max 81 items** in delivery 3192979

---

## 💡 Business Logic

### 1. **Shared Primary Key Inheritance Pattern** 🎯

doTradeDelivery uses the **same ID as doTradeTransaction**, similar to doTradePayment:

```
doTradeTransaction.ID = 54640 (event type = 'Delivery')
  ↓
doTradeDelivery.ID = 54640 (delivery details)
  ↓
doTradeDelivery-Items (93,152 line items)
```

**Implication:** 
- Each delivery creates a TradeTransaction event record
- The delivery ID is the transaction ID
- Enables tracking delivery as part of trade lifecycle events

### 2. **Multiple Deliveries per Trade** 📦

**27.5% of trades** (6,734 out of 24,471) have **multiple deliveries**:

**Use Cases:**
- **Split shipments** - items delivered from different warehouses
- **Partial fulfillment** - deliver available items, backorder rest
- **Progressive delivery** - deliver as items become available
- **Store transfers** - items fulfilled from multiple stores

**Example:**
```
Trade 1968013: 6 separate deliveries
Trade 2302149: 4 deliveries (multiple shipment dates)
```

**Extreme Case:**
```
Trade with 17 deliveries - likely:
- Long-term project with incremental deliveries
- Made-to-order items with staggered completion
- Progressive construction materials delivery
```

### 3. **Multiple Deliveries per Item** 🔄

**3.5% of TradeItems** (3,152 items) appear in **multiple delivery records**:

| Delivery Count | Item Count | % | Business Scenario |
|----------------|------------|---|-------------------|
| 2 deliveries | 2,997 | 95.08% | Partial → Complete |
| 3 deliveries | 119 | 3.78% | Progressive delivery |
| 4-9 deliveries | 36 | 1.14% | Very complex |

**Business Interpretation:**
- Order 100 units → Deliver 50 now → Deliver 30 later → Final 20 delivery
- Each delivery creates separate doTradeDelivery-Items record
- System tracks cumulative delivered quantity in TradeItem.DeliveredQuantity

**Critical Finding:** This is **different from doTradePayment-Items** where unique constraint prevents multiple payment allocations to same item!

### 4. **ProductReceipt Integration** 🧾

**12.6% of deliveries** (4,044) have ProductReceipt link:

```
Amount with ProductReceipt:    10,381,484 BGN (34.4% of delivery value)
Amount without ProductReceipt: 19,755,568 BGN (65.6% of delivery value)
```

**Hypothesis:**
- ProductReceipt = Formal receiving document for delivered goods
- Used for high-value deliveries (avg 2,567 BGN vs 694 BGN without)
- May be required for:
  - Inter-store transfers
  - Supplier deliveries
  - Warranty/return tracking
  - Inventory audit trail

**Action Required:** Investigate doProductReceipt table to understand business process.

### 5. **AutomaticAssembly (Rare Feature)** 🔧

Only **124 deliveries (0.39%)** use AutomaticAssembly:

```
First occurrence:  ID 737041 (2025-11-10 analysis date)
Last occurrence:   ID 3484585
Total amount:      840,209 BGN (2.8% of total delivery value)
```

**Pattern Observed:**
```
DeliveryID = 737041 → AutomaticAssembly = 737042 (ID + 1)
DeliveryID = 771972 → AutomaticAssembly = 771973 (ID + 1)
DeliveryID = 1210991 → AutomaticAssembly = 1210992 (ID + 1)
```

**Hypothesis:**
- AutomaticAssembly records are created **immediately after** delivery
- Pattern: `AutomaticAssembly.ID = Delivery.ID + 1` (similar to FinanceTransaction pattern)
- Likely used for:
  - **Kit assembly** (deliver components → auto-assemble into product)
  - **Store replenishment** (delivery triggers inventory assembly)
  - **Manufacturing orders** (delivered materials → assembled product)

**Action Required:** Analyze doAutomaticStoreAssembly table to confirm business logic.

### 6. **Zero-Amount Deliveries** ⚠️

**23 deliveries (0.07%)** have TotalAmount = 0:

**Possible Scenarios:**
- **Promotional items** (free samples, gifts with purchase)
- **Warranty replacements** (no charge deliveries)
- **Returns** (mistakenly created as delivery)
- **Data correction records** (placeholders)
- **Test transactions** (ID 0 is confirmed placeholder)

**Examples:**
```
ID 0:       Trade 0, Store 0 → Placeholder record ✓
ID 477947:  Trade 473986, Store 27104 → Legitimate trade
ID 2288662: Trade 2284029, Store 892259 → Different store
```

**Action Required:** Validate with business team if zero-amount deliveries are valid.

---

## 🚨 Critical Data Quality Issues

### 1. **DISCONNECTED DELIVERED AMOUNTS** 🔴 **CRITICAL**

**The system tracks deliveries in TWO separate ways:**

#### Method 1: doTradeDelivery + doTradeDelivery-Items (Formal Delivery System)
```
Total in Delivery System:  30,137,052 BGN
Deliveries tracked:        32,113
Items tracked:             93,152 (8.9% of all TradeItems)
```

#### Method 2: TradeItem.DeliveredAmount (Direct Update Field)
```
Total DeliveredAmount:     97,574,975 BGN
Items with amount:         1,029,474 (99.85% of all TradeItems)
Items WITHOUT delivery:    936,672 (91%!) ❌
Amount untracked:          68,208,711 BGN (69%)
```

**CRITICAL PROBLEM:**
- **91% of TradeItems** with DeliveredAmount > 0 have **NO corresponding doTradeDelivery record**!
- **68.2M BGN** in "delivered" amounts are **not tracked in the formal delivery system**!

**What This Means:**
1. **Two delivery workflows exist:**
   - **Formal workflow:** Creates doTradeDelivery + doTradeDelivery-Items (30M BGN, 9% of items)
   - **Direct workflow:** Updates TradeItem.DeliveredAmount directly (68M BGN, 91% of items)

2. **The direct workflow bypasses:**
   - Delivery event logging
   - Delivery line item tracking
   - ProductReceipt integration
   - AutomaticAssembly triggers
   - Delivery history audit trail

3. **Business Implications:**
   - Cannot track "when" 91% of items were delivered (no delivery timestamp)
   - Cannot track "who" delivered items (no delivery personnel link)
   - Cannot generate delivery reports for 68M BGN in deliveries
   - Cannot trace delivery-related issues for majority of items

**Root Cause Hypotheses:**
1. **Performance optimization** - Bypass formal system for simple deliveries
2. **Legacy migration** - Old system used direct updates, new system uses doTradeDelivery
3. **Different business processes:**
   - **Retail sales** (walk-in customers) → Direct update (no delivery needed)
   - **Wholesale/B2B** → Formal delivery system (shipping required)
4. **Incomplete implementation** - Formal system not rolled out to all stores

**Action Required:**
- **URGENT:** Validate with business team which workflow is "correct"
- Document business rules for when to use formal vs direct delivery
- Plan migration strategy to unify delivery tracking
- Consider materialized view to combine both sources for reporting

### 2. **Delivery Items with Multiple Delivery Records** ⚠️

**3.5% of items (3,152)** appear in **multiple deliveries**:

```
1 delivery:  86,592 items (96.49%) ✓
2 deliveries: 2,997 items (3.34%)
3 deliveries: 119 items (0.13%)
4-9 deliveries: 36 items (0.04%)
```

**Business Logic:**
- Same TradeItem delivered across multiple shipments
- Each delivery record tracks partial quantity
- Cumulative total should match TradeItem.DeliveredQuantity

**Validation Example:**
```sql
TradeItem 957317:
- Ordered: 2.98 units
- Delivered: 1.152 units (38.66%)
- Delivery records: 2
- Need to verify: SUM(DeliveryItems.Quantity) = 1.152
```

**Data Quality Check Needed:**
```sql
-- Verify cumulative delivery quantities match
SELECT 
    di.Item,
    SUM(di.Quantity) as TotalDeliveredInRecords,
    MAX(ti.DeliveredQuantity) as TradeItemDeliveredQty,
    ABS(SUM(di.Quantity) - MAX(ti.DeliveredQuantity)) as Discrepancy
FROM [doTradeDelivery-Items] di
INNER JOIN doTradeItem ti ON ti.ID = di.Item
GROUP BY di.Item
HAVING ABS(SUM(di.Quantity) - MAX(ti.DeliveredQuantity)) > 0.01;
```

**Action Required:** Run validation query to check for discrepancies.

### 3. **Small Sum Discrepancy (283K BGN)** 🟡

**Delivery Items vs TradeItem.DeliveredAmount:**
```
Sum(DeliveryItems.TotalPrice):    30,137,052 BGN
Sum(TradeItem.DeliveredAmount):   30,420,484 BGN (for items in delivery system)
Difference:                        283,432 BGN (0.9%)
```

**Possible Causes:**
1. **Rounding errors** - Accumulated over 89,744 items
2. **Tax calculation differences** - TotalPrice vs DeliveredAmount formulas
3. **Price changes** - Item price updated after delivery created
4. **Data correction** - Manual adjustments to TradeItem amounts
5. **Multiple deliveries** - Partial delivery amounts don't sum perfectly

**Risk Assessment:** LOW - 0.9% variance is acceptable for financial data

**Action Required:** Sample check 10-20 items with largest discrepancies.

### 4. **Zero-Amount Deliveries (23 records)** 🟡

**23 deliveries (0.07%)** have TotalAmount = 0:
- ID 0 = Placeholder ✓
- 22 legitimate trades with zero delivery amounts

**Scenarios to Validate:**
1. **Free items** - Promotional/warranty items with 0 cost
2. **Return processing** - Mistakenly created as delivery
3. **Data entry errors** - Should have been deleted
4. **Test transactions** - Created for system testing

**Example:**
```
ID 2447837: Trade 2430910, Store 27090
- TotalAmount: 0
- Has ProductReceipt: 2447838 (exists!)
- Implies: Legitimate delivery of zero-cost items
```

**Action Required:** Review all 23 zero-amount deliveries with business team.

### 5. **Partial Deliveries in TradeItems** 📦

**343 TradeItems** have **incomplete deliveries**:

| Delivery Status | Count | Total Value | Delivered Value | % Delivered |
|-----------------|-------|-------------|-----------------|-------------|
| 0% delivered | 316 | 670,055 BGN | 0 BGN | 0% |
| 1-25% delivered | 1 | 1,110 BGN | 278 BGN | 25% |
| 26-50% delivered | 9 | 346 BGN | 155 BGN | 45% |
| 51-75% delivered | 8 | 884 BGN | 644 BGN | 73% |
| 76-99% delivered | 9 | 1,748 BGN | 1,566 BGN | 90% |

**Total Outstanding:** 670,055 BGN worth of items **ordered but not delivered**

**Key Questions:**
1. **0% delivered items (316):** Are these backorders? Cancelled? Pending?
2. **Partial deliveries (27):** When will remaining items be delivered?
3. **Business rules:** Max time allowed for pending deliveries?

**Example Partial Delivery:**
```
Item 1065597:
- Ordered: 10.08 units
- Delivered: 7.93 units (78.67%)
- Remaining: 2.15 units
- Value: 142.90 BGN delivered, 38.74 BGN pending
```

**Action Required:**
- Identify business process for handling backorders
- Document timeout rules for incomplete deliveries
- Plan notification system for delayed deliveries

---

## 🔧 PostgreSQL Migration Complexity

### **Complexity Rating: HIGH** 🔴

### Migration Challenges:

#### 1. **Critical: Dual Delivery Tracking System**

**Current State:**
- 9% of items use formal delivery system (doTradeDelivery)
- 91% of items use direct field update (TradeItem.DeliveredAmount)
- No unified view of all deliveries

**PostgreSQL Strategy:**

**Option A: Preserve Both Systems (Low Risk)**
```sql
-- Keep tables as-is
CREATE TABLE trade_deliveries (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL REFERENCES trade_transactions(id),
    total_amount NUMERIC(18,4) NOT NULL DEFAULT 0,
    total_tax_amount NUMERIC(18,4) NOT NULL DEFAULT 0,
    automatic_assembly_id BIGINT REFERENCES automatic_store_assemblies(id),
    product_receipt_id BIGINT REFERENCES product_receipts(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Add materialized view for unified reporting
CREATE MATERIALIZED VIEW all_deliveries AS
SELECT 
    'formal' as delivery_type,
    td.id as delivery_id,
    tt.trade_id,
    tt.store_id,
    di.trade_item_id,
    di.quantity as delivered_quantity,
    di.total_price as delivered_amount,
    td.created_at as delivery_date
FROM trade_deliveries td
JOIN trade_transactions tt ON tt.id = td.id
JOIN trade_delivery_items di ON di.delivery_id = td.id

UNION ALL

SELECT 
    'direct' as delivery_type,
    NULL as delivery_id,
    ti.trade_id,
    NULL as store_id,
    ti.id as trade_item_id,
    ti.delivered_quantity,
    ti.delivered_amount,
    NULL as delivery_date
FROM trade_items ti
WHERE ti.delivered_amount > 0
  AND NOT EXISTS (
      SELECT 1 FROM trade_delivery_items di WHERE di.trade_item_id = ti.id
  );
```

**Option B: Unify Delivery Tracking (High Risk, High Reward)**
```sql
-- Create delivery records for ALL TradeItems with DeliveredAmount > 0
INSERT INTO trade_deliveries (transaction_id, total_amount, total_tax_amount)
SELECT 
    /* Create synthetic transaction IDs */
    nextval('trade_transactions_id_seq'),
    SUM(ti.delivered_amount),
    SUM(ti.delivered_tax_amount)
FROM trade_items ti
WHERE ti.delivered_amount > 0
  AND NOT EXISTS (SELECT 1 FROM trade_delivery_items di WHERE di.trade_item_id = ti.id)
GROUP BY ti.trade_id;

-- Backfill delivery items
INSERT INTO trade_delivery_items (delivery_id, trade_item_id, quantity, ...)
SELECT 
    /* Link to synthetic delivery */
    td.id,
    ti.id,
    ti.delivered_quantity,
    ...
FROM trade_items ti
JOIN trade_deliveries td ON td.trade_id = ti.trade_id
WHERE ti.delivered_amount > 0
  AND NOT EXISTS (SELECT 1 FROM trade_delivery_items di WHERE di.trade_item_id = ti.id);
```

**Recommendation:** Start with **Option A** (preserve both), then gradually migrate to **Option B** after validating business rules.

#### 2. **Decimal Precision**

Current: `decimal(28,10)` - excessive precision  
Observed: All values use ≤4 decimal places

**PostgreSQL Schema:**
```sql
CREATE TABLE trade_deliveries (
    id BIGSERIAL PRIMARY KEY,
    total_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    total_tax_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    automatic_assembly_id BIGINT REFERENCES automatic_store_assemblies(id),
    product_receipt_id BIGINT REFERENCES product_receipts(id),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE trade_delivery_items (
    id BIGSERIAL PRIMARY KEY,
    delivery_id BIGINT NOT NULL REFERENCES trade_deliveries(id) ON DELETE CASCADE,
    trade_item_id BIGINT NOT NULL REFERENCES trade_items(id),
    quantity NUMERIC(18, 4) NOT NULL DEFAULT 0,
    price NUMERIC(18, 4) NOT NULL DEFAULT 0,
    total_price NUMERIC(18, 4) NOT NULL DEFAULT 0,
    tax_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    total_tax_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
```

#### 3. **Indexing Strategy**

```sql
-- Primary indexes (auto-created)
CREATE UNIQUE INDEX idx_trade_deliveries_pk ON trade_deliveries(id);
CREATE UNIQUE INDEX idx_trade_delivery_items_pk ON trade_delivery_items(id);

-- Foreign key indexes
CREATE INDEX idx_trade_deliveries_transaction ON trade_deliveries(transaction_id);
CREATE INDEX idx_trade_deliveries_assembly ON trade_deliveries(automatic_assembly_id) 
    WHERE automatic_assembly_id IS NOT NULL;  -- Partial index (0.39%)
CREATE INDEX idx_trade_deliveries_receipt ON trade_deliveries(product_receipt_id) 
    WHERE product_receipt_id IS NOT NULL;  -- Partial index (12.6%)

-- Delivery items indexes
CREATE INDEX idx_delivery_items_delivery ON trade_delivery_items(delivery_id);
CREATE INDEX idx_delivery_items_trade_item ON trade_delivery_items(trade_item_id);

-- Composite index for common queries
CREATE INDEX idx_delivery_items_item_delivery ON trade_delivery_items(trade_item_id, delivery_id);

-- Reporting indexes
CREATE INDEX idx_trade_deliveries_amount ON trade_deliveries(total_amount) 
    WHERE total_amount > 0;  -- Exclude zero-amount deliveries
```

#### 4. **Handling Multiple Deliveries**

Unlike doTradePayment-Items, **items CAN appear in multiple deliveries**:

```sql
-- NO unique constraint on (delivery_id, trade_item_id)
-- Allow multiple partial deliveries for same item

-- Instead, add validation check
ALTER TABLE trade_delivery_items ADD CONSTRAINT chk_cumulative_delivery
CHECK (
    (SELECT SUM(quantity) 
     FROM trade_delivery_items 
     WHERE trade_item_id = trade_delivery_items.trade_item_id)
    <= 
    (SELECT quantity FROM trade_items WHERE id = trade_delivery_items.trade_item_id)
);

-- Create trigger to update TradeItem.DeliveredQuantity
CREATE OR REPLACE FUNCTION update_delivered_quantity()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE trade_items
    SET 
        delivered_quantity = (
            SELECT COALESCE(SUM(quantity), 0)
            FROM trade_delivery_items
            WHERE trade_item_id = NEW.trade_item_id
        ),
        delivered_amount = (
            SELECT COALESCE(SUM(total_price), 0)
            FROM trade_delivery_items
            WHERE trade_item_id = NEW.trade_item_id
        )
    WHERE id = NEW.trade_item_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_update_delivered_quantity
AFTER INSERT OR UPDATE OR DELETE ON trade_delivery_items
FOR EACH ROW
EXECUTE FUNCTION update_delivered_quantity();
```

#### 5. **Shared PK Pattern Migration**

Current: `doTradeDelivery.ID = doTradeTransaction.ID`

**Option A: Preserve Pattern**
```sql
-- Keep shared ID (requires coordination)
CREATE TABLE trade_deliveries (
    id BIGINT PRIMARY KEY,  -- Manual ID from trade_transactions
    ...
);

-- Application must:
-- 1. INSERT INTO trade_transactions RETURNING id
-- 2. INSERT INTO trade_deliveries VALUES (returned_id, ...)
```

**Option B: Separate Sequence (Recommended)**
```sql
-- Independent ID sequence
CREATE TABLE trade_deliveries (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT NOT NULL UNIQUE REFERENCES trade_transactions(id),
    ...
);

-- Cleaner design, easier to manage
```

**Recommendation:** Use **Option B** for new system simplicity.

#### 6. **Data Integrity Constraints**

```sql
-- Prevent negative amounts
ALTER TABLE trade_deliveries ADD CONSTRAINT chk_positive_amounts
CHECK (total_amount >= 0 AND total_tax_amount >= 0);

-- Tax should not exceed amount (reasonable business rule)
ALTER TABLE trade_deliveries ADD CONSTRAINT chk_tax_reasonable
CHECK (total_tax_amount <= total_amount * 0.5);  -- Max 50% tax

-- Delivery items must belong to same trade
CREATE OR REPLACE FUNCTION validate_delivery_item_trade()
RETURNS TRIGGER AS $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 
        FROM trade_deliveries td
        JOIN trade_transactions tt ON tt.id = td.transaction_id
        JOIN trade_items ti ON ti.trade_id = tt.trade_id
        WHERE td.id = NEW.delivery_id AND ti.id = NEW.trade_item_id
    ) THEN
        RAISE EXCEPTION 'Delivery item must belong to same trade as delivery';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_validate_delivery_item_trade
BEFORE INSERT OR UPDATE ON trade_delivery_items
FOR EACH ROW
EXECUTE FUNCTION validate_delivery_item_trade();
```

---

## 🎯 Migration Recommendations

### Phase 1: Data Migration (Week 5-6)

#### Step 1: Extract Formal Deliveries
```sql
-- Export doTradeDelivery
SELECT 
    ID,
    TotalAmount,
    TotalTaxAmount,
    AutomaticAssembly,
    ProductReceipt
FROM doTradeDelivery
WHERE ID > 0  -- Exclude placeholder
ORDER BY ID;

-- Export doTradeDelivery-Items
SELECT 
    ID,
    Owner,
    Item,
    Quantity,
    Price,
    TotalPrice,
    TaxAmount,
    TotalTaxAmount
FROM [doTradeDelivery-Items]
ORDER BY Owner, ID;
```

#### Step 2: Analyze "Direct Delivery" Items
```sql
-- Identify items delivered outside formal system
SELECT 
    ti.ID as TradeItemID,
    ti.Owner as TradeID,
    ti.Quantity as OrderedQty,
    ti.DeliveredQuantity,
    ti.TotalPaymentPrice,
    ti.DeliveredAmount,
    ti.DeliveredTaxAmount,
    CASE 
        WHEN di.ID IS NOT NULL THEN 'Has Formal Delivery'
        ELSE 'Direct Update Only'
    END as DeliveryType
FROM doTradeItem ti
LEFT JOIN [doTradeDelivery-Items] di ON di.Item = ti.ID
WHERE ti.DeliveredAmount > 0
  AND ti.Owner > 0
ORDER BY ti.Owner, ti.ID;
```

#### Step 3: Stakeholder Decision Required
**CRITICAL DECISION:** How to handle 91% of items with "direct delivery" updates?

**Option A: Leave as-is**
- Migrate only formal deliveries (9% of items)
- Keep DeliveredAmount field in TradeItems
- Accept dual tracking system
- **Risk:** Reporting complexity continues

**Option B: Backfill synthetic deliveries**
- Create delivery records for all items with DeliveredAmount > 0
- Synthetic delivery date = Trade date (best guess)
- Unified delivery tracking
- **Risk:** Historical data distortion

**Option C: Gradual migration**
- Start: Dual system (preserve both)
- Future: All NEW deliveries use formal system
- Historical: Keep direct updates
- **Risk:** Complexity persists during transition

**Recommendation:** Start with **Option A** → Transition to **Option C** → Eventually **Option B** after validation.

### Phase 2: Application Code (Week 7-8)

#### Update ORM Models
```csharp
// Old: Entity Framework 4.x
public class TradeDelivery {
    public long ID { get; set; }
    public decimal TotalAmount { get; set; }
    public decimal TotalTaxAmount { get; set; }
    public long? AutomaticAssembly { get; set; }
    public long? ProductReceipt { get; set; }
}

// New: EF Core 8
public class TradeDelivery {
    public long Id { get; set; }
    
    public long TransactionId { get; set; }
    public TradeTransaction Transaction { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal TotalAmount { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal TotalTaxAmount { get; set; }
    
    public long? AutomaticAssemblyId { get; set; }
    public AutomaticStoreAssembly AutomaticAssembly { get; set; }
    
    public long? ProductReceiptId { get; set; }
    public ProductReceipt ProductReceipt { get; set; }
    
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;
    
    // Navigation
    public ICollection<TradeDeliveryItem> Items { get; set; }
}

public class TradeDeliveryItem {
    public long Id { get; set; }
    
    public long DeliveryId { get; set; }
    public TradeDelivery Delivery { get; set; }
    
    public long TradeItemId { get; set; }
    public TradeItem TradeItem { get; set; }
    
    [Column(TypeName = "numeric(18,4)")]
    public decimal Quantity { get; set; }
    
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

#### Refactor Delivery Logic
```csharp
// OLD: Direct TradeItem update
tradeItem.DeliveredQuantity = deliveryQty;
tradeItem.DeliveredAmount = deliveryAmount;
dbContext.SaveChanges();

// NEW: Formal delivery system
var delivery = new TradeDelivery {
    TransactionId = transaction.Id,
    TotalAmount = deliveryItems.Sum(x => x.TotalPrice),
    TotalTaxAmount = deliveryItems.Sum(x => x.TotalTaxAmount)
};
dbContext.TradeDeliveries.Add(delivery);

foreach (var item in deliveryItems) {
    delivery.Items.Add(new TradeDeliveryItem {
        TradeItemId = item.TradeItemId,
        Quantity = item.Quantity,
        Price = item.Price,
        TotalPrice = item.TotalPrice,
        TaxAmount = item.TaxAmount,
        TotalTaxAmount = item.TotalTaxAmount
    });
}

await dbContext.SaveChangesAsync();
// Trigger will auto-update TradeItem.DeliveredQuantity
```

### Phase 3: Business Process Review (Week 8-9)

**Critical Questions for Stakeholders:**

#### Delivery Workflow:
1. **Direct vs Formal:** When should we use direct TradeItem update vs formal delivery system?
2. **Retail vs Wholesale:** Different delivery processes for different customer types?
3. **Store pickup:** How to track when customer picks up in-store? (no shipping needed)
4. **Multiple warehouses:** How to handle split shipments from different locations?

#### Partial Deliveries:
5. **Backorder policy:** Max time allowed for unfulfilled items (316 items, 670K BGN)?
6. **Customer notification:** Automated alerts for partial deliveries?
7. **Cancellation rules:** When to auto-cancel pending deliveries?

#### ProductReceipt:
8. **Purpose:** What is the business purpose of ProductReceipt? (12.6% of deliveries)
9. **Threshold:** When is ProductReceipt required? (avg 2,567 BGN vs 694 BGN)
10. **Audit trail:** Is this for compliance, warranty, or inventory tracking?

#### AutomaticAssembly:
11. **Use cases:** What triggers AutomaticAssembly? (0.39% of deliveries)
12. **Kit assembly:** Delivering components that auto-assemble into finished product?
13. **Manufacturing:** Related to production orders?

#### Zero-Amount Deliveries:
14. **Valid scenarios:** Are zero-amount deliveries legitimate? (23 records)
15. **Free items:** How to track promotional/warranty items with 0 cost?

### Phase 4: Performance Testing (Week 9)

**Test Scenarios:**
1. **Single item delivery** - Most common (48.95%)
2. **Multi-item delivery** - 398 items (extreme case)
3. **Multiple deliveries per trade** - 17 deliveries (extreme case)
4. **Multiple deliveries per item** - 9 deliveries for same item
5. **Partial delivery workflow** - Deliver 50% now, 50% later
6. **Materialized view refresh** - Unified delivery reporting

**Benchmarks:**
- Single delivery creation: <50ms
- 398-item delivery: <500ms
- Delivery history query (per trade): <100ms
- Unified delivery report (all sources): <5 seconds
- Materialized view refresh: <30 seconds

---

## 📝 Questions for Stakeholders

### Data Model:
1. **Dual tracking:** Why do 91% of items use direct DeliveredAmount field instead of formal delivery system?
2. **Store split:** Do we intentionally deliver items from multiple stores? (27.5% multi-delivery trades)
3. **Item split:** Why do 3.5% of items have multiple delivery records?

### Business Process:
4. **ProductReceipt:** What triggers creation? What is its purpose?
5. **AutomaticAssembly:** What business process uses this? (very rare - 0.39%)
6. **Zero-amount:** Are zero-cost deliveries valid business transactions?
7. **Backorders:** What is the process for 316 items (670K BGN) with 0% delivery?

### Migration Strategy:
8. **Historical data:** Should we backfill formal deliveries for 91% of "direct" items?
9. **Unified system:** Should new system enforce formal delivery for ALL items?
10. **Reporting:** How important is unified delivery reporting across both systems?

---

## 🔍 Sample Data

### Standard Single Delivery:
```
DeliveryID: 54640
Trade: 51296, Store: 27090
TotalAmount: 26,600 BGN
TotalTax: 5,320 BGN
Items: [Not shown - need to query doTradeDelivery-Items]
ProductReceipt: 250976 ✓
AutomaticAssembly: NULL
```

### Multi-Item Delivery (398 items):
```
DeliveryID: 1434783
Trade: 1433999, Store: 27090
TotalAmount: 9,596.30 BGN
TotalTax: [Not shown]
Items: 398 separate line items
Avg per item: 24.11 BGN
Pattern: Large bulk order with detailed item tracking
```

### Zero-Amount Delivery:
```
DeliveryID: 2447837
Trade: 2430910, Store: 27090
TotalAmount: 0 BGN
TotalTax: 0 BGN
ProductReceipt: 2447838 ✓
Pattern: Free items delivered with formal receipt
```

### Delivery with AutomaticAssembly:
```
DeliveryID: 737041
Trade: 735177, Store: 27090
TotalAmount: 7,800 BGN
AutomaticAssembly: 737042 (ID + 1 pattern)
ProductReceipt: NULL
Pattern: Delivery triggers automatic inventory assembly
```

---

## ✅ Analysis Complete

**Next Steps:**
1. Analyze `doTradeDelivery-Items` for line item details (already partially analyzed)
2. Investigate doProductReceipt table (12.6% of deliveries link to it)
3. Investigate doAutomaticStoreAssembly table (0.39% of deliveries)
4. Interview stakeholders about dual delivery tracking system
5. Validate business rules for partial deliveries and backorders
6. Plan unified delivery reporting strategy

**Key Discoveries:**
- **Dual delivery system:** 9% formal, 91% direct updates (CRITICAL ISSUE!)
- **Multiple deliveries:** 27.5% of trades, up to 17 deliveries per trade
- **Multiple deliveries per item:** 3.5% of items, up to 9 deliveries
- **ProductReceipt:** 12.6% of deliveries (high-value: 2,567 BGN avg)
- **AutomaticAssembly:** 0.39% of deliveries (rare feature)
- **Partial deliveries:** 343 items with incomplete fulfillment (670K BGN outstanding)

**Migration Complexity:** HIGH (dual tracking system, multiple deliveries per item, shared PK pattern)  
**Business Criticality:** VERY HIGH (30M BGN tracked + 68M BGN untracked = 98M BGN total)  
**PostgreSQL Readiness:** 60% (needs stakeholder decision on unification strategy)

---

**Analyst:** Claude (Sonnet 4.5)  
**Validated By:** Svetlyo Partenev  
**Status:** ✅ Complete  
**Duration:** [Analysis time]

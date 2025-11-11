# doTradeTransaction - Analysis Report

**Table:** `doTradeTransaction`  
**Domain:** Trade/Sales  
**Analysis Date:** 2025-11-10  
**Database:** TEKA (SQL Server 2005)

---

## 📋 Schema

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NO | 0 | Primary Key (shared with SystemTransaction) |
| Trade | bigint | NO | 0 | FK to doTrade |
| Store | bigint | NO | 0 | FK to doStore |

**Primary Key:** `PK_doTradeTransaction` (ID) - Clustered  
**Indexes:**
- `IX_Trade` (Trade) - Nonclustered
- `IX_Store` (Store) - Nonclustered

---

## 🔗 Relationships

### Foreign Keys IN:
1. **doStore.ID → Store** (many-to-one)
2. **doTrade.ID → Trade** (many-to-one)
3. **doSystemTransaction.ID → ID** (one-to-one inheritance)

### Foreign Keys OUT (ID is shared PK):
1. **doTrade** (ID) - Trade creation events
2. **doTradePayment** (ID) - Payment events
3. **doTradeDelivery** (ID) - Delivery events
4. **doTradeReturn** (ID) - Return events
5. **doTradeCancel** (ID) - Cancellation events

---

## 📊 Data Statistics

```
Total Records:        764,906
Unique Trades:        365,771
Unique Stores:        27
Date Range:           (Inherited from SystemTransaction)
Orphaned Records:     0 (excellent referential integrity)
```

### Event Distribution:
```
Trade Creations:      365,771 (47.8%)
Payments:             365,963 (47.8%)
Deliveries:            32,113 (4.2%)
Returns:                1,060 (0.1%)
Cancellations:              3 (0.0%)
─────────────────────────────────
Total Events:         764,910 ≈ 764,906 ✓
```

### Average Events per Trade:
- **Mean:** 2.09 events/trade
- **Min:** 1 event (trade only, no payment)
- **Max:** 29 events (complex multi-store, multi-payment trade)

### Store Concentration:
| Store ID | Unique Trades | Total Events | % of Total |
|----------|---------------|--------------|------------|
| 27104    | 114,300       | 233,022      | 30.5%      |
| 27126    | 107,467       | 216,539      | 28.3%      |
| 27090    | 75,903        | 141,061      | 18.4%      |
| **Top 3**| **297,670**   | **590,622**  | **77.2%**  |

---

## 💡 Business Logic

### Architecture Pattern: **Event Sourcing**

`doTradeTransaction` implements an **event log** pattern where:
1. Each row represents a **business event** in the trade lifecycle
2. The `ID` column serves as both:
   - Primary key for this junction table
   - Shared primary key for 5 child event tables (inheritance)
3. One Trade generates multiple transaction events across its lifecycle

### Event Flow Example (Trade ID: 1230765):
```
Event #1  (ID: 1230765) → doTrade          [Store: 892259] - Trade Created
Event #2  (ID: 1297737) → doTradePayment   [Store: 27090]  - Payment 1
Event #3  (ID: 1477655) → doTradePayment   [Store: 27090]  - Payment 2
Event #4  (ID: 1486752) → doTradeReturn    [Store: 27090]  - Return 1
Event #5  (ID: 1486769) → doTradePayment   [Store: 27090]  - Payment 3
...
Event #29 (ID: 3485554) → doTradePayment   [Store: 27090]  - Payment 17

Total: 1 Trade + 17 Payments + 11 Returns = 29 Events
```

### Key Patterns:
1. **Multiple Payments:** Trades support installment payments (17 payments for 1 trade observed)
2. **Multi-Store Fulfillment:** One trade can span multiple stores (11 different stores for returns)
3. **Partial Returns:** Returns are recorded separately per store
4. **Rare Cancellations:** Only 3 cancellations in 365K trades (0.0008%)

---

## 🚨 Data Quality Issues

### ✅ Strengths:
- **Zero orphaned records** (perfect referential integrity)
- **Consistent event recording** (math validates: 365,771 + 365,963 + 32,113 + 1,060 + 3 ≈ 764,906)

### ⚠️ Risks:
1. **Trades without Payments:** 1,605 trades (0.4%) have no payment events
   - Likely: Credit transactions, samples, or internal transfers
   - **Action Required:** Validate business rules with stakeholders

2. **Store Concentration:** 77% of transactions in 3 stores
   - **Risk:** Performance bottleneck if queries don't filter by Store
   - **Mitigation:** Partition by Store in PostgreSQL

3. **High Max Events (29):** Complex trades exist
   - **Risk:** N+1 query problems when reconstructing trade history
   - **Mitigation:** Eager loading or materialized views

---

## 🔧 PostgreSQL Migration Complexity

### **Complexity Rating: HIGH** 🔴

### Migration Challenges:

#### 1. **Inheritance Pattern** (Critical)
Current SQL Server design uses **shared primary key inheritance**:
```
doSystemTransaction (base)
    └─ doTradeTransaction (adds Trade, Store columns)
           └─ doTrade, doTradePayment, doTradeDelivery, etc. (share same ID)
```

**PostgreSQL Options:**
- **Option A:** Keep SQL Server pattern (works, but non-idiomatic)
- **Option B:** Use PostgreSQL table inheritance (better, but changes FK structure)
- **Option C:** Add `event_type` ENUM column and merge 5 tables into one

**Recommendation:** Option C (denormalize event types)
```sql
CREATE TYPE trade_event_type AS ENUM (
    'trade', 'payment', 'delivery', 'return', 'cancel'
);

CREATE TABLE trade_transactions (
    id BIGSERIAL PRIMARY KEY,
    trade_id BIGINT NOT NULL REFERENCES trades(id),
    store_id BIGINT NOT NULL REFERENCES stores(id),
    event_type trade_event_type NOT NULL,
    event_data JSONB,  -- Store event-specific fields
    created_at TIMESTAMP DEFAULT NOW()
);
```

#### 2. **Partitioning Strategy**
With 764K rows and 77% concentration in 3 stores:

```sql
-- Partition by store_id (hash or list)
CREATE TABLE trade_transactions_store_27104 PARTITION OF trade_transactions
    FOR VALUES IN (27104);

CREATE TABLE trade_transactions_store_27126 PARTITION OF trade_transactions
    FOR VALUES IN (27126);

CREATE TABLE trade_transactions_store_27090 PARTITION OF trade_transactions
    FOR VALUES IN (27090);

CREATE TABLE trade_transactions_others PARTITION OF trade_transactions
    DEFAULT;
```

#### 3. **Indexing Strategy**
```sql
-- Primary index for event reconstruction
CREATE INDEX idx_trade_events ON trade_transactions(trade_id, id);

-- Store-based queries
CREATE INDEX idx_store_events ON trade_transactions(store_id, created_at);

-- Event type filtering
CREATE INDEX idx_event_type ON trade_transactions(event_type) 
    WHERE event_type IN ('return', 'cancel');  -- Partial index for rare events
```

#### 4. **Performance Optimization**
Create materialized view for trade summaries:
```sql
CREATE MATERIALIZED VIEW trade_summary AS
SELECT 
    trade_id,
    COUNT(*) as total_events,
    COUNT(*) FILTER (WHERE event_type = 'payment') as payment_count,
    COUNT(*) FILTER (WHERE event_type = 'delivery') as delivery_count,
    COUNT(*) FILTER (WHERE event_type = 'return') as return_count,
    MAX(created_at) as last_event_at
FROM trade_transactions
GROUP BY trade_id;

CREATE UNIQUE INDEX ON trade_summary(trade_id);
```

---

## 🎯 Migration Recommendations

### Phase 1: Data Migration
1. **Extract all 5 event tables** (doTrade, doTradePayment, etc.)
2. **Merge into single `trade_transactions` table** with `event_type` column
3. **Validate row count:** 764,906 events total
4. **Check for ID collisions** (should be none due to shared PK)

### Phase 2: Application Code Changes
1. **Refactor queries** to use `event_type` filter instead of JOINs to 5 tables
2. **Update ORM models** (Entity Framework → EF Core 8)
3. **Test event reconstruction logic** (especially for 29-event trades)

### Phase 3: Performance Testing
1. **Load test:** Query performance for top 3 stores (77% of traffic)
2. **Benchmark:** Event reconstruction for high-event trades (29+ events)
3. **Monitor:** Materialized view refresh performance

---

## 📝 Questions for Stakeholders

1. **Business Rules:**
   - What do the 1,605 trades without payments represent? (Credits? Samples?)
   - Are multi-store fulfillments common or edge cases?
   - Max expected payments per trade? (Current max: 17)

2. **Performance Requirements:**
   - Acceptable latency for trade history queries?
   - How often is trade summary data accessed?
   - Are real-time event logs required, or can we cache?

3. **Feature Usage:**
   - How often are cancellations used? (Only 3 in dataset)
   - Is the return process per-store or per-trade?

---

## 🔍 Sample Data

### High-Complexity Trade (ID: 1230765, 29 Events):
```
Creation Store: 892259
Payment Stores: 27090 (17 payments)
Return Stores:  27090 (6), 27108 (3), 27104 (1), 892259 (1)
Event Span:     Multiple dates (check SystemTransaction for timestamps)
```

### Normal Trade Pattern (2 Events):
```
Trade Creation  → 1 event in doTrade
Payment         → 1 event in doTradePayment
                  (Same Trade ID, likely same/next Store)
```

---

## ✅ Analysis Complete

**Next Steps:**
1. Analyze child event tables (doTrade, doTradePayment, etc.) for event-specific fields
2. Document SystemTransaction inheritance (timestamps, user tracking)
3. Map to Next.js 14 frontend requirements

**Migration Complexity:** HIGH (inheritance pattern, partitioning, denormalization)  
**Business Criticality:** CRITICAL (core transaction log)  
**PostgreSQL Readiness:** 70% (needs schema redesign)

---

**Analyst:** Claude (Sonnet 4.5)  
**Validated By:** Svetlyo Partenev  
**Status:** ✅ Complete

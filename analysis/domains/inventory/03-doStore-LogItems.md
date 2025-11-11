# doStore-LogItems - Daily Inventory Movement Aggregates

**Domain:** Inventory  
**Table Type:** Daily Aggregated Log (Movement History)  
**Analysis Date:** 2025-11-11  
**Status:** ✅ COMPLETE

---

## 📊 QUICK SUMMARY

- **Volume:** 1,206,225 movement records ⚠️ **MASSIVE TABLE!**
- **Date Range:** 2006-02-14 to 2021-09-15 (15.6 years)
- **Stores:** 29 unique locations
- **Products:** 24,277 unique SKUs tracked
- **Granularity:** Daily aggregates per (Store, Product, Date)

### Movement Type Distribution:
- 📦 **Sale:** 684,546 (56.8%) - Dominant movement
- 📥 **Supply:** 197,263 (16.4%) - Inbound from suppliers
- 🔄 **TransferIn:** 131,425 (10.9%) - Inter-store transfers
- 🔄 **TransferOut:** 113,346 (9.4%)
- 🔧 **AssemblyOutput:** 7,089 (0.6%) - Products created
- 🔧 **AssemblyInput:** 5,582 (0.5%) - Components consumed
- 🗑️ **Discard:** 3,413 (0.3%) - Write-offs
- ❓ **Unknown:** 63,561 (5.3%) - **INVESTIGATE!**

---

## 📋 SCHEMA (17 columns)

| # | Column | Type | Nullable | Default | Description |
|---|--------|------|----------|---------|-------------|
| 1 | **ID** | bigint | NO | - | Primary key |
| 2 | **Owner** | bigint | NO | 0 | FK → doStore (location) |
| 3 | **Product** | bigint | NO | 0 | FK → doProduct (SKU) |
| 4 | **Date** | smalldatetime | NO | 1901-01-01 | Movement date (daily aggregation) |
| 5 | **Input** | decimal | NO | 0.0 | Total units received (sum of all inputs) |
| 6 | **Output** | decimal | NO | 0.0 | Total units removed (sum of all outputs) |
| 7 | Supply | decimal | NO | 0.0 | Inbound from suppliers |
| 8 | SupplyDelivery | decimal | NO | 0.0 | Supplier delivery fulfillment |
| 9 | SupplyReturn | decimal | NO | 0.0 | Returns to supplier |
| 10 | **Sale** | decimal | NO | 0.0 | Sales to customers |
| 11 | SaleDelivery | decimal | NO | 0.0 | Sales delivery fulfillment |
| 12 | SaleReturn | decimal | NO | 0.0 | Customer returns |
| 13 | TransferInput | decimal | NO | 0.0 | Received from other stores |
| 14 | TransferOutput | decimal | NO | 0.0 | Sent to other stores |
| 15 | AssemblyInput | decimal | NO | 0.0 | Components used in assembly |
| 16 | AssemblyOutput | decimal | NO | 0.0 | Finished products from assembly |
| 17 | Discard | decimal | NO | 0.0 | Write-offs, damages, spoilage |

**Design Pattern:** Daily bucket aggregation - one record per (Store, Product, Date) with movement types as columns.

---

## 🔗 RELATIONSHIPS (2 Foreign Keys)

### Outgoing:
| FK Name | Column | → Referenced Table |
|---------|--------|-------------------|
| FK_doStore-LogItems_Owner | Owner | doStore |
| FK_doStore-LogItems_Product | Product | doProduct |

### Incoming:
- **None** - Historical log table, not referenced

---

## 🔍 KEY FINDINGS

### ✅ Strengths:
1. **Comprehensive tracking** - 15.6 years of inventory history
2. **Granular movement types** - 11 distinct transaction types
3. **Event sourcing foundation** - Can reconstruct inventory at any date
4. **Daily aggregation** - Reduces volume vs. transaction-level logging

### ⚠️ CRITICAL ISSUES:

#### 1. **MASSIVE VOLUME (1.2M rows)**
```
Performance Risk: 15-second query timeouts
Migration Complexity: 6-8 hours for data transfer
```
- **Recommendation:** Partition by Year in PostgreSQL
- **Archive Strategy:** Move data older than 3 years to cold storage

#### 2. **Unknown Movement Type (63,561 records - 5.3%)**
```
Records with no movement type columns > 0
```
- **Impact:** Data quality issue, missing classification
- **Action:** Investigate why Input/Output exist without type

#### 3. **Date Default (1901-01-01)**
```sql
Date smalldatetime DEFAULT '1901-01-01'
```
- **Risk:** Invalid dates may exist
- **Validation Required:** Check for dates < 2006

#### 4. **No Transaction Reference**
```
Missing FK to source transaction (Trade, Transfer, etc.)
```
- **Limitation:** Cannot trace back to originating document
- **Workaround:** Must join by Date + Store + Product

#### 5. **Dual Tracking System**
```
Input/Output = Summary totals
Sale/Supply/Transfer/etc = Detailed breakdown

Input should = Supply + SupplyDelivery + TransferInput + AssemblyInput
Output should = Sale + SaleDelivery + TransferOutput + AssemblyOutput + Discard
```
- **Validation:** Check if Input/Output match sum of details

---

## 📊 SAMPLE DATA PATTERNS

From TOP 20 (2019-2021):
- **Most common:** Sale movements (10 out of 20)
- **Fractional quantities:** 3.05, 7.925, 10.08 (weight-based products)
- **Assembly pattern:** Input=Output for assembled items (15 in, 15 out)
- **Store 27096:** High activity (11 records in top 20)

---

## 🎯 BUSINESS LOGIC INTERPRETATION

### Movement Lifecycle:
```
Daily Batch Job → Aggregate all transactions for (Store, Product, Date)
                → Insert/Update doStore-LogItems record
                → Update doStore-Items.Quantity accordingly

Inventory Formula:
Current Stock = Opening + Input - Output
              = Opening + (Supply + Transfers In + Assembly Out) 
                        - (Sales + Transfers Out + Assembly In + Discards)
```

### Movement Types Explained:

**Inbound (Input):**
- Supply: Purchase orders from vendors
- TransferInput: Inter-store transfers received
- AssemblyOutput: Finished goods from production
- SaleReturn: Customer returns

**Outbound (Output):**
- Sale: Sold to customers
- TransferOutput: Sent to other stores
- AssemblyInput: Raw materials for production
- Discard: Damage, expiry, theft
- SupplyReturn: Returns to vendor

---

## 🚀 POSTGRESQL MIGRATION COMPLEXITY

**Rating:** ⭐⭐⭐⭐ (HIGH)

### Why High Complexity:

1. **Massive Volume:** 1.2M rows → requires batch processing
2. **Performance Critical:** Needs partitioning strategy
3. **Date Range Validation:** Potential invalid dates
4. **Complex Schema:** 17 columns with business logic
5. **Query Timeouts:** Large aggregations need optimization

### Migration Steps:

#### Phase 1: Schema with Partitioning (2 hours)
```sql
CREATE TABLE do_store_log_items (
    id BIGSERIAL,
    owner_id BIGINT NOT NULL,
    product_id BIGINT NOT NULL,
    movement_date DATE NOT NULL,
    input_qty NUMERIC(18,4) NOT NULL DEFAULT 0,
    output_qty NUMERIC(18,4) NOT NULL DEFAULT 0,
    supply NUMERIC(18,4) NOT NULL DEFAULT 0,
    supply_delivery NUMERIC(18,4) NOT NULL DEFAULT 0,
    supply_return NUMERIC(18,4) NOT NULL DEFAULT 0,
    sale NUMERIC(18,4) NOT NULL DEFAULT 0,
    sale_delivery NUMERIC(18,4) NOT NULL DEFAULT 0,
    sale_return NUMERIC(18,4) NOT NULL DEFAULT 0,
    transfer_input NUMERIC(18,4) NOT NULL DEFAULT 0,
    transfer_output NUMERIC(18,4) NOT NULL DEFAULT 0,
    assembly_input NUMERIC(18,4) NOT NULL DEFAULT 0,
    assembly_output NUMERIC(18,4) NOT NULL DEFAULT 0,
    discard NUMERIC(18,4) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    PRIMARY KEY (id, movement_date)
) PARTITION BY RANGE (movement_date);

-- Create partitions by year
CREATE TABLE do_store_log_items_2006_2010 
    PARTITION OF do_store_log_items 
    FOR VALUES FROM ('2006-01-01') TO ('2011-01-01');

CREATE TABLE do_store_log_items_2011_2015 
    PARTITION OF do_store_log_items 
    FOR VALUES FROM ('2011-01-01') TO ('2016-01-01');

CREATE TABLE do_store_log_items_2016_2020 
    PARTITION OF do_store_log_items 
    FOR VALUES FROM ('2016-01-01') TO ('2021-01-01');

CREATE TABLE do_store_log_items_2021_2025 
    PARTITION OF do_store_log_items 
    FOR VALUES FROM ('2021-01-01') TO ('2026-01-01');

-- Indexes on each partition
CREATE INDEX idx_log_items_owner_date ON do_store_log_items(owner_id, movement_date);
CREATE INDEX idx_log_items_product_date ON do_store_log_items(product_id, movement_date);
CREATE INDEX idx_log_items_date ON do_store_log_items(movement_date);
```

#### Phase 2: Data Cleaning (2 hours)
```sql
-- Identify invalid dates
SELECT COUNT(*) FROM [doStore-LogItems] WHERE Date < '2006-01-01';

-- Identify unknown movements
SELECT COUNT(*) FROM [doStore-LogItems] 
WHERE Input = 0 AND Output = 0;

-- Validate Input/Output consistency
SELECT TOP 100 *,
    (Supply + SupplyDelivery + TransferInput + AssemblyInput + SaleReturn) AS calculated_input,
    (Sale + SaleDelivery + TransferOutput + AssemblyOutput + Discard + SupplyReturn) AS calculated_output
FROM [doStore-LogItems]
WHERE ABS(Input - (Supply + SupplyDelivery + TransferInput + AssemblyInput + SaleReturn)) > 0.01
   OR ABS(Output - (Sale + SaleDelivery + TransferOutput + AssemblyOutput + Discard + SupplyReturn)) > 0.01;
```

#### Phase 3: Batch Migration (6 hours)
```sql
-- Migrate in batches of 100K records per transaction
-- Use cursor or pagination by ID ranges
-- Monitor memory and connection timeouts
```

#### Phase 4: Validation (2 hours)
```sql
-- Row count verification
-- Sum validations by year
-- Date range checks
-- FK integrity verification
```

### Estimated Migration Time: **12 hours** (1.5 days)

---

## 📋 RECOMMENDATIONS

### Pre-Migration:
1. 🔴 **Archive old data** (2006-2015?) to reduce volume
2. 🔴 **Investigate 63K unknown movements** - add classification
3. ✅ **Validate Input/Output consistency** with detail columns
4. ✅ **Document movement type meanings** for business users

### Post-Migration:
1. ✅ Create materialized views for monthly aggregates
2. ✅ Set up automated partition management (add new years)
3. ✅ Implement retention policy (7 years legal requirement?)
4. ✅ Add CHECK constraints for Input/Output >= 0

### Performance:
1. 🔴 **Partition by Year** (critical for query performance)
2. ✅ Index on (Owner, Date), (Product, Date)
3. ✅ Consider columnstore index for analytics queries
4. ✅ Schedule vacuum and analyze jobs

---

## 📊 STAKEHOLDER QUESTIONS

1. Why are 63K movements (5.3%) unclassified?
2. Should we archive data older than 5 years?
3. Are Assembly movements used actively (0.6% only)?
4. What's the Discard rate target? (0.3% seems low)
5. Can we trace movements back to source documents?

---

**Analysis Complete:** 2025-11-11  
**Next Table:** 04-doStore-InitiationItems  
**Estimated Time:** 1 hour

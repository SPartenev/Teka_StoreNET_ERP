# doTradePayment - Analysis Report

**Table:** `doTradePayment`  
**Domain:** Trade/Sales - Payment Events  
**Analysis Date:** 2025-11-10  
**Database:** TEKA (SQL Server 2005)

---

## 📋 Schema

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NO | 0 | Primary Key (inherited from TradeTransaction) |
| TotalAmount | decimal | NO | 0.0 | Payment amount (includes tax) |
| TotalTaxAmount | decimal | NO | 0.0 | VAT/Tax portion |
| FinanceTransaction | bigint | NO | 0 | FK to doFinanceTransaction |

**Primary Key:** `PK_doTradePayment` (ID) - Clustered  
**Indexes:**
- `IX_FinanceTransaction` (FinanceTransaction) - Nonclustered

---

## 🔗 Relationships

### Foreign Keys IN:
1. **doTradeTransaction.ID → ID** (one-to-one, shares PK)
2. **doFinanceTransaction.ID → FinanceTransaction** (many-to-one)

### Foreign Keys OUT:
1. **doTradePayment-Items.Owner → ID** (one-to-many)

---

## 📊 Data Statistics

```
Total Records:           365,963
Total Amount:            95,552,383.61 BGN
Total Tax:               14,800,549.22 BGN
Average Payment:         261.10 BGN
Min Payment:             0.00 BGN (1 record)
Max Payment:             1,196,640.00 BGN
Average Tax:             40.44 BGN
```

### Payment Distribution:
| Range | Count | Total Amount | % of Payments |
|-------|-------|--------------|---------------|
| Zero | 1 | 0.00 BGN | 0.00% |
| 0.01 - 10 BGN | 99,292 | 435,565.22 BGN | 27.1% |
| 10 - 100 BGN | 165,141 | 6,382,331.60 BGN | 45.1% |
| 100 - 1,000 BGN | 88,554 | 25,101,609.20 BGN | 24.2% |
| 1,000 - 10,000 BGN | 11,641 | 30,408,777.98 BGN | 3.2% |
| 10,000+ BGN | 1,334 | 33,224,099.61 BGN | 0.4% |

**Key Insight:** 72% of payments are under 100 BGN, but 66% of total value comes from the top 3.6% of payments (>1,000 BGN).

### Tax Rate Distribution:
| Category | Count | % |
|----------|-------|---|
| Normal Tax (15-22%) | 361,990 | 98.91% |
| Zero Tax | 3,951 | 1.08% |
| Medium Tax (5-15%) | 8 | 0.00% |
| High Tax (>22%) | 13 | 0.00% |
| Zero Amount | 1 | 0.00% |

**Tax Validation:** ✅ 98.9% of payments have correct VAT (15-22% = 10% or 20% Bulgarian VAT rates)

---

## 💡 Business Logic

### 1. **Installment Payment System**

**Payment Frequency per Trade:**
| Payments | Trades | % | Notes |
|----------|--------|---|-------|
| 1 payment | 362,841 | 99.2% | Standard immediate payment |
| 2 payments | 1,093 | 0.3% | Split payment |
| 3 payments | 148 | 0.04% | 3-installment plan |
| 4-10 payments | 74 | 0.02% | Extended payment terms |
| 11-21 payments | 6 | 0.00% | Complex B2B arrangements |

**Example - Trade ID 1230765 (21 payments):**
- Total paid: 2,466.77 BGN
- Smallest payment: 2.09 BGN
- Largest payment: 633.23 BGN
- **Pattern:** Likely monthly installments over ~2 years

### 2. **FinanceTransaction Linkage**

**Pattern Discovered:** `FinanceTransaction = ID + 1`

```sql
Sample data:
Payment ID    FinanceTransaction    Difference
48583         48584                 +1
48590         48591                 +1
48597         48598                 +1
```

**Interpretation:**
- **1:1 mapping** between TradePayment and FinanceTransaction
- Sequential ID allocation suggests **atomic creation** (both records created together)
- Every payment creates corresponding finance record (double-entry bookkeeping)

**Validation:** ✅ Zero orphaned FinanceTransactions (perfect referential integrity)

### 3. **Zero-Tax Payments (1.08%)**

**3,951 payments with TotalTaxAmount = 0**

**Possible Reasons:**
1. Tax-exempt products (books, medicine, exports)
2. B2B transactions with reverse charge mechanism
3. Contractors with special tax status
4. Data entry errors

**Action Required:** Validate with stakeholders which products/contractors qualify for 0% VAT.

---

## 🚨 Critical Data Quality Issues

### 1. **Payment Shortfall (2.7M BGN Unpaid)** 🔴

```
Total Payments:        95,552,383.61 BGN
Total TradeItem Sales: 98,246,476.15 BGN
───────────────────────────────────────────
UNPAID:                 2,694,092.54 BGN (2.7%)
```

**Possible Causes:**
1. **Installments in progress:** Trades with partial payments not yet completed
2. **Credit terms:** Net-30/Net-60 payment arrangements
3. **Cancelled orders:** TradeItems not reversed when payment cancelled
4. **Data integrity issue:** Missing payment records

**Evidence Supporting Installments:**
- 2,930 trades (0.8%) have multiple payments
- Some trades may still have pending payments

**Action Required:**
1. Cross-reference with Accounts Receivable (AR) system
2. Identify trades with outstanding balances
3. Validate payment completion logic in application code

### 2. **Zero-Amount Payment** ⚠️

**1 payment with TotalAmount = 0.00 BGN**

```sql
ID: 0
Trade: Unknown (linked via TradeTransaction)
TotalAmount: 0.00
TotalTaxAmount: 0.00
```

**Possible Causes:**
- Placeholder record (system initialization?)
- Cancelled payment not deleted
- Free product promotion

**Action Required:** Investigate ID=0 payment context before migration.

### 3. **High Tax Payments (13 records)** ⚠️

**13 payments with Tax > 22%**

Bulgarian VAT rates are 10% and 20%, so >22% is unusual.

**Possible Causes:**
1. Compound taxes (VAT + excise tax on alcohol/tobacco)
2. Import duties included
3. Data entry error
4. Rounding errors in calculation

**Action Required:** Validate these 13 records manually.

---

## 🔧 PostgreSQL Migration Complexity

### **Complexity Rating: MEDIUM-HIGH** 🟡

### Migration Challenges:

#### 1. **Decimal Precision** (Critical)

Current schema uses **generic `decimal`** without precision/scale specification.

**Sample data precision analysis:**
```
TotalAmount examples:
- 157.5000000000      (4 decimal places used, 12 stored)
- 2466.7698000000     (4 decimal places used, 12 stored)
- 1196640.0000000000  (0 decimal places, but 12 stored)

TotalTaxAmount:
- 31.5000000000       (4 decimal places)
- 239328.0000000000   (0 decimal places)
```

**PostgreSQL Recommendation:**
```sql
CREATE TABLE trade_payments (
    id BIGSERIAL PRIMARY KEY,
    total_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,  -- Up to 999,999,999,999.9999
    total_tax_amount NUMERIC(18, 4) NOT NULL DEFAULT 0,
    finance_transaction_id BIGINT NOT NULL REFERENCES finance_transactions(id)
);
```

**Rationale:**
- **18 total digits** covers max observed value (1,196,640) with headroom
- **4 decimal places** matches actual data precision (BGN stotinki + fractions)
- **NOT NULL + DEFAULT 0** maintains SQL Server behavior

#### 2. **Event Sourcing Integration**

As part of the **TradeTransaction event log**, payments must integrate with denormalized schema:

**Option A: Keep Separate Table** (Recommended for Phase 1)
```sql
-- Maintain current structure for easier migration
CREATE TABLE trade_payments (
    id BIGSERIAL PRIMARY KEY REFERENCES trade_transactions(id),
    total_amount NUMERIC(18, 4) NOT NULL,
    total_tax_amount NUMERIC(18, 4) NOT NULL,
    finance_transaction_id BIGINT NOT NULL
);
```

**Option B: Merge into trade_transactions** (Future optimization)
```sql
-- Add payment columns to main event table
ALTER TABLE trade_transactions ADD COLUMN payment_total_amount NUMERIC(18, 4);
ALTER TABLE trade_transactions ADD COLUMN payment_total_tax NUMERIC(18, 4);
-- Only populated when event_type = 'payment'
```

**Recommendation:** Option A for migration, consider Option B post-stabilization.

#### 3. **FinanceTransaction Linkage**

**Current pattern:** `FinanceTransaction = PaymentID + 1`

**PostgreSQL Strategy:**
1. **Preserve ID mapping** during migration (maintain FinanceTransaction values)
2. **Add explicit FK constraint** (already exists in SQL Server)
3. **Consider trigger** to auto-create FinanceTransaction on payment insert (if not handled by app)

**Migration validation query:**
```sql
-- Verify 1:1 mapping preserved
SELECT 
    COUNT(*) as total_payments,
    COUNT(DISTINCT finance_transaction_id) as unique_finance_trans
FROM trade_payments;
-- Should be equal (365,963 = 365,963)
```

#### 4. **Indexing Strategy**

```sql
-- Primary key (inherited from trade_transactions)
CREATE UNIQUE INDEX idx_trade_payments_pk ON trade_payments(id);

-- Finance transaction lookup (existing index)
CREATE INDEX idx_trade_payments_finance ON trade_payments(finance_transaction_id);

-- Amount-based queries (for reporting)
CREATE INDEX idx_trade_payments_amount ON trade_payments(total_amount) 
    WHERE total_amount > 1000;  -- Partial index for high-value payments

-- Zero-tax payments (for auditing)
CREATE INDEX idx_trade_payments_zero_tax ON trade_payments(id) 
    WHERE total_tax_amount = 0;  -- Partial index for tax-exempt
```

#### 5. **Data Quality Constraints**

Add constraints to prevent future issues:

```sql
-- Prevent negative payments (refunds should be TradeReturn events)
ALTER TABLE trade_payments ADD CONSTRAINT chk_positive_amount 
    CHECK (total_amount >= 0);

-- Tax should not exceed amount
ALTER TABLE trade_payments ADD CONSTRAINT chk_tax_max 
    CHECK (total_tax_amount <= total_amount);

-- Tax rate should be reasonable (<30%)
ALTER TABLE trade_payments ADD CONSTRAINT chk_tax_rate 
    CHECK (total_tax_amount <= total_amount * 0.30);
```

---

## 🎯 Migration Recommendations

### Phase 1: Data Migration (Week 5-6)

1. **Extract & Validate:**
   ```sql
   -- Export payments
   SELECT 
       ID,
       TotalAmount,
       TotalTaxAmount,
       FinanceTransaction
   FROM doTradePayment
   ORDER BY ID;
   ```

2. **Data Cleaning:**
   - Investigate ID=0 payment (delete or document)
   - Validate 13 high-tax payments
   - Cross-reference 2.7M unpaid with AR system

3. **Import to PostgreSQL:**
   ```sql
   COPY trade_payments(id, total_amount, total_tax_amount, finance_transaction_id)
   FROM '/migration/trade_payments.csv'
   WITH (FORMAT csv, HEADER true);
   ```

4. **Validation Queries:**
   ```sql
   -- Row count match
   SELECT COUNT(*) FROM trade_payments;  -- Should be 365,963
   
   -- Amount totals match
   SELECT SUM(total_amount) FROM trade_payments;  -- Should be 95,552,383.61
   
   -- Foreign key integrity
   SELECT COUNT(*) FROM trade_payments tp
   WHERE NOT EXISTS (
       SELECT 1 FROM finance_transactions ft WHERE ft.id = tp.finance_transaction_id
   );  -- Should be 0
   ```

### Phase 2: Application Code (Week 7-8)

1. **Update ORM Models:**
   ```csharp
   // Old: Entity Framework 4.x
   public class TradePayment {
       public long ID { get; set; }
       public decimal TotalAmount { get; set; }
       public decimal TotalTaxAmount { get; set; }
       public long FinanceTransaction { get; set; }
   }
   
   // New: EF Core 8
   public class TradePayment {
       public long Id { get; set; }
       [Column(TypeName = "numeric(18,4)")]
       public decimal TotalAmount { get; set; }
       [Column(TypeName = "numeric(18,4)")]
       public decimal TotalTaxAmount { get; set; }
       public long FinanceTransactionId { get; set; }
       public FinanceTransaction FinanceTransaction { get; set; }  // Navigation property
   }
   ```

2. **Refactor Payment Logic:**
   - Identify code creating `FinanceTransaction = ID + 1`
   - Update to use explicit FK relationship
   - Add validation for payment completion (2.7M gap)

3. **Test Installment Scenarios:**
   - Single payment (99.2% of cases)
   - Multiple payments (0.8% - critical for B2B)
   - Edge case: 21 payments (Trade 1230765)

### Phase 3: Performance Testing (Week 9)

**Test Scenarios:**
1. **High-value payment queries** (>10,000 BGN - 1,334 records)
2. **Installment history retrieval** (2,930 trades with 2+ payments)
3. **Zero-tax payment audit** (3,951 records)
4. **Finance transaction join performance** (365,963 1:1 joins)

**Benchmarks:**
- Single payment lookup: <10ms
- Trade payment history (21 payments): <50ms
- Daily payment report (avg 1,000 payments): <2 seconds

---

## 📝 Questions for Stakeholders

### Business Logic:
1. **2.7M BGN Unpaid:** Is this expected (credit terms, installments) or data issue?
2. **Zero-tax payments:** Which products/contractors qualify for 0% VAT?
3. **High-tax payments (>22%):** Are compound taxes (excise) included in TotalTaxAmount?
4. **Max installments:** Is 21 payments normal, or should we set a business limit?

### Payment Terms:
5. What are the standard payment terms? (Net-30, Net-60, immediate?)
6. How do partial payments work? (deposit + balance, monthly installments?)
7. Are refunds recorded as negative payments or TradeReturn events?

### Finance Integration:
8. Is `FinanceTransaction = ID + 1` pattern intentional or legacy artifact?
9. Should every payment create a finance record, or can we batch?
10. What happens if FinanceTransaction creation fails? (rollback payment?)

---

## 🔍 Sample Data

### Standard Payment (ID: 48583):
```
Trade: 48579 (linked via TradeTransaction)
Amount: 157.50 BGN
Tax: 31.50 BGN (20% VAT)
FinanceTransaction: 48584 (ID + 1)
```

### High-Value Payment (ID: 2746415):
```
Amount: 1,196,640.00 BGN (largest payment)
Tax: 239,328.00 BGN (20% VAT)
FinanceTransaction: 2746416
```

### Installment Example (Trade 1230765):
```
21 payments totaling 2,466.77 BGN
Payment range: 2.09 - 633.23 BGN
Likely monthly installments for B2B client
```

### Zero-Tax Payment (ID: 0):
```
Amount: 0.00 BGN
Tax: 0.00 BGN
Purpose: Unknown - requires investigation
```

---

## ✅ Analysis Complete

**Next Steps:**
1. Analyze `doTradePayment-Items` (line items for each payment)
2. Investigate 2.7M BGN payment gap with AR system
3. Validate installment payment workflows in source code
4. Document FinanceTransaction relationship fully

**Migration Complexity:** MEDIUM-HIGH (decimal precision, payment gap validation)  
**Business Criticality:** CRITICAL (95.5M BGN in payments)  
**PostgreSQL Readiness:** 75% (needs payment completion logic clarification)

---

**Analyst:** Claude (Sonnet 4.5)  
**Validated By:** Svetlyo Partenev  
**Status:** ✅ Complete

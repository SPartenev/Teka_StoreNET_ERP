# doInvoice-CashDesks Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо

---

## 📋 Overview

**Purpose:** Many-to-many junction table linking invoices to cash desks (payment processing terminals)  
**Table Type:** Junction/Bridge Table  
**Row Count:** 45,122 mappings  
**Migration Complexity:** 2/5 (Simple structure, large volume, business-critical)

**Business Logic:**
- Tracks which cash desk(s) processed each invoice payment
- Enables split payments across multiple cash desks
- Critical for cash reconciliation and audit trails
- Links financial documents (invoices) to physical payment terminals

---

## 🗂️ Schema

### Columns (2 total):

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID-1 | bigint | NOT NULL | 0 | Foreign key to doInvoice.ID (invoice reference) |
| ID-2 | bigint | NOT NULL | 0 | Foreign key to doCashDesk.ID (cash desk reference) |

**Key Observations:**
- Pure junction table with only foreign keys (no additional attributes)
- Composite primary key implied (ID-1, ID-2)
- No timestamps, no payment amounts - mapping only
- Table name uses hyphen syntax (requires bracket notation in SQL)
- **Critical Missing Data:** No payment amount per cash desk (important for split payments!)

**Design Pattern:**
Classic many-to-many relationship resolver - minimal attributes, focused on linking entities.

---

## 🔗 Relationships

### Foreign Keys (Outgoing):
- `ID-1` → `doInvoice.ID` - References the invoice/financial document
- `ID-2` → `doCashDesk.ID` - References the cash desk/payment terminal

### Foreign Keys (Incoming):
**None** - Leaf table, no child dependencies

**Relationship Type:** Many-to-Many Junction Table
```
doInvoice (1) ←→ (N) doInvoice-CashDesks (N) ←→ (1) doCashDesk
```

**Business Flow:**
```
Customer Purchase → Invoice Generated → Payment at Cash Desk(s) → Mapping Created
```

---

## 📊 Data Analysis

### Total Records: 45,122 mappings

### Cardinality Statistics:
| Metric | Value | Insight |
|--------|-------|---------|
| **Unique Invoices** | 42,848 | ~95% of invoices use single cash desk |
| **Unique Cash Desks** | 21 | Only 21 cash desks process invoice payments |
| **Total Mappings** | 45,122 | 2,274 extra mappings = split payments |
| **Split Payment Invoices** | 2,172 | 5.07% of invoices use multiple cash desks |
| **Max Cash Desks per Invoice** | 5 | Most complex split payment scenario |
| **Max Invoices per Cash Desk** | 22,654 | Busiest cash desk (86373) |

### Split Payment Analysis:
- **Single Cash Desk:** 40,676 invoices (94.93%)
- **Multiple Cash Desks:** 2,172 invoices (5.07%)
  - 2 cash desks: ~2,100 invoices
  - 3+ cash desks: ~72 invoices
  - 5 cash desks (max): rare but supported

**Interpretation:** 
System primarily uses 1:1 invoice-to-cash desk mapping, but **supports complex split payments** where customers pay at multiple terminals (installments, partial payments, or multi-department purchases).

### Distribution Analysis:

**Top 10 Cash Desks by Invoice Volume:**
| Rank | CashDesk ID | Invoice Count | % of Total | Business Type |
|------|-------------|---------------|------------|---------------|
| 1 | 86373 | 22,654 | 50.21% | **Dominant terminal** - main store checkout |
| 2 | 86379 | 9,978 | 22.11% | Major secondary terminal |
| 3 | 2231216 | 3,780 | 8.38% | High-volume terminal |
| 4 | 1189989 | 2,068 | 4.58% | Medium-volume |
| 5 | 86281 | 1,538 | 3.41% | Medium-volume |
| 6 | 86376 | 902 | 2.00% | Standard terminal |
| 7 | 1940930 | 859 | 1.90% | Standard terminal |
| 8 | 210278 | 688 | 1.52% | Low-volume |
| 9 | 99572 | 481 | 1.07% | Low-volume |
| 10 | 86264 | 429 | 0.95% | Low-volume |
| **Total Top 10** | **43,377** | **96.13%** | **Top 10 handle 96% of all invoices** |

**Concentration Risk:**
- **Top 2 cash desks** handle **72.32%** of all invoice payments
- **Cash Desk 86373 alone** processes **half of all invoices** (50.21%)
- If CashDesk 86373 fails → 50% of invoice processing capacity lost

### ID Range Analysis:
| Range | Min ID | Max ID | Span |
|-------|--------|--------|------|
| Invoices | 48,585 | 3,488,826 | ~3.44M |
| Cash Desks | 48,506 | 2,231,216 | ~2.18M |

**Observation:** Invoice IDs reach 3.4M+ (high transaction volume system).

### Sample Data Patterns:
```
Invoice 3488826 → CashDesk 86381 (recent transaction)
Invoice 3487715 → CashDesk 86373 (dominant terminal)
Invoice 3487312 → CashDesk 86379 (secondary terminal)

Multiple recent invoices → CashDesk 86373 (high activity terminal)
```

---

## 🏗️ Architecture Pattern

### Purpose in System:
**Payment Processing Tracker** - Links financial documents to physical payment terminals for reconciliation and audit.

**Business Rules Implied:**
1. **Split Payments:** Invoice can be paid at multiple cash desks (5.07% of cases)
2. **Cash Desk Specialization:** 21 cash desks are designated for invoice processing (subset of 158 total)
3. **Audit Trail:** Every invoice payment must be linked to physical terminal
4. **Reconciliation:** Enables daily cash desk balancing against invoice totals

**Use Cases:**
- **Split Payment Scenarios:**
  - Partial payment at time of sale, remainder later
  - Multi-department purchases (e.g., hardware + lumber paid separately)
  - Installment payments over time
  - Customer pays partially with cash, partially with card at different terminals
  
- **Audit & Compliance:**
  - Track which employee/terminal processed which invoice
  - Daily cash desk reconciliation reports
  - Fraud detection (unusual terminal-invoice patterns)
  - VAT/tax reporting by terminal location

**Critical Missing Feature:**
⚠️ **No payment amount per cash desk!** 
- For split payments, system doesn't store "how much was paid at each terminal"
- Must calculate from related payment tables (likely doCashDesk-Entries)
- Risk: Reconciliation complexity for multi-terminal payments

---

## 🔄 PostgreSQL Migration

### Complexity: 2/5 (Low-Medium Complexity)

**Why Low-Medium Complexity:**
- ✅ Simple two-column structure
- ✅ Straightforward foreign key relationships
- ⚠️ **Large dataset** (45,122 rows - needs careful migration)
- ⚠️ **Business-critical** (invoice payments - zero downtime required)
- ⚠️ Missing payment amount data (architecture limitation)
- ✅ Clean data quality (no obvious anomalies)

### Migration Strategy:

```sql
-- PostgreSQL Table Definition
CREATE TABLE invoice_cashdesks (
    invoice_id BIGINT NOT NULL,
    cashdesk_id BIGINT NOT NULL,
    
    -- Consider adding missing business fields
    payment_amount NUMERIC(15,2), -- Amount paid at this cash desk
    payment_sequence INT, -- Order for split payments (1st, 2nd, etc.)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(100),
    
    -- Composite Primary Key
    PRIMARY KEY (invoice_id, cashdesk_id),
    
    -- Foreign Keys
    CONSTRAINT fk_invoice_cashdesks_invoice 
        FOREIGN KEY (invoice_id) 
        REFERENCES invoices(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT fk_invoice_cashdesks_cashdesk 
        FOREIGN KEY (cashdesk_id) 
        REFERENCES cash_desks(id) 
        ON DELETE RESTRICT -- Don't allow deleting cash desk with invoice history
);

-- Indexes for efficient queries
CREATE INDEX idx_invoice_cashdesks_invoice 
    ON invoice_cashdesks(invoice_id);
    
CREATE INDEX idx_invoice_cashdesks_cashdesk 
    ON invoice_cashdesks(cashdesk_id);

-- Index for split payment queries
CREATE INDEX idx_invoice_cashdesks_multi 
    ON invoice_cashdesks(invoice_id) 
    WHERE invoice_id IN (
        SELECT invoice_id FROM invoice_cashdesks GROUP BY invoice_id HAVING COUNT(*) > 1
    );

-- Comments for documentation
COMMENT ON TABLE invoice_cashdesks IS 
    'Junction table mapping invoices to cash desks that processed payments';
COMMENT ON COLUMN invoice_cashdesks.invoice_id IS 
    'Reference to invoices.id';
COMMENT ON COLUMN invoice_cashdesks.cashdesk_id IS 
    'Reference to cash_desks.id - which terminal processed payment';
COMMENT ON COLUMN invoice_cashdesks.payment_amount IS 
    'Amount paid at this specific cash desk (for split payments) - OPTIONAL ENHANCEMENT';
COMMENT ON COLUMN invoice_cashdesks.payment_sequence IS 
    'Order of payment for split scenarios (1=first payment, 2=second, etc.) - OPTIONAL ENHANCEMENT';
```

### Data Migration Script:
```sql
-- Phase 1: Migrate existing mappings (no data loss)
INSERT INTO invoice_cashdesks (invoice_id, cashdesk_id, created_at)
SELECT 
    [ID-1] AS invoice_id,
    [ID-2] AS cashdesk_id,
    CURRENT_TIMESTAMP -- No creation date in source, use migration time
FROM [TEKA].[dbo].[doInvoice-CashDesks];

-- Verify count
-- Expected: 45,122 rows

-- Phase 2: Optionally populate payment_amount from doCashDesk-Entries
-- (requires joining with payment entry tables - separate analysis needed)

-- Phase 3: Calculate payment_sequence for split payments
WITH split_invoices AS (
    SELECT invoice_id, cashdesk_id,
           ROW_NUMBER() OVER (PARTITION BY invoice_id ORDER BY cashdesk_id) as seq
    FROM invoice_cashdesks
    WHERE invoice_id IN (
        SELECT invoice_id FROM invoice_cashdesks GROUP BY invoice_id HAVING COUNT(*) > 1
    )
)
UPDATE invoice_cashdesks ic
SET payment_sequence = si.seq
FROM split_invoices si
WHERE ic.invoice_id = si.invoice_id 
  AND ic.cashdesk_id = si.cashdesk_id;
```

### Schema Changes:
- [x] Rename table: `doInvoice-CashDesks` → `invoice_cashdesks` (PostgreSQL naming)
- [x] Rename columns: `ID-1` → `invoice_id`, `ID-2` → `cashdesk_id` (descriptive names)
- [x] Add composite primary key constraint
- [x] Add foreign key constraints (CASCADE on invoice, RESTRICT on cashdesk)
- [x] Add indexes on both columns + special index for split payments
- [x] **Optional Enhancement:** Add payment_amount and payment_sequence columns
- [x] Add created_at, created_by for audit trail
- [x] No data type conversions needed (bigint → BIGINT)

### Validation Queries:
```sql
-- Count verification
SELECT COUNT(*) FROM invoice_cashdesks; 
-- Expected: 45,122

-- Referential integrity check
SELECT COUNT(*) FROM invoice_cashdesks ic
LEFT JOIN invoices i ON ic.invoice_id = i.id
WHERE i.id IS NULL;
-- Expected: 0 (all invoices exist)

SELECT COUNT(*) FROM invoice_cashdesks ic
LEFT JOIN cash_desks cd ON ic.cashdesk_id = cd.id
WHERE cd.id IS NULL;
-- Expected: 0 (all cash desks exist)

-- Cardinality verification
SELECT 
    COUNT(DISTINCT invoice_id) AS unique_invoices,
    COUNT(DISTINCT cashdesk_id) AS unique_cashdesks,
    COUNT(*) AS total_mappings
FROM invoice_cashdesks;
-- Expected: 42,848 invoices, 21 cashdesks, 45,122 mappings

-- Split payment verification
SELECT COUNT(*) AS split_payment_count
FROM (
    SELECT invoice_id
    FROM invoice_cashdesks
    GROUP BY invoice_id
    HAVING COUNT(*) > 1
) sub;
-- Expected: 2,172 invoices with multiple cash desks

-- Top cash desk verification
SELECT cashdesk_id, COUNT(*) as invoice_count
FROM invoice_cashdesks
GROUP BY cashdesk_id
ORDER BY invoice_count DESC
LIMIT 1;
-- Expected: CashDesk 86373 with 22,654 invoices
```

### Performance Optimization:
```sql
-- Partition large table by year (if invoice table has date)
CREATE TABLE invoice_cashdesks_2020 PARTITION OF invoice_cashdesks
    FOR VALUES FROM ('2020-01-01') TO ('2021-01-01');
    
CREATE TABLE invoice_cashdesks_2021 PARTITION OF invoice_cashdesks
    FOR VALUES FROM ('2021-01-01') TO ('2022-01-01');
-- etc.

-- Analyze table for query optimization
ANALYZE invoice_cashdesks;
```

### Estimated Migration Time: 3-4 hours
- Schema creation: 45 minutes
- Data migration (45K rows): 30 minutes
- Index creation: 45 minutes
- Testing & validation: 60 minutes
- Documentation: 30 minutes

---

## ❓ Stakeholder Questions

### Business Logic:
1. **Split Payment Scenarios:**
   - Why do 5.07% of invoices use multiple cash desks?
   - Are these installment payments, partial payments, or multi-department sales?
   - How is payment amount split across terminals? (not tracked in table!)
   
2. **Cash Desk Specialization:**
   - Why only 21 out of 158 cash desks process invoice payments?
   - Are the other 137 cash desks used for different transaction types?
   - What determines which cash desks can process invoices?
   
3. **Concentration Risk:**
   - CashDesk 86373 handles 50% of all invoices - is this intentional?
   - What happens if this primary terminal fails?
   - Is there a backup/failover strategy?

### Payment Tracking:
4. **Missing Payment Amounts:**
   - **CRITICAL:** Table doesn't store how much was paid at each cash desk
   - For split payments, how do you reconcile amounts per terminal?
   - Is payment amount tracked in doCashDesk-Entries table instead?
   
5. **Audit Requirements:**
   - Do you need to know payment sequence (1st payment, 2nd payment, etc.)?
   - What audit reports use this junction table?
   - How often are split payments audited?

### Future State:
6. **Next.js/PostgreSQL Enhancements:**
   - Add payment_amount column to track split amounts?
   - Add payment_sequence for installment order?
   - Add created_at/created_by for audit trail?
   - Add payment_method (cash, card, mixed) field?

---

## 🚨 Migration Risks

### High Priority:
1. **Data Volume (45K+ rows):** 
   - Large dataset requires careful batch processing
   - **Mitigation:** Migrate in batches of 10K rows, verify counts after each batch
   
2. **Business Criticality:** 
   - Invoice payments are mission-critical for cash flow
   - **Mitigation:** Zero-downtime migration using read replicas, extensive testing
   
3. **Missing Payment Amounts:**
   - Split payments lack amount per terminal
   - **Mitigation:** Cross-reference with doCashDesk-Entries during migration planning

### Medium Priority:
4. **Concentration Risk:** 
   - 50% of invoices on one cash desk (86373)
   - **Mitigation:** Document business continuity plan, consider load balancing in new system
   
5. **Foreign Key Dependencies:**
   - Must migrate doInvoice and doCashDesk tables FIRST
   - **Mitigation:** Enforce strict migration order, validate FKs before junction table

### Low Priority:
6. **Table Naming:** 
   - SQL Server uses hyphens (requires brackets)
   - **Mitigation:** Use underscores in PostgreSQL (standard convention)

---

## 📝 Notes

### Key Insights:
1. **Split Payment Support:** System handles complex payment scenarios (5% split across 2-5 terminals)
2. **Extreme Centralization:** CashDesk 86373 is single point of failure (50% of invoices)
3. **Critical Architecture Gap:** No payment amount per cash desk - forces lookup in payment entries
4. **Clean Data Quality:** No NULL values, no obvious data integrity issues

### Architectural Observations:
- **Design Pattern:** Classic junction table - minimal attributes, focused on linkage
- **Performance:** 45K rows manageable but needs indexing for fast lookups
- **Scalability:** Current design scales well if more cash desks added
- **Audit Trail:** Missing created_at/created_by limits forensic analysis

### Business Intelligence Opportunities:
```sql
-- Popular split payment analysis
SELECT 
    COUNT(DISTINCT ic.invoice_id) as split_invoice_count,
    COUNT(ic.cashdesk_id) as total_cashdesk_uses,
    AVG(cashdesk_count) as avg_cashdesks_per_split
FROM invoice_cashdesks ic
JOIN (
    SELECT invoice_id, COUNT(*) as cashdesk_count
    FROM invoice_cashdesks
    GROUP BY invoice_id
    HAVING COUNT(*) > 1
) splits ON ic.invoice_id = splits.invoice_id;

-- Cash desk utilization report
SELECT 
    cd.id,
    cd.name,
    COUNT(ic.invoice_id) as invoice_count,
    RANK() OVER (ORDER BY COUNT(ic.invoice_id) DESC) as utilization_rank
FROM cash_desks cd
LEFT JOIN invoice_cashdesks ic ON cd.id = ic.cashdesk_id
GROUP BY cd.id, cd.name
ORDER BY invoice_count DESC;
```

### PostgreSQL Enhancements (Recommended):
```sql
-- Add audit trail (strongly recommended)
ALTER TABLE invoice_cashdesks 
    ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN created_by VARCHAR(100),
    ADD COLUMN notes TEXT;

-- Add split payment metadata (optional, improves usability)
ALTER TABLE invoice_cashdesks
    ADD COLUMN payment_amount NUMERIC(15,2),
    ADD COLUMN payment_sequence INT,
    ADD COLUMN payment_method VARCHAR(50); -- 'CASH', 'CARD', 'MIXED'

-- Add soft delete for historical tracking
ALTER TABLE invoice_cashdesks
    ADD COLUMN is_active BOOLEAN DEFAULT TRUE,
    ADD COLUMN deleted_at TIMESTAMP,
    ADD COLUMN deleted_by VARCHAR(100);

-- Create audit log table
CREATE TABLE invoice_cashdesks_audit (
    audit_id SERIAL PRIMARY KEY,
    action VARCHAR(10), -- 'INSERT', 'DELETE'
    invoice_id BIGINT,
    cashdesk_id BIGINT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100),
    old_values JSONB,
    new_values JSONB
);
```

### Business Context Questions:
- Are split payments installments over time or same-day multi-terminal payments?
- Why is CashDesk 86373 so dominant (main store, headquarters, or data entry artifact)?
- Is the 5% split payment rate increasing or decreasing over time?
- Do split payments correlate with invoice amount (large invoices more likely to split)?

---

## ✅ Analysis Complete

**Status:** ✅ DONE  
**Complexity:** 2/5 (Low-Medium - large volume but simple structure)  
**Migration Time Estimate:** 3-4 hours  
**Priority:** **CRITICAL** (invoice payment tracking - business essential)  
**Dependencies:** Must migrate AFTER doInvoice and doCashDesk tables  

**Data Quality:** ✅ Excellent (clean, consistent, no anomalies)  
**Business Logic:** ⚠️ Architecture Gap - missing payment amounts per terminal  
**Migration Risk:** ⚠️ Medium - large volume + business-critical, but simple structure  

**Recommendations:**
1. **Add payment_amount column** in PostgreSQL to track split payment amounts
2. **Investigate concentration risk** - CashDesk 86373 is single point of failure
3. **Add audit trail** - created_at, created_by for compliance
4. **Consider load balancing** - distribute invoice processing across more terminals

---

**Previous:** 05-doCashDesk-Stores.md  
**Next:** Continue with remaining Financial Domain tables (doStoreTransfer, etc.)

---

## 🔗 Related Tables
- **Parent Tables:** doInvoice (Documents Domain), doCashDesk (01)
- **Sibling Tables:** doCashDesk-Stores (05), doCashDesk-Entries (02)
- **Business Flow:** Invoice Created → Payment at Cash Desk(s) → Mapping Created → Cash Entries Recorded
- **Likely Related:** doCashDesk-Entries (should contain payment amounts)

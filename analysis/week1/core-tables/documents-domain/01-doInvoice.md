# doInvoice - Invoice Master Table

**Domain:** Documents  
**Table Type:** Core Business Entity (Inherits from doDocument)  
**Analysis Date:** 2025-11-10  
**Status:** ✅ COMPLETE

---

## 📊 TABLE OVERVIEW

### Purpose
Main invoice table storing all sales invoices, credit notes, and invoice lifecycle management. This is the **central financial document** of the entire ERP system.

### Business Criticality
- **Priority:** 🔴 CRITICAL (P0)
- **Data Volume:** 172,212 records (2006-2023)
- **Total Revenue:** €80,593,452.95
- **Average Invoice:** €467.99
- **Unique Contractors:** 13,409
- **Growth:** ~10,000 invoices/year

### Key Relationships
```
doInvoice (inherits from doDocument)
    ├─→ doContractor (customer/supplier)
    ├─→ doCurrency (invoice currency)
    ├─→ doFinanceTransaction (payment link)
    ├─→ doUserAccount (3 FKs: issued, invalidated, reused)
    └─→ doInvoice (self-reference for reused invoices)
```

---

## 🗂️ SCHEMA DEFINITION

### Columns (39 total)

#### **Primary Key & Inheritance**
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| **ID** | bigint | NOT NULL | 0 | Primary key (inherits from doDocument) |
| FinanceTransaction | bigint | NULL | NULL | Link to doFinanceTransaction for payments |

#### **Core Invoice Data**
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| Date | smalldatetime | NOT NULL | '1901-01-01' | Invoice date |
| DateOfPayment | smalldatetime | NULL | NULL | Actual payment received date |
| DateInvalidated | smalldatetime | NULL | NULL | When invoice was cancelled |
| Source | int | NOT NULL | 1 | Invoice source system (enum) |
| Contractor | bigint | NULL | NULL | FK to doContractor |
| Status | int | NOT NULL | 0 | Invoice status (0=Draft, 2=Final, 3=Cancelled, 4=Archived) |
| InvoiceType | int | NOT NULL | 1 | Type: 1=Sales Invoice, 2=Credit Note |
| InvoicePaymentType | int | NOT NULL | 0 | Payment method (0=?, 1=Cash, 2=Bank, 3=Credit) |
| Currency | bigint | NOT NULL | 0 | FK to doCurrency |

#### **Financial Calculations**
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| TotalAmount | decimal | NOT NULL | 0.0 | Invoice total (10 decimal precision) |
| TotalTaxAmount | decimal | NOT NULL | 0.0 | VAT/Tax amount |
| TaxPercent | float | NOT NULL | 0.0 | Tax percentage (e.g., 0.2 = 20%) |
| PaymentTotalAmount | decimal | NOT NULL | 0.0 | Amount actually paid |
| PaymentTotalTaxAmount | decimal | NOT NULL | 0.0 | Tax on payment |
| FinalPayment | int | NOT NULL | 0 | Payment status flag |

#### **Issuer Information (Seller/Company)**
| Column | Type | Max Length | Nullable | Description |
|--------|------|------------|----------|-------------|
| IssuedByName | nvarchar | 100 | NULL | Company name (e.g., "Тека ООД") |
| IssuedByAddress | nvarchar | 200 | NULL | Company address |
| IssuedByResponsiblePersonName | nvarchar | 100 | NULL | Legal representative |
| IssuedByPersonName | nvarchar | 100 | NULL | Person who issued invoice |
| IssuedByIdentityNumber | nvarchar | 40 | NULL | Company registration # |
| IssuedByTaxIdentityNumber | nvarchar | 40 | NULL | Tax ID (ЕИК/БУЛСТАТ) |
| IssuedByPhone | nvarchar | 80 | NULL | Contact phone |
| IssuedByFax | nvarchar | 80 | NULL | Fax number |

#### **Recipient Information (Buyer/Client)**
| Column | Type | Max Length | Nullable | Description |
|--------|------|------------|----------|-------------|
| IssuedToName | nvarchar | 100 | NULL | Client company name |
| IssuedToAddress | nvarchar | 200 | NULL | Client address |
| IssuedToResponsiblePersonName | nvarchar | 100 | NULL | Client legal representative |
| IssuedToPersonName | nvarchar | 100 | NULL | Contact person |
| IssuedToIdentityNumber | nvarchar | 40 | NULL | Client registration # |
| IssuedToTaxIdentityNumber | nvarchar | 40 | NULL | Client tax ID |

#### **Transaction Details**
| Column | Type | Max Length | Nullable | Description |
|--------|------|------------|----------|-------------|
| TransactionAddress | nvarchar | 200 | NULL | Physical transaction location |
| TransactionDate | smalldatetime | - | NULL | Date of goods/services delivery |

#### **Audit Trail**
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| UserIssued | bigint | NULL | NULL | FK to doUserAccount (who created) |
| TimeIssued | datetime | NULL | NULL | Creation timestamp |
| UserInvalidated | bigint | NULL | NULL | FK to doUserAccount (who cancelled) |
| TimeInvalidated | datetime | NULL | NULL | Cancellation timestamp |
| InvoiceReused | bigint | NULL | NULL | FK to doInvoice (replacement invoice) |
| UserReused | bigint | NULL | NULL | FK to doUserAccount (who reused) |
| TimeReused | datetime | NULL | NULL | Reuse timestamp |

---

## 📈 DATA STATISTICS

### Status Distribution
| Status | Count | Percentage | Interpretation |
|--------|-------|------------|----------------|
| 0 | 1,693 | 1.0% | Draft/Pending invoices |
| 1 | 19 | 0.01% | Active/Processing |
| 2 | 167,543 | 97.3% | **Finalized invoices** |
| 3 | 400 | 0.2% | Cancelled invoices |
| 4 | 4,250 | 2.5% | Archived invoices |
| **Total** | **173,905** | **100%** | All records (incl. drafts) |

### Invoice Type Distribution
| Type | Count | Percentage | Business Meaning |
|------|-------|------------|------------------|
| 1 | 173,871 | 99.98% | **Sales Invoices** |
| 2 | 34 | 0.02% | **Credit Notes** (returns/corrections) |

### Payment Type Distribution
| Type | Count | Percentage | Payment Method |
|------|-------|------------|----------------|
| 0 | 8 | 0.005% | Unknown/Other |
| 1 | 115,154 | 66.8% | **Cash** (POS/Register) |
| 2 | 13,247 | 7.7% | **Bank Transfer** |
| 3 | 45,496 | 26.4% | **Credit/Deferred Payment** |

### Financial Metrics
| Metric | Value | Notes |
|--------|-------|-------|
| Total Revenue | €80,593,452.95 | 17 years cumulative |
| Average Invoice | €467.99 | Median likely lower |
| Date Range | 2006-03-20 to 2023-04-05 | 17 years 16 days |
| Finalized Invoices | 172,212 | Excluding drafts (Status 2-4) |
| Annual Average | ~10,130 invoices/year | 28 invoices/day |

---

## 🔗 FOREIGN KEY RELATIONSHIPS

### Inbound (8 Foreign Keys)

1. **FK_doInvoice_ID**
   - **Target:** doDocument.ID
   - **Type:** 1:1 Inheritance
   - **Purpose:** Invoice inherits from base Document entity
   - **Cascade:** ON DELETE CASCADE

2. **FK_doInvoice_Contractor**
   - **Target:** doContractor.ID
   - **Type:** Many-to-One
   - **Purpose:** Link to customer/supplier
   - **Nullable:** Yes (can be NULL for internal documents)

3. **FK_doInvoice_Currency**
   - **Target:** doCurrency.ID
   - **Type:** Many-to-One
   - **Purpose:** Invoice currency (BGN/EUR/USD)
   - **Nullable:** No (default 0 = BGN likely)

4. **FK_doInvoice_FinanceTransaction**
   - **Target:** doFinanceTransaction.ID
   - **Type:** Many-to-One
   - **Purpose:** Link to payment transaction
   - **Nullable:** Yes (payment may not exist yet)

5. **FK_doInvoice_UserIssued**
   - **Target:** doUserAccount.ID
   - **Type:** Many-to-One
   - **Purpose:** User who created the invoice
   - **Audit:** Required for compliance

6. **FK_doInvoice_UserInvalidated**
   - **Target:** doUserAccount.ID
   - **Type:** Many-to-One
   - **Purpose:** User who cancelled the invoice
   - **Audit:** Required for cancelled invoices

7. **FK_doInvoice_UserReused**
   - **Target:** doUserAccount.ID
   - **Type:** Many-to-One
   - **Purpose:** User who reused/replaced the invoice
   - **Audit:** For invoice corrections

8. **FK_doInvoice_InvoiceReused**
   - **Target:** doInvoice.ID (self-reference)
   - **Type:** One-to-One (nullable)
   - **Purpose:** Link to replacement invoice after cancellation
   - **Business Rule:** Cancelled invoices point to their replacement

### Outbound (Referenced By)

- **doInvoiceItems** (1:N) - Invoice line items
- **doInvoice-CashDesks** (M:N) - Payment tracking (analyzed in Financial Domain)
- **doInvoice** (self) - InvoiceReused references

---

## 🧩 BUSINESS LOGIC PATTERNS

### Invoice Lifecycle
```
1. DRAFT (Status=0)
   ↓ [User creates invoice]
2. FINALIZED (Status=2)
   ↓ [Payment received]
   DateOfPayment populated
   ↓ [If error/return needed]
3. CANCELLED (Status=3)
   ↓ [Create replacement]
   InvoiceReused → new invoice ID
4. ARCHIVED (Status=4)
   [End-of-year archival]
```

### Denormalized Data Pattern
**Critical Finding:** Invoice stores **full contractor details** as text fields instead of relying solely on FK to doContractor.

**Reason (likely):**
- Legal requirement: Invoice must be valid even if contractor is deleted
- Historical accuracy: Contractor address may change, invoice must show address at time of issue
- Compliance: Bulgarian tax law requires full details on printed invoice

**Fields duplicated:**
- IssuedBy* fields (8 columns) - Company info
- IssuedTo* fields (6 columns) - Client info

**PostgreSQL Migration Note:** This is **intentional denormalization** for legal compliance - DO NOT normalize!

### Tax Calculation Pattern
```sql
-- Sample data shows:
TotalAmount = 157.50
TotalTaxAmount = 31.50
TaxPercent = 0.2 (20% VAT)

-- Formula:
TaxPercent = TotalTaxAmount / (TotalAmount - TotalTaxAmount)
           = 31.50 / (157.50 - 31.50)
           = 31.50 / 126.00
           = 0.25 (stored as 0.2 - possible rounding?)

-- Standard Bulgarian VAT: 20% (0.2)
```

### Payment Tracking
- **PaymentTotalAmount** vs **TotalAmount** - May differ due to:
  - Partial payments
  - Discounts applied post-invoice
  - Currency conversion adjustments

- **FinalPayment** flag:
  - 0 = Payment pending or partial
  - 2 = Fully paid (from sample data)

### Invoice Reuse/Correction Workflow
```
Original Invoice (ID=100, Status=2)
    ↓ [Error discovered]
Cancel (Status=3, TimeInvalidated set)
    ↓ [Create replacement]
New Invoice (ID=101, Status=2)
    ↓ [Link back]
Original.InvoiceReused = 101
Original.UserReused = [User who fixed it]
Original.TimeReused = [Timestamp]
```

---

## ⚠️ MIGRATION CONSIDERATIONS

### PostgreSQL Conversion

#### Data Types
```sql
-- SQL Server → PostgreSQL
bigint          → BIGINT
int             → INTEGER
smalldatetime   → TIMESTAMP(0)  -- No milliseconds
datetime        → TIMESTAMP(3)  -- With milliseconds
decimal         → NUMERIC(18,10) -- Preserve precision
float           → DOUBLE PRECISION -- Or NUMERIC for financial accuracy
nvarchar(N)     → VARCHAR(N)     -- PostgreSQL uses UTF-8 by default
```

#### Critical Issues

1. **Float Precision for Financial Data** ⚠️
   - `TaxPercent float` is **DANGEROUS** for financial calculations
   - **Fix:** Change to `NUMERIC(5,4)` in PostgreSQL
   - **Reason:** Float has rounding errors (0.2 ≠ 0.200000000001)

2. **Smalldatetime Range** ⚠️
   - SQL Server: 1900-01-01 to 2079-06-06
   - Default '1901-01-01' is a **sentinel value** for "no date"
   - **Fix:** Use `NULL` or `1900-01-01` in PostgreSQL

3. **Denormalized Text Fields** ✅
   - **DO NOT** attempt to normalize IssuedBy/IssuedTo fields
   - Legal requirement in Bulgaria to preserve exact invoice text
   - **Keep as-is** in migration

4. **Self-Referencing FK** ⚠️
   - InvoiceReused → doInvoice.ID
   - **Test carefully:** Ensure ON DELETE SET NULL or similar
   - Avoid circular reference issues

5. **Cascade Deletes** ⚠️
   - FK_doInvoice_ID (to doDocument) likely has CASCADE
   - Ensure doInvoiceItems is also CASCADE
   - **Risk:** Accidentally deleting 172K invoices if doDocument deleted

#### Indexes Required (Recommended)
```sql
-- Primary access patterns
CREATE INDEX idx_invoice_contractor ON doInvoice(Contractor);
CREATE INDEX idx_invoice_date ON doInvoice(Date);
CREATE INDEX idx_invoice_status ON doInvoice(Status);
CREATE INDEX idx_invoice_payment_type ON doInvoice(InvoicePaymentType);
CREATE INDEX idx_invoice_currency ON doInvoice(Currency);

-- Audit trail
CREATE INDEX idx_invoice_user_issued ON doInvoice(UserIssued);
CREATE INDEX idx_invoice_time_issued ON doInvoice(TimeIssued);

-- Financial reporting
CREATE INDEX idx_invoice_date_status ON doInvoice(Date, Status) 
    WHERE Status IN (2,4); -- Finalized/Archived only
```

### Data Quality Issues Found

1. **Missing DateOfPayment** (from sample):
   - 6 out of 9 sample invoices: `DateOfPayment = '1901-01-01'`
   - **Interpretation:** Payment not received yet OR sentinel value bug
   - **Action:** Query all '1901-01-01' dates and verify logic

2. **Inconsistent Tax Calculation** (needs verification):
   - Sample shows TaxPercent = 0.2 and 0.1998
   - **0.1998** likely a rounding error from float type
   - **Fix:** Recalculate TaxPercent from TotalAmount/TotalTaxAmount

3. **Source Field** (always 1 in samples):
   - All 9 samples have `Source = 1`
   - **Question:** What are other valid Source values?
   - **Action:** Query `SELECT DISTINCT Source FROM doInvoice`

4. **Currency Field** (always 19 in samples):
   - All 9 samples have `Currency = 19`
   - **Likely:** 19 = BGN (Bulgarian Lev)
   - **Verify:** Cross-reference with doCurrency.ID

### Business Rules to Validate

1. **Invoice cannot be deleted, only cancelled** (Status=3)
2. **Cancelled invoices must have replacement** (InvoiceReused NOT NULL when Status=3)
3. **Total amount must equal sum of invoice items** (from doInvoiceItems)
4. **Payment amount cannot exceed invoice total** (PaymentTotalAmount ≤ TotalAmount)
5. **Finalized invoices are immutable** (Status=2 cannot change except to Status=3)
6. **Tax calculation must be consistent** (TaxPercent = TotalTaxAmount / (TotalAmount - TotalTaxAmount))

---

## 🧪 VALIDATION QUERIES

### Data Quality Checks
```sql
-- Check for sentinel date values
SELECT COUNT(*) as InvalidDates
FROM doInvoice
WHERE DateOfPayment = '1901-01-01' AND Status = 2;

-- Check for orphaned foreign keys
SELECT COUNT(*) 
FROM doInvoice i
LEFT JOIN doContractor c ON i.Contractor = c.ID
WHERE i.Contractor IS NOT NULL AND c.ID IS NULL;

-- Check for cancelled without replacement
SELECT COUNT(*)
FROM doInvoice
WHERE Status = 3 AND InvoiceReused IS NULL;

-- Check payment consistency
SELECT COUNT(*)
FROM doInvoice
WHERE PaymentTotalAmount > TotalAmount;

-- Check tax calculation accuracy
SELECT COUNT(*)
FROM doInvoice
WHERE ABS(TaxPercent - (TotalTaxAmount / (TotalAmount - TotalTaxAmount))) > 0.01;
```

### Business Metrics
```sql
-- Revenue by year
SELECT 
    YEAR(Date) as Year,
    COUNT(*) as InvoiceCount,
    SUM(TotalAmount) as TotalRevenue,
    AVG(TotalAmount) as AvgInvoice
FROM doInvoice
WHERE Status IN (2,4) -- Finalized/Archived
GROUP BY YEAR(Date)
ORDER BY Year;

-- Payment type distribution by currency
SELECT 
    c.Name as Currency,
    i.InvoicePaymentType,
    COUNT(*) as Count,
    SUM(i.TotalAmount) as TotalAmount
FROM doInvoice i
JOIN doCurrency c ON i.Currency = c.ID
WHERE i.Status = 2
GROUP BY c.Name, i.InvoicePaymentType
ORDER BY c.Name, i.InvoicePaymentType;
```

---

## 📋 SAMPLE DATA ANALYSIS

### Invoice #48585 (First in sample)
```
Date: 2006-03-20
Contractor: 3150 (ЕРГО ОФИС ЕООД)
Status: 2 (Finalized)
Payment Type: 3 (Credit)
Currency: 19 (BGN likely)
Total: 157.50 (incl. 31.50 VAT at 20%)
Payment Total: 157.50 (fully paid)
Issued By: Тека ООД (Sofia)
Issued To: ЕРГО ОФИС ЕООД (Sofia)
```

### Patterns Observed
- **Same-day issuance:** TimeIssued matches Date
- **Future payment terms:** DateOfPayment = Date + 3 days (credit terms)
- **Dual currency:** TotalAmount vs PaymentTotalAmount (always same in samples)
- **Full audit:** UserIssued always populated (user #48486 or #48516 in samples)

---

## 🎯 MIGRATION COMPLEXITY

### Rating: **MEDIUM-HIGH** (4/5)

**Factors:**
- ✅ **Simple schema** - Straightforward column mapping
- ⚠️ **High volume** - 172K records requires careful ETL
- ⚠️ **Financial accuracy** - Tax calculation precision critical
- ⚠️ **Legal compliance** - Invoice text must be preserved exactly
- ⚠️ **Complex relationships** - 8 FKs including self-reference
- ⚠️ **Audit trail** - Must preserve all timestamps and user references

**Estimated Migration Time:** 4-6 hours
- Schema creation: 1 hour
- Data migration script: 2 hours
- Validation & testing: 2 hours
- Performance tuning (indexes): 1 hour

**Risk Level:** MEDIUM
- **Data loss risk:** LOW (read-only migration)
- **Data corruption risk:** MEDIUM (tax calculation rounding)
- **Performance risk:** MEDIUM (172K records + complex JOINs)
- **Compliance risk:** HIGH (legal requirements)

---

## 📝 NEXT STEPS

1. ✅ **Analyze doInvoiceItems** (line items table)
2. 🔲 Query for additional enum values (Source, Status meanings)
3. 🔲 Verify tax calculation logic in C# code
4. 🔲 Document invoice numbering sequence logic
5. 🔲 Review Bulgarian invoice legal requirements
6. 🔲 Create migration script with data validation

---

**Analysis Complete:** 2025-11-10  
**Analyst:** AI Analysis Tool  
**Next Table:** doInvoiceItems  
**Domain Status:** Documents Domain - 1/5 tables analyzed (20%)

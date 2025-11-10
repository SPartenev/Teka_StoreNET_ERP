# PaymentTypes Enum - Raw Query Results

**Date:** 2025-11-08  
**Status:** Data collected, analysis pending

---

## Query 1: doInvoice.InvoicePaymentType Distribution

```
PaymentTypeCode | UsageCount | PercentageOfTotal
----------------|------------|------------------
1               | 115,154    | 66.22%
3               | 45,496     | 26.16%
2               | 13,247     | 7.62%
0               | 8          | 0.00%
```

**Total Records:** 173,905 invoices

**Observations:**
- Type 1 (66%) = Dominant payment type
- Type 3 (26%) = Second most common
- Type 2 (8%) = Rare
- Type 0 (<0.01%) = Almost never used (only 8 records!)

---

## Query 2: doTrade.PaymentType Distribution

```
PaymentTypeCode | UsageCount | PercentageOfTotal
----------------|------------|------------------
1               | 337,807    | 92.35%
4               | 24,536     | 6.71%
2               | 3,303      | 0.90%
3               | 125        | 0.03%
```

**Total Records:** 365,771 trade documents

**Observations:**
- Type 1 (92%) = OVERWHELMINGLY dominant
- Type 4 (7%) = Second option (only exists in doTrade!)
- Type 2 (1%) = Rarely used
- Type 3 (<0.1%) = Almost never
- **Type 0 missing** = Not used in Trade

---

## Query 3: System Settings

```
SalePaymentType:   1
SupplyPaymentType: 0
```

**Observation:** Defaults are Type 1 for sales, Type 0 for supplies

---

## Query 4: All PaymentType Columns in Database

```
TABLE_NAME              | COLUMN_NAME              | DATA_TYPE
------------------------|--------------------------|----------
doInvoice               | InvoicePaymentType       | int
doInvoice-View          | InvoicePaymentType       | int
doSystemSettings        | SalePaymentType          | int
doSystemSettings        | SupplyPaymentType        | int
doSystemSettings-View   | SalePaymentType          | int
doSystemSettings-View   | SupplyPaymentType        | int
doTrade                 | PaymentType              | int
doTrade-View            | PaymentType              | int
```

**Observations:**
- 8 columns total (4 real tables + 4 views)
- All are `int` type (no enum constraint in DB)
- Naming inconsistency: `InvoicePaymentType` vs `PaymentType`

---

## Query 5: Sample Invoice Records (Failed - Column Names Changed)

**Error:** Invalid column names 'InvoiceNo', 'CreationTime'

**Actual Sample Data Retrieved (TOP 5 by ID desc):**

### Record 1: ID 3488826
- Code: 3213826
- Date: 2022-04-29
- **PaymentType: 1**
- Total: 2,194.41 BGN
- Supplier: SC WWS Technology Trade SRL (Romania)
- Client: Тека ООД

### Record 2: ID 3488722
- Code: 3488721
- Date: 2021-03-01
- **PaymentType: 1**
- Total: 245.59 BGN + 49.12 VAT
- Supplier: 912 ООД (София)
- Client: Тека ООД

### Record 3: ID 3487725
- Code: 2091066
- Date: 2020-01-07
- **PaymentType: 1**
- Total: 1,834.50 BGN + 366.90 VAT
- Supplier: Арт Дизайн Р ООД
- Client: ТЕКА ООД

### Record 4: ID 3487715
- Code: 3487714
- Date: 2019-11-29
- **PaymentType: 1**
- Total: 247.46 BGN + 49.49 VAT
- Supplier: ТАШЕВ-ГАЛВИНГ ООД
- Client: Тека ООД
- Has payment deadline (2019-12-29)

### Record 5: ID 3487668
- Code: 3487667
- Date: 2019-12-30
- **PaymentType: 1**
- Total: 391.73 BGN + 78.35 VAT
- Supplier: Биасо ООД
- Client: Тека ООД

**Pattern:** All 5 recent samples use PaymentType = 1

---

## Initial Enum Mapping Hypothesis

Based on business logic context:

```
0 = Cash / В брой (almost never used - only 8 invoices, default for supplies)
1 = Bank Transfer / По банка (dominant - 66% invoices, 92% trade, default for sales)
2 = Debit/Credit Card / С карта (7-8%)
3 = Payment Order / Платежно нареждане (26% invoices, <1% trade)
4 = Unknown / Other (only in doTrade - 7%)
```

**CRITICAL:** Need to verify from .NET code (enums defined in .cs files)

---

## Next Steps

1. Search for `PaymentType` enum definition in C# code
2. Verify enum value meanings
3. Check business rules around payment type selection
4. Analyze relationship with CashDesks (Type 0/2 → Cash registers?)
5. Document migration strategy (normalize to lookup table?)

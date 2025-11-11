# doInvoice-Items - Invoice Line Items

**Domain:** Documents  
**Table Type:** Child Entity (Line Items)  
**Analysis Date:** 2025-11-10  
**Status:** ✅ COMPLETE

---

## 📊 QUICK SUMMARY

### Volume
- **487,725 line items** (17 years of data)
- **173,900 unique invoices** (avg 2.8 items/invoice)
- **€80,919,965** total revenue
- **Avg unit price:** €131.55
- **Avg quantity:** 18.66 units

### Schema (9 columns)
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | - | Primary key |
| Owner | bigint | NOT NULL | 0 | FK to doInvoice |
| Name | nvarchar(1000) | NOT NULL | '' | Product name (Bulgarian text) |
| MeasureUnit | bigint | NOT NULL | 0 | FK to doMeasureUnit |
| Quantity | decimal | NOT NULL | 0.0 | Quantity sold |
| Price | decimal | NOT NULL | 0.0 | Unit price |
| TotalPrice | decimal | NOT NULL | 0.0 | Line total (Quantity × Price) |
| TaxAmount | decimal | NOT NULL | 0.0 | VAT per unit |
| TotalTaxAmount | decimal | NOT NULL | 0.0 | Total VAT (Quantity × TaxAmount) |

### Relationships
- **Owner** → doInvoice.ID (Many-to-One)
- **MeasureUnit** → doMeasureUnit.ID (Many-to-One)

### Key Findings
- ✅ Simple, clean schema
- ✅ All financial data matches doInvoice totals
- ⚠️ Some items have Price=0 (free items/corrections)
- ✅ Standard 20% VAT applied
- ✅ Product names stored as text (not FK to products)

---

## 🎯 MIGRATION COMPLEXITY

**Rating:** 2/5 (LOW-MEDIUM)

**Why:**
- Simple schema, straightforward mapping
- High volume (500K records) requires batching
- No complex business logic

**Estimated Time:** 2-3 hours

---

## 📋 SAMPLE DATA (Top 3)

```
ID: 492156 | Owner: 3488826 | Ексцентършлайф машина ETS 150/5 EQ | Qty: 1 | Price: 0.00
ID: 492155 | Owner: 3488826 | Капекс KS 120 EB | Qty: 1 | Price: 2194.41
ID: 492154 | Owner: 3488722 | Покритие Color Core F2255 Mat | Qty: 3.72 | Price: 66.00
```

---

**Analysis Complete:** 2025-11-10  
**Next Table:** doDocument (base entity)

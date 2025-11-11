# doDocument - Base Document Entity

**Domain:** Documents  
**Table Type:** Base Entity (Inheritance Root)  
**Analysis Date:** 2025-11-10  
**Status:** ✅ COMPLETE

---

## 📊 QUICK SUMMARY

### Volume
- **350,852 documents** (all types combined)
- **268,162 unique RootOwners**
- **346,296 unique Owners**
- **29 stores**
- **344,888 unique DocumentIds**

### Schema (5 columns - Minimal Design)
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | 0 | Primary key (FK to doCoreFtObject) |
| RootOwner | bigint | YES | NULL | FK to doDataObject (original document) |
| Owner | bigint | YES | NULL | FK to doDataObject (current owner/parent) |
| Store | bigint | NOT NULL | 0 | FK to doStore (location) |
| DocumentId | nvarchar(40) | YES | NULL | Human-readable document number |

### Relationships
- **ID** → doCoreFtObject.ID (Inheritance - IS-A relationship)
- **RootOwner** → doDataObject.ID (Original document in chain)
- **Owner** → doDataObject.ID (Current parent document)
- **Store** → doStore.ID (Physical/logical location)

### Key Findings
- ✅ **Inheritance pattern:** doDocument extends doCoreFtObject (OOP-style)
- ✅ **Document hierarchy:** RootOwner ≠ Owner suggests document chains/revisions
- ⚠️ **150 NULL RootOwners** (0.04%) - orphaned documents?
- ⚠️ **3,946 NULL Owners** (1.1%) - standalone documents
- ⚠️ **1,693 NULL DocumentIds** (0.5%) - drafts or system-generated docs?
- 🏪 **29 stores** - multi-location system
- 📈 **Most recent:** ID 3488856, DocumentId "180942"

---

## 🎯 BUSINESS LOGIC INTERPRETATION

### Document Ownership Pattern
```
RootOwner = Original document (e.g., Order)
Owner = Current parent (e.g., Invoice derived from Order)
```

**Example from data:**
- Most documents: `RootOwner = Owner` (standalone)
- Some documents: `RootOwner ≠ Owner` (derived/linked)
  - ID 3488846: RootOwner=3342091, Owner=3356558 (child of different parent)

### DocumentId Pattern
- Sequential numbering: 180924, 180925, 180926...
- Suggests auto-increment business ID (not PK)
- NULL values likely for drafts/internal documents

---

## 🔗 ARCHITECTURE NOTES

### Inheritance Hierarchy
```
doCoreFtObject (grandparent - core object system)
    ↓
doDocument (parent - document abstraction)
    ↓
doInvoice, doOrder, doPurchase, etc. (children - specific types)
```

### Why This Design?
- **Polymorphism:** All documents share common fields (ID, Store, DocumentId)
- **Code reuse:** Base queries work across all document types
- **Type safety:** Specific tables (doInvoice) add domain logic

---

## 🎯 MIGRATION COMPLEXITY

**Rating:** 3/5 (MEDIUM)

**Why:**
- Simple schema BUT complex relationships
- Inheritance pattern requires careful PostgreSQL mapping
- Document chains (RootOwner/Owner) need integrity checks
- High volume (350K records)

**PostgreSQL Strategy:**
- Option 1: Keep inheritance (PostgreSQL supports table inheritance)
- Option 2: Flatten to single `documents` table with `type` column
- Option 3: Keep separate tables, use views for polymorphism

**Estimated Time:** 4-6 hours (design decisions + migration)

---

## 📋 SAMPLE DATA (Top 5)

```
ID: 3488856 | RootOwner: 2958996 | Owner: 2958996 | Store: 27090 | DocId: 180942
ID: 3488854 | RootOwner: 1285827 | Owner: 1285827 | Store: 27090 | DocId: 180941
ID: 3488852 | RootOwner: 2800200 | Owner: 2800200 | Store: 27090 | DocId: 180940
ID: 3488850 | RootOwner: 3173178 | Owner: 3173178 | Store: 27090 | DocId: 180939
ID: 3488848 | RootOwner: 3343504 | Owner: 3343504 | Store: 27090 | DocId: 180938
```

---

## ⚠️ DATA QUALITY ISSUES

1. **NULL RootOwners (150):** Investigate orphaned documents
2. **NULL Owners (3,946):** Document business rules for standalone docs
3. **NULL DocumentIds (1,693):** Confirm if intentional for drafts
4. **RootOwner ≠ Owner cases:** Map document derivation chains before migration

---

## 🔍 RECOMMENDED QUERIES FOR NEXT ANALYSIS

```sql
-- Find document chains (parent-child relationships)
SELECT RootOwner, COUNT(*) as ChainLength
FROM doDocument
WHERE RootOwner != Owner
GROUP BY RootOwner
ORDER BY ChainLength DESC;

-- Check doCoreFtObject relationship
SELECT COUNT(*) FROM doCoreFtObject WHERE ID IN (SELECT ID FROM doDocument);
```

---

**Analysis Complete:** 2025-11-10  
**Next Table:** doDocumentsOperations (operations log)

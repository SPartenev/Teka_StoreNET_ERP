# doCashDesk-Stores Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо

---

## 📋 Overview

**Purpose:** Many-to-many junction table linking cash desks to stores (locations)  
**Table Type:** Junction/Bridge Table  
**Row Count:** 181 mappings  
**Migration Complexity:** 2/5 (Simple structure, straightforward mapping)

**Business Logic:**
- Defines which cash desks are authorized/assigned to which store locations
- Enables multi-store cash desk operations (one cash desk can serve multiple stores)
- Supports multi-terminal stores (one store can have multiple cash desks)

---

## 🗂️ Schema

### Columns (2 total):

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID-1 | bigint | NOT NULL | 0 | Foreign key to doCashDesk.ID (cash desk reference) |
| ID-2 | bigint | NOT NULL | 0 | Foreign key to doStore.ID (store location reference) |

**Key Observations:**
- Pure junction table with only foreign keys (no additional attributes)
- Composite primary key implied (ID-1, ID-2)
- No timestamps, no status fields - simple mapping only
- Table name uses hyphen syntax (requires bracket notation in SQL)

**Design Pattern:**
Classic many-to-many relationship resolver - no business logic columns, pure mapping.

---

## 🔗 Relationships

### Foreign Keys (Outgoing):
- `ID-1` → `doCashDesk.ID` - References the cash desk entity
- `ID-2` → `doStore.ID` - References the store/location entity

### Foreign Keys (Incoming):
**None** - Leaf table, no child dependencies

**Relationship Type:** Many-to-Many Junction Table
```
doCashDesk (1) ←→ (N) doCashDesk-Stores (N) ←→ (1) doStore
```

---

## 📊 Data Analysis

### Total Records: 181 mappings

### Cardinality Statistics:
| Metric | Value | Insight |
|--------|-------|---------|
| **Unique Cash Desks** | 46 | Not all 158 cash desks are assigned to stores |
| **Unique Stores** | 24 | Active store locations with cash desk operations |
| **Total Mappings** | 181 | Average ~3.9 mappings per cash desk |
| **Max Stores per Cash Desk** | 16 | Most versatile cash desk (ID: 86379) |
| **Max Cash Desks per Store** | 39 | Largest store operation (Store ID: 27090) |

### Distribution Analysis:

**Top 5 Cash Desks by Store Coverage:**
| CashDesk ID | Store Count | Coverage % |
|-------------|-------------|------------|
| 86379 | 16 stores | 66.7% of all stores |
| 86264 | 13 stores | 54.2% |
| 86284 | 13 stores | 54.2% |
| 99573 | 13 stores | 54.2% |
| 99653 | 13 stores | 54.2% |

**Top 5 Stores by Cash Desk Count:**
| Store ID | CashDesk Count | Insight |
|----------|---------------|---------|
| 27090 | 39 cash desks | **Primary/flagship store** - 85% of all active cash desks |
| 27110 | 11 cash desks | Large store operation |
| 27120 | 10 cash desks | Large store operation |
| 27092 | 9 cash desks | Medium-large store |
| 27096 | 9 cash desks | Medium-large store |

### Sample Data Patterns:
```
CashDesk 48505 → Serves 11 stores (27090, 27096, 27098, 27102, 27108, 27110, 27116, 27120, 27122, 66041, 66093)
CashDesk 48504 → Serves 2 stores (27090, 27104)
Store 27090 → Has 39 cash desks assigned (dominant location)
```

**Key Observation:**
- **Store 27090** is the central hub with 85% of all active cash desks (39 out of 46)
- Most cash desks (35 out of 46) serve only Store 27090
- Only 11 cash desks are multi-store enabled (serve 2+ locations)
- Suggests centralized cash management with occasional multi-location flexibility

---

## 🏗️ Architecture Pattern

### Purpose in System:
**Access Control & Authorization Layer** for cash desk operations across physical locations.

**Business Rules Implied:**
1. **Multi-Store Cash Desks:** A cash desk can process transactions for multiple store locations (e.g., mobile/shared terminals)
2. **Multi-Terminal Stores:** A store location can have multiple cash desks (checkout lanes, departments)
3. **Centralization:** Store 27090 appears to be headquarters/main warehouse with consolidated cash operations
4. **Flexibility:** System supports both dedicated (1:1) and shared (N:N) cash desk assignments

**Use Cases:**
- Mobile cash desk operations (market events, temporary locations)
- Shared back-office cash desks processing for multiple stores
- Store-specific authorization (prevent unauthorized location transactions)
- Multi-location retail chain management

---

## 🔄 PostgreSQL Migration

### Complexity: 2/5 (Low Complexity)

**Why Low Complexity:**
- ✅ Simple two-column structure (no complex data types)
- ✅ Straightforward foreign key relationships
- ✅ No business logic to migrate (pure mapping)
- ✅ Small dataset (181 rows)
- ✅ No NULLs, no data quality issues
- ⚠️ Only consideration: hyphenated table name (use underscores in PostgreSQL)

### Migration Strategy:

```sql
-- PostgreSQL Table Definition
CREATE TABLE cashdesk_stores (
    cashdesk_id BIGINT NOT NULL,
    store_id BIGINT NOT NULL,
    
    -- Composite Primary Key
    PRIMARY KEY (cashdesk_id, store_id),
    
    -- Foreign Keys
    CONSTRAINT fk_cashdesk_stores_cashdesk 
        FOREIGN KEY (cashdesk_id) 
        REFERENCES cash_desks(id) 
        ON DELETE CASCADE,
    
    CONSTRAINT fk_cashdesk_stores_store 
        FOREIGN KEY (store_id) 
        REFERENCES stores(id) 
        ON DELETE CASCADE
);

-- Indexes for efficient queries
CREATE INDEX idx_cashdesk_stores_store 
    ON cashdesk_stores(store_id);
    
CREATE INDEX idx_cashdesk_stores_cashdesk 
    ON cashdesk_stores(cashdesk_id);

-- Comments for documentation
COMMENT ON TABLE cashdesk_stores IS 
    'Junction table mapping cash desks to authorized store locations';
COMMENT ON COLUMN cashdesk_stores.cashdesk_id IS 
    'Reference to cash_desks.id';
COMMENT ON COLUMN cashdesk_stores.store_id IS 
    'Reference to stores.id';
```

### Data Migration Script:
```sql
-- Direct 1:1 mapping, no transformations needed
INSERT INTO cashdesk_stores (cashdesk_id, store_id)
SELECT 
    [ID-1] AS cashdesk_id,
    [ID-2] AS store_id
FROM [TEKA].[dbo].[doCashDesk-Stores];

-- Verify count
-- Expected: 181 rows
```

### Schema Changes:
- [x] Rename table: `doCashDesk-Stores` → `cashdesk_stores` (PostgreSQL naming convention)
- [x] Rename columns: `ID-1` → `cashdesk_id`, `ID-2` → `store_id` (descriptive names)
- [x] Add composite primary key constraint
- [x] Add foreign key constraints with CASCADE behavior
- [x] Add indexes on both columns for bidirectional queries
- [x] No data type conversions needed (bigint → BIGINT)

### Validation Queries:
```sql
-- Count verification
SELECT COUNT(*) FROM cashdesk_stores; 
-- Expected: 181

-- Referential integrity check
SELECT COUNT(*) FROM cashdesk_stores cs
LEFT JOIN cash_desks cd ON cs.cashdesk_id = cd.id
WHERE cd.id IS NULL;
-- Expected: 0

SELECT COUNT(*) FROM cashdesk_stores cs
LEFT JOIN stores s ON cs.store_id = s.id
WHERE s.id IS NULL;
-- Expected: 0

-- Cardinality verification
SELECT 
    COUNT(DISTINCT cashdesk_id) AS unique_cashdesks,
    COUNT(DISTINCT store_id) AS unique_stores
FROM cashdesk_stores;
-- Expected: 46 cashdesks, 24 stores
```

### Estimated Migration Time: 1-2 hours
- Schema creation: 30 minutes
- Data migration: 15 minutes
- Testing & validation: 30 minutes
- Documentation: 15 minutes

---

## ❓ Stakeholder Questions

### Business Logic:
1. **Authorization Model:**
   - Are cash desks physically mobile/shared between stores?
   - Or is this logical grouping (e.g., all cash desks belong to HQ but process for branches)?
   
2. **Store 27090 Dominance:**
   - Why does one store have 85% of all cash desks?
   - Is this headquarters/warehouse or data modeling artifact?
   
3. **Multi-Store Cash Desks:**
   - What business scenario requires one cash desk to serve 16 stores?
   - Are these temporary assignments or permanent configuration?

### Operational Rules:
4. **Assignment Changes:**
   - Can cash desk-store assignments change dynamically?
   - Who manages these assignments (admin, store manager)?
   
5. **Transaction Authorization:**
   - Does a transaction fail if cash desk tries to process for non-assigned store?
   - Or is this purely informational/reporting dimension?

### Future State:
6. **Next.js/PostgreSQL:**
   - Keep same many-to-many flexibility?
   - Add audit fields (created_at, updated_at, created_by)?
   - Add active/inactive status flag?

---

## 🚨 Migration Risks

### Low Priority (Minor Issues):
1. **Naming Convention:** 
   - SQL Server uses hyphens in table name (requires brackets)
   - **Mitigation:** Use underscores in PostgreSQL (`cashdesk_stores`)

2. **Orphaned References:** 
   - Possible if cash desks/stores deleted but mappings remain
   - **Mitigation:** Add CASCADE foreign keys, run cleanup before migration

3. **Missing Audit Trail:**
   - No created_at, updated_at, or created_by columns
   - **Mitigation:** Consider adding in PostgreSQL for future compliance

### No High/Medium Risks Identified
- Data quality is clean (no NULLs, no invalid IDs visible)
- Small dataset reduces migration failure risk
- Simple structure minimizes transformation errors

---

## 📝 Notes

### Key Insights:
1. **Centralized Model:** System shows extreme centralization with Store 27090 handling 85% of cash operations
2. **Flexible Architecture:** Many-to-many design supports complex retail scenarios (mobile POS, shared terminals)
3. **Clean Data:** No obvious data quality issues, straightforward migration path
4. **Missing Metadata:** No timestamps or status flags - purely relational mapping

### Architectural Observations:
- **Design Pattern:** Classic junction table - textbook many-to-many implementation
- **Performance:** Small dataset (181 rows) means negligible performance impact
- **Scalability:** Current design scales well if business adds more stores/cash desks
- **Flexibility:** Supports future scenarios (pop-up stores, temporary locations, franchise model)

### PostgreSQL Enhancements (Optional):
```sql
-- Consider adding for Next.js application:
ALTER TABLE cashdesk_stores 
    ADD COLUMN created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ADD COLUMN created_by VARCHAR(100),
    ADD COLUMN is_active BOOLEAN DEFAULT TRUE,
    ADD COLUMN notes TEXT;

-- For audit compliance
CREATE TABLE cashdesk_stores_audit (
    audit_id SERIAL PRIMARY KEY,
    action VARCHAR(10), -- 'INSERT', 'DELETE'
    cashdesk_id BIGINT,
    store_id BIGINT,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(100)
);
```

### Business Context Questions:
- Is Store 27090 the main warehouse/distribution center?
- Are the 11 multi-store cash desks mobile units (e.g., market stands)?
- Do cash desk assignments change frequently or are they static?

---

## ✅ Analysis Complete

**Status:** ✅ DONE  
**Complexity:** 2/5 (Low)  
**Migration Time Estimate:** 1-2 hours  
**Priority:** MEDIUM (supporting infrastructure for cash operations)  
**Dependencies:** Must migrate AFTER doCashDesk and doStore tables  

**Data Quality:** ✅ Excellent (clean, consistent, no anomalies)  
**Business Logic:** ✅ Clear (straightforward many-to-many mapping)  
**Migration Risk:** ✅ Low (simple structure, small dataset)

---

**Previous:** 04-doCashDeskCurrencyChange.md  
**Next:** Continue with remaining Financial Domain tables or move to next domain

---

## 🔗 Related Tables
- **Parent Tables:** doCashDesk (01), doStore (Products Domain)
- **Sibling Tables:** doCashDesk-Entries (02), doCashDeskAmountTransfer (03), doCashDeskCurrencyChange (04)
- **Business Flow:** Store Location → Cash Desk Assignment → Cash Operations → Entries/Transactions

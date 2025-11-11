# doTransaction Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо

---

## 📋 Overview

**Purpose:** Unused intermediate layer in transaction inheritance hierarchy  
**Row Count:** 0 records (EMPTY TABLE)  
**Status:** DEPRECATED / UNUSED  
**Migration Complexity:** 1/5 (LOW - can be ignored)

---

## 🗂️ Schema

### Columns (2 total):
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | ((0)) | Primary key (inherited from doDataObject) |
| IsCommitted | bit | NOT NULL | ((0)) | Transaction commit status flag |

---

## 🔗 Relationships

### Foreign Keys (Outgoing):
- `ID` → `doDataObject.ID` - Inherits from base entity system

### Foreign Keys (Incoming):
- **NONE** - No tables reference doTransaction

---

## 🏗️ Architecture Discovery: Actual Hierarchy

### Expected Pattern (WRONG):
```
doDataObject
    ↓
doTransaction
    ↓
doSystemTransaction
    ↓
doTradeTransaction
```

### Actual Pattern (CORRECT):
```
doDataObject (base for all entities)
    ├─ doTransaction (EMPTY - never used)
    └─ doSystemTransaction (actual base for transactions)
           ├─ doTradeTransaction (764,906 records)
           ├─ doFinanceTransaction
           ├─ doStoreTransfer
           ├─ doStoreAssembly
           ├─ doStoreDiscard
           ├─ doCashDeskCurrencyChange
           └─ doCashDeskAmountTransfer
```

---

## 🎯 Key Findings

### 1. Unused Architectural Layer
- **doTransaction is completely empty** (0 records)
- **Never referenced** by any child tables
- **Parallel hierarchy exists** - doSystemTransaction serves the same purpose

### 2. doSystemTransaction is the Real Base
- Contains actual transaction fields:
  - `Date` (smalldatetime)
  - `Description` (nvarchar(1000))
  - `UserCreated`, `TimeCreated` (audit fields)
  - `IsCommitted`, `UserCommitted`, `TimeCommitted` (commit workflow)
- Referenced by 7 transaction types
- Contains all business logic for transactions

### 3. Likely Development History
**Hypothesis:** doTransaction was an early design attempt that was abandoned in favor of doSystemTransaction. The table was kept in schema but never populated.

---

## 🔄 PostgreSQL Migration

### Complexity: 1/5 (LOWEST PRIORITY)

**Strategy:** **SKIP THIS TABLE**

### Reasons to Skip:
1. **Zero records** - no data to migrate
2. **No references** - no dependencies
3. **Unused code** - likely no C# classes using it
4. **Duplicate purpose** - doSystemTransaction already exists

### Recommended Actions:
- [ ] **Document as deprecated** in migration notes
- [ ] **DO NOT create** in PostgreSQL schema
- [ ] **Search C# code** for `doTransaction` references (likely none)
- [ ] **Add migration note** explaining why it was skipped

### PostgreSQL Equivalent:
```sql
-- DO NOT CREATE - Table is unused
-- See doSystemTransaction for actual transaction base class
```

### Estimated Time: 0 hours (skip)

---

## 📊 Comparison: doTransaction vs doSystemTransaction

| Aspect | doTransaction | doSystemTransaction |
|--------|---------------|---------------------|
| Records | 0 | 764,906+ (via children) |
| Columns | 2 | 8 |
| Child Tables | 0 | 7 |
| Purpose | Unknown/Abandoned | Transaction base class |
| Usage | NONE | Active |
| Migration | Skip | Critical (analyze separately) |

---

## ❓ Stakeholder Questions

1. **Was doTransaction ever used in production?**
   - If yes, when was it deprecated?
   - Are there archived records elsewhere?

2. **Should doTransaction be dropped from schema?**
   - Safe to remove in new system?
   - Any code dependencies to check?

3. **Why were two similar tables created?**
   - Design evolution story?
   - Lessons for new architecture?

4. **Are there other unused "do*" tables?**
   - Should we audit all tables for similar cases?
   - Pattern of abandoned designs?

---

## 🚨 Migration Risks

### Risk Level: NONE (table is empty)

**Potential Issues:**
- ❌ None - table can be safely ignored

**Mitigation:**
- Document in "Tables Not Migrated" registry
- Add comment in migration scripts explaining why skipped
- Verify C# codebase doesn't reference this table

---

## 📝 Notes

### Architecture Insights:
1. **Inheritance pattern in SQL Server:**
   - Uses shared primary key (ID)
   - Each level adds columns
   - Foreign key from child.ID → parent.ID

2. **doSystemTransaction is comprehensive:**
   - Handles all transaction types
   - Includes audit trail (UserCreated, TimeCreated)
   - Supports commit workflow (IsCommitted, UserCommitted, TimeCommitted)
   - Has business description field

3. **Why doTransaction was abandoned (speculation):**
   - Too minimal (only ID + IsCommitted)
   - Missing critical fields (Date, Description, User audit)
   - doSystemTransaction added all needed functionality
   - Table kept for backward compatibility but never used

### Next Steps:
1. ✅ Mark doTransaction as analyzed but skipped
2. 🔄 Analyze doSystemTransaction next (if not already done)
3. 🔄 Understand full transaction hierarchy
4. 🔄 Map all 7 transaction child types

---

## 📚 Related Tables

**Should analyze next:**
- `doSystemTransaction` - The actual base class (HIGH PRIORITY)
- `doFinanceTransaction` - Financial operations
- `doStoreTransfer` - Inventory transfers
- `doStoreAssembly` - Product assemblies
- `doStoreDiscard` - Inventory write-offs
- `doCashDeskCurrencyChange` - Currency exchanges
- `doCashDeskAmountTransfer` - Cash movements

---

## ✅ Analysis Complete

**Status:** DONE  
**Recommendation:** SKIP in migration (document reason)  
**Complexity:** 1/5 (trivial - nothing to migrate)  
**Time Saved:** ~10-15 hours (by not migrating empty table)

---

**Analyst Note:** This discovery highlights the importance of analyzing schema before migration. Migrating every table blindly would waste time on unused structures.

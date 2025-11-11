# doSystemTransaction Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо

---

## 📋 Overview

**Purpose:** Base class for all system transactions - the actual transactional foundation for 7 different transaction types  
**Row Count:** 1,255,901 records  
**Date Range:** 1901-01-01 to 2021-09-15  
**Unique Users:** 55  
**Migration Complexity:** 4/5 (HIGH)

---

## 🗂️ Schema

### Columns (8 total):

| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | bigint | NOT NULL | ((0)) | Primary key (shared with child tables) |
| Date | smalldatetime | NOT NULL | ('1901-01-01 00:00:00') | Transaction date |
| Description | nvarchar(1000) | YES | (NULL) | Optional business description |
| UserCreated | bigint | NOT NULL | ((0)) | User who created transaction |
| TimeCreated | datetime | NOT NULL | ('1800-01-01 00:00:00') | Creation timestamp |
| IsCommitted | bit | NOT NULL | ((0)) | Commit status (0=draft, 1=committed) |
| UserCommitted | bigint | YES | (NULL) | User who committed transaction |
| TimeCommitted | datetime | YES | (NULL) | Commit timestamp |

---

## 🔗 Relationships

### Foreign Keys (Outgoing - 3):
- `ID` → `doDataObject.ID` - Inherits from base entity class
- `UserCreated` → `doUserAccount.ID` - Created by user
- `UserCommitted` → `doUserAccount.ID` - Committed by user

### Foreign Keys (Incoming - 7 Transaction Types):

1. **doTradeTransaction.ID** → ID - Trade operations (known: 764,906 records)
2. **doFinanceTransaction.ID** → ID - Financial transactions
3. **doStoreTransfer.ID** → ID - Inventory transfers between stores
4. **doStoreAssembly.ID** → ID - Product assembly operations
5. **doStoreDiscard.ID** → ID - Inventory write-offs/discards
6. **doCashDeskCurrencyChange.ID** → ID - Currency exchange operations
7. **doCashDeskAmountTransfer.ID** → ID - Cash desk transfers

**Total Records by Type:**
- Trade: 764,906 (60.9%)
- Other 6 types: ~491,000 (39.1%)

---

## 📊 Data Analysis

### Total Records: 1,255,901

### Commit Status Distribution:

| IsCommitted | Count | With User | With Time | Percentage |
|-------------|-------|-----------|-----------|------------|
| 0 (Uncommitted) | 44 | 0 | 0 | 0.0035% |
| 1 (Committed) | 1,255,857 | 1,255,857 | 1,255,857 | 99.9965% |

**Key Insights:**
- **99.9965% completion rate** - excellent workflow compliance
- Only 44 draft/abandoned transactions
- Perfect data integrity: committed transactions ALWAYS have UserCommitted + TimeCommitted
- Uncommitted transactions NEVER have commit fields populated

### Date Range:
- **Earliest:** 1901-01-01 (default value - indicates data quality issue)
- **Latest:** 2021-09-15 (actual last transaction)
- **Active Period:** Approximately 2020-2021 based on sample data

### User Activity:
- **55 unique users** created transactions
- **Primary users observed:** 48486, 606823

### Sample Data Observations (Latest 10 Records):

**Patterns Identified:**
1. **Description Field Usage:**
   - Often NULL (~70% of samples)
   - When populated: "Контрагент: [company/person name]"
   - Sometimes includes document references (e.g., "6000012452 / 28.05.20")

2. **Commit Timing:**
   - Most commits happen immediately (same second as creation)
   - Occasional delays observed (e.g., 20 minutes between create and commit)
   - Suggests manual approval workflow for certain transaction types

3. **Transaction Activity:**
   - Last activity: September 2021
   - Most recent samples from 2020-2021
   - Mix of corporate entities (ООД, ЕООД) and individuals ("частно лице")

---

## 🏗️ Architecture Pattern

### Inheritance Hierarchy:

```
doDataObject (universal base class)
    └─ doSystemTransaction (transaction base class - THIS TABLE)
           ├─ doTradeTransaction (764,906 records - 60.9%)
           ├─ doFinanceTransaction (~82K records est.)
           ├─ doStoreTransfer
           ├─ doStoreAssembly
           ├─ doStoreDiscard
           ├─ doCashDeskCurrencyChange
           └─ doCashDeskAmountTransfer
```

**Pattern Type:** Shared Primary Key Inheritance

**How It Works:**
1. Each transaction gets ID from doDataObject
2. Base transaction fields stored in doSystemTransaction
3. Type-specific fields stored in child tables
4. Same ID across all three tables (DataObject → SystemTransaction → SpecificType)

### Key Architectural Components:

**Audit Trail (Who/When):**
- UserCreated + TimeCreated - tracks origination
- UserCommitted + TimeCommitted - tracks approval

**Workflow State Machine:**
```
[CREATE] → IsCommitted=0, UserCommitted=NULL
    ↓
[COMMIT] → IsCommitted=1, UserCommitted=UserID, TimeCommitted=NOW()
```

**Business Description:**
- Optional field for human-readable context
- Commonly used for counterparty identification
- Can include document references

---

## 🔄 PostgreSQL Migration

### Complexity Rating: 4/5 (HIGH)

**Complexity Factors:**
- ✅ Base class for 7 transaction types (inheritance complexity)
- ✅ High volume: 1.26M records
- ✅ Critical business logic: commit workflow
- ✅ Must preserve parent-child relationships across 3 levels
- ⚠️ Data quality issues (default dates)
- ⚠️ Datetime precision changes required

### Migration Strategy - RECOMMENDED: PostgreSQL Table Inheritance

**Option 1: Native PostgreSQL Inheritance (BEST)**

```sql
-- Base transaction table
CREATE TABLE system_transactions (
    id BIGINT PRIMARY KEY,
    date TIMESTAMP NOT NULL,
    description VARCHAR(1000),
    user_created BIGINT NOT NULL REFERENCES users(id),
    time_created TIMESTAMP NOT NULL,
    is_committed BOOLEAN NOT NULL DEFAULT FALSE,
    user_committed BIGINT REFERENCES users(id),
    time_committed TIMESTAMP,
    
    -- Constraints
    CONSTRAINT check_commit_logic 
        CHECK (
            (is_committed = FALSE AND user_committed IS NULL AND time_committed IS NULL) OR
            (is_committed = TRUE AND user_committed IS NOT NULL AND time_committed IS NOT NULL)
        )
);

-- Child tables inherit automatically
CREATE TABLE trade_transactions (
    -- Trade-specific columns
    trade_type_id BIGINT NOT NULL,
    counterparty_id BIGINT,
    -- ... other trade fields
) INHERITS (system_transactions);

CREATE TABLE finance_transactions (
    -- Finance-specific columns
    account_id BIGINT NOT NULL,
    -- ... other finance fields
) INHERITS (system_transactions);

-- ... 5 more child tables
```

**Benefits:**
- Native PostgreSQL feature
- Automatic query inheritance (SELECT from parent includes children)
- Type-specific queries remain simple
- Maintains clear domain separation

**Option 2: Single Table with Discriminator (Alternative)**

```sql
CREATE TABLE transactions (
    id BIGINT PRIMARY KEY,
    transaction_type VARCHAR(50) NOT NULL, -- 'TRADE', 'FINANCE', etc.
    date TIMESTAMP NOT NULL,
    description VARCHAR(1000),
    user_created BIGINT NOT NULL,
    time_created TIMESTAMP NOT NULL,
    is_committed BOOLEAN DEFAULT FALSE,
    user_committed BIGINT,
    time_committed TIMESTAMP,
    
    -- Type-specific fields (all nullable)
    trade_counterparty_id BIGINT,
    finance_account_id BIGINT,
    -- ... (sparse columns)
    
    CHECK (
        (transaction_type = 'TRADE' AND trade_counterparty_id IS NOT NULL) OR
        (transaction_type = 'FINANCE' AND finance_account_id IS NOT NULL)
        -- ... type-specific validations
    )
);
```

**Trade-offs:**
- Simpler structure
- Better for cross-type reporting
- Sparse columns (many NULLs)
- Harder to maintain type-specific constraints

**Option 3: Table Per Type (NOT RECOMMENDED)**

Separate tables with no inheritance - loses shared transaction logic.

---

### Schema Transformations Required:

| Current (SQL Server) | Target (PostgreSQL) | Notes |
|---------------------|---------------------|-------|
| smalldatetime | TIMESTAMP | Precision: minute → microsecond |
| datetime | TIMESTAMP | Date range: 1753-9999 → 4713 BC-294276 AD |
| bit | BOOLEAN | TRUE/FALSE vs 1/0 |
| nvarchar(1000) | VARCHAR(1000) | UTF-8 native in PostgreSQL |
| bigint | BIGINT | Compatible (8 bytes) |

### Data Cleanup Required:

**1. Default Date Values (Priority: HIGH)**
```sql
-- Find records with default date
SELECT COUNT(*) FROM doSystemTransaction 
WHERE Date = '1901-01-01';

-- Strategy:
-- Option A: Use TimeCreated as proxy for Date
-- Option B: Mark as data quality issue, keep date
-- Option C: Set to NULL if business rules allow
```

**2. Commit Logic Validation (Priority: CRITICAL)**
```sql
-- Verify no orphaned commit data
SELECT COUNT(*) FROM doSystemTransaction
WHERE IsCommitted = 0 AND (UserCommitted IS NOT NULL OR TimeCommitted IS NOT NULL);

SELECT COUNT(*) FROM doSystemTransaction
WHERE IsCommitted = 1 AND (UserCommitted IS NULL OR TimeCommitted IS NULL);

-- Should both return 0 (validated: TRUE based on analysis)
```

### Indexes Strategy:

```sql
-- Primary operations
CREATE INDEX idx_sys_trans_date ON system_transactions(date);
CREATE INDEX idx_sys_trans_user_created ON system_transactions(user_created);
CREATE INDEX idx_sys_trans_is_committed ON system_transactions(is_committed);

-- Composite for common queries
CREATE INDEX idx_sys_trans_date_committed 
    ON system_transactions(date, is_committed) 
    WHERE is_committed = TRUE;

-- User activity tracking
CREATE INDEX idx_sys_trans_user_time 
    ON system_transactions(user_created, time_created);

-- Uncommitted transactions (rare, but critical)
CREATE INDEX idx_sys_trans_uncommitted 
    ON system_transactions(id) 
    WHERE is_committed = FALSE;
```

### Performance Optimizations:

**1. Partitioning by Date (RECOMMENDED)**
```sql
-- Monthly partitions for better query performance
CREATE TABLE system_transactions (
    -- ... columns
) PARTITION BY RANGE (date);

CREATE TABLE sys_trans_2020_01 PARTITION OF system_transactions
    FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

-- ... create partitions for each month
```

**Benefits:**
- Faster date-range queries
- Easier archival (DROP old partitions)
- Better vacuum performance

**2. Materialized Views for Reporting**
```sql
CREATE MATERIALIZED VIEW mv_transaction_summary AS
SELECT 
    date_trunc('month', date) AS month,
    COUNT(*) AS total_transactions,
    COUNT(*) FILTER (WHERE is_committed) AS committed_count,
    COUNT(DISTINCT user_created) AS unique_users
FROM system_transactions
GROUP BY date_trunc('month', date);

CREATE INDEX ON mv_transaction_summary(month);

-- Refresh strategy: REFRESH MATERIALIZED VIEW CONCURRENTLY mv_transaction_summary;
```

---

## 📝 Migration Implementation Plan

### Phase 1: Schema Creation (2 hours)
1. Create base system_transactions table
2. Create 7 child tables with INHERITS
3. Add all constraints and CHECK logic
4. Create indexes

### Phase 2: Data Migration (12-15 hours)
1. Extract doSystemTransaction data (1.26M records)
2. Transform dates, booleans, NULLs
3. Load to PostgreSQL with COPY command
4. Verify record counts match exactly

### Phase 3: Child Table Migration (8-10 hours)
1. Migrate doTradeTransaction (764K records)
2. Migrate other 6 child types (~491K total)
3. Verify FK relationships preserved
4. Validate shared PK inheritance

### Phase 4: Validation (3-4 hours)
1. Row count verification
2. Commit logic integrity checks
3. Date range validation
4. User reference integrity
5. Sample data comparison

### Phase 5: Performance Tuning (2-3 hours)
1. ANALYZE tables
2. Test query performance
3. Add missing indexes if needed
4. Configure autovacuum settings

**Total Estimated Time: 27-34 hours (3.5-4.5 days)**

---

## ❓ Stakeholder Questions

### Business Logic Validation:

1. **Commit Workflow:**
   - Is IsCommitted = 0 an intentional draft state or abandoned transaction?
   - Who has permission to commit transactions?
   - Can committed transactions be reversed? If yes, how?
   - What triggers the commit action in the UI?

2. **Default Date Handling:**
   - Records with Date = '1901-01-01' - are these valid or data errors?
   - Should we use TimeCreated as the actual transaction date?
   - Business impact if we correct these dates?

3. **Transaction Types Priority:**
   - Are all 7 transaction types actively used?
   - Priority order for migration testing?
   - Any types being deprecated in new system?
   - Expected transaction volume in Next.js system?

4. **Description Field Usage:**
   - Is nvarchar(1000) sufficient for future needs?
   - Should description be required or optional?
   - Any standardization rules for counterparty descriptions?
   - Do we need full-text search on descriptions?

5. **Audit Requirements:**
   - Current audit trail (UserCreated/TimeCreated) sufficient?
   - Need additional fields (IP address, location, device)?
   - Retention policy for transaction history?
   - Compliance requirements (GDPR, accounting standards, tax)?

6. **Uncommitted Transactions:**
   - 44 uncommitted records - should they be migrated?
   - Can users see their uncommitted drafts?
   - Timeout policy for auto-cleanup of drafts?

### Performance & Scalability:

7. **Query Patterns:**
   - Most common report queries?
   - Real-time vs batch reporting needs?
   - Expected concurrent user load?
   - Data archival strategy (keep all history or archive old years)?

8. **Partitioning Strategy:**
   - Monthly partitions acceptable?
   - Need to query across long date ranges?
   - Archive strategy for old partitions?

---

## 🚨 Migration Risks

### High Priority:

**1. Data Volume** (Risk: HIGH, Impact: HIGH)
- **Issue:** 1.26M records require careful migration
- **Mitigation:** 
  - Use PostgreSQL COPY for bulk load
  - Partition during migration
  - Test with 10% sample first
  - Plan for 12-15 hour migration window

**2. Inheritance Pattern Preservation** (Risk: HIGH, Impact: CRITICAL)
- **Issue:** Shared Primary Key across 3 levels (DataObject → SystemTransaction → SpecificType)
- **Mitigation:**
  - Use PostgreSQL native inheritance
  - Validate FK relationships post-migration
  - Test all 7 child types individually
  - Create comprehensive integration tests

**3. Commit Workflow Logic** (Risk: MEDIUM, Impact: CRITICAL)
- **Issue:** Business-critical two-phase commit must work identically
- **Mitigation:**
  - Implement CHECK constraint on commit fields
  - Add database triggers if needed
  - Test commit scenarios extensively
  - Document workflow in migration guide

**4. Date Precision Changes** (Risk: MEDIUM, Impact: MEDIUM)
- **Issue:** smalldatetime (minute precision) → TIMESTAMP (microsecond precision)
- **Mitigation:**
  - Validate date ranges before migration
  - Test datetime comparisons in new system
  - Document precision upgrade
  - Check if any code relies on minute precision

### Medium Priority:

**5. Default Date Values** (Risk: LOW, Impact: MEDIUM)
- **Issue:** Records with 1901-01-01 dates (default values)
- **Mitigation:**
  - Get business decision on handling
  - Option to use TimeCreated as proxy
  - Document as known data quality issue

**6. Performance Degradation** (Risk: MEDIUM, Impact: MEDIUM)
- **Issue:** Query patterns may differ in PostgreSQL
- **Mitigation:**
  - Implement partitioning from start
  - Create necessary indexes before go-live
  - Benchmark critical queries
  - Have rollback plan ready

**7. User Reference Integrity** (Risk: LOW, Impact: HIGH)
- **Issue:** 55 users referenced - must all exist in new system
- **Mitigation:**
  - Migrate doUserAccount first
  - Validate all UserCreated/UserCommitted references
  - Handle deleted users scenario

---

## 📝 Notes

### Key Architectural Insights:

1. **Real Transaction Base**
   - doTransaction table exists but is empty (0 records)
   - doSystemTransaction is the ACTUAL base class in production
   - Suggests architectural evolution where "SystemTransaction" superseded "Transaction"

2. **Audit-First Design**
   - Every transaction tracks WHO created it and WHEN
   - Optional commit tracking (WHO approved, WHEN approved)
   - Immutable audit trail (no UPDATE of audit fields)

3. **Two-Phase Commit Pattern**
   - Phase 1: CREATE → IsCommitted=0, minimal data
   - Phase 2: COMMIT → IsCommitted=1, adds approval metadata
   - 99.9965% completion rate indicates mature workflow

4. **Flexible Inheritance Architecture**
   - Single base class supports 7 diverse transaction types
   - Shared fields (date, audit, commit) in base
   - Type-specific fields in child tables
   - Easy to add new transaction types (8th, 9th, etc.)

5. **Business Description Field**
   - Optional field for human-readable context
   - Primary use: identify counterparty
   - Sometimes includes document references
   - Not heavily used (~30% populated based on samples)

### Why This Design Works Well:

**Benefits:**
- ✅ **Consistent audit trail** across all transaction types
- ✅ **Unified commit workflow** reduces code duplication
- ✅ **Type safety** via inheritance prevents mixing concerns
- ✅ **Query efficiency** for cross-type reporting (query base table)
- ✅ **Maintainable** - shared logic lives in one place

**Challenges:**
- ⚠️ **Complexity** - requires understanding 3-level inheritance
- ⚠️ **SQL Server limitations** - shared PK pattern less elegant than PostgreSQL INHERITS
- ⚠️ **Join overhead** - queries often need 3-table JOIN

### PostgreSQL Migration Advantages:

**Native Features That Help:**

1. **Table Inheritance**
   - Built-in INHERITS keyword
   - Automatic query propagation from parent to children
   - Cleaner than SQL Server's shared PK pattern

2. **Partitioning**
   - Native support for date-based partitioning
   - Better query performance for time-series data
   - Easier data archival (DROP old partitions)

3. **CHECK Constraints**
   - Can enforce complex commit logic at DB level
   - Better data integrity than application-only validation

4. **JSONB Type**
   - Could store type-specific metadata flexibly
   - Reduces need for sparse columns in single-table approach

5. **CTEs and Recursive Queries**
   - Cleaner syntax for complex inheritance queries
   - Better optimization for hierarchical data

6. **Full-Text Search**
   - Could enable powerful search on Description field
   - Built-in vs needing external search engine

### Design Decisions for Next.js System:

**Keep:**
- Two-phase commit workflow (proven effective)
- Audit trail architecture (WHO/WHEN tracking)
- Inheritance pattern (but use PostgreSQL INHERITS)

**Enhance:**
- Add more granular audit fields (IP, device, action type)
- Implement soft deletes (is_deleted flag)
- Add version tracking for transaction updates
- Create materialized views for reporting
- Implement row-level security for multi-tenant if needed

**Modernize:**
- Use TIMESTAMP WITH TIME ZONE (better for international)
- Add created_at/updated_at triggers
- Implement proper ENUM types for transaction types
- Add full-text search indexes on Description
- Use JSONB for flexible metadata storage

---

## ✅ Analysis Complete

**Status:** DONE ✅  
**Complexity Rating:** 4/5 (HIGH)  
**Migration Time Estimate:** 27-34 hours (3.5-4.5 days)  
**Business Priority:** CRITICAL (base class for ALL transactions)

**Key Takeaway:**  
doSystemTransaction is the foundational transaction class with excellent data integrity (99.9965% committed), mature audit patterns, and a proven two-phase commit workflow. PostgreSQL native inheritance will simplify the current SQL Server shared-PK pattern while maintaining all business logic. The 1.26M record volume requires careful migration planning with partitioning and thorough testing of all 7 transaction types.

---

**Next Steps:**
1. Validate business questions with stakeholders
2. Analyze 6 remaining child transaction types (Finance, Store operations, CashDesk)
3. Create detailed migration scripts
4. Plan testing strategy for commit workflow

**Migration Dependencies:**
- ✅ Must migrate doDataObject first (parent class)
- ✅ Must migrate doUserAccount first (user references)
- 🔄 This table before all 7 child types
- 🔲 Child types can migrate in parallel after this is done

# 🤖 AGENT HANDOFF INSTRUCTIONS - Database Table Analysis
**Project:** TEKA_NET ERP Migration (Store.NET → Next.js/PostgreSQL)  
**Phase:** Week 1-2 - Database Domain Analysis  
**Current Progress:** 45% Complete (16/125 tables)  
**Date:** 2025-11-10  
**For:** Next Session Claude Agent

---

## 🎯 YOUR MISSION

Continue **systematic database table analysis** using the **proven micro-steps methodology** that has successfully completed **3 full domains** (Products, Financial, Documents) with **perfect 100% data integrity**.

**What You'll Do:**
1. Analyze database tables **one at a time** (never rush!)
2. Use **MCP Filesystem tools** for all file operations
3. Execute SQL queries via **Светльо** (you provide query, he executes)
4. Document findings **immediately** after each table
5. Update progress trackers after **each completion**

---

## 📁 PROJECT STRUCTURE (CRITICAL!)

```
C:\TEKA_NET\Teka_StoreNET_ERP\
├── 📜 README.md                              (Project overview)
├── 📜 PROJECT_STATUS_AND_NEXT_STEPS.md       (Overall status)
├── 📜 GIT-QUICK-COMMIT.ps1                   (Git helper)
│
├── 📁 docs/                                   (All documentation)
│   ├── handoffs/                             (Session handoffs)
│   ├── progress/                             (Domain progress)
│   ├── analysis/                             (Supporting docs)
│   ├── archive/                              (Old/temp files)
│   └── status/                               (Status reports)
│
├── 📁 analysis/                               (TABLE ANALYSES ONLY!)
│   ├── domains/
│   │   └── TRADE-DOMAIN-ANALYSIS.md          (Summary doc)
│   └── week1/
│       └── core-tables/
│           ├── part-1-products/              (✅ 6 tables - 100%)
│           ├── financial-domain/             (✅ 7 tables - 100%)
│           ├── documents-domain/             (✅ 3 tables - 100%)
│           └── trade-domain/                 (🔄 10/14 tables - 71%)
│               ├── 01-doTrade.md
│               ├── 02-doTradeItem.md
│               ├── ... (8 more completed)
│               └── trade-domain-progress.md  (CRITICAL!)
│
├── 📁 IMPLEMENTATION/ (Future migration code)
└── 📁 PROJECT-TRACKING/ (Tracking files)
```

**GOLDEN RULE:** 
- `analysis/` = **ONLY table analysis markdown files**
- `docs/` = **ALL other documentation** (handoffs, progress, status)

---

## 🛠️ MCP TOOLS YOU MUST USE

### 1️⃣ **Filesystem Tools** (PRIMARY)

#### Read Files:
```
Filesystem:read_file - Read single file
Filesystem:read_multiple_files - Read multiple files at once
```

**Use Cases:**
- Read handoff instructions
- Read progress trackers
- Check existing analyses

#### Write Files:
```
Filesystem:write_file - CREATE OR OVERWRITE files
```

**⚠️ CRITICAL:**
- **ALWAYS use `write_file`** (NOT `create_file` - compatibility issues!)
- Use for: Table analyses, progress updates, handoffs
- Overwrites existing files (safe for updates)

#### Navigate Structure:
```
Filesystem:list_directory - List files in directory
Filesystem:directory_tree - Get full tree structure
Filesystem:search_files - Find files by pattern
```

**Use Cases:**
- Orient yourself in project
- Find existing analyses
- Check file organization

### 2️⃣ **Database Tool** (INDIRECT)

**IMPORTANT:** You **CANNOT directly query** the database!

**Workflow:**
1. **You** create SQL query
2. **Светльо** executes in AdminSQL
3. **Светльо** provides results
4. **You** analyze and document

**Format:**
```sql
-- Always provide queries in code blocks
-- Use brackets for special characters: [doTradeCancel-Items]
-- SQL Server 2005 syntax
-- Database: TEKA (not TEKA MAT!)
```

### 3️⃣ **Progress Tracking** (MANDATORY)

After **EVERY table completion**, update:
```
Filesystem:write_file
Path: analysis/week1/core-tables/[domain]/[domain]-progress.md
```

---

## 📋 STEP-BY-STEP WORKFLOW

### 🔹 SESSION START (5-10 minutes)

#### 1. Orient Yourself
```javascript
// Read these files IN ORDER:
1. Filesystem:read_file("C:\\TEKA_NET\\Teka_StoreNET_ERP\\docs\\handoffs\\TRADE-next-session.md")
2. Filesystem:read_file("C:\\TEKA_NET\\Teka_StoreNET_ERP\\docs\\progress\\trade-domain.md")
3. Filesystem:read_file("C:\\TEKA_NET\\Teka_StoreNET_ERP\\PROJECT_STATUS_AND_NEXT_STEPS.md")
```

**Extract:**
- Current progress percentage
- Last completed table
- Next table to analyze
- Known issues/patterns

#### 2. Confirm Next Table
```
ASK СВЕТЛЬО: "Should I start with [TableName] or different table?"
WAIT for confirmation before proceeding!
```

---

### 🔹 TABLE ANALYSIS (1-3 hours per table)

#### Step 1: Schema Analysis (15-20 min)
```sql
-- Query 1: Get schema
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT,
    CHARACTER_MAXIMUM_LENGTH,
    NUMERIC_PRECISION,
    NUMERIC_SCALE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = '[YourTableName]'
  AND TABLE_SCHEMA = 'dbo'
ORDER BY ORDINAL_POSITION;
```

**Document:**
- Column names, types, nullability
- Key fields (ID, dates, amounts)
- Foreign key columns (end with ID)

#### Step 2: Foreign Keys (10-15 min)
```sql
-- Query 2: Incoming FKs
SELECT 
    fk.name AS FK_Name,
    OBJECT_NAME(fk.parent_object_id) AS Child_Table,
    COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS Child_Column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.referenced_object_id) = '[YourTableName]';

-- Query 3: Outgoing FKs
SELECT 
    fk.name AS FK_Name,
    OBJECT_NAME(fk.referenced_object_id) AS Parent_Table,
    COL_NAME(fkc.referenced_object_id, fkc.referenced_column_id) AS Parent_Column
FROM sys.foreign_keys fk
INNER JOIN sys.foreign_key_columns fkc 
    ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) = '[YourTableName]';
```

#### Step 3: Basic Statistics (20-30 min)
```sql
-- Query 4: Row count and date range
SELECT 
    COUNT(*) AS TotalRecords,
    MIN(CreatedOn) AS EarliestDate,
    MAX(CreatedOn) AS LatestDate,
    COUNT(DISTINCT StoreID) AS UniqueStores,
    COUNT(*) - COUNT([ImportantColumn]) AS NullValues
FROM [YourTableName];
```

**Customize based on table columns!**

#### Step 4: Data Integrity Checks (30-45 min)
```sql
-- Query 5: Orphaned records
SELECT COUNT(*) AS OrphanedRecords
FROM [YourTableName] t
LEFT JOIN [ParentTable] p ON t.ParentID = p.ID
WHERE p.ID IS NULL AND t.ParentID IS NOT NULL;

-- Query 6: Value distributions
SELECT TOP 20
    [KeyColumn],
    COUNT(*) AS RecordCount,
    SUM([AmountColumn]) AS TotalAmount
FROM [YourTableName]
GROUP BY [KeyColumn]
ORDER BY RecordCount DESC;
```

#### Step 5: Business Logic Analysis (30-60 min)
```sql
-- Query 7: Complex patterns (customize!)
-- Examples:
-- - Negative values
-- - Zero prices
-- - Future dates
-- - Duplicate entries
-- - Statistical outliers
```

**Look for:**
- Unusual patterns
- Data quality issues
- Business rules embedded in data
- Relationships to other tables

#### Step 6: Document Findings (30-45 min)

**Use this template:**

```markdown
# [TableName] Analysis

**Date:** 2025-11-10  
**Database:** TEKA  
**Analyst:** Claude + Светльо

---

## 📋 Table Overview

**Purpose:** [1-2 sentence description]  
**Row Count:** [X records]  
**Date Range:** [earliest] to [latest]  
**Migration Complexity:** [1-5 rating] ([LOW/MEDIUM/HIGH/VERY HIGH])

---

## 🗂️ Schema Structure

### Columns ([X total]):
| Column | Type | Nullable | Default | Description |
|--------|------|----------|---------|-------------|
| ID | int | NOT NULL | - | Primary key |
| ... | ... | ... | ... | ... |

### Indexes:
- PRIMARY KEY: ID
- ... (list all indexes)

---

## 🔗 Relationships

### Foreign Keys (Outgoing):
- `ParentID` → `ParentTable.ID` ([description])

### Foreign Keys (Incoming):
- `ChildTable.ParentID` → `ID` ([description])

---

## 📊 Data Statistics

### Basic Counts:
- Total Records: X
- Date Range: YYYY-MM-DD to YYYY-MM-DD
- Active Records: X
- Deleted Records: X

### Distributions:
[Key distributions with business meaning]

---

## 🚨 Data Integrity Issues

### 1. [Issue Type]
- **Count:** X records
- **Impact:** [Business impact]
- **Example:** [Specific example]
- **Recommendation:** [Fix strategy]

[Repeat for each issue]

---

## 💼 Business Logic

### Patterns Discovered:
1. **[Pattern Name]:** [Description]
2. **[Pattern Name]:** [Description]

### Business Rules:
1. [Rule extracted from data]
2. [Rule extracted from data]

---

## 🔄 PostgreSQL Migration

### Complexity Rating: [X/5]

### Schema Changes Required:
- [ ] Float → NUMERIC(19,4) for monetary fields
- [ ] DateTime → TIMESTAMP WITH TIME ZONE
- [ ] NVARCHAR(MAX) → TEXT
- [ ] Add constraints
- [ ] Create indexes

### Data Transformation:
- [ ] [Transformation needed]
- [ ] [Transformation needed]

### Migration Steps:
1. [Step 1]
2. [Step 2]

### Estimated Time: [X hours] ([X days])

---

## ❓ Stakeholder Questions

1. **[Question about business logic]**
2. **[Question about data discrepancy]**
3. **[Question about process]**

---

## 📝 Notes

- [Additional context]
- [Cross-references to other tables]
- [Migration risks]

---

**Analysis Complete:** ✅  
**Quality Check:** ✅  
**Next Table:** [Name]
```

#### Step 7: Save Analysis (5 min)
```javascript
Filesystem:write_file({
  path: "C:\\TEKA_NET\\Teka_StoreNET_ERP\\analysis\\week1\\core-tables\\[domain]\\[NN]-[TableName]-analysis.md",
  content: "[Your complete analysis]"
})
```

**Naming Convention:**
- Format: `NN-TableName-analysis.md`
- Example: `12-doTransaction-analysis.md`
- Use next sequential number (check progress file!)

---

### 🔹 AFTER EACH TABLE (10-15 minutes)

#### 1. Update Progress Tracker
```javascript
// Read current progress
Filesystem:read_file("analysis/week1/core-tables/[domain]/[domain]-progress.md")

// Update with new completion
// Change status from 🔲 TODO to ✅ DONE
// Update percentage
// Add findings summary

// Write updated progress
Filesystem:write_file({
  path: "analysis/week1/core-tables/[domain]/[domain]-progress.md",
  content: "[Updated progress content]"
})
```

**Update:**
- Table status (🔲 → ✅)
- Progress percentage
- Add key findings to cumulative section
- Update next steps

#### 2. Create Mini-Handoff (if session ending)
```javascript
Filesystem:write_file({
  path: "docs/handoffs/[DOMAIN]-next-session.md",
  content: `
# HANDOFF - [Domain] Analysis
Date: [Today]
Progress: X/Y tables (Z%)
Last Completed: [TableName]
Next: [NextTableName]

## Quick Context:
[2-3 sentences about progress]

## Start Next Session:
1. Read: [This file path]
2. Read: [Progress tracker path]
3. Start with: [NextTableName]
4. First query: [SQL]

## Critical Issues:
- [Issue 1]
- [Issue 2]
`
})
```

---

### 🔹 SESSION END (15-20 minutes)

#### 1. Final Progress Check
```javascript
// Read all progress files
Filesystem:read_multiple_files([
  "analysis/week1/core-tables/[domain]/[domain]-progress.md",
  "PROJECT_STATUS_AND_NEXT_STEPS.md",
  "docs/progress/[domain]-domain.md"
])
```

#### 2. Create Comprehensive Handoff
```javascript
Filesystem:write_file({
  path: "docs/handoffs/[DOMAIN]-SESSION-[N].md",
  content: `[Full session summary with all completed tables, findings, next steps]`
})
```

#### 3. Confirm with Светльо
```
ASK: "Session complete! I've analyzed [N] tables today. 
     Updated progress to [X%]. 
     Ready for you to review and commit to Git?"
```

---

## 🎯 QUALITY CHECKLIST

Before marking table as ✅ DONE:

### Analysis Quality:
- [ ] All SQL queries executed successfully
- [ ] Schema fully documented (columns, types, constraints)
- [ ] Foreign keys identified (incoming + outgoing)
- [ ] Row counts and distributions calculated
- [ ] Data integrity issues documented
- [ ] Business logic patterns identified
- [ ] PostgreSQL migration complexity rated
- [ ] Stakeholder questions listed

### File Quality:
- [ ] Analysis file saved with correct naming convention
- [ ] Markdown formatting correct (readable)
- [ ] Progress tracker updated
- [ ] Next steps clearly documented
- [ ] No placeholder text (e.g., "[TODO]")

### Cross-References:
- [ ] Related tables mentioned
- [ ] Links to other analyses (if relevant)
- [ ] Cumulative statistics updated
- [ ] Domain summary updated (if last table)

---

## 🚨 CRITICAL RULES (DO NOT BREAK!)

### 1. **Micro-Steps Methodology**
```
❌ BAD:  Analyze 3 tables at once
✅ GOOD: Complete 1 table, document, then next
```

**Why:** Prevents data loss, ensures quality, maintains focus

### 2. **Always Use MCP Filesystem Tools**
```
❌ BAD:  "I'll create a file..." (without tool call)
✅ GOOD: Filesystem:write_file(...)
```

**Why:** Only way files actually get created!

### 3. **Wait for Query Results**
```
❌ BAD:  "Here's the query... based on typical results..."
✅ GOOD: "Here's the query. [WAIT] Now analyzing results..."
```

**Why:** Don't assume data patterns - validate everything!

### 4. **Never Skip Progress Updates**
```
❌ BAD:  Complete table, move to next
✅ GOOD: Complete table → Update progress → Create handoff → Next
```

**Why:** Ensures continuity if session interrupted

### 5. **Document Immediately**
```
❌ BAD:  "Let me analyze 3 more tables, then document"
✅ GOOD: "Table done. Saving analysis now."
```

**Why:** Context is fresh, prevents forgetting details

### 6. **Use Correct Paths**
```
✅ Table analyses:  analysis/week1/core-tables/[domain]/
✅ Handoffs:        docs/handoffs/
✅ Progress:        docs/progress/
✅ Status:          docs/status/
```

### 7. **Always Read Handoff First**
```
FIRST ACTION in new session:
Filesystem:read_file("docs/handoffs/[DOMAIN]-next-session.md")
```

**Why:** Understand context, avoid redoing work

---

## 🎓 PROVEN PATTERNS

### Pattern 1: Table Inheritance
```
If you see:
- Shared primary key (ID) across tables
- Similar column names
- Event log references

Then: Document inheritance pattern!
Example: doDocument → doInvoice
```

### Pattern 2: Header-Detail Relationship
```
If you see:
- ParentTable + ParentTable-Items
- TotalAmount in header = SUM(items)

Then: Validate 100% integrity!
Example: doTradeDelivery + doTradeDelivery-Items
```

### Pattern 3: Event Sourcing
```
If you see:
- TransactionID referencing event log
- Immutable records (no updates)
- Sequential IDs

Then: Document event-driven architecture!
Example: doTradeTransaction → all Trade* tables
```

### Pattern 4: Dual Tracking
```
If you see:
- Formal process (table + items)
- Direct field update (DeliveredAmount)
- 90%+ bypass formal system

Then: 🚨 CRITICAL ISSUE - flag for stakeholders!
Example: doTradeDelivery (9%) vs TradeItem.DeliveredAmount (91%)
```

### Pattern 5: Pending Workflow
```
If you see:
- High percentage "pending" status
- Large amounts frozen
- Approval gates

Then: Document workflow bottleneck!
Example: doTradeReturn (58% pending, 313K BGN frozen)
```

---

## 📊 CURRENT DOMAIN STATUS

### ✅ COMPLETED (100%):
1. **Products Domain:** 6/6 tables
   - Location: `analysis/week1/core-tables/part-1-products/`
   - Key: 19,845 products, hierarchical categories

2. **Financial Domain:** 7/7 tables
   - Location: `analysis/week1/core-tables/financial-domain/`
   - Key: €33M+ cash operations, double-entry accounting

3. **Documents Domain:** 3/3 tables
   - Location: `analysis/week1/core-tables/documents-domain/`
   - Key: 350K documents, €80.9M revenue, inheritance pattern

### 🔄 IN PROGRESS (71%):
4. **Trade Domain:** 10/14 tables
   - Location: `analysis/week1/core-tables/trade-domain/`
   - Progress: **71% - Over two-thirds complete!**
   - Remaining: 4 tables (doTransaction, doTransactionInfo, doSystemTransaction, +1)
   - Critical Issues: Dual delivery system, pending returns, quote cancellations

### 🔲 TODO:
5. Store/Inventory Domain (21 tables)
6. Contractors Domain (8 tables)
7. Security/Users Domain (11 tables)
8. Geographic Domain (4 tables)
9. Finance Transactions (10 tables)
10. [Other domains...]

**Total:** 16/125 tables complete (13%)

---

## 🔥 CRITICAL DISCOVERIES (Brief)

### Trade Domain:
1. **Dual Delivery System:** 91% items bypass formal tracking (68M BGN!)
2. **Pending Returns:** 58% awaiting approval (313K BGN frozen)
3. **Quote Cancellations:** Cancels = aborted quotes, NOT reversed trades!
4. **Payment Gap:** 2.77M BGN unpaid
5. **Tax Exemptions:** Returns 20x higher rate than deliveries (8.7% vs 0.44%)

### Financial Domain:
1. **Float Data Types:** Must convert to NUMERIC for PostgreSQL
2. **Stale Exchange Rates:** Last updated 2012
3. **Hot Spot:** CashDesk #27096 handles 95%+ transfers

### Documents Domain:
1. **Object Inheritance:** doDocument → doInvoice pattern
2. **€80.9M Revenue:** Fully documented in invoice line items

---

## 📞 WHEN TO ASK СВЕТЛЬО

### Always Ask:
- **Which table to analyze next?** (confirm priority)
- **SQL query results ready?** (wait for execution)
- **Any business context?** (before finalizing analysis)
- **Session ending?** (create proper handoff)

### Never Assume:
- Table priorities (follow progress tracker)
- SQL results (wait for actual data)
- Business logic (ask if unclear)
- File structure (check with list_directory)

---

## 🎯 SUCCESS METRICS

### Session Goals:
- **Minimum:** 1 complete table analysis
- **Target:** 2-3 tables per session
- **Excellent:** 4+ tables (if simple)

### Quality Metrics:
- **100% schema documentation**
- **All foreign keys identified**
- **Data integrity validated**
- **Business patterns documented**
- **Migration complexity rated**
- **Stakeholder questions listed**

### Progress Tracking:
- Progress tracker updated after **EACH** table
- Handoff created at **session end**
- Files in **correct directories**
- **No placeholder text** in docs

---

## 🚀 QUICK START TEMPLATE

```
👋 Hi! I'm taking over the [Domain] analysis.

Let me orient myself...

[READ HANDOFF FILE]
[READ PROGRESS FILE]
[READ STATUS FILE]

Current status:
- Domain: [Name]
- Progress: X/Y tables (Z%)
- Last completed: [TableName]
- Next: [NextTableName]

Ready to start with [NextTableName]?
Here's my first SQL query:

```sql
SELECT ...
```

Please execute this in TEKA database and provide results.
```

---

## 📚 KEY RESOURCES

### Must-Read Before Starting:
1. `docs/handoffs/TRADE-next-session.md` - Where we left off
2. `docs/progress/trade-domain.md` - Overall progress
3. `PROJECT_STATUS_AND_NEXT_STEPS.md` - Big picture

### Reference During Work:
- `analysis/week1/core-tables/[domain]/[NN]-*.md` - Existing analyses (for patterns)
- `docs/analysis/database-table-list.md` - All 125 tables
- Template sections in this document

### Update After Each Table:
- `analysis/week1/core-tables/[domain]/[domain]-progress.md`
- `docs/progress/[domain]-domain.md`
- `docs/handoffs/[DOMAIN]-next-session.md` (if ending)

---

## 🎉 YOU'VE GOT THIS!

**Remember:**
- You're continuing **excellent work** (3 domains 100% complete!)
- **Proven methodology** works (71% Trade Domain done!)
- **Quality over speed** (micro-steps prevent errors)
- **Светльо is your partner** (ask questions!)
- **MCP tools are your friends** (use them!)

**Current Streak:**
- ✅ Perfect data integrity in all item tables
- ✅ Critical architectural patterns discovered
- ✅ 2.66M+ records analyzed with 100% accuracy
- ✅ Zero placeholder documentation

**Keep it going!** 🚀

---

**Created:** 2025-11-10  
**For:** Next Session Claude Agent  
**From:** Claude Sonnet 4.5 + Светльо Партенев  
**Project:** TEKA_NET Database Migration  
**Status:** Trade Domain 71% → Next: doTransaction

---

## 🔧 TROUBLESHOOTING

### Issue: "I can't find the handoff file"
```javascript
// List handoffs directory
Filesystem:list_directory("C:\\TEKA_NET\\Teka_StoreNET_ERP\\docs\\handoffs")

// Look for most recent
```

### Issue: "SQL query failed"
- Check table name spelling (case-sensitive!)
- Use brackets for special chars: `[doTradeCancel-Items]`
- Confirm database: TEKA (not TEKA MAT!)
- Ask Светльо for error message

### Issue: "Where do I save this file?"
```
Table analysis:  analysis/week1/core-tables/[domain]/
Handoff:         docs/handoffs/
Progress:        docs/progress/
Status:          docs/status/
```

### Issue: "Progress tracker outdated"
- Read current file first
- Update only your changes
- Keep existing content
- Don't delete others' work

### Issue: "Unsure about complexity rating"
```
1-2 = Simple lookup/junction (few columns, clear purpose)
3   = Medium (some business logic, moderate relationships)
4   = High (complex logic, multiple FKs, large data)
5   = Very High (inheritance, events, critical to business)
```

---

**END OF HANDOFF INSTRUCTIONS**

**Next Agent:** Read this fully, then start with Trade Domain!  
**First Action:** Read `docs/handoffs/TRADE-next-session.md`  
**Goal:** Complete remaining 4 Trade Domain tables (29%)  
**Then:** Start Store/Inventory Domain (21 tables)

**Good luck!** 🎯

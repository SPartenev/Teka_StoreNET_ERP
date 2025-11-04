# TASK 1.3.2: Financial Domain Schema Analysis

**Status:** 🟡 READY TO START  
**Prerequisites:** ✅ Task 1.1 (Tables Inventory), ✅ Task 1.2 (Relationships)  
**Estimated Duration:** 2-3 hours  
**Priority:** HIGH (blocks multiple other domains)

---

## 🎯 Task Objective

Analyze the Financial domain tables to extract complete schema, business rules, and migration requirements with 100% accuracy using C# + SQL validation approach.

---

## 📋 Scope

### Tables to Analyze (8 tables)

#### Core Financial Tables
1. **CashOperations** - Cash register transactions
2. **CashTypes** - Operation types (sale, purchase, expense, etc.)
3. **Currencies** - Supported currencies (BGN, EUR, USD, etc.)
4. **CurrenciesRates** - Exchange rates with history
5. **PaymentTypes** - Payment methods (cash, card, bank transfer, etc.)

#### Supporting Tables
6. **Discounts** - Product/category discounts
7. **AccountingSchemes** - Integration with accounting software
8. **BankAccounts** - Company bank accounts

---

## 📂 Input Files

### C# Source Files (Expected Location)
```
C:\Users\SvetoslavPartenev\Documents\Teka_analize\Store.NET\Source\DataModel\
├── CashOperation.cs
├── CashType.cs
├── Currency.cs
├── CurrencyRate.cs
├── PaymentType.cs
├── Discount.cs
├── AccountingScheme.cs
└── BankAccount.cs
```

**Note:** If files not in this location, search recursively in `Source/` and `Store.NET_2011-09-03/` directories.

### Database Backup
```
C:\Users\SvetoslavPartenev\Documents\Teka_analize\Store.NET\BackupBase\TEKA.bak
```

---

## 🔍 Analysis Process

### Phase 1: C# Code Analysis (90 minutes)

#### Step 1: Locate C# Files
```bash
# Search for financial-related files
find Source/ -name "*Cash*.cs" -o -name "*Currenc*.cs" -o -name "*Payment*.cs" -o -name "*Discount*.cs"
```

#### Step 2: Parse Each Class
For each file, extract:
- **Table name** (from class name, usually `do` prefix)
- **Columns:**
  - Name (from property name)
  - Type (from C# type + attributes)
  - Nullable (from `[Nullable]` attribute or `?` type)
  - Length (from `[Length(n)]` attribute)
  - Default value (from `[Default]` or field initializer)
  - Indexed (from `[Indexed]` attribute)
  - Unique (from `[Indexed(Unique=true)]`)
- **Foreign Keys:**
  - Abstract properties → FK columns
  - Navigation properties
  - Cascade behavior (from `[Contained]` attribute)
- **Indexes:**
  - From `[Indexed]` on properties
  - From `[Index]` on class level
- **Validators:**
  - `[Validator]` attributes
  - Business rules in code
- **Collections:**
  - `[ItemType]` for child tables
  - One-to-many relationships

#### Step 3: Document Uncertainties
Create list of items needing SQL validation:
- Exact decimal precisions
- SQL type overrides
- Complex index compositions
- Actual table/column names (DataObjects.NET may differ)
- Triggers, computed columns

**Expected Output:**
- `financial-schema-draft.json` (90% accuracy)
- `financial-validation-queries.sql` (10 queries)

---

### Phase 2: SQL Validation (30 minutes)

#### Query Template (adapt for each table)

```sql
-- ============================================================
-- QUERY 1: Complete [TableName] Schema
-- ============================================================
SELECT 
    ORDINAL_POSITION as [Order],
    COLUMN_NAME as [Column],
    DATA_TYPE as [Type],
    CHARACTER_MAXIMUM_LENGTH as [Length],
    NUMERIC_PRECISION as [Precision],
    NUMERIC_SCALE as [Scale],
    IS_NULLABLE as [Nullable],
    COLUMN_DEFAULT as [Default],
    CONSTRAINT_TYPE as [Constraint]
FROM INFORMATION_SCHEMA.COLUMNS c
LEFT JOIN INFORMATION_SCHEMA.CONSTRAINT_COLUMN_USAGE ccu 
    ON c.TABLE_NAME = ccu.TABLE_NAME AND c.COLUMN_NAME = ccu.COLUMN_NAME
LEFT JOIN INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc 
    ON ccu.CONSTRAINT_NAME = tc.CONSTRAINT_NAME
WHERE c.TABLE_SCHEMA = 'dbo' 
  AND c.TABLE_NAME = 'doCashOperation'  -- Change table name
ORDER BY ORDINAL_POSITION;

-- ============================================================
-- QUERY 2: [TableName] Indexes
-- ============================================================
SELECT 
    i.name as [Index Name],
    i.type_desc as [Index Type],
    i.is_unique as [Is Unique],
    STUFF((
        SELECT ', ' + c.name
        FROM sys.index_columns ic
        JOIN sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
        WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id
        ORDER BY ic.key_ordinal
        FOR XML PATH('')
    ), 1, 2, '') as [Columns]
FROM sys.indexes i
WHERE i.object_id = OBJECT_ID('dbo.doCashOperation')  -- Change table name
  AND i.name IS NOT NULL
ORDER BY i.name;

-- ============================================================
-- QUERY 3: [TableName] Foreign Keys
-- ============================================================
SELECT 
    fk.name as [FK Name],
    OBJECT_NAME(fk.parent_object_id) as [From Table],
    c1.name as [From Column],
    OBJECT_NAME(fk.referenced_object_id) as [To Table],
    c2.name as [To Column],
    fk.delete_referential_action_desc as [On Delete],
    fk.update_referential_action_desc as [On Update]
FROM sys.foreign_keys fk
JOIN sys.foreign_key_columns fkc ON fk.object_id = fkc.constraint_object_id
JOIN sys.columns c1 ON fkc.parent_object_id = c1.object_id AND fkc.parent_column_id = c1.column_id
JOIN sys.columns c2 ON fkc.referenced_object_id = c2.object_id AND fkc.referenced_column_id = c2.column_id
WHERE fk.parent_object_id = OBJECT_ID('dbo.doCashOperation')  -- Change table name
ORDER BY fk.name;

-- ============================================================
-- QUERY 4: Sample Data Statistics
-- ============================================================
SELECT 
    COUNT(*) as [Total Rows],
    COUNT(DISTINCT [KeyColumn]) as [Unique Values],
    MIN([DateColumn]) as [Earliest Date],
    MAX([DateColumn]) as [Latest Date]
FROM dbo.doCashOperation;  -- Adapt columns and table name

-- ============================================================
-- QUERY 5: Check for Triggers
-- ============================================================
SELECT 
    t.name as [Trigger Name],
    t.type_desc as [Trigger Type],
    OBJECT_NAME(t.parent_id) as [Table Name]
FROM sys.triggers t
WHERE t.parent_id = OBJECT_ID('dbo.doCashOperation');  -- Change table name
```

#### Execute Queries
1. Connect to SQL Server (Docker container or direct)
2. Run all validation queries
3. Export results to text file: `financial-validation-results.txt`
4. Copy results for next session

---

### Phase 3: Merge & Finalize (30 minutes)

#### Update Schema JSON
- Replace uncertainties with SQL-confirmed values
- Add validated indexes, FKs, constraints
- Include sample data statistics
- Document any triggers found

**Output:** `financial-domain-schema-FINAL.json`

#### Create Business Rules Doc
Based on C# validators and code analysis:
- Cash operation rules
- Currency conversion logic
- Exchange rate update process
- Payment type validations
- Discount calculation rules
- Accounting integration rules

**Output:** `financial-business-rules-FINAL.md`

#### Create Migration Strategy
- PostgreSQL type mappings
- DDL scripts for all tables
- Data migration process
- EF Core entity classes
- Testing strategy
- Risk assessment

**Output:** `financial-migration-strategy-FINAL.md`

---

## 📊 Expected Findings

### CashOperations Table (Estimated)
- **Purpose:** Record all cash register transactions
- **Columns:** ~15-20 (ID, CashDesk, User, Type, Amount, Currency, Date, Document, etc.)
- **Foreign Keys:** CashType, Currency, User, CashDesk, Document
- **Business Rules:** 
  - Amount must be > 0 for sales/income
  - Must reference document for most operations
  - Multi-currency support with conversion
  - Daily reconciliation required

### Currencies Table (Estimated)
- **Purpose:** Define supported currencies
- **Columns:** ~5-7 (ID, Code, Name, Symbol, Active, IsDefault)
- **Sample:** BGN (Bulgarian Lev), EUR, USD, GBP
- **Business Rules:**
  - One currency must be default (base currency)
  - Cannot delete if used in transactions

### CurrenciesRates Table (Estimated)
- **Purpose:** Historical exchange rates
- **Columns:** ~5-6 (ID, FromCurrency, ToCurrency, Rate, Date)
- **Business Rules:**
  - Rates updated daily (or manually)
  - Used for multi-currency price conversions
  - Historical rates preserved for accounting

### PaymentTypes (Estimated)
- **Purpose:** Payment methods
- **Columns:** ~5-7 (ID, Name, Description, RequiresBankAccount, Active)
- **Sample:** Cash, Credit Card, Debit Card, Bank Transfer, PayPal
- **Business Rules:**
  - Some types require bank account link
  - Used in sales, purchases, expenses

---

## 🎯 Success Criteria

### Phase 1 (C# Analysis)
- [ ] All 8 C# files located and parsed
- [ ] Table structures extracted (90% accuracy)
- [ ] Foreign keys identified
- [ ] Indexes documented from attributes
- [ ] Business rules extracted from validators
- [ ] Uncertainties clearly marked
- [ ] Validation queries generated

### Phase 2 (SQL Validation)
- [ ] All validation queries executed successfully
- [ ] Results documented in text file
- [ ] All uncertainties resolved
- [ ] Sample data statistics collected
- [ ] Triggers checked (if any)
- [ ] Actual table/column names confirmed

### Phase 3 (Finalization)
- [ ] Schema JSON 100% accurate
- [ ] Business rules comprehensive
- [ ] Migration strategy complete
- [ ] PostgreSQL DDL scripts created
- [ ] EF Core examples provided
- [ ] Testing checklist included

---

## ⚠️ Known Challenges

### Decimal Precision
- Financial data likely uses high precision (e.g., decimal(28,10))
- Verify exact precision for amounts, rates, prices
- Critical for currency conversion accuracy

### Multi-Currency Logic
- Exchange rate application rules
- Base currency vs transaction currency
- Historical rate preservation

### Accounting Integration
- AccountingSchemes table may have complex export rules
- Profit calculation logic
- Integration with external accounting software

### Discount Calculations
- Percentage vs fixed amount
- Cascading discounts
- Product vs category discounts
- Time-based promotions

---

## 📦 Deliverables

### 1. financial-domain-schema-FINAL.json
**Structure:**
```json
{
  "metadata": {
    "domain": "Financial",
    "total_tables": 8,
    "total_columns": "~60-80",
    "completeness": "100%"
  },
  "tables": {
    "doCashOperation": { ... },
    "doCashType": { ... },
    "doCurrency": { ... },
    "doCurrencyRate": { ... },
    "doPaymentType": { ... },
    "doDiscount": { ... },
    "doAccountingScheme": { ... },
    "doBankAccount": { ... }
  }
}
```

### 2. financial-business-rules-FINAL.md
**Sections:**
- Cash operations management
- Multi-currency support
- Exchange rate logic
- Payment processing
- Discount system
- Accounting integration
- Security & permissions
- Validation rules

### 3. financial-migration-strategy-FINAL.md
**Content:**
- PostgreSQL type mappings
- DDL scripts (CREATE TABLE, indexes, FKs)
- Data migration process
- Currency conversion handling
- EF Core setup
- Testing strategy
- Migration timeline (est. 40-50 hours)

### 4. PROGRESS-FINAL.md
**Tracking:**
- Time breakdown
- Challenges encountered
- Lessons learned
- Quality metrics
- Next steps

---

## 🔗 Dependencies

### Requires (Already Complete)
- ✅ Task 1.1: Tables inventory
- ✅ Task 1.2: Relationships map
- ✅ Task 1.3.1: Products domain (Currency FKs in ProductPrices)

### Blocks These Tasks
- Task 1.3.3: Documents domain (CashOperations in invoices)
- Task 1.3.4: Warehouse domain (currency in inventory valuation)
- Week 2: Financial module code analysis

### External Dependencies
- doDocument table (for CashOperation.Document FK)
- doCashDesk table (for CashOperation.CashDesk FK)
- doUser table (for CashOperation.User FK)
- doProduct table (for Discount.Product FK)
- doCategory table (for Discount.Category FK)

---

## 📅 Recommended Timeline

| Activity | Duration | Status |
|----------|----------|--------|
| Locate C# files | 15 min | ⏸️ Not started |
| Parse C# classes | 60 min | ⏸️ Not started |
| Generate SQL queries | 15 min | ⏸️ Not started |
| Execute SQL validation | 30 min | ⏸️ Not started |
| Merge results | 30 min | ⏸️ Not started |
| Create business rules | 30 min | ⏸️ Not started |
| Create migration strategy | 30 min | ⏸️ Not started |
| **Total** | **3.5 hours** | ⏸️ Ready to start |

---

## 🚀 Quick Start Commands

### Step 1: Find Financial C# Files
```bash
cd C:\Users\SvetoslavPartenev\Documents\Teka_analize\Store.NET\Source
dir /s /b *Cash*.cs *Currenc*.cs *Payment*.cs *Discount*.cs *Account*.cs *Bank*.cs
```

### Step 2: Start Analysis
Copy-paste into new chat session:

```markdown
# TASK 1.3.2: Financial Domain Analysis - START

**Previous Task:** Task 1.3.1 Products Domain ✅ Complete

## Input Files
C# Source: C:\Users\SvetoslavPartenev\Documents\Teka_analize\Store.NET\Source\DataModel\
Database: C:\Users\SvetoslavPartenev\Documents\Teka_analize\Store.NET\BackupBase\TEKA.bak

## Tables to Analyze (8)
1. CashOperations
2. CashTypes
3. Currencies
4. CurrenciesRates
5. PaymentTypes
6. Discounts
7. AccountingSchemes
8. BankAccounts

## Task
Analyze Financial domain using same process as Products:
1. Parse C# files (90% schema)
2. Generate SQL validation queries
3. Execute queries and provide results
4. Merge to 100% accuracy
5. Create business rules doc
6. Create migration strategy

## Output Directory
C:\Users\SvetoslavPartenev\Documents\Teka_StoreNET_ERP\analysis\week1\core-tables\part-2-financial\

START NOW - follow Products domain template!
```

---

## ✅ Pre-Flight Checklist

Before starting this task:
- [x] Task 1.3.1 (Products) is 100% complete
- [x] GitHub repo is accessible
- [x] SQL Server backup is available
- [x] Source code files are accessible
- [x] Output directory structure ready
- [x] Template files created
- [x] Estimated timeline reviewed

**Status:** ✅ READY TO START

---

**Template Version:** 1.0  
**Created:** November 4, 2025  
**Based On:** Task 1.3.1 Success Pattern  
**Next Task:** Task 1.3.3 (Documents Domain)

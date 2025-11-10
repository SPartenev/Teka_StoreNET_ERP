# HANDOFF INSTRUCTIONS - Documents Domain Analysis

**Date:** 2025-11-10  
**Session:** 1 COMPLETE  
**Next Session:** Continue with doDocument, doDocumentsOperations, doDocumentsTypes

---

## ✅ COMPLETED (2/5 tables - 40%)

1. ✅ **doInvoice** - 172K invoices, €80.6M revenue - `01-doInvoice.md`
2. ✅ **doInvoice-Items** - 488K line items - `02-doInvoice-Items.md`

---

## 🎯 NEXT SESSION - START HERE

### Step 1: Read Progress File
```
File: C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\documents-domain-progress.md
```

### Step 2: Analyze doDocument (Base Entity)

**SQL Queries to Execute:**

```sql
-- 1. Schema
SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, IS_NULLABLE, COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'doDocument'
ORDER BY ORDINAL_POSITION;

-- 2. Sample Data
SELECT TOP 20 * FROM doDocument ORDER BY ID DESC;

-- 3. Foreign Keys
SELECT fk.name AS FK_Name,
       COL_NAME(fkc.parent_object_id, fkc.parent_column_id) AS Column_Name,
       OBJECT_NAME(fk.referenced_object_id) AS Referenced_Table
FROM sys.foreign_keys AS fk
INNER JOIN sys.foreign_key_columns AS fkc ON fk.object_id = fkc.constraint_object_id
WHERE OBJECT_NAME(fk.parent_object_id) = 'doDocument';

-- 4. Statistics
SELECT COUNT(*) as TotalDocs,
       MIN(Date) as FirstDate,
       MAX(Date) as LastDate
FROM doDocument;
```

### Step 3: Create Documentation
- Create file: `03-doDocument.md` (keep it SHORT!)
- Update: `documents-domain-progress.md` (mark doDocument as ✅)

### Step 4: Repeat for Remaining Tables
- doDocumentsOperations
- doDocumentsTypes

---

## 📁 FILE LOCATIONS

```
C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\
├── documents-domain\
│   ├── 01-doInvoice.md ✅
│   ├── 02-doInvoice-Items.md ✅
│   ├── 03-doDocument.md 🔲 TODO
│   ├── 04-doDocumentsOperations.md 🔲 TODO
│   └── 05-doDocumentsTypes.md 🔲 TODO
└── documents-domain-progress.md (UPDATE THIS!)
```

---

## ⚡ QUICK START COMMAND

**Tell Claude:**
```
"Продължавам Documents Domain анализ. 
Прочети: documents-domain-progress.md
Следваща таблица: doDocument
Работи стъпка по стъпка, питай за SQL заявки."
```

---

## 🚨 IMPORTANT RULES

1. ✅ Use **Filesystem:write_file** ONLY (not create_file)
2. ✅ Keep docs SHORT (1-2 pages max per table)
3. ✅ Work ONE table at a time
4. ✅ Update progress file after EACH table
5. ✅ Ask for SQL results, don't assume

---

**Session 1 Duration:** 90 minutes  
**Tables Completed:** 2/5 (40%)  
**Remaining:** 3 tables (~2 hours estimated)

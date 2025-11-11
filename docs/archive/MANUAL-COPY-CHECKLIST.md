# 📋 СПИСЪК ЗА РЪЧНО КОПИРАНЕ НА ФАЙЛОВЕ

**Дата:** 2025-11-10  
**Цел:** Попълване на новата структура `analysis/domains/`  
**Метод:** Ръчно копиране (copy/paste в Windows Explorer)

---

## 🎯 ИНСТРУКЦИИ

1. **НЕ ИЗТРИВАЙ** оригиналните файлове (само копирай)
2. **Запази имената** точно както е в колона "Target"
3. **Провери** дали новите папки съществуват преди копиране
4. **Съобщи на Claude** след като завършиш за проверка

---

## 📁 1. PRODUCTS DOMAIN

### Създай папка (ако не съществува):
```
C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\products\
```

### Файлове за копиране:

| # | Source (OLD) | Target (NEW) | Size | Notes |
|---|--------------|--------------|------|-------|
| 1 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\part-1-products\products-migration-strategy-FINAL.md` | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\products\products-migration-strategy.md` | 20 KB | ✅ COPY |
| 2 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\part-1-products\products-domain-schema-FINAL.json` | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\products\products-schema.json` | 30 KB | ✅ COPY |
| 3 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\part-1-products\validation-queries.sql` | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\products\validation-queries.sql` | 2 KB | ✅ COPY |
| 4 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\part-1-products\schema-draft.json` | - | - | ⏭️ SKIP (superseded) |
| 5 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\part-1-products\PROGRESS.md` | - | - | ⏭️ SKIP (old version) |
| 6 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\part-1-products\Validation_doProduct Table.txt` | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\products\validation-results.txt` | 5 KB | 📦 OPTIONAL |

**Вече копирани от Claude:**
- ✅ DOMAIN-SUMMARY.md
- ✅ products-business-rules.md
- ✅ FILE-INVENTORY.md

**Общо за копиране:** 3 задължителни + 1 опционален

---

## 📁 2. FINANCIAL DOMAIN

### Създай папка (ако не съществува):
```
C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\financial\
```

### ⚠️ ПРОБЛЕМ: Няма индивидуални анализи на таблици!

**Налични файлове в старата структура:**

| # | Source (OLD) | Target (NEW) | Size | Notes |
|---|--------------|--------------|------|-------|
| 1 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\financial-domain\FINANCIAL-DOMAIN-COMPLETE.md` | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\financial\DOMAIN-COMPLETE.md` | 15 KB | ✅ COPY |
| 2 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\financial-domain\INDEX.md` | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\financial\INDEX.md` | 5 KB | ✅ COPY |
| 3 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\financial-domain-data\paymenttypes-enum-raw-data.md` | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\financial\paymenttypes-data.md` | 3 KB | ✅ COPY |

**Липсват 7 таблични анализа:**
- 01-doCashDesk.md ❌
- 02-doCashDesk-Entries.md ❌
- 03-doCashDeskAmountTransfer.md ❌
- 04-doCashDeskCurrencyChange.md ❌
- 05-doCashDesk-Stores.md ❌
- 06-doInvoice-CashDesks.md ❌
- 07-doCurrency.md ❌

**Общо за копиране:** 3 файла (7 липсват!)

**ACTION:** Проверка в GitHub дали съществуват!

---

## 📁 3. DOCUMENTS DOMAIN

### Папката вече съществува:
```
C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\documents\
```

### ✅ Вече има 3 файла:
- ✅ 01-doDocument.md
- ✅ 02-doInvoice.md
- ✅ 03-doInvoice-Items.md

### Допълнителни файлове за копиране:

| # | Source (OLD) | Target (NEW) | Size | Notes |
|---|--------------|--------------|------|-------|
| 1 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\documents-domain\01-doInvoice.md` | - | - | ⚠️ РАЗЛИЧНА НОМЕРАЦИЯ |
| 2 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\documents-domain\02-doInvoice-Items.md` | - | - | ⚠️ РАЗЛИЧНА НОМЕРАЦИЯ |
| 3 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\documents-domain\03-doDocument.md` | - | - | ⚠️ РАЗЛИЧНА НОМЕРАЦИЯ |

**⚠️ ВНИМАНИЕ:** Новата структура (`domains/documents/`) има ПРАВИЛНА номерация:
- 01-doDocument (base class)
- 02-doInvoice (derived)
- 03-doInvoice-Items (items)

**Старата структура (`week1/core-tables/documents-domain/`) има ГРЕШНА номерация:**
- 01-doInvoice
- 02-doInvoice-Items
- 03-doDocument

**РЕШЕНИЕ:** Запазваме новата номерация! Старите файлове остават за архив.

**Общо за копиране:** 0 (вече правилно номерирани!)

---

## 📁 4. TRADE DOMAIN

### Папката вече съществува:
```
C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\trade\
```

### ✅ Вече има 11 файла:
- ✅ 01-doTrade.md
- ✅ 02-doTradeItem.md
- ✅ 03-doTradeTransaction.md
- ✅ 04-doTradePayment.md
- ✅ 05-doTradePayment-Items.md
- ✅ 06-doTradeDelivery.md
- ✅ 07-doTradeDelivery-Items.md
- ✅ 08-doTradeReturn.md
- ✅ 09-doTradeReturn-Items.md
- ✅ 10-doTradeCancel.md
- ✅ 11-doTransaction.md

### Допълнителни файлове:

**От `analysis/domains/`:**
| # | Source (OLD) | Target (NEW) | Notes |
|---|--------------|--------------|-------|
| 1 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\TRADE-DOMAIN-ANALYSIS.md` | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\domains\trade\DOMAIN-ANALYSIS.md` | ✅ MOVE (rename) |

**От `week1/core-tables/trade-domain/`:**
| # | Source (OLD) | Target (NEW) | Notes |
|---|--------------|--------------|-------|
| 2 | Всички файлове | - | ⏭️ SKIP (дубликати с `-analysis` суфикс) |

**Общо за копиране:** 1 файл (преместване/преименуване)

---

## 📁 5. DOCS/PROGRESS FILES

### Папката вече съществува:
```
C:\TEKA_NET\Teka_StoreNET_ERP\docs\progress\
```

### ✅ Вече копирани:
- ✅ documents-domain.md
- ✅ financial-domain-FINAL.md
- ✅ trade-domain.md

### Допълнителни за копиране:

| # | Source (OLD) | Target (NEW) | Notes |
|---|--------------|--------------|-------|
| 1 | `C:\TEKA_NET\Teka_StoreNET_ERP\analysis\week1\core-tables\part-1-products\PROGRESS-FINAL.md` | `C:\TEKA_NET\Teka_StoreNET_ERP\docs\progress\products-domain.md` | ✅ COPY |

**Общо за копиране:** 1 файл

---

## 📁 6. DOCS/ANALYSIS FILES

### Папката вече съществува:
```
C:\TEKA_NET\Teka_StoreNET_ERP\docs\analysis\
```

### ✅ Вече копирани много файлове

### Проверка дали всичко е на място:

**Products файлове:**
| File | Status |
|------|--------|
| products-business-rules-FINAL.md | ✅ |
| products-migration-strategy-FINAL.md | ✅ |
| products-domain-schema-FINAL.json | ✅ |
| products-README.md | ✅ |
| products-SESSION-SUMMARY.md | ✅ |
| products-validation.txt | ✅ |
| schema-draft.json | ✅ |
| validation-queries.sql | ✅ |

**Financial файлове:**
| File | Status |
|------|--------|
| financial-domain-COMPLETE.md | ✅ |
| financial-domain-INDEX.md | ✅ |
| paymenttypes-enum-raw-data.md | ✅ |

**Trade файлове:**
| File | Status |
|------|--------|
| TRADE-DOMAIN-ANALYSIS.md | ✅ |

**Общо:** Изглежда всичко е копирано! Проверка след твоето копиране.

---

## 📁 7. DOCS/HANDOFFS FILES

### Папката вече съществува:
```
C:\TEKA_NET\Teka_StoreNET_ERP\docs\handoffs\
```

### ✅ Вече копирани:
- ✅ DOCUMENTS-DOMAIN.md
- ✅ TRADE-DOMAIN.md
- ✅ TRADE-SESSION2.md
- ✅ TRADE-SESSION3.md
- ✅ TRADE-next-session.md
- ✅ TRADE-doTradeReturn.md
- ✅ TRADE-doTradeReturn-Items.md
- ✅ QUICK-HANDOFF.md

**Общо:** Изглежда всичко е копирано!

---

## 📋 ОБОБЩЕНИЕ - ДЕЙСТВИЯ ЗА ТЕБ

### ✅ ЗАДЪЛЖИТЕЛНО КОПИРАНЕ (7 файла):

#### Products Domain (3):
1. `week1\core-tables\part-1-products\products-migration-strategy-FINAL.md` → `domains\products\products-migration-strategy.md`
2. `week1\core-tables\part-1-products\products-domain-schema-FINAL.json` → `domains\products\products-schema.json`
3. `week1\core-tables\part-1-products\validation-queries.sql` → `domains\products\validation-queries.sql`

#### Financial Domain (3):
4. `week1\core-tables\financial-domain\FINANCIAL-DOMAIN-COMPLETE.md` → `domains\financial\DOMAIN-COMPLETE.md`
5. `week1\core-tables\financial-domain\INDEX.md` → `domains\financial\INDEX.md`
6. `week1\core-tables\financial-domain-data\paymenttypes-enum-raw-data.md` → `domains\financial\paymenttypes-data.md`

#### Docs/Progress (1):
7. `week1\core-tables\part-1-products\PROGRESS-FINAL.md` → `docs\progress\products-domain.md`

### 📦 ОПЦИОНАЛНО (1 файл):
8. `week1\core-tables\part-1-products\Validation_doProduct Table.txt` → `domains\products\validation-results.txt`

### 📋 ПРЕМЕСТВАНЕ (1 файл):
9. `analysis\domains\TRADE-DOMAIN-ANALYSIS.md` → `analysis\domains\trade\DOMAIN-ANALYSIS.md`

---

## ✅ КОНТРОЛЕН СПИСЪК

След копиране, маркирай ✅:

- [ ] Копирани 3 Products файла
- [ ] Копирани 3 Financial файла
- [ ] Копиран 1 Progress файл
- [ ] Преместен 1 Trade файл
- [ ] (Optional) Копиран validation results

**ОБЩО:** 7 задължителни + 1 optional + 1 move = 9 операции

---

## 🔍 СЛЕД КОПИРАНЕ

**Съобщи на Claude:** "Готово, копирах файловете"

**Claude ще:**
1. Провери дали всички файлове са на място
2. Валидира структурата
3. Създаде финален инвентар
4. Предложи следващи стъпки

---

**Създадено:** 2025-11-10  
**Статус:** Готов за копиране  
**Операции:** 9 (7 задължителни + 1 optional + 1 move)

**Успех!** 🚀

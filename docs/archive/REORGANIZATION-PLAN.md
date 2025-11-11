# 📁 ПЛАН ЗА РЕОРГАНИЗАЦИЯ НА СТРУКТУРАТА

**Проблем:** Файловете са разпръснати - HANDOFF, PROGRESS, INDEX файлове са смесени с анализите на таблиците  
**Цел:** Чиста структура - само таблиците в отделни файлове, останалите документи в организирани папки

---

## 🎯 ПРЕПОРЪЧАНА СТРУКТУРА

```
Teka_StoreNET_ERP/
├── README.md (главен)
├── PROJECT_STATUS_AND_NEXT_STEPS.md (главен статус)
│
├── docs/ (НОВА ПАПКА - всички документи)
│   ├── handoffs/ (всички HANDOFF файлове)
│   ├── progress/ (всички PROGRESS файлове)
│   ├── status/ (статус файлове)
│   └── analysis/ (analysis документи - README, INDEX, и т.н.)
│
├── analysis/ (САМО АНАЛИЗИ НА ТАБЛИЦИ)
│   ├── domains/
│   │   ├── products/ (само файлове за таблици)
│   │   ├── financial/ (само файлове за таблици)
│   │   ├── documents/ (само файлове за таблици)
│   │   └── trade/ (само файлове за таблици)
│   └── database/ (database анализ)
│
└── IMPLEMENTATION/ (остава както е)
```

---

## 📋 ДЕТАЙЛЕН ПЛАН

### Стъпка 1: Създаване на docs/ структура

```
docs/
├── handoffs/
│   ├── TRADE-DOMAIN.md (главен)
│   ├── TRADE-SESSION2.md
│   ├── TRADE-SESSION3.md
│   ├── TRADE-next-session.md (най-актуален)
│   ├── TRADE-doTradeReturn.md
│   ├── TRADE-doTradeReturn-Items.md
│   └── DOCUMENTS-DOMAIN.md
│
├── progress/
│   ├── financial-domain-FINAL.md
│   ├── documents-domain.md
│   ├── trade-domain.md
│   └── products-FINAL.md
│
├── status/
│   └── (ако има други статус файлове)
│
└── analysis/
    ├── README.md (от analysis/)
    ├── database-table-list.md
    └── DATABASE-COMPARISON.md
```

### Стъпка 2: Реорганизация на analysis/

**Текущо:**
```
analysis/
├── HANDOFF-*.md (разпръснати)
├── README.md
├── database-table-list.md
├── week1/
│   ├── core-tables/
│   │   ├── documents-domain/ (таблици ✅)
│   │   ├── documents-domain-progress.md (❌ премести)
│   │   ├── HANDOFF-DOCUMENTS-DOMAIN.md (❌ премести)
│   │   ├── financial-domain/ (INDEX, COMPLETE - ❌ премести)
│   │   ├── financial-domain-progress-FINAL.md (❌ премести)
│   │   ├── financial-domain-data/ (❌ премести в docs/)
│   │   ├── part-1-products/ (смесено - ❌ раздели)
│   │   ├── trade-domain/ (таблици + HANDOFF - ❌ раздели)
│   │   └── TASK-*.md (❌ премести в docs/)
```

**След реорганизация:**
```
analysis/
├── domains/
│   ├── products/
│   │   ├── 01-doProduct.md
│   │   ├── 02-ProductCategories.md
│   │   ├── 03-ProductTypes.md
│   │   ├── 04-ProductUnits.md
│   │   ├── 05-ProductPrices.md
│   │   └── 06-Stores.md
│   │
│   ├── financial/
│   │   ├── 01-doCashDesk.md
│   │   ├── 02-doCashDesk-Entries.md
│   │   ├── 03-doCashDeskAmountTransfer.md
│   │   ├── 04-doCashDeskCurrencyChange.md
│   │   ├── 05-doCashDesk-Stores.md
│   │   ├── 06-doInvoice-CashDesks.md
│   │   └── 07-doCurrency.md
│   │
│   ├── documents/
│   │   ├── 01-doDocument.md
│   │   ├── 02-doInvoice.md
│   │   └── 03-doInvoice-Items.md
│   │
│   └── trade/
│       ├── 01-doTrade.md
│       ├── 02-doTradeItem.md
│       ├── 03-doTradeTransaction.md
│       ├── 04-doTradePayment.md
│       ├── 05-doTradePayment-Items.md
│       ├── 06-doTradeDelivery.md
│       ├── 07-doTradeDelivery-Items.md
│       ├── 08-doTradeReturn.md
│       ├── 09-doTradeReturn-Items.md
│       ├── 10-doTradeCancel.md
│       └── 11-doTransaction.md
│
└── database/
    ├── tables-data.json
    ├── tables-report.md
    ├── relationships.json
    ├── database_erd-diagram.mermaid
    └── (останалите database файлове)
```

---

## 🔄 СПИСЪК НА ПРЕМЕСТВАНИЯ

### Root → docs/

1. `HANDOFF-next-session-doTradeReturn.md` → `docs/handoffs/TRADE-doTradeReturn.md`
2. `QUICK-HANDOFF.md` → `docs/handoffs/QUICK-HANDOFF.md`
3. `FILES-TO-SYNC.md` → `docs/analysis/FILES-TO-SYNC.md`
4. `FILES-UPDATED.md` → `docs/analysis/FILES-UPDATED.md`
5. `DUPLICATE-FILES-ANALYSIS.md` → `docs/analysis/DUPLICATE-FILES-ANALYSIS.md`
6. `FILE-COMPARISON-ANALYSIS.md` → `docs/analysis/FILE-COMPARISON-ANALYSIS.md`
7. `sync-to-github.md` → `docs/analysis/sync-to-github.md`

### analysis/ → docs/

8. `analysis/HANDOFF-TRADE-DOMAIN.md` → `docs/handoffs/TRADE-DOMAIN.md`
9. `analysis/HANDOFF-TRADE-DOMAIN-SESSION2.md` → `docs/handoffs/TRADE-SESSION2.md`
10. `analysis/HANDOFF-TRADE-DOMAIN-SESSION3.md` → `docs/handoffs/TRADE-SESSION3.md`
11. `analysis/README.md` → `docs/analysis/README.md`
12. `analysis/database-table-list.md` → `docs/analysis/database-table-list.md`
13. `analysis/week1/DATABASE-COMPARISON-TEKA-vs-TEKA-MAT.md` → `docs/analysis/DATABASE-COMPARISON.md`

### analysis/week1/core-tables/ → docs/

14. `documents-domain-progress.md` → `docs/progress/documents-domain.md`
15. `financial-domain-progress-FINAL.md` → `docs/progress/financial-domain-FINAL.md`
16. `HANDOFF-DOCUMENTS-DOMAIN.md` → `docs/handoffs/DOCUMENTS-DOMAIN.md`
17. `TASK-1.3.2-FINANCIAL-TEMPLATE.md` → `docs/analysis/TASK-1.3.2-FINANCIAL-TEMPLATE.md`

### analysis/week1/core-tables/financial-domain/ → docs/

18. `INDEX.md` → `docs/analysis/financial-domain-INDEX.md`
19. `FINANCIAL-DOMAIN-COMPLETE.md` → `docs/analysis/financial-domain-COMPLETE.md`

### analysis/week1/core-tables/financial-domain-data/ → docs/

20. `paymenttypes-enum-raw-data.md` → `docs/analysis/paymenttypes-enum-raw-data.md`

### analysis/week1/core-tables/part-1-products/ → раздели

**Таблици → analysis/domains/products/**
21. (няма отделни файлове за таблици - трябва да се създадат или оставят както са)

**Документи → docs/**
22. `PROGRESS-FINAL.md` → `docs/progress/products-FINAL.md`
23. `README.md` → `docs/analysis/products-README.md`
24. `SESSION-COMPLETION-SUMMARY.md` → `docs/analysis/products-SESSION-SUMMARY.md`
25. `products-business-rules-FINAL.md` → `docs/analysis/products-business-rules-FINAL.md`
26. `products-migration-strategy-FINAL.md` → `docs/analysis/products-migration-strategy-FINAL.md`
27. `products-domain-schema-FINAL.json` → `docs/analysis/products-domain-schema-FINAL.json`
28. `schema-draft.json` → `docs/analysis/products-schema-draft.json`
29. `validation-queries.sql` → `docs/analysis/products-validation-queries.sql`
30. `Validation_doProduct Table.txt` → `docs/analysis/products-validation.txt`

### analysis/week1/core-tables/trade-domain/ → раздели

**Таблици → analysis/domains/trade/**
31. `01-doTrade.md` → `analysis/domains/trade/01-doTrade.md`
32. `02-doTradeItem.md` → `analysis/domains/trade/02-doTradeItem.md`
33. `doTradeTransaction-analysis.md` → `analysis/domains/trade/03-doTradeTransaction.md`
34. `doTradePayment-analysis.md` → `analysis/domains/trade/04-doTradePayment.md`
35. `doTradePayment-Items-analysis.md` → `analysis/domains/trade/05-doTradePayment-Items.md`
36. `doTradeDelivery-analysis.md` → `analysis/domains/trade/06-doTradeDelivery.md`
37. `doTradeDelivery-Items-analysis.md` → `analysis/domains/trade/07-doTradeDelivery-Items.md`
38. `08-doTradeReturn-analysis.md` → `analysis/domains/trade/08-doTradeReturn.md`
39. `09-doTradeReturn-Items-analysis.md` → `analysis/domains/trade/09-doTradeReturn-Items.md`
40. `10-doTradeCancel-analysis.md` → `analysis/domains/trade/10-doTradeCancel.md`
41. `11-doTransaction-analysis.md` → `analysis/domains/trade/11-doTransaction.md`

**Документи → docs/**
42. `trade-domain-progress.md` → `docs/progress/trade-domain.md`
43. `HANDOFF-next-session.md` → `docs/handoffs/TRADE-next-session.md`
44. `HANDOFF-2025-11-10-doTradeReturn-Items.md` → `docs/handoffs/TRADE-doTradeReturn-Items.md`

### analysis/week1/database/ → analysis/database/

45. Всички файлове остават, но се преместват директно в `analysis/database/`

---

## ✅ ПРЕДИМСТВА НА НОВАТА СТРУКТУРА

1. **Ясна разделителна линия:**
   - `analysis/` = САМО анализи на таблици
   - `docs/` = Всички документи (HANDOFF, PROGRESS, INDEX, README)

2. **Лесно навигация:**
   - Всички таблици на едно място
   - Всички документи организирани по тип

3. **Чиста структура:**
   - Няма смесване на типове файлове
   - Лесно да се намери каквото търсиш

---

## 🚀 СЛЕДВАЩИ СТЪПКИ

1. Създай `docs/` структура
2. Премести всички документи
3. Реорганизирай `analysis/` - само таблици
4. Обнови всички линкове
5. Тествай навигацията

---

**Готов за изпълнение?** Да започна ли реорганизацията?


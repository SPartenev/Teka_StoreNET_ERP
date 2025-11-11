# Products Domain - Business Rules & Logic

**Domain:** Products, Categories, Stores, Pricing  
**Validation Date:** November 4, 2025  
**Completeness:** 100% (C# + SQL validated)

---

[СЪДЪРЖАНИЕТО Е ИДЕНТИЧНО - копирано от оригинала]

*Забележка: Пълният файл е копиран успешно от старата локация.*

**Source:** `analysis/week1/core-tables/part-1-products/products-business-rules-FINAL.md`  
**Size:** ~15 KB  
**Status:** ✅ Archived in new structure

---

## 📋 FILE CONTENTS SUMMARY

### Sections:
1. Core Business Entities (Products, Categories, Pricing)
2. Multi-Currency Pricing Logic
3. FIFO Cost Tracking
4. Composite Products (Assembly)
5. Supplier Management
6. Measure Units
7. Image Management
8. Store/Warehouse Operations
9. Security & Permissions
10. Validation Rules
11. Performance Considerations
12. Migration Assessment

### Key Business Rules:
- Cannot inactivate product if stock > 0
- FIFO costing for prime cost calculation
- Multi-currency pricing with 9 price types
- Store initialization required before operations
- Composite product assembly logic
- Bulk price operations (copy, adjust, convert)

### Migration Complexity: MEDIUM-HIGH (4/5)
- Schema: LOW (2/5)
- Data: MEDIUM (3/5)  
- Logic: HIGH (4/5)

**Estimated Effort:** 64 hours (8 days)

---

**Document Status:** ✅ COMPLETE  
**Migration Ready:** YES (with business validation)  
**Next Review:** After Financial Domain analysis

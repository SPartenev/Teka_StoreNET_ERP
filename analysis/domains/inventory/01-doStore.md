# doStore - Store/Location Master Data

**Domain:** Inventory  
**Table Type:** Master Data Entity  
**Analysis Date:** 2025-11-11  
**Status:** ✅ COMPLETE

---

## 📊 QUICK SUMMARY

- **Volume:** 31 store/warehouse locations
- **Active:** 16 stores (51.6%)
- **Inactive:** 15 stores (48.4%)
- **Date Range:** 2006-03-18 to 2008-12-15
- **Key Pattern:** Central reference table for all operations
- **Referenced by:** 19 tables (critical hub)

### Key Metrics:
- ✅ **With Address:** 12 stores (38.7%)
- ✅ **With Identity:** 8 stores (25.8%)
- ✅ **Initiated:** 29 stores (93.5%)
- ⚠️ **Internal Stores:** 0 (all external)
- 🔴 **Inactive Rate:** 48.4% (high!)

---

## 📋 SCHEMA (10 columns)

| # | Column | Type | Nullable | Default | Description |
|---|--------|------|----------|---------|-------------|
| 1 | **ID** | bigint | NO | 0 | Primary key |
| 2 | Name | nvarchar(40) | NO | '' | Store name |
| 3 | Description | nvarchar(100) | YES | NULL | Additional description |
| 4 | **Active** | bit | NO | 0 | Active/inactive flag |
| 5 | IsInternal | bit | NO | 0 | Internal vs external store |
| 6 | Address | bigint | YES | NULL | FK → doAddress |
| 7 | IsInitiated | bit | NO | 0 | Initialization status |
| 8 | UserInitiated | bigint | YES | NULL | FK → doUserAccount |
| 9 | TimeInitiated | datetime | YES | NULL | Initialization timestamp |
| 10 | Identity | bigint | YES | NULL | FK → doCompanyIdentity |

---

## 🔗 RELATIONSHIPS

### Outgoing Foreign Keys (4):
| FK Name | Column | → Referenced Table | Referenced Column |
|---------|--------|-------------------|-------------------|
| FK_doStore_ID | ID | doDataObject | ID |
| FK_doStore_Address | Address | doAddress | ID |
| FK_doStore_UserInitiated | UserInitiated | doUserAccount | ID |
| FK_doStore_Identity | Identity | doCompanyIdentity | ID |

### Incoming Foreign Keys (19) - CRITICAL HUB:
| Source Table | FK Column | Business Purpose |
|--------------|-----------|------------------|
| **doTradeTransaction** | Store | Sales transactions |
| **doFinanceTransaction** | Store | Financial transactions |
| **doDocument** | Store | Documents |
| **doUserAccount** | Store | User assignments |
| **doStoreTransfer** | Store/DestinationStore | Inter-store transfers |
| **doStore-Items** | Owner | Inventory items |
| **doStore-LogItems** | Owner | Inventory logs |
| **doStore-RequestItems** | Owner | Store requests |
| **doStoreAssembly** | Store | Assembly operations |
| **doStoreDiscard** | Store | Discard operations |
| **doAutomaticStoreAssembly** | Store | Automatic assembly |
| **doCashDesk-Stores** | ID-2 | Cash desk assignments |
| **doProductPriceType-Stores** | ID-2 | Store-specific pricing |
| **doCashDeskAmountTransfer** | Store | Cash transfers |
| **doCashDeskCurrencyChange** | Store | Currency exchanges |
| **doIFinancedTransaction** | Store | Interface transactions |
| **doStore-InitiationItems** | Owner | Initial inventory |
| **doStore-InitiationLogItems** | Owner | Initialization logs |

### Critical Dependencies:
- Central hub for **ALL** inventory operations
- Referenced by trade, finance, and document systems
- Cannot delete any store with dependent data

---

## 🔍 KEY FINDINGS

### ✅ Strengths:
1. **Small master data set** - Only 31 stores (manageable)
2. **Comprehensive tracking** - Initiation user, time, status
3. **Multi-location support** - Separate stores for Sofia, Plovdiv, Ruse
4. **Identity separation** - Different company identities per store

### ⚠️ Issues & Risks:

#### 1. **High Inactive Rate (48.4%)**
```
Active: 16 stores
Inactive: 15 stores (including "Не се ползва вече")
```
- **Impact:** Legacy data, potential confusion
- **Action:** Confirm if inactive stores have historical transactions

#### 2. **Missing Addresses (61.3%)**
```sql
Stores with Address: 12 (38.7%)
Stores without: 19 (61.3%)
```
- **Risk:** Incomplete location data for logistics
- **Migration:** May need address enrichment

#### 3. **No Internal Stores**
```sql
IsInternal = 0 for all 31 stores
```
- **Question:** Is this field obsolete or incorrectly configured?
- **Impact:** May affect internal vs. external transfer logic

#### 4. **Placeholder Record (ID=0)**
```sql
ID=0, Name='', Active=0, IsInitiated=0
```
- **Risk:** Used as NULL reference in other tables
- **Migration:** Handle specially to avoid FK violations

#### 5. **Company Identity Gaps**
```
Only 8 stores (25.8%) have Identity assigned
```
- **Business Question:** Are multi-company operations properly tracked?

---

## 📊 SAMPLE DATA ANALYSIS

### Active TEKA Stores:
```
1ТЕКА ООД - СОФИЯ (ID: 27090)
2ТЕКА ООД - Южен Парк (ID: 27104)
4ТЕКА ООД - Пловдив (ID: 27092) - Identity: 278796
5ТЕКА ООД - РУСЕ (ID: 27094) - Identity: 278798
```

### Warehouse/Partner Stores:
```
92Склад Декопласт (ID: 27096) - Active
ЛУКА (ID: 27100) - "бивш ЕТ Интерформ"
```

### Inactive/Historical:
```
"Не се ползва вече - 82ТП СОФИЯ" - Former construction market
"Ю-БУЛДЕКОР-СКЛАД" - Inactive
"Стоки за адлон" - Changed in 2011
```

### Patterns:
- Store names include numbers (1ТЕКА, 2ТЕКА, 4ТЕКА, 5ТЕКА)
- Descriptions track historical changes ("бивш", "от 2011 год.")
- All stores initiated by same user (48486) on 2006-03-18

---

## 🎯 BUSINESS LOGIC INTERPRETATION

### Store Hierarchy:
```
Main Stores (TEKA branded):
├─ Sofia (2 locations)
├─ Plovdiv (1 location)
└─ Ruse (1 location)

Partner/Warehouse:
├─ Декопласт (supplier warehouse)
└─ ЛУКА (partner store)
```

### Lifecycle States:
1. **Created** → Basic record exists
2. **Initiated** → IsInitiated = 1, inventory setup complete
3. **Active** → Active = 1, operational
4. **Inactive** → Active = 0, historical/closed

### Multi-Company Support:
- Different Identity values suggest separate legal entities
- Plovdiv (278796), Ruse (278798) have distinct identities
- Sofia stores lack Identity (same legal entity?)

---

## 🚀 POSTGRESQL MIGRATION COMPLEXITY

**Rating:** ⭐⭐ LOW (2/5)

### Why Low Complexity:
1. **Small volume** - Only 31 records
2. **Simple schema** - 10 columns, basic types
3. **No complex logic** - Straightforward master data
4. **Manual cleanup feasible** - Can review all records

### Migration Steps:

#### Phase 1: Schema Creation (30 min)
```sql
CREATE TABLE do_store (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL DEFAULT '',
    description VARCHAR(100),
    active BOOLEAN NOT NULL DEFAULT FALSE,
    is_internal BOOLEAN NOT NULL DEFAULT FALSE,
    address_id BIGINT REFERENCES do_address(id),
    is_initiated BOOLEAN NOT NULL DEFAULT FALSE,
    user_initiated_id BIGINT REFERENCES do_user_account(id),
    time_initiated TIMESTAMPTZ,
    identity_id BIGINT REFERENCES do_company_identity(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Critical indexes for performance
CREATE INDEX idx_dostore_active ON do_store(active);
CREATE INDEX idx_dostore_address ON do_store(address_id);
CREATE INDEX idx_dostore_identity ON do_store(identity_id);
```

#### Phase 2: Data Cleaning (30 min)
```sql
-- Handle placeholder record
-- Verify inactive stores have no recent transactions
-- Document store naming convention
```

#### Phase 3: Data Migration (30 min)
```sql
-- Simple INSERT with ID preservation
-- Map legacy IDs for FK relationships
-- Special handling for ID=0 record
```

#### Phase 4: Validation (30 min)
```sql
-- Verify all 31 records migrated
-- Check FK integrity with dependent tables
-- Validate active/inactive status
```

### Estimated Migration Time: **2 hours**

---

## 📋 RECOMMENDATIONS

### Pre-Migration:
1. ✅ **Audit inactive stores** - Confirm no active transactions
2. ✅ **Address enrichment** - Fill missing addresses (19 stores)
3. ✅ **Identity mapping** - Clarify multi-company structure
4. ✅ **Document ID=0** - Special handling for placeholder

### Post-Migration:
1. ✅ Add CHECK constraint for active store validation
2. ✅ Create view for active stores only
3. ✅ Add trigger to prevent deletion of referenced stores
4. ✅ Implement soft delete (deactivation) instead of hard delete

### Business Process:
1. ⚠️ **Review inactive stores** - Archive or remove?
2. ⚠️ **Standardize naming** - Remove numbers from store names?
3. ⚠️ **Define IsInternal usage** - Currently unused field
4. ✅ **Multi-location strategy** - Confirm store hierarchy

---

## 📊 STORE DISTRIBUTION

### By Status:
```
Active Stores:    16 (51.6%)
├─ TEKA Stores:    4
├─ Warehouses:     3
└─ Other:          9

Inactive Stores:  15 (48.4%)
├─ Historical:     8
├─ Replaced:       4
└─ Placeholder:    1
```

### By Location (from names):
```
Sofia:     ~10 stores (including inactive)
Plovdiv:   1 store
Ruse:      1 store
Unknown:   ~19 stores
```

### Critical Stores (by references):
1. Most likely high-volume stores based on naming:
   - 1ТЕКА ООД - СОФИЯ
   - 2ТЕКА ООД - Южен Парк
   - 4ТЕКА ООД - Пловдив
   - 5ТЕКА ООД - РУСЕ

---

## ⚠️ MIGRATION RISKS

1. **ID=0 Record**
   - Used as NULL reference in other tables
   - Must preserve or handle FK updates

2. **Dependent Tables (19)**
   - Migration order critical
   - Cannot migrate stores before addresses
   - Must migrate before trade/finance tables

3. **Active/Inactive Logic**
   - Verify business rules for deactivation
   - Check if inactive stores can be reactivated

---

**Analysis Complete:** 2025-11-11  
**Next Table:** doInventory (or another from the 21-table list)  
**Estimated Time for Next:** 45-60 min

---

## 🔄 SYSTEM DEPENDENCIES

This table is a **CRITICAL HUB** that must be migrated early:

```
Migration Order:
1. doDataObject
2. doAddress
3. doCompanyIdentity
4. doUserAccount
5. ➡️ doStore ⬅️ (THIS TABLE)
6. Then: All 19 dependent tables
```
# Store.NET Database Relationships Analysis

**Database:** TEKA  
**Analysis Date:** 2025-11-03  
**Total Relationships:** 45  
**Foreign Keys:** 41  
**Junction Tables:** 4

---

## Executive Summary

The Store.NET database implements a comprehensive ERP structure with strong relational integrity. The schema follows a hub-and-spoke pattern with **Products**, **Stores**, **Contractors**, and **Users** as central entities. All relationships are enforced through foreign key constraints, ensuring data consistency.

### Key Characteristics:
- **Normalized Design:** 3NF with minimal redundancy
- **Audit Trail:** Comprehensive logging of inventory changes
- **Security Model:** Role-based access control (RBAC)
- **Multi-Store Support:** Full multi-location inventory tracking

---

## Relationship Types

| Type | Count | Description |
|------|-------|-------------|
| **One-to-Many (1:N)** | 35 | Parent-child relationships |
| **Many-to-Many (M:N)** | 4 | Junction table relationships |
| **One-to-One (1:1)** | 6 | Contained/extension relationships |

---

## Core Relationships by Module

### 📦 Products Module

#### Product Hierarchy
```
ProductGroups (Categories)
    └─> Products [1:N]
        ├─> Prices [1:N] (per PriceType)
        ├─> StoreItems [1:N] (inventory per store)
        ├─> ProductDiscounts [M:N via Contractors]
        └─> AssemblySchemes [1:1] (for composite products)
```

**Key Relationships:**
- **REL-002:** `ProductGroups → Products` - Product categorization
- **REL-001:** `Products → Prices` - Multi-price support (retail, wholesale, etc.)
- **REL-003:** `Products → StoreItems` - Quantity tracking per store
- **REL-017:** `Products → AssemblySchemes` - Bill of materials for composite products

**Business Rules:**
- Product must belong to exactly one category
- Each product can have multiple prices (one per price type)
- Unique constraint: (Product, PriceType) in Prices table
- Product cannot be deleted if inventory exists in any store

---

### 🏪 Warehouse & Inventory

#### Store Structure
```
Stores
    ├─> StoreItems [1:N] - Current inventory
    ├─> StoreLogItems [1:N] - Historical changes
    ├─> InitiationItems [1:N] - Opening balances
    ├─> Transfers [1:N] (as source)
    ├─> Transfers [1:N] (as destination)
    ├─> Assemblies [1:N] - Product assembly operations
    └─> Rejections [1:N] - Waste/damage tracking
```

**Key Relationships:**
- **REL-004:** `Stores → StoreItems` - Current stock levels
- **REL-005:** `Stores → Documents` - Document issuance location
- **REL-013/014:** `Stores ↔ Transfers` - Inter-store movements
- **REL-020:** `Stores → Assemblies` - Assembly location

**Business Rules:**
- Unique constraint: (Store, Product) in StoreItems
- Store must be initiated before inventory operations
- Transfer requires both source and destination stores
- Cannot delete store with existing inventory

---

### 🔧 Composite Products (Assembly)

#### Assembly Workflow
```
Product [IsComposite=true]
    └─> AssemblySchemes (Template) [1:1]
        └─> AssemblySchemeItems [1:N] (Bill of Materials)
            └─> Products [N:1] (Component parts)

Assemblies (Actual Operations)
    ├─> Store [N:1] - Where assembled
    ├─> Product [N:1] - What is created
    └─> AssemblyItems [1:N] - Parts consumed
```

**Key Relationships:**
- **REL-017:** `Products → AssemblySchemes` - Template definition
- **REL-018:** `AssemblySchemes → AssemblySchemeItems` - BOM lines
- **REL-021:** `Products → Assemblies` - Assembly operations
- **REL-022:** `Assemblies → AssemblyItems` - Parts consumption

**Business Rules:**
- Composite product has exactly one assembly template
- Template can be in Straight (disassembly) or Reverse (assembly) direction
- Assembly consumes parts from store inventory
- Circular reference: Product can contain itself as component (validated)

---

### 📋 Documents & Operations

#### Document Structure
```
DocumentsTypes
    └─> Documents [1:N]
        ├─> Store [N:1] - Issuance location
        ├─> Contractor [N:1] - Business partner (optional)
        └─> DocumentsOperations [1:N] - Line items
            └─> Products [N:1] - Items operated on
```

**Key Relationships:**
- **REL-006:** `DocumentsTypes → Documents` - Document classification
- **REL-005:** `Documents → Store` - Location tracking
- **REL-007:** `Documents → DocumentsOperations` - Detail lines
- **REL-009:** `Documents → Contractors` - Partner association (nullable)

**Business Rules:**
- Document must have a type and store
- Contractor is optional (for internal operations)
- Document can have Owner and RootOwner (hierarchical)
- DocumentId is indexed for fast lookup

---

### 💰 Financial Module

#### Financial Entities
```
Currencies
    ├─> CurrenciesRates [1:N] - Exchange rates
    └─> CashOperations [1:N] - Cash movements

CashOperations
    ├─> Currency [N:1]
    ├─> CashType [N:1] - Income/Expense type
    ├─> PaymentType [N:1] - Cash/Card/Transfer
    └─> Store [N:1] - Location
```

**Key Relationships:**
- **REL-031:** `Currencies → CashOperations` - Multi-currency support
- **REL-032:** `CashTypes → CashOperations` - Operation classification
- **REL-033:** `Currencies → CurrenciesRates` - Daily exchange rates

**Business Rules:**
- One base currency, others converted via rates
- Cash operation must specify currency and type
- Historical rates preserved for audit

---

### 👥 Security & Users

#### Security Model
```
Users
    ├─> UserRoles [M:N] - Role assignment
    ├─> UserRights [M:N] - Direct permissions
    └─> Store [1:1] (optional) - Default store

Roles
    └─> RoleRights [M:N] - Role permissions

Rights (Permissions)
    ├─> UserRights [M:N]
    └─> RoleRights [M:N]
```

**Key Relationships:**
- **REL-034:** `Users ↔ Roles` (via UserRoles junction)
- **REL-035:** `Users ↔ Rights` (via UserRights junction)
- **REL-036:** `Roles ↔ Rights` (via RoleRights junction)
- **REL-044:** `Users → Stores` - Default working location

**Business Rules:**
- User permissions = RoleRights ∪ UserRights
- Built-in roles: Administrators, Users, Guests
- Granular permissions per module (Product, Store, Finance, etc.)
- IP address restrictions supported

---

### 💬 Messaging System

#### Message Flow
```
Users (Sender)
    └─> Messages [1:N]
        ├─> MessageRecipients [1:N]
        │   └─> Users (Recipient) [N:1]
        └─> MessageAttachments [1:N] - Files

Users
    └─> Chat [1:N] - Real-time messages
    └─> Notifications [1:N] - System alerts
```

**Key Relationships:**
- **REL-037:** `Users → Messages` - Message author
- **REL-038:** `Messages → MessageRecipients` - Delivery
- **REL-039:** `Users → MessageRecipients` - Recipient tracking
- **REL-040:** `Messages → MessageAttachments` - File attachments

**Business Rules:**
- Message can have multiple recipients
- Supports private messages and chat
- Notification system for alerts
- File attachments supported

---

## Critical Relationships for Migration

### High-Priority Foreign Keys

| Priority | Relationship | Reason |
|----------|-------------|--------|
| **P0** | Products → StoreItems | Core inventory tracking |
| **P0** | Documents → DocumentsOperations | Transaction integrity |
| **P0** | Users → Roles → Rights | Security model |
| **P1** | Products → Prices | Pricing logic |
| **P1** | Stores → Transfers | Multi-location support |
| **P2** | Products → AssemblySchemes | Composite products |

### Complex Relationships Requiring Validation

1. **Composite Products:**
   - Circular reference: Product → AssemblyScheme → Items → Product
   - Must validate no infinite loops

2. **Store Transfers:**
   - Same store appears twice (source + destination)
   - PostgreSQL foreign key behavior differs from SQL Server

3. **Multi-Store Inventory:**
   - Unique constraint: (Store, Product)
   - Quantity updates must be atomic

4. **Discount Hierarchy:**
   - Priority: ProductDiscount > CategoryDiscount > Contractor.Discount
   - Application logic in stored procedures

---

## Junction Tables (Many-to-Many)

| Table | Connects | Unique Constraint | Purpose |
|-------|----------|-------------------|---------|
| **UserRoles** | Users ↔ Roles | (User, Role) | Role-based access |
| **UserRights** | Users ↔ Rights | (User, Right) | Direct permissions |
| **RoleRights** | Roles ↔ Rights | (Role, Right) | Role permissions |
| **ProductDiscounts** | Contractors ↔ Products | (Contractor, Product) | Product-specific pricing |

---

## PostgreSQL Migration Considerations

### 1. Foreign Key Naming
```sql
-- SQL Server auto-names: FK_Products_Category_12345678
-- PostgreSQL: Explicit naming required, max 63 chars
ALTER TABLE products 
  ADD CONSTRAINT fk_products_category 
  FOREIGN KEY (category_id) REFERENCES product_groups(id);
```

### 2. Cascading Deletes
```sql
-- Review cascade rules per relationship:
ON DELETE CASCADE    -- Delete children (e.g., DocumentOperations)
ON DELETE RESTRICT   -- Prevent delete (e.g., Products with inventory)
ON DELETE SET NULL   -- Nullify FK (e.g., Contractor on Document)
```

### 3. Unique Constraints
```sql
-- Multi-column unique constraints must be recreated:
CREATE UNIQUE INDEX idx_store_items_store_product 
  ON store_items(store_id, product_id);
```

### 4. Index Strategy
- SQL Server clustered indexes → PostgreSQL primary key indexes
- Non-clustered indexes → Regular indexes
- Include columns → PostgreSQL covering indexes

---

## Data Integrity Rules

### Mandatory Relationships (NOT NULL)
- Product **must** have Category
- Document **must** have Store and DocumentType
- StoreItem **must** have Store and Product
- CashOperation **must** have Currency and CashType

### Optional Relationships (NULLABLE)
- Product → Supplier (default supplier optional)
- Document → Contractor (internal operations)
- User → Store (default store optional)
- Product → ImageData (picture optional)

---

## Circular Dependencies

### 1. Composite Products
```
Products ──┐
    ↓      │
AssemblySchemes
    ↓      │
AssemblySchemeItems
    ↓      │
Products ←─┘
```
**Resolution:** Validate at application layer, prevent infinite loops

### 2. Document Hierarchy
```
Documents (RootOwner) → DataObject → Documents (Owner)
```
**Resolution:** Self-referential FKs, nullable

---

## Performance Implications

### Highly-Connected Tables (Join Hot Spots)
1. **Products** - 15+ relationships → Cache heavily
2. **Stores** - 12+ relationships → Partition by location
3. **Users** - 10+ relationships → Session caching
4. **Contractors** - 8+ relationships → Index optimization

### Recommended Indexes
```sql
-- Critical for performance:
CREATE INDEX idx_store_items_product ON store_items(product_id);
CREATE INDEX idx_documents_ops_product ON documents_operations(product_id);
CREATE INDEX idx_prices_product_type ON prices(product_id, price_type_id);
CREATE INDEX idx_transfers_source ON transfers(source_store_id);
CREATE INDEX idx_transfers_dest ON transfers(destination_store_id);
```

---

## Next Steps for Migration

### Phase 1: Schema Generation
- [ ] Generate PostgreSQL DDL from relationships
- [ ] Create foreign key constraints
- [ ] Define cascade rules per relationship
- [ ] Create junction table indexes

### Phase 2: Data Migration
- [ ] Migrate parent tables first (Products, Stores, Users)
- [ ] Migrate child tables (StoreItems, Documents)
- [ ] Validate referential integrity
- [ ] Import junction table data

### Phase 3: Validation
- [ ] Verify all 45 relationships enforced
- [ ] Test cascade delete behavior
- [ ] Validate unique constraints
- [ ] Performance test with realistic data volume

---

## Summary Statistics

| Metric | Count |
|--------|-------|
| Total Relationships | 45 |
| Foreign Keys | 41 |
| Junction Tables | 4 |
| Self-Referential FKs | 2 |
| Nullable FKs | 8 |
| Unique Constraints (Multi-Column) | 12 |

**Complexity Rating:** ⭐⭐⭐⭐ (High)  
**Migration Risk:** Medium - Complex relationships require careful validation

---

*Generated: 2025-11-03*  
*Next Document: Core Tables Schema (TASK 1.3)*

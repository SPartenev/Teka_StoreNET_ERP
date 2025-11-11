# Products Domain - PostgreSQL Migration Strategy

**Source:** SQL Server 2005 + DataObjects.NET ORM  
**Target:** PostgreSQL 15 + Entity Framework Core  
**Migration Date:** November 4, 2025  
**Estimated Duration:** 1.6 weeks (64 hours, 1 developer)

---

## 📋 Migration Overview

### Scope
- **9 tables** (8 main + 1 junction)
- **97 columns** total
- **27,747 products** with pricing data
- **53,742 price records**
- **Images:** varbinary(max) data (size TBD)

### Migration Strategy
**Phased Approach:**
1. Schema setup (tables, indexes, constraints)
2. Reference data (categories, units, price types, stores)
3. Core data (contractors, products)
4. Transactional data (prices, cost items)
5. Binary data (product images)
6. Validation and reconciliation

---

## 🔄 Data Type Mappings

| SQL Server | PostgreSQL | Notes | Complexity |
|------------|------------|-------|------------|
| `bigint` | `BIGINT` | Direct mapping | ✅ Low |
| `nvarchar(n)` | `VARCHAR(n)` | UTF-8 by default in PG | ✅ Low |
| `decimal(28,10)` | `NUMERIC(28,10)` | Full precision support | ⚠️ Medium |
| `bit` | `BOOLEAN` | 0/1 → false/true | ⚠️ Medium |
| `varbinary(max)` | `BYTEA` | Max 1GB, consider blob storage | 🔴 High |
| `smalldatetime` | `TIMESTAMP` | Higher precision in PG | ✅ Low |
| `datetime` | `TIMESTAMPTZ` | Timezone-aware recommended | ⚠️ Medium |

### Critical Mappings

#### Decimal Precision (28,10)
```sql
-- SQL Server
PrimeCost decimal(28,10) NOT NULL DEFAULT 0.0

-- PostgreSQL
PrimeCost NUMERIC(28,10) NOT NULL DEFAULT 0.0
```
**Notes:**
- Unusual precision (typically 18,2 for money)
- Verify business requirement (likely for multi-currency calculations)
- PostgreSQL handles this natively
- Watch for arithmetic overflow in calculations

#### Boolean Conversion
```sql
-- SQL Server
Active bit NOT NULL DEFAULT 0

-- PostgreSQL
Active BOOLEAN NOT NULL DEFAULT false
```
**Migration Script:**
```sql
-- During data import
CASE WHEN Active = 0 THEN false ELSE true END
```

#### Image Storage
```sql
-- SQL Server
ImageData varbinary(max) NULL

-- PostgreSQL Option 1: BYTEA
ImageData BYTEA NULL

-- PostgreSQL Option 2: External Storage (RECOMMENDED)
ImageData TEXT NULL  -- Store URL/path to blob storage
```

**Recommendation:**
- **External Blob Storage** (Azure Blob, AWS S3, MinIO)
  - Better performance (no DB bloat)
  - Scalable storage
  - CDN-friendly for web
  - Cost-effective
  
**Migration Process:**
1. Extract images from SQL Server
2. Upload to blob storage
3. Store URLs in PostgreSQL
4. Update application to fetch from URLs

---

## 🗄️ Schema Migration Scripts

### 1. Create Tables

```sql
-- doCategory
CREATE TABLE do_category (
    id BIGSERIAL PRIMARY KEY,
    category_id VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL UNIQUE,
    description VARCHAR(500),
    annotation_title VARCHAR(100),
    annotation_one_title VARCHAR(100),
    annotation_two_title VARCHAR(100),
    web_visible BOOLEAN NOT NULL DEFAULT true
);

-- doMeasureUnit
CREATE TABLE do_measure_unit (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(10) NOT NULL UNIQUE,
    full_name VARCHAR(40),
    active BOOLEAN NOT NULL DEFAULT true
);

-- doCurrency (external dependency - placeholder)
-- CREATE TABLE do_currency (...);

-- doProductPriceType
CREATE TABLE do_product_price_type (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL UNIQUE,
    description VARCHAR(300),
    currency_id BIGINT NOT NULL,
    allow_different_currency BOOLEAN NOT NULL DEFAULT true,
    active BOOLEAN NOT NULL DEFAULT true,
    FOREIGN KEY (currency_id) REFERENCES do_currency(id)
);

-- doProduct
CREATE TABLE do_product (
    id BIGSERIAL PRIMARY KEY,
    category_id BIGINT NOT NULL,
    product_id VARCHAR(80) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL,
    annotation VARCHAR(100),
    annotation_one VARCHAR(100),
    annotation_two VARCHAR(100),
    description VARCHAR(500),
    description_one VARCHAR(1000),
    description_two VARCHAR(1000),
    measure_unit_id BIGINT,
    image_available BOOLEAN NOT NULL DEFAULT false,
    image_data BYTEA,  -- or TEXT for URL
    image_content_type VARCHAR(40),
    image_file_name VARCHAR(100),
    is_composite BOOLEAN NOT NULL DEFAULT false,
    template_id BIGINT,
    supplier_id BIGINT,
    supplier_product_id VARCHAR(40),
    customer_product_id VARCHAR(40),
    active BOOLEAN NOT NULL DEFAULT false,
    web_visible BOOLEAN NOT NULL DEFAULT false,
    prime_cost NUMERIC(28,10) NOT NULL DEFAULT 0.0,
    FOREIGN KEY (category_id) REFERENCES do_category(id),
    FOREIGN KEY (measure_unit_id) REFERENCES do_measure_unit(id),
    FOREIGN KEY (supplier_id) REFERENCES do_contractor(id),
    FOREIGN KEY (template_id) REFERENCES do_store_assembly_template(id)
);

-- doProduct-Prices
CREATE TABLE do_product_price (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    price_type_id BIGINT NOT NULL,
    price NUMERIC(28,10) NOT NULL DEFAULT 0.0,
    currency_id BIGINT NOT NULL,
    FOREIGN KEY (product_id) REFERENCES do_product(id),
    FOREIGN KEY (price_type_id) REFERENCES do_product_price_type(id),
    FOREIGN KEY (currency_id) REFERENCES do_currency(id),
    UNIQUE (product_id, price_type_id)
);

-- doProduct-PrimeCostItems
CREATE TABLE do_product_prime_cost_item (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT NOT NULL,
    quantity NUMERIC(28,10) NOT NULL,
    input_document_id BIGINT NOT NULL,
    input_date TIMESTAMP NOT NULL,
    input_price NUMERIC(28,10) NOT NULL,
    output_document_id BIGINT,
    output_date TIMESTAMP,
    output_price NUMERIC(28,10),
    FOREIGN KEY (product_id) REFERENCES do_product(id),
    FOREIGN KEY (input_document_id) REFERENCES do_document(id),
    FOREIGN KEY (output_document_id) REFERENCES do_document(id)
);

-- doStore
CREATE TABLE do_store (
    id BIGSERIAL PRIMARY KEY,
    name VARCHAR(40) NOT NULL UNIQUE,
    description VARCHAR(100),
    active BOOLEAN NOT NULL DEFAULT true,
    is_internal BOOLEAN NOT NULL DEFAULT false,
    address_id BIGINT,
    is_initiated BOOLEAN NOT NULL DEFAULT false,
    user_initiated_id BIGINT,
    time_initiated TIMESTAMPTZ,
    identity_id BIGINT,
    FOREIGN KEY (address_id) REFERENCES do_address(id),
    FOREIGN KEY (user_initiated_id) REFERENCES do_user(id),
    FOREIGN KEY (identity_id) REFERENCES do_company_identity(id)
);

-- Junction table: doProductPriceType-Stores
CREATE TABLE do_product_price_type_store (
    price_type_id BIGINT NOT NULL,
    store_id BIGINT NOT NULL,
    PRIMARY KEY (price_type_id, store_id),
    FOREIGN KEY (price_type_id) REFERENCES do_product_price_type(id),
    FOREIGN KEY (store_id) REFERENCES do_store(id)
);
```

### 2. Create Indexes

```sql
-- doProduct indexes
CREATE INDEX idx_product_category ON do_product(category_id);
CREATE INDEX idx_product_name ON do_product(name);
CREATE INDEX idx_product_measure_unit ON do_product(measure_unit_id);
CREATE INDEX idx_product_supplier ON do_product(supplier_id);
CREATE INDEX idx_product_template ON do_product(template_id);

-- Partial index for active products (PostgreSQL feature)
CREATE INDEX idx_product_active ON do_product(active) WHERE active = true;

-- doProduct-Prices indexes
CREATE INDEX idx_product_price_product ON do_product_price(product_id, id);

-- doProduct-PrimeCostItems indexes
CREATE INDEX idx_prime_cost_item_product ON do_product_prime_cost_item(product_id);
CREATE INDEX idx_prime_cost_item_input_date ON do_product_prime_cost_item(input_date);
CREATE INDEX idx_prime_cost_item_output_date ON do_product_prime_cost_item(output_date);
```

### 3. Add Computed Column (Optional)

```sql
-- Alternative to application-level ImageAvailable computation
ALTER TABLE do_product 
ADD COLUMN image_available_computed BOOLEAN 
GENERATED ALWAYS AS (image_data IS NOT NULL) STORED;
```

---

## 📦 Data Migration Process

### Phase 1: Reference Data (1 hour)
**Order:**
1. do_measure_unit (6 rows)
2. do_category (118 rows)
3. do_currency (external dependency)
4. do_product_price_type (9 rows)

**Script:**
```bash
# Export from SQL Server
bcp "SELECT * FROM TEKA.dbo.doMeasureUnit" queryout measure_units.csv -c -t',' -S server -U user -P pass

# Import to PostgreSQL
psql -d teka_new -c "\COPY do_measure_unit FROM 'measure_units.csv' CSV HEADER"
```

### Phase 2: Contractors (2 hours)
- 19,955 rows
- External dependency for Products
- Run before Products migration

### Phase 3: Products (3 hours)
**Challenges:**
- 27,747 rows
- Image data (defer to Phase 5)
- Foreign key dependencies

**Export Script (SQL Server):**
```sql
SELECT 
    ID,
    Category,
    ProductId,
    Name,
    Annotation,
    AnnotationOne,
    AnnotationTwo,
    Description,
    DescriptionOne,
    DescriptionTwo,
    MeasureUnit,
    -- Skip ImageData for now
    CASE WHEN ImageData IS NULL THEN 0 ELSE 1 END as ImageAvailable,
    ImageContentType,
    ImageFileName,
    IsComposite,
    Template,
    Supplier,
    SupplierProductId,
    CustomerProductId,
    Active,
    WebVisible,
    PrimeCost
FROM TEKA.dbo.doProduct
ORDER BY ID;
```

**Import Script (PostgreSQL):**
```sql
-- Disable triggers temporarily for bulk insert
ALTER TABLE do_product DISABLE TRIGGER ALL;

\COPY do_product FROM 'products.csv' CSV HEADER;

-- Re-enable triggers
ALTER TABLE do_product ENABLE TRIGGER ALL;

-- Update sequence
SELECT setval('do_product_id_seq', (SELECT MAX(id) FROM do_product));
```

### Phase 4: Prices (2 hours)
- 53,742 rows
- Straightforward mapping
- Composite unique constraint validation

**Validation Query:**
```sql
-- Check for duplicate (product_id, price_type_id)
SELECT product_id, price_type_id, COUNT(*) as cnt
FROM do_product_price
GROUP BY product_id, price_type_id
HAVING COUNT(*) > 1;
```

### Phase 5: Images (TBD - depends on approach)

#### Option A: BYTEA Migration (slower, simpler)
```sql
-- Extract images with IDs
SELECT ID, ImageData, ImageContentType, ImageFileName
FROM TEKA.dbo.doProduct
WHERE ImageData IS NOT NULL;

-- Import to PostgreSQL
-- Use binary format for efficiency
```

#### Option B: Blob Storage Migration (faster, recommended)
```python
import pyodbc
import boto3  # for AWS S3, or azure.storage.blob for Azure

# 1. Extract images from SQL Server
conn = pyodbc.connect('DSN=TEKA')
cursor = conn.execute("""
    SELECT ID, ImageData, ImageContentType, ImageFileName
    FROM doProduct 
    WHERE ImageData IS NOT NULL
""")

# 2. Upload to blob storage
s3 = boto3.client('s3')
for row in cursor:
    product_id, image_data, content_type, filename = row
    key = f"products/{product_id}/{filename}"
    s3.put_object(
        Bucket='teka-product-images',
        Key=key,
        Body=image_data,
        ContentType=content_type
    )
    
    # 3. Update PostgreSQL with URL
    url = f"https://teka-product-images.s3.amazonaws.com/{key}"
    pg_cursor.execute(
        "UPDATE do_product SET image_data = %s WHERE id = %s",
        (url, product_id)
    )
```

**Estimated Time:**
- Option A (BYTEA): 4-6 hours (depends on image sizes)
- Option B (Blob): 2-3 hours (parallel uploads)

### Phase 6: Cost Items (2 hours)
- Table: do_product_prime_cost_item
- Row count: Unknown (depends on transaction history)
- Critical for PrimeCost calculations

### Phase 7: Validation (2 hours)
```sql
-- Row count validation
SELECT 'do_product' as table_name, COUNT(*) as pg_count, 27747 as sql_count;
SELECT 'do_product_price' as table_name, COUNT(*) as pg_count, 53742 as sql_count;

-- Data integrity checks
SELECT COUNT(*) FROM do_product WHERE category_id NOT IN (SELECT id FROM do_category);
SELECT COUNT(*) FROM do_product_price WHERE product_id NOT IN (SELECT id FROM do_product);

-- Sample data comparison
SELECT id, product_id, name, prime_cost 
FROM do_product 
ORDER BY id LIMIT 10;

-- Price range validation
SELECT 
    MIN(price) as min_price,
    MAX(price) as max_price,
    AVG(price) as avg_price
FROM do_product_price;
-- Expected: min=0, max=238330, avg≈268.80
```

---

## 🔧 Entity Framework Core Setup

### 1. Install Packages
```bash
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.EntityFrameworkCore.Design
```

### 2. Entity Classes

```csharp
public class Product
{
    public long Id { get; set; }
    
    [Required]
    public long CategoryId { get; set; }
    public Category Category { get; set; }
    
    [Required, MaxLength(80)]
    public string ProductId { get; set; }
    
    [Required, MaxLength(80)]
    public string Name { get; set; }
    
    [MaxLength(100)]
    public string Annotation { get; set; }
    
    [MaxLength(500)]
    public string Description { get; set; }
    
    public long? MeasureUnitId { get; set; }
    public MeasureUnit MeasureUnit { get; set; }
    
    public bool ImageAvailable { get; set; }
    public byte[] ImageData { get; set; }  // or string if using URLs
    
    [MaxLength(40)]
    public string ImageContentType { get; set; }
    
    public bool IsComposite { get; set; }
    
    public long? SupplierId { get; set; }
    public Contractor Supplier { get; set; }
    
    [MaxLength(40)]
    public string SupplierProductId { get; set; }
    
    public bool Active { get; set; }
    public bool WebVisible { get; set; }
    
    [Column(TypeName = "decimal(28,10)")]
    public decimal PrimeCost { get; set; }
    
    // Navigation properties
    public ICollection<ProductPrice> Prices { get; set; }
    public ICollection<ProductPrimeCostItem> PrimeCostItems { get; set; }
}

public class ProductPrice
{
    public long Id { get; set; }
    
    [Required]
    public long ProductId { get; set; }
    public Product Product { get; set; }
    
    [Required]
    public long PriceTypeId { get; set; }
    public ProductPriceType PriceType { get; set; }
    
    [Column(TypeName = "decimal(28,10)")]
    public decimal Price { get; set; }
    
    [Required]
    public long CurrencyId { get; set; }
    public Currency Currency { get; set; }
}
```

### 3. DbContext Configuration

```csharp
public class TekaDbContext : DbContext
{
    public DbSet<Product> Products { get; set; }
    public DbSet<ProductPrice> ProductPrices { get; set; }
    public DbSet<Category> Categories { get; set; }
    // ... other DbSets

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        // Product configuration
        modelBuilder.Entity<Product>(entity =>
        {
            entity.ToTable("do_product");
            entity.Property(e => e.Id).HasColumnName("id");
            entity.Property(e => e.ProductId).HasColumnName("product_id");
            
            // Unique constraint
            entity.HasIndex(e => e.ProductId).IsUnique();
            
            // Foreign keys
            entity.HasOne(e => e.Category)
                  .WithMany(c => c.Products)
                  .HasForeignKey(e => e.CategoryId)
                  .OnDelete(DeleteBehavior.Restrict);
            
            // Decimal precision
            entity.Property(e => e.PrimeCost)
                  .HasColumnType("decimal(28,10)");
        });
        
        // ProductPrice configuration
        modelBuilder.Entity<ProductPrice>(entity =>
        {
            entity.ToTable("do_product_price");
            
            // Composite unique index
            entity.HasIndex(e => new { e.ProductId, e.PriceTypeId })
                  .IsUnique();
            
            entity.Property(e => e.Price)
                  .HasColumnType("decimal(28,10)");
        });
    }
}
```

---

## 🧪 Testing Strategy

### 1. Unit Tests (Business Logic)
```csharp
[Fact]
public void Product_PrimeCost_MustBeNonNegative()
{
    var product = new Product { PrimeCost = -10 };
    var context = new ValidationContext(product);
    var results = new List<ValidationResult>();
    
    Assert.False(Validator.TryValidateObject(product, context, results, true));
    Assert.Contains(results, r => r.MemberNames.Contains("PrimeCost"));
}

[Fact]
public void ProductPrice_UniquePerProductAndType()
{
    var db = GetInMemoryDbContext();
    
    db.ProductPrices.Add(new ProductPrice { ProductId = 1, PriceTypeId = 1, Price = 100 });
    db.SaveChanges();
    
    // Attempt duplicate
    db.ProductPrices.Add(new ProductPrice { ProductId = 1, PriceTypeId = 1, Price = 200 });
    
    Assert.Throws<DbUpdateException>(() => db.SaveChanges());
}
```

### 2. Integration Tests (Database)
```csharp
[Fact]
public async Task Migration_AllProductsMigrated()
{
    using var db = new TekaDbContext();
    var count = await db.Products.CountAsync();
    Assert.Equal(27747, count);  // Expected from SQL Server
}

[Fact]
public async Task Migration_PriceStatistics()
{
    using var db = new TekaDbContext();
    var avgPrice = await db.ProductPrices.AverageAsync(p => p.Price);
    Assert.InRange(avgPrice, 268.0m, 269.0m);  // ~268.80 expected
}
```

### 3. Performance Tests
```csharp
[Fact]
public async Task Query_ProductsWithPrices_UnderOneSecond()
{
    var stopwatch = Stopwatch.StartNew();
    
    using var db = new TekaDbContext();
    var products = await db.Products
        .Include(p => p.Prices)
        .Take(100)
        .ToListAsync();
    
    stopwatch.Stop();
    Assert.True(stopwatch.ElapsedMilliseconds < 1000);
}
```

---

## ⚠️ Migration Risks & Mitigation

### Risk 1: Data Loss During Image Migration
**Probability:** Medium  
**Impact:** High  

**Mitigation:**
- Validate all images before deletion from SQL Server
- Keep SQL Server read-only for 30 days post-migration
- Checksum validation (MD5) before/after transfer
- Backup blob storage daily

### Risk 2: Decimal Precision Errors
**Probability:** Low  
**Impact:** High (financial data)

**Mitigation:**
- Unit tests for all decimal calculations
- Parallel run both systems for 1 week
- Compare PrimeCost calculations
- Automated reconciliation reports

### Risk 3: Performance Degradation
**Probability:** Medium  
**Impact:** Medium

**Mitigation:**
- Create all indexes before data load
- VACUUM ANALYZE after bulk insert
- Monitor query performance with pg_stat_statements
- Index optimization based on actual query patterns

### Risk 4: Foreign Key Violations
**Probability:** Medium  
**Impact:** High (blocks migration)

**Mitigation:**
- Pre-validate all FKs in SQL Server
- Load reference data first (categories, units, etc.)
- Use transactions (rollback on error)
- Detailed error logging with row IDs

### Risk 5: Application Downtime
**Probability:** Low  
**Impact:** Critical

**Mitigation:**
- Dry run migration on test database
- Weekend/off-hours migration window
- Blue-green deployment (old system standby)
- Rollback plan documented and tested

---

## 📊 Migration Timeline

| Phase | Duration | Parallel? | Dependencies |
|-------|----------|-----------|--------------|
| Schema Setup | 4h | No | None |
| Reference Data | 1h | No | Schema complete |
| Contractors | 2h | Yes (after Schema) | None |
| Products | 3h | No | Categories, Units, Contractors |
| Prices | 2h | No | Products, Price Types, Currencies |
| Cost Items | 2h | No | Products, Documents |
| Images | 3h | Yes (after Products) | Products |
| Validation | 2h | No | All data loaded |
| **Total** | **19h** | - | - |

**With parallelization:** 14-16 hours

### Recommended Schedule
**Friday Evening:**
- 6:00 PM: Freeze SQL Server (read-only mode)
- 6:30 PM: Begin migration
- 10:00 PM: Complete data migration
- 11:00 PM: Validation tests

**Saturday Morning:**
- 9:00 AM: Deploy new application
- 10:00 AM: Smoke tests
- 12:00 PM: Go-live (if all green)

**Rollback Window:** Until Sunday 6:00 PM

---

## ✅ Migration Checklist

### Pre-Migration
- [ ] PostgreSQL 15 installed and configured
- [ ] Database created with proper encoding (UTF8)
- [ ] Backup SQL Server database
- [ ] Export all table schemas
- [ ] Document row counts for all tables
- [ ] Test connection from application server

### Migration Execution
- [ ] Create all tables in PostgreSQL
- [ ] Create all indexes
- [ ] Load reference data (categories, units, price types)
- [ ] Load contractors
- [ ] Load products (exclude images)
- [ ] Load prices
- [ ] Load cost items
- [ ] Migrate images (separate process)
- [ ] Run validation queries

### Post-Migration
- [ ] Compare row counts (SQL Server vs PostgreSQL)
- [ ] Verify foreign key integrity
- [ ] Test price calculations (average, min, max)
- [ ] Test FIFO costing logic
- [ ] Verify image access (URLs or BYTEA)
- [ ] Performance test key queries (<1s for 100 rows)
- [ ] Deploy new application
- [ ] Smoke test all CRUD operations
- [ ] Monitor error logs for 24 hours

### Rollback Criteria
- [ ] Row count mismatch > 0.1%
- [ ] Foreign key violations detected
- [ ] Price calculation errors
- [ ] Application errors > 5 per hour
- [ ] Query performance degradation > 2x

---

## 📞 Support Contacts

**Database Migration:** [Migration Lead]  
**Application Deployment:** [DevOps Team]  
**Business Validation:** [Product Owner]  
**Emergency Rollback:** [IT Manager]  

**Escalation Path:**
1. Database errors → Migration Lead
2. Application errors → DevOps Team
3. Data discrepancies → Business Validation
4. Critical failure → Emergency Rollback

---

**Document Version:** 1.0 Final  
**Last Updated:** November 4, 2025  
**Estimated Total Cost:** 64 developer hours  
**Next Step:** Execute Task 1.3.2 (Financial Domain)

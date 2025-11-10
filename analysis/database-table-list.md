# Complete Table List - Teka_StoreNET_ERP Database

**Generated:** 2025-11-10  
**Total Tables:** 112  
**Purpose:** Quick reference to avoid unnecessary SQL queries

---

## 📋 ALL TABLES (Alphabetical)

```
doAddress
doAnonymousContractor
doAutomaticStoreAssembly
doBankAccount
doCashDesk
doCashDeskAmountTransfer
doCashDeskCurrencyChange
doCashDesk-Entries
doCashDesk-Stores
doCategory
doCity
doCompany
doCompany-BankAccounts
doCompanyIdentity
doContractor
doContractor-CategoryDiscounts
doContractor-ProductDiscounts
doCoreFtObject
doCountry
doCurrency
doCurrency-Rates
doDataObject
doDocument
doFinanceDefinition
doFinanceGroup
doFinanceTransaction
doFinanceTransaction-Items
doFtObject
doFtRecord
doIDataObject
doIFinancedTransaction
doIFinancedTransaction-Finances
doIFinanceTransactionOwner
doIFtObject
doIHasAutomaticAssembly
doIHasNoAccessControlList
doInvoice
doInvoice-CashDesks
doInvoice-Items
doISecurityRoot
doISystemTransaction
doITransaction
doMeasureUnit
doMessagePool
doMessagePool-ChatMessages
doMessagePool-MessageFileContents
doMessagePool-MessageFiles
doMessagePool-Messages
doObjectIdentity
doPermissionRoot
doPerson
doPrincipal
doPrincipal-Roles
doProduct
doProduct-Prices
doProductPriceType
doProductPriceType-Stores
doProduct-PrimeCostItems
doProductReceipt
doRegion
doRole
doSecurityLog
doSecurityLog-Entries
doSecurityRoot
doStdUser
doStore
doStoreAssembly
doStoreAssembly-InputItems
doStoreAssemblyItem
doStoreAssembly-OutputItems
doStoreAssemblyTemplate
doStoreAssemblyTemplate-InputItems
doStoreAssemblyTemplateItem
doStoreAssemblyTemplate-OutputItems
doStoreDiscard
doStoreDiscardItem
doStore-InitiationItems
doStore-InitiationLogItems
doStore-Items
doStore-LogItems
doStore-RequestItems
doStoreTransfer
doStoreTransfer-HistoryItems
doStoreTransferItem
doStoreTransfer-LogItems
doSysInfo
doSystemFinanceDefinition
doSystemSettings
doSystemSettings-Identities
doSystemTransaction
doSysTypes
doTrade
doTradeCancel
doTradeCancel-Items
doTradeDelivery
doTradeDelivery-Items
doTradeItem
doTradePayment
doTradePayment-Items
doTradeReturn
doTradeReturn-Items
doTradeTransaction
doTransaction
doTransactionFinance
doTransactionFinanceDefinition
doTransactionInfo
doUser
doUserAccount
doUserRole
```

---

## 🎯 DOMAIN CATEGORIZATION

### Core Infrastructure (12)
- doCoreFtObject, doDataObject, doFtObject, doFtRecord
- doIDataObject, doIFtObject, doObjectIdentity
- doSysInfo, doSystemSettings, doSystemSettings-Identities, doSysTypes
- doPermissionRoot

### Documents Domain (3)
- doDocument
- doInvoice, doInvoice-Items
- doInvoice-CashDesks

### Financial Domain (8)
- doCurrency, doCurrency-Rates
- doCashDesk, doCashDesk-Entries, doCashDesk-Stores
- doCashDeskAmountTransfer, doCashDeskCurrencyChange
- doBankAccount

### Products Domain (9)
- doProduct, doProduct-Prices, doProduct-PrimeCostItems
- doProductReceipt
- doProductPriceType, doProductPriceType-Stores
- doCategory, doMeasureUnit
- doAutomaticStoreAssembly

### Store/Inventory Domain (21)
- doStore, doStore-Items, doStore-LogItems
- doStore-InitiationItems, doStore-InitiationLogItems
- doStore-RequestItems
- doStoreTransfer, doStoreTransfer-HistoryItems, doStoreTransfer-LogItems
- doStoreTransferItem
- doStoreAssembly, doStoreAssembly-InputItems, doStoreAssembly-OutputItems
- doStoreAssemblyItem
- doStoreAssemblyTemplate, doStoreAssemblyTemplate-InputItems, doStoreAssemblyTemplate-OutputItems
- doStoreAssemblyTemplateItem
- doStoreDiscard, doStoreDiscardItem

### Trade/Sales Domain (14)
- doTrade, doTradeItem, doTradeTransaction
- doTradeCancel, doTradeCancel-Items
- doTradeDelivery, doTradeDelivery-Items
- doTradePayment, doTradePayment-Items
- doTradeReturn, doTradeReturn-Items
- doTransaction, doTransactionInfo
- doSystemTransaction

### Finance Transactions Domain (10)
- doFinanceDefinition, doSystemFinanceDefinition
- doFinanceGroup, doFinanceTransaction, doFinanceTransaction-Items
- doTransactionFinance, doTransactionFinanceDefinition
- doIFinancedTransaction, doIFinancedTransaction-Finances
- doIFinanceTransactionOwner

### Contractors/Parties Domain (8)
- doContractor, doContractor-CategoryDiscounts, doContractor-ProductDiscounts
- doAnonymousContractor
- doCompany, doCompany-BankAccounts, doCompanyIdentity
- doPerson

### Geographic Domain (4)
- doAddress, doCity, doRegion, doCountry

### Security/Users Domain (11)
- doUser, doUserAccount, doUserRole
- doStdUser
- doPrincipal, doPrincipal-Roles, doRole
- doSecurityRoot, doSecurityLog, doSecurityLog-Entries
- doISecurityRoot

### Messaging Domain (5)
- doMessagePool
- doMessagePool-ChatMessages
- doMessagePool-MessageFileContents
- doMessagePool-MessageFiles
- doMessagePool-Messages

### Interface Tables (7)
- doIDataObject, doIFtObject
- doIFinancedTransaction, doIFinanceTransactionOwner
- doIHasAutomaticAssembly, doIHasNoAccessControlList
- doISecurityRoot, doISystemTransaction, doITransaction

---

## 📊 STATISTICS

- **Total Tables:** 112
- **Interface Tables (doI*):** 7
- **Junction Tables (*-*):** 25
- **Log Tables (*Log*):** 4
- **History Tables (*History*):** 1

---

**Last Updated:** 2025-11-10

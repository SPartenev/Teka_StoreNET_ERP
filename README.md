# Teka Store.NET ERP - Modernization Project

## 🎯 Project Overview

Migration of Store.NET ERP system from legacy stack to modern architecture.

### Current System
- **Framework:** .NET Framework 1.1 / ASP.NET Web Forms
- **Database:** SQL Server 2005
- **ORM:** DataObjects.NET
- **UI:** Infragistics Web Controls

### Target System
- **Frontend:** Next.js 14 + TypeScript + Tailwind CSS
- **Backend:** .NET 8 Web API + Entity Framework Core
- **Database:** PostgreSQL 15
- **Architecture:** CQRS (MediatR) + SignalR

## 📊 Current Phase

**Month 1 - Week 1:** AI-Assisted Analysis & Database Schema Extraction

## 📁 Repository Structure
```
Teka_StoreNET_ERP/
├── analysis/
│   └── week1/
│       └── database/
│           ├── tables-data.json       # Machine-readable tables inventory
│           └── tables-report.md       # Human-readable overview
├── IMPLEMENTATION/
│   ├── Детайлен план за изпълнение.pdf
│   └── DETAILED IMPLEMENTATION PLAN04092025.pdf
├── docs/                              # (Coming soon)
└── README.md
```

## ✅ Progress Tracker

### Week 1: Database Analysis
- ✅ **Task 1.1:** Database Tables Inventory (57 tables documented)
- ⏳ **Task 1.2:** Foreign Keys & Relationships
- ⏳ **Task 1.3:** ERD Diagram Generation
- ⏳ **Task 1.4:** PostgreSQL Migration Notes

### Week 2-4: (Upcoming)
- Source Code Analysis
- UI Feature Mapping
- Business Rules Extraction
- Complete Feature Inventory

## 📈 Database Summary

- **Total Tables:** 57
- **Categories:** 8 (Core Business, Financial, Warehouse, Documents, Security, Messages, Reports, System)
- **Source:** TEKA.bak (backup dated 2024-11-26)

## 🔗 Key Documents

- [Детайлен план за изпълнение](./IMPLEMENTATION/Детайлен план за изпълнение.pdf)
- [Detailed Implementation Plan](./IMPLEMENTATION/DETAILED IMPLEMENTATION PLAN04092025.pdf)
- [Database Tables Report](./analysis/week1/database/tables-report.md)

## 👥 Team

- **Analysis Phase:** 1 developer + AI tools (Claude, GitHub Copilot)
- **Implementation Phase:** 3 specialists
- **Timeline:** 6 months (120 working days)

## 📝 Notes

This is a private repository for the Teka Store.NET modernization project. All analysis outputs are structured for both human review and AI agent consumption in future phases.

---

**Last Updated:** 2025-02-04
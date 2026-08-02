# Ramest Krishi Sewa Kendra - Database Schema Design

This document outlines the production-ready PostgreSQL schema designed specifically for Supabase. It incorporates offline-first considerations, audit logging, and multi-branch readiness.

## User Review Required
> [!IMPORTANT]
> Please review the SQL schema below. Ensure that the entities (Branches, Customers, Products, Sales) accurately reflect your business model. 
> 
> *Note:* I have bound the `profiles` table directly to Supabase's built-in `auth.users` table for secure authentication.

---

## 1. Architecture & Normalization Strategy
*   **Normalization (3NF):** Data is normalized to the Third Normal Form. For instance, customer details are not duplicated in the `sales` table; only the `customer_id` is referenced.
*   **UUIDs for Offline Sync:** All primary keys (`id`) are of type `UUID`. In an offline-first app, the Flutter client must generate the ID before syncing to prevent collision when multiple offline devices come online simultaneously.
*   **Multi-Tenant (Branch) Support:** Almost all operational tables include a `branch_id` foreign key. This ensures the database is future-proofed for the "Multi Branch" requirement.

## 2. Soft Delete & Sync Strategy
*   **Soft Deletes:** No operational data is ever physically deleted using `DELETE`. Instead, a `deleted_at` timestamp is set. 
    *   *Why?* If a record is hard-deleted on the server, offline devices pulling updates won't know the record was removed. With soft deletes, they pull the `deleted_at` flag and remove it from their local SQLite DB.
*   **Sync Tracking:** An `updated_at` column exists on every table. A PostgreSQL Trigger automatically updates this timestamp on every `UPDATE`. The offline sync engine uses this to fetch only records changed since the last sync.

## 3. Backup Strategy
*   **Automated Daily Backups:** Supabase provides automated daily backups by default.
*   **Point-in-Time Recovery (PITR):** For a production ERP, upgrading the Supabase project to the Pro plan enables PITR, allowing you to restore the database to any specific second in the past (crucial for ransomware or accidental bulk updates).
*   **Logical Backups:** A monthly `pg_dump` can be scheduled via a GitHub Action to store an encrypted SQL backup in cold storage (AWS S3) for disaster recovery compliance.

---

## 4. Complete PostgreSQL Schema (Supabase Compatible)

```sql
-- ===========================================================================
-- 1. EXTENSIONS & UTILITY FUNCTIONS
-- ===========================================================================
-- Ensure UUID generation is available
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Function to automatically update the 'updated_at' timestamp
CREATE OR REPLACE FUNCTION update_modified_column()   
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;   
END;
$$ language 'plpgsql';

-- ===========================================================================
-- 2. CORE TABLES
-- ===========================================================================

-- BRANCHES (Future-proofing for multi-branch)
CREATE TABLE public.branches (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- PROFILES (Extends Supabase auth.users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    branch_id UUID REFERENCES public.branches(id),
    full_name VARCHAR(255) NOT NULL,
    role VARCHAR(50) DEFAULT 'cashier' CHECK (role IN ('admin', 'cashier', 'manager')),
    phone VARCHAR(20),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- CUSTOMERS (Farmers / Khata ledgers)
CREATE TABLE public.customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES public.branches(id) NOT NULL,
    name VARCHAR(255) NOT NULL,
    phone VARCHAR(20),
    address TEXT,
    credit_balance NUMERIC(12, 2) DEFAULT 0.00, -- Negative means they owe us, Positive means advance
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- PRODUCT CATEGORIES
CREATE TABLE public.categories (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES public.branches(id) NOT NULL,
    name VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- PRODUCTS
CREATE TABLE public.products (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES public.branches(id) NOT NULL,
    category_id UUID REFERENCES public.categories(id),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    unit VARCHAR(50) NOT NULL, -- e.g., 'Kg', 'Litre', 'Bag'
    cost_price NUMERIC(10, 2) NOT NULL,
    selling_price NUMERIC(10, 2) NOT NULL,
    stock_quantity NUMERIC(10, 2) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- ===========================================================================
-- 3. TRANSACTIONS & SALES
-- ===========================================================================

-- SALES (Invoices)
CREATE TABLE public.sales (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES public.branches(id) NOT NULL,
    customer_id UUID REFERENCES public.customers(id), -- Can be NULL for Walk-in
    user_id UUID REFERENCES public.profiles(id) NOT NULL,
    total_amount NUMERIC(12, 2) NOT NULL,
    paid_amount NUMERIC(12, 2) NOT NULL,
    discount NUMERIC(12, 2) DEFAULT 0.00,
    payment_method VARCHAR(50) CHECK (payment_method IN ('cash', 'upi', 'khata', 'split')),
    sale_date TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- SALE ITEMS (Invoice Line Items)
CREATE TABLE public.sale_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    sale_id UUID REFERENCES public.sales(id) ON DELETE CASCADE,
    product_id UUID REFERENCES public.products(id) NOT NULL,
    quantity NUMERIC(10, 2) NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
    subtotal NUMERIC(12, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

-- ===========================================================================
-- 4. AUDIT & LOGGING
-- ===========================================================================

-- INVENTORY LOGS (Tracks every stock movement for transparency)
CREATE TABLE public.inventory_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    branch_id UUID REFERENCES public.branches(id) NOT NULL,
    product_id UUID REFERENCES public.products(id) NOT NULL,
    user_id UUID REFERENCES public.profiles(id) NOT NULL,
    change_type VARCHAR(20) CHECK (change_type IN ('PURCHASE', 'SALE', 'RETURN', 'ADJUSTMENT')),
    quantity_changed NUMERIC(10, 2) NOT NULL,
    reference_id UUID, -- Links to sale_id or purchase_id
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- AUDIT LOGS (For critical security auditing)
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    table_name VARCHAR(255) NOT NULL,
    record_id UUID NOT NULL,
    action VARCHAR(20) CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    old_data JSONB,
    new_data JSONB,
    user_id UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===========================================================================
-- 5. INDEXES for Performance (Crucial for ERPs)
-- ===========================================================================
CREATE INDEX idx_customers_branch ON public.customers(branch_id);
CREATE INDEX idx_products_category ON public.products(category_id);
CREATE INDEX idx_sales_date ON public.sales(sale_date);
CREATE INDEX idx_sales_customer ON public.sales(customer_id);
CREATE INDEX idx_sync_updated_at ON public.products(updated_at); 
-- (Indexes on updated_at are critical across all tables to speed up offline sync queries)
CREATE INDEX idx_sales_updated_at ON public.sales(updated_at);
CREATE INDEX idx_customers_updated_at ON public.customers(updated_at);

-- ===========================================================================
-- 6. TRIGGERS
-- ===========================================================================
-- Apply the updated_at trigger to all syncable tables
CREATE TRIGGER update_branches_modtime BEFORE UPDATE ON public.branches FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER update_profiles_modtime BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER update_customers_modtime BEFORE UPDATE ON public.customers FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER update_categories_modtime BEFORE UPDATE ON public.categories FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER update_products_modtime BEFORE UPDATE ON public.products FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER update_sales_modtime BEFORE UPDATE ON public.sales FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
CREATE TRIGGER update_sale_items_modtime BEFORE UPDATE ON public.sale_items FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
```

---

## 5. Relationships & Constraints Summary
*   **Cascading Deletes:** Avoided wherever possible to prevent accidental massive data loss. The exception is `sale_items` which cascades if a `sale` is somehow hard-deleted (though our soft-delete strategy prevents this).
*   **Foreign Keys:** Strictly enforced. A sale cannot reference a non-existent customer or product.
*   **Data Integrity:** Checks are placed on enums like `payment_method` (`cash`, `upi`, `khata`, `split`) and `change_type` to ensure clean data input.

## 6. Sync Tables Note
You might notice there isn't a `sync_queue` table in the *Supabase* schema. 
This is intentional. The `sync_queue` table is strictly an **offline SQLite concept** used to queue actions locally on the device when there is no internet. Supabase itself does not need a sync queue; it acts as the centralized source of truth processing standard REST/RPC commands sent by the clients when they come online.

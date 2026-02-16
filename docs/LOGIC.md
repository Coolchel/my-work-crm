# Business Logic & Algorithms

## 1. Calculation Rules
*   **Rounding:**
    *   **Works:** Always Integer (Round to nearest 1).
    *   **Materials:** 2 decimal places.
    *   **Display:** Strip trailing zeros (`10.00` -> `10`).
*   **Smart Calculator (Volumes):**
    *   `Total` is the Anchor.
    *   `Partner` is usually the variable.
    *   `Me = Total - Partner`.
*   **Markup (Materials):**
    *   `ClientPrice = BasePrice + (BasePrice * Markup% / 100)`.
    *   `MyIncome = (ClientPrice * Qty) - (PartnerQty * BasePrice)`. Partner gets NO markup share.

## 2. Automation Algorithms
### 2.1. Shield -> Material (Import)
1.  **Scan:** Iterate all `ShieldGroup` items.
2.  **Key Gen:** Create key `shield_{device_type}_{poles}` (e.g., `shield_circuit_breaker_1P`).
3.  **Lookup:** Find `CatalogItem` where `mapping_key` matches.
4.  **Action:**
    *   If found: Create/Update `EstimateItem` (Material).
    *   If not found: Create Warning Item ("NOT FOUND: ...").
    *   **Quantity:** Sum of physical devices.

### 2.2. Material -> Work (Auto-Calc)
Triggered when Materials are updated.
1.  **Direct Link:** If Material has `related_work_item`, create Work Item 1-to-1.
2.  **Aggregation:**
    *   Group Materials by `aggregation_key` (e.g., `cable_laying`).
    *   Sum Quantities (100m + 50m = 150m).
    *   Find Work Item with corresponding matching key.
    *   Create **ONE** Work Item with total quantity.

### 2.3. Template System
*   **Behavior:** "Clear & Apply" (Полная замена).
*   **Logic:**
    1.  User selects a template (Work, Material, Shield).
    2.  System **deletes all existing items** in that specific section/stage.
    3.  System inserts items from the template.
*   **Safety:** Must trigger `ConfirmationDialog` before execution to prevent data loss.

## 3. Engineering Logic
### 3.1. Shield Sizing
*   **Power:** `Modules = Sum(DeviceWidths)`. 1P=1, 2P=2, 3P=3, 4P=4.
*   **LED (Transformers -> Modules):**
    *   1-2 -> 0 (External/Weak Current)
    *   3-4 -> 24 mod
    *   5-9 -> 36 mod
    *   10-12 -> 48 mod
    *   13+ -> 60 mod / Custom
*   **Multimedia (Lines -> Modules):**
    *   0-4 -> 24 mod
    *   5-10 -> 36 mod
    *   10+ -> Custom

## 4. Updates & Synchronization
*   **Project Dates:**
    *   `updated_at`: Updates only if changes > 2 hours after creation.
*   **Stage Dates:**
    *   Updating an Estimate Item touches parent Stage `updated_at`.


## 5. Directory (Reference Book) Logic
### 5.1. Data Model
*   `DirectorySection`: stores section-level metadata (`code`, `name`, `description`).
*   `DirectoryEntry`: stores editable values for a section (`code`, `name`, `sort_order`, `is_active`, `metadata`).
*   Uniqueness rule: `DirectoryEntry.code` must be unique inside one section.

### 5.2. Bootstrap Synchronization
*   Endpoint: `POST /api/directory-sections/bootstrap/`.
*   Purpose: synchronize built-in model choices into editable DB dictionaries.
*   Source choices include: project statuses, object types, stage titles/statuses, catalog item types, currencies, estimate item types, shield types, shield mounting, shield device types, project file categories.
*   Behavior: upsert sections and entries (safe re-run, idempotent in practice for existing codes).

### 5.3. CRUD Access
*   `DirectorySection` and `DirectoryEntry` provide full CRUD via REST endpoints.
*   Catalog admin part (categories + catalog items) also remains full CRUD from app UI.
*   Catalog item CRUD must preserve technical fields: `mapping_key`, `aggregation_key`, `related_work_item`.
*   Directory entry CRUD must preserve JSON `metadata`.


### 5.4. UI Synchronization Flow
*   On entering the directory screen, app triggers automatic `bootstrap` synchronization for system sections.
*   During synchronization, system tab shows a loading state with explicit wait message to prevent editing stale data.
*   Manual "Synchronize" action remains available as a recovery/retry path for admins.
*   If backend returns `503` (tables not ready/migrations missing), UI shows a human-readable error message instead of raw transport error text.

### 5.5. Directory Error Contract (Tables Not Ready)
*   Backend detection: missing `core_directorysection` / `core_directoryentry` tables.
*   Response strategy:
    *   `list`: return empty array for directory sections/entries.
    *   `bootstrap`, `retrieve`, `create`, `update`, `partial_update`, `destroy`: return HTTP `503` with readable `error`.
*   Goal: safe startup behavior before migrations and predictable client UX.

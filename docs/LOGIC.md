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

### 2.4. Precalc -> Active Stage Transfer (Estimate Sections)
Triggered manually from estimate `Actions` menu.
1.  **Availability:**
    *   Current stage title must be one of `stage_1`, `stage_2`, `stage_1_2`.
    *   Project must contain `precalc` stage.
    *   `precalc` must have at least one estimate item in the currently opened section (`work` for Works tab, non-`work` for Materials tab).
2.  **Confirmation Rule:**
    *   If current section already has items, show confirmation dialog before replacement.
3.  **Apply Rule (Clear & Replace):**
    *   Delete all current section items in target stage.
    *   Create new section items in target stage by copying fields from `precalc` section items (`item_type`, `name`, `unit`, `price_per_unit`, `currency`, `total_quantity`, `employer_quantity`).
4.  **Scope Isolation:**
    *   Works transfer affects only `work` items.
    *   Materials transfer affects only non-`work` items.

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
*   **Home Smart Search Normalization:**
    *   Query and searchable text are normalized to lowercase before matching.
    *   Search behavior is always case-insensitive.
*   **Home Settings Entry Flow:**
    *   Settings screen is opened from Home header action button (`top-right`).
    *   Bottom main navigation does not include a dedicated Settings destination.
*   **Project List Stripe Color Priority (By Stage Composition):**
    *   Priority order: `stage_3` -> `stage_1/stage_2/stage_1_2` -> `extra/other` -> `precalc` -> default.
    *   Mapping:
        *   `stage_3` present with at least one `work` estimate item -> Green.
        *   `stage_1` / `stage_2` / `stage_1_2` present (without `stage_3`) -> Blue.
        *   `extra` present (without core stages) -> Purple.
        *   `other` present (without core stages and without `extra`) -> Amber.
        *   `precalc` only -> BlueGrey.
        *   no stages -> Indigo.
*   **Create Operation Stability (Project/Stage):**
    *   Frontend must treat `201 Created` as success without emitting secondary false errors from local async state transitions.
    *   UI dialogs should block repeated submit while request is in-flight.
*   **User Feedback Routing:**
    *   Domain/transport errors -> snackbar.
    *   Input validation failures -> inline field error.
    *   Success snackbar should be omitted when UI already reflects the completed action directly.
*   **Estimate Dense UI Invariance:**
    *   Compact redesign of estimate rows/groups is presentation-only.
    *   Existing payloads, calculations, rounding, and stage update side-effects remain unchanged.
*   **No-Data Presentation Rule:**
    *   Any UI branch with `items.isEmpty`/`data.isEmpty` should render a unified friendly empty-state widget with icon + explanatory text.
    *   Empty-state rendering must not change existing data fetch/update flow; it is presentation-only.
*   **Files Category Default Expansion:**
    *   Initial category expansion depends on file count only.
    *   `count == 0` -> collapsed.
    *   `count >= 1 && count <= 6` -> expanded.
    *   `count > 6` -> collapsed.
*   **Statistics Period Switching:**
    *   Selecting the same period value must not trigger a new state update/fetch.
    *   On period change, previously loaded statistics remain visible while fresh data is requested.
    *   Period switching must not show a separate moving top loading bar under section header.
*   **Statistics Work-Dynamics Help Hint:**
    *   Help tooltip is anchored to the top-right corner of each chart card (USD/BYN), not inside chart legend row.
    *   Tooltip message is multiline and explains that chart values are based on completed objects and are independent from payment state.


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

### 5.6. Directory Interaction Rules
*   Second-level directory entities (section entries, category items) support row-tap edit flow.
*   Bottom directory navigation remains accessible on second-level screens; switching tab returns to the corresponding root tab context.
*   Delete icons use neutral hover styling (no danger-color hover escalation on icon hover itself); destructive intent remains in confirmation dialog.

### 5.7. Directory Access Gate (Settings)
*   Entry point: Settings -> Directory.
*   Flow:
    1. Show warning dialog about high-impact dictionary/catalog changes.
    2. Require current-account password.
    3. Validate password using auth repository flow.
    4. Navigate to Directory only on successful validation.
*   Invalid password keeps dialog open and shows field-level error.

### 5.8. Text Encoding Resilience (Directory/Catalog)
*   Backend normalizes potentially broken mojibake strings on serializer input/output for:
    *   `DirectorySection.name`, `DirectorySection.description`
    *   `DirectoryEntry.name`
    *   `CatalogCategory.name`
    *   `CatalogItem.name`, `CatalogItem.unit`
*   Repair command is available for one-shot cleanup of persisted data:
    *   `python manage.py repair_text_encoding`

# Functional Specifications (Specs)

## 1. Authentication & Security
*   **Mechanism:** JWT (Access + Refresh).
*   **Flow:**
    *   **App Start:** Check local storage for tokens. Verify validity via API.
    *   **Interceptors:** Auto-inject `Bearer` token. Auto-refresh on 401. Redirect to Login on failure.
*   **Settings:** Centralized "Account" section for Logout and Password Change.

## 2. Dashboard (Home)
*   **Smart Search:** Global search across Projects, Materials, and Works.
    *   Matching is always case-insensitive (forced normalization regardless of keyboard layout/case).
*   **Quick Stats (Current Month):**
    *   *Pre-calculations:* Count of stages with "precalc" title.
    *   *Active Objects:* Unique projects with active stages.
    *   *Paid:* Count of paid stages.
*   **Recent Projects:** Sorted by update time.
*   **Recent Projects Hover:** Card hover behavior must match "Objects" section interaction style.

## 3. Project Management
*   **Structure:**
    *   **List View:** Filters (Source, Type, Status), Sorting (Date, Profitability).
    *   **Detail View:** header with Client/Source info. Tabs: Stages, Shields, Files.
*   **Files:**
    *   Limit: 12 files/project, 20MB/file.
    *   Types: Images, Documents, Video.
    *   Features: Rename (safe), Download, Auto-expand categories < 5 items.

## 4. Estimates (The Core)
*   **Structure:**
    *   **Stages:** Flexible workspace (e.g., "Stage 1", "Stage 2").
    *   **Tabs:** Works (Labor) vs. Materials (Goods).
*   **Calculation Logic:**
    *   **Smart Input:** `Total = Me + Partner`. Editing any 2 updates the 3rd.
    *   **Markup:** Applies to Material Client Price only. `ClientPrice = BasePrice * (1 + Markup%)`.
    *   **Currencies:** USD / BYN support per item.
*   **Automation (Import):**
    *   **Shield -> Materials:** Devices in Shield map to Catalog Items via `mapping_key`.
    *   **Materials -> Works:** Materials map to Works via `related_work_item` or `aggregation_key`.
*   **Reporting:**
    *   **Client:** Total amount.
    *   **Partner:** Their share (`employer_quantity`).
    *   **Internal:** "My Share" calculation.
    *   **Export:** Native PDF generation.

## 5. Engineering Map (Shields)
*   **Types:** Power, LED, Multimedia (Low-voltage).
*   **Power Shields:**
    *   Hierarchy: Shield -> Groups -> Devices.
    *   Logic: Auto-calculate modules (`1P=1mod`, `3P=3mod`).
*   **LED Shields:**
    *   Logic: Suggest enclosure size based on transformer count (1-2->Small, 3-4->Medium...).
*   **Multimedia:**
    *   Logic: Suggest enclosure based on line count.

## 6. Financial Monitor
*   **Purpose:** Track unpaid stages across all projects.
*   **Views:**
    *   List of projects with expandable stages.
    *   Visual "Paid" confirmation.
    *   "Employer Share" display (if > 0).
*   **Hover Consistency:** All interactive finance list positions use the same hover feedback pattern for pointer devices.

## 7. Catalog & Directory (Admin)
*   **Catalog:**
    *   Editable categories.
    *   Editable catalog items (materials/works) with advanced automation fields.
    *   Keys:
        *   `mapping_key`: Connects Shield Device -> Material.
        *   `aggregation_key`: Groups multiple materials -> One Work (e.g., All cables -> "Cable Laying").
        *   `related_work_item`: Direct material -> work relation (1-to-1 override).
    *   Category field `labor_coefficient` must be editable from UI.
*   **System Directory Sections:**
    *   Editable dictionaries for values historically stored in model `choices`.
    *   Includes statuses/types/currencies/shield and file classification enums.
    *   Bootstrap endpoint to sync defaults into DB: `POST /api/directory-sections/bootstrap/`.
*   **CRUD:** Full add/edit/delete from app UI for directory sections, directory entries, categories, and catalog items.
*   **Entry Metadata:** `DirectoryEntry.metadata` is editable from UI as JSON object.
*   **System Sync UX:**
    *   Auto-run sync when opening the directory screen.
    *   Show dedicated loading state (please wait) during sync.
    *   Keep manual sync action in the directory AppBar as explicit retry tool on both tabs (`Система` and `Каталог`).
    *   Sync icon style must stay neutral (no blue-hover recolor) and match standard top-bar icon sizing.
*   **Directory Navigation UX:**
    *   Bottom directory `NavigationBar` (`System Sections` / `Catalog`) must stay visible on second-level screens (entries/items).
    *   Root tab label for system dictionaries is `Система`.
    *   Nested cards should not show chevron affordance; open/edit behavior is triggered by card tap.
    *   On second-level screens, tapping a row opens edit flow directly.
    *   Second-level screens keep FAB `+` tooltip and use explicit back-left AppBar icon for consistency.
*   **DB Not Ready Handling (Directory API):**
    *   If directory tables are missing, backend returns `503` for directory CRUD and bootstrap/retrieve operations.
    *   Directory list endpoints may return empty arrays as a safe fallback during startup/migration mismatch.
*   **Settings Entry Protection (Directory):**
    *   Entering Directory from Settings requires two-step confirmation:
        *   warning dialog about high-impact edits;
        *   current-account password validation before navigation.
    *   Access is denied when password check fails; user receives explicit validation error.
*   **Directory Form Controls:**
    *   In Directory dialogs, default dropdown widgets are replaced with custom popup-select controls (clean neutral style, no logos/icons in options).

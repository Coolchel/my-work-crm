# Functional Specifications (Specs)

## 0. Encoding Contract
*   **UTF-8 Everywhere:** Frontend/backend source files and runtime UI strings must use UTF-8 encoding; any mojibake text is treated as a blocking defect.

## 1. Authentication & Security
*   **Mechanism:** JWT (Access + Refresh).
*   **Flow:**
    *   **App Start:** Check local storage for tokens. Verify validity via API.
    *   **Interceptors:** Auto-inject `Bearer` token. Auto-refresh on 401. Redirect to Login on failure.
*   **Settings:** Centralized "Account" section for Logout and Password Change.

## 2. Dashboard (Home)
*   **Smart Search:** Global search across Projects, Materials, and Works.
    *   Matching is always case-insensitive (forced normalization regardless of keyboard layout/case).
*   **Main Navigation Contract:**
    *   Home tab label in bottom navigation is `Главная`.
    *   `Settings` is not present in the bottom navigation.
    *   Settings entry is available via top-right settings icon in the Home header.
    *   Bottom navigation labels are always visible under icons across primary app sections.
*   **Quick Stats (Current Month):**
    *   *Pre-calculations:* Count of stages with "precalc" title.
    *   *Active Objects:* Unique projects with active stages.
    *   *Paid:* Count of paid stages.
*   **Recent Projects:** Sorted by update time.
*   **Recent Projects Hover:** Card interaction in Home recent list follows the same visual behavior as `Stages` cards (no extra custom hover animation layer).

## 3. Project Management
*   **Structure:**
    *   **List View:** Filters (Source, Type, Status), Sorting (Date, Profitability).
    *   **Detail View:** header with Client/Source info. Tabs: Stages, Shields, Files.
    *   **Create UX Reliability:** Successful create operations (`Project`, `Stage`) must not show false error banners after HTTP `201`.
    *   **Object Card Accent Stripe:** color depends on stage composition:
        *   No stages -> Indigo (default).
        *   Has `precalc` only -> BlueGrey.
        *   Has `stage_1` / `stage_2` / `stage_1_2` -> Blue.
        *   Has `stage_3` with at least one estimate item of type `work` -> Green.
        *   Only `other` (or `precalc` + `other`) -> Amber.
        *   Only `extra` (or `precalc` + `extra`) -> Purple.
        *   If `stage_1`/`stage_2`/`stage_1_2` or `stage_3` is present together with `other`/`extra`, core stage colors (Blue/Green) take priority.
*   **Files:**
    *   Limit: 12 files/project, 20MB/file.
    *   Types: Images, Documents, Video.
    *   Features: Rename (safe), Download.
    *   Category Default Expand Rule:
        *   0 files -> collapsed.
        *   1-6 files -> expanded.
        *   7+ files -> collapsed.

## 4. Estimates (The Core)
*   **Structure:**
    *   **Stages:** Flexible workspace (e.g., "Stage 1", "Stage 2").
    *   **Tabs:** Works (Labor) vs. Materials (Goods).
    *   **Compact Density Contract:** Works/Materials lists keep compact row/card density for high item count scenarios.
    *   **Behavior Preservation:** Redesign must not alter existing estimate flows (add/edit/delete/import/template/text/PDF actions, markup handling, totals visibility rules).
*   **Calculation Logic:**
    *   **Smart Input:** `Total = Me + Partner`. Editing any 2 updates the 3rd.
    *   **Markup:** Applies to Material Client Price only. `ClientPrice = BasePrice * (1 + Markup%)`.
    *   **Currencies:** USD / BYN support per item.
*   **Automation (Import):**
    *   **Shield -> Materials:** Devices in Shield map to Catalog Items via `mapping_key`.
    *   **Materials -> Works:** Materials map to Works via `related_work_item` or `aggregation_key`.
    *   **Precalc -> Stage 1/2/1+2 (Manual Action):**
        *   In estimate `Actions` menu, a transfer action is shown only for stages `stage_1`, `stage_2`, `stage_1_2`.
        *   Action is available only when project has `precalc` stage with at least one position in the current section (`materials` or `works`).
        *   On confirm, current section positions are fully replaced by positions from project `precalc` stage in the same section.
        *   If target section is non-empty, user must pass confirmation dialog before replacement.
    *   **Stage 3 Materials Armature Calculator (Manual Action):**
        *   In estimate `Actions` menu for Materials tab, action is shown only for stage `stage_3`.
        *   Action opens dedicated dialog with fixed armature positions from catalog (switches/sockets/frames), readable Russian labels, semantic row icons by armature type, quick add buttons (`+1`, `+2`, `+3`) and editable total per row.
        *   Catalog binding is resolved by technical `mapping_key` values for each armature row (name text can vary in catalog without breaking calculator mapping).
        *   Applying calculator transfers only rows with total > 0 into current stage materials estimate.
        *   If materials section already has items, user must confirm full replacement before old positions are deleted and replaced.
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
*   **Expanded Card Tint:** Expanded/hovered project card background under header uses a soft low-intensity green tint (no saturated fill).
*   **Stage Date Tone:** Stage date labels under project headers use neutral text tones (black/grey), not alert colors.
*   **Pay Toggle UI:** "Оплачено/Не оплачено" control in stage rows uses compact modern pill styling while preserving existing action behavior.
*   **Hover Consistency:** All interactive finance list positions use the same hover feedback pattern for pointer devices.
*   **Card Family Consistency:** Finance project cards and nested stage rows follow the same visual family as Objects/Stages cards (neutral surface, shared radius/spacing rhythm, accent stripe semantics), while preserving existing finance interactions and calculations.
*   **Finance Service States:** Finance loading/error empty-service states use friendly centered presentation with explicit retry action for recoverable fetch failures.

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

## 8. Section Header UX
*   **Compact Visual Header:**
    *   Sections `Statistics`, `Finance`, `Objects`, `Stages`, `Estimates`, `Shields`, `Files`, `Directory`, and `Settings` use a unified compact top header style.
    *   Header must stay visually expressive (gradient + icon + title) while remaining mobile-friendly in height.
    *   Header title typography should avoid over-bold rendering: prefer readable medium/semi-bold weight with slightly increased visual size.
    *   Detail sub-sections may show contextual subtitle (e.g., object address or selected directory entity).
    *   Header keeps a unified bottom gap before content; non-home sections use increased spacing for clearer visual rhythm.
    *   `Home` keeps its own hero spacing model and is not constrained by compact-section header gap rules.
    *   `Statistics` keeps a compact header-to-content spacing profile compared to other sections.
*   **Main Tabs Motif Rule:**
    *   `Home` remains the primary hero-gradient screen.
    *   `Objects`, `Finance`, and `Statistics` reuse the same motif in a restrained compact-header gradient (no layout or height increase).
*   **Statistics Accent Rule:**
    *   Top period switch and decorative section stripes in `Statistics` use brand blue/indigo accent tokens.
*   **Statistics Tooltip Rule:**
    *   Work-dynamics charts (USD and BYN cards) show a compact `?` help icon in the top-right card corner.
    *   Tooltip text: `Динамика работ. Показывает заработок по сделанным объектам. Не связано с оплатой.`
    *   Legacy bottom note under charts is removed to reduce visual noise.
*   **Statistics Refresh UX Rule:**
    *   Changing period in statistics updates data content without full-screen loading replacement.
    *   No moving top loading bar should appear under the header on period switch.

## 9. Visual Consistency Contracts
*   **Shared Background Contract:** Primary app screens use one common soft-light app background; foreground cards/dialogs remain visually distinct on light surfaces.
*   **Bottom Navigation Consistency:** Main app nav, project-detail nav, and estimate nav share one tokenized visual family (bar height, icon sizing, selected-state pill/indicator, text emphasis).
*   **Empty State Contract:** In list/section areas where data can be absent, UI shows a reusable centered empty-state component (large low-contrast icon + title + short friendly hint) instead of plain `Text` placeholders.

## 10. Feedback UX (Snackbar & Validation)
*   **Error-first Snackbar:** keep snackbar primarily for operation/network/file errors.
*   **Validation Inline:** form validation messages are displayed inline near the relevant input instead of snackbar where possible.
*   **Success Signal Reduction:** avoid routine success snackbar when the result is immediately visible on screen (e.g., item added/deleted/renamed in-place).
*   **Batch Actions:** avoid redundant "start + finish" snackbars for one flow; prefer one final status message.

## 11. App Theme
*   **Theme Modes:** Settings screen controls `Light` / `Dark` / `System` theme modes.
*   **Persistence:** Selected theme mode is persisted locally and restored on next app launch.
*   **Coverage Contract:** Dark theme must cover all primary sections and nested UI layers (dialogs, popups, cards, navigation bars, and empty states) without changing business behavior.
*   **Dark Surface Hierarchy Contract:** Dark mode uses three tonal layers: scaffold `background`, content `surface-1` (cards/lists), and elevated `surface-2` (dialogs/forms/summary panels).
*   **Dark Header Restraint Contract:** In dark mode, section AppBars use `surface` background with subtle accent tint only (no saturated full-width color fills).
*   **Dark Controls Contract:** Text inputs, popup selects, dropdown menus, and popup menus in dark mode must use dark filled surfaces and low-contrast borders.

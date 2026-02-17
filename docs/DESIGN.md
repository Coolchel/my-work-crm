# Design System & UI/UX

## 1. Color Palette
*   **Primary (Indigo):** Headers, Key Actions, Power Shields.
*   **Success (Teal/Green):** "Paid" status, Positive balances, Work Items.
*   **Unified Green Token:** All green accents across app sections (Estimates/Dialogs/Finance/Statistics/Object & Stage accents/Files) use one base color token equal to object accent stripe green (`Colors.green`). Opacity rules remain context-specific.
*   **Info (Blue):** Material Items, Files.
*   **Warning (Orange):** Alerts, Markup, Power Shield Accents.
*   **Purple:** LED Shields.
*   **Green:** Multimedia Shields (aligned with unified app green token).

## 2. Component Guidelines

### 2.1. Premium Dialogs
*   **Structure:**
    *   Rounded Corners: **24px**.
    *   Shadow: `blur: 20`, `offset: 0,10`, `opacity: 0.15`.
    *   Header: Light colored background (Theme Color with `opacity 0.12`).
*   **Inputs:**
    *   No fill (transparent).
    *   Floating Labels.
    *   Border Radius: **12px**.

### 2.2. Interactive Cards (Hover)
*   **Behavior:** Scale x1.05 on hover.
*   **Rendering:** MUST use `Clip.antiAlias` to prevent square hover effects on rounded cards.
*   **Cursor:** `SystemMouseCursors.click` (Hand) for all clickable zones.
*   **Consistency Rule:** Home recent objects and Finance interactive rows follow the same hover feedback family as object cards (matching visual intensity and timing).

### 2.3. Typography & Data
*   **Numbers:**
    *   Prices/Sums: **Black** (for visibility).
    *   Secondary Info (e.g., "from total"): **Grey** (11px).
*   **Lists:**
    *   Dense layout (min vertical padding).
    *   Vertical centering of all row elements.
*   **Validation Messaging:** Prefer inline compact validation text near a field over bottom snackbar for form constraints.
*   **Snackbar Density:** Keep snackbar usage concise and event-critical; avoid routine positive noise when result is already visible in UI.

## 3. Specific Screens

### 3.1. Project Header (V6)
*   **Look:** White Card, 20px Radius, 6px Indigo Stripe left.
*   **Content:** Vertical Stack: [Client Info] + [Source].
*   **Interaction:** Selectable text for copy-paste.
*   **Object List Card Stripe:** Left accent stripe reflects aggregate stage progress:
    *   default/no stages -> Indigo;
    *   `precalc` only -> BlueGrey;
    *   `stage_1` / `stage_2` / `stage_1_2` -> Blue;
    *   `stage_3` -> Green;
    *   `other` (or `precalc`+`other`) -> Amber;
    *   `extra` (or `precalc`+`extra`) -> Purple;
    *   core production stages (`stage_1/2/1+2/3`) visually override `other/extra`.

### 3.2. Shield Cards
*   **Visual Logic:**
    *   **Stripe:** 4px left border coding type (Blue=Power, Purple=LED, Green=Multimedia).
    *   **Header:** Expands to show content. Background tints slightly on expand.
    *   **Devices:** Colored icons (Red=Switch, Blue=Breaker, Amber=RCD).

### 3.3. Finance Dashboard
*   **Project Card:**
    *   **Active:** Green border (width 2.0) when expanded.
    *   **Paid Badge:** Green Pill with "PAID" text.
    *   **Expanded Surface:** Keep expanded card/body fill soft and low-intensity in green (subtle tint only).
*   **Stage Date Label:** Use neutral black/grey date colors under stage names (no warning/error hue coding).
*   **Pay Toggle Button:** Stage payment button uses compact rounded pill style with soft green tint and subtle hover shadow.
*   **All Positions Hover:** Every clickable finance position has hover highlight (not only parent project card).

### 3.4. Home Header & Main Navigation
*   **Bottom Main Navigation:** Includes `Главная`, `Объекты`, `Финансы`, `Статистика`; no `Settings` destination.
*   **Settings Entry Point:** Top-right settings icon in Home header gradient block.
*   **Header Balance:** Keep greeting text area dominant while preserving touch-friendly settings icon hit target.

### 3.5. Section Header Typography
*   **Weight:** Use medium/semi-bold title weight to avoid visually heavy section names.
*   **Scale:** Keep title slightly larger for quicker recognition on desktop and mobile.
*   **Subtitle Contrast:** Subtitle remains lighter to preserve hierarchy under section title.

### 3.6. Project Files Tab
*   **Category Cards:** File category sections in project detail follow the same card family as `Objects`/`Stages` (neutral white surface, subtle shadow, compact readable typography, left accent stripe, `Clip.antiAlias`).
*   **Header Accent Mapping:** Left stripe and header accents follow stage-like semantics by category: `PROJECT` -> BlueGrey (drawings), `WORK` -> Blue (implementation), `FINISH` -> Green (final photos).
*   **Header Actions:** Upload and expand/collapse controls stay in the category header with compact neutral action chips; file count is shown as a compact readable pill (`N файл/файла/файлов`).
*   **Vertical Rhythm:** Keep tighter spacing between collapsed file category headers to reduce visual gaps.
*   **File Item Cards:** Uploaded file cards use a compact visual footprint (smaller size in grid, reduced radii/paddings, concise metadata badge) while preserving quick hover actions.
*   **Quick Actions Contract:** Each file card keeps 4 hover actions (`rename`, `save as`, `share`, `delete`) and tap-to-open behavior unchanged.
*   **Behavior Contract:** Visual refresh must not alter file operations flow (upload/rename/download/share/delete/open) or auto-expand rule for categories with <= 5 files.

## 4. Icons & Assets
*   **Style:** Material Symbols Rounded.
*   **Files:**
    *   PDF: Neutral document icon with non-red accent.
    *   DOC: Blue Icon.
    *   Image: Thumbnail preview (`BoxFit.cover`).


### 3.7. Directory Screen (Reference Book)
*   **Navigation:** Bottom `NavigationBar` with two destinations: `System Sections` and `Catalog` (same pattern as main app sections).
*   **Nested Navigation:** Keep the same bottom `NavigationBar` visible on second-level directory screens.
*   **Naming:** System tab title in UI is `Система`.
*   **Density:** Use compact list rows (`dense`, reduced vertical visual density).
*   **Card Shape:** Rounded cards (~14px) with left accent stripe (entity color coding) to match object/stage cards.
*   **Dialogs:** Reuse premium dialog shell (24px corners, tinted header, concise actions).
*   **Dialog Controls:** Keep header/actions, but use refreshed form control styling (filled inputs, clearer focus border, styled switch container, consistent dropdown visual weight).
*   **Select Controls:** Replace default dropdown controls in directory forms with custom popup-select fields (neutral palette, no logos/images in options).
*   **Actions:** Fast inline CRUD icons (edit/delete/open) with minimal vertical space usage and hover tint.
*   **Hover:** No card scaling in directory; use light surface tint + soft shadow increase, `Clip.antiAlias`, and pointer cursor for interactive cards.
*   **Entry Behavior:** Auto-sync system sections on screen open; show blocking loading indicator with "please wait" message while synchronization is in progress.
*   **AppBar Action:** Use a back arrow as leading action. Place manual sync in right AppBar action icon on both directory tabs (neutral style, standard top-bar icon size, no blue-hover recolor).
*   **Nested Editing:** On second-level lists, tapping a row opens edit flow directly (inline edit icon remains available).
*   **Delete Icon:** Use close icon with neutral grey hover tint; destructive semantics are communicated by confirmation dialog.
*   **Affordance Cleanup:** Remove trailing chevron icon from cards that open nested lists.
*   **Nested FAB:** Second-level FAB `+` uses tooltip with the same placement pattern as stage/object analogs.

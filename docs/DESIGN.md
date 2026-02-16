# Design System & UI/UX

## 1. Color Palette
*   **Primary (Indigo):** Headers, Key Actions, Power Shields.
*   **Success (Teal/Green):** "Paid" status, Positive balances, Work Items.
*   **Info (Blue):** Material Items, Files.
*   **Warning (Orange):** Alerts, Markup, Power Shield Accents.
*   **Purple:** LED Shields.
*   **Amber:** Multimedia Shields.

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

### 2.3. Typography & Data
*   **Numbers:**
    *   Prices/Sums: **Black** (for visibility).
    *   Secondary Info (e.g., "from total"): **Grey** (11px).
*   **Lists:**
    *   Dense layout (min vertical padding).
    *   Vertical centering of all row elements.

## 3. Specific Screens

### 3.1. Project Header (V6)
*   **Look:** White Card, 20px Radius, 6px Indigo Stripe left.
*   **Content:** Vertical Stack: [Client Info] + [Source].
*   **Interaction:** Selectable text for copy-paste.

### 3.2. Shield Cards
*   **Visual Logic:**
    *   **Stripe:** 4px left border coding type (Blue=Power, Purple=LED, Amber=Media).
    *   **Header:** Expands to show content. Background tints slightly on expand.
    *   **Devices:** Colored icons (Red=Switch, Blue=Breaker, Amber=RCD).

### 3.3. Finance Dashboard
*   **Project Card:**
    *   **Active:** Green border (width 2.0) when expanded.
    *   **Paid Badge:** Green Pill with "PAID" text.

## 4. Icons & Assets
*   **Style:** Material Symbols Rounded.
*   **Files:**
    *   PDF: Red Icon.
    *   DOC: Blue Icon.
    *   Image: Thumbnail preview (`BoxFit.cover`).


### 3.4. Directory Screen (Reference Book)
*   **Navigation:** Bottom `NavigationBar` with two destinations: `System Sections` and `Catalog` (same pattern as main app sections).
*   **Nested Navigation:** Keep the same bottom `NavigationBar` visible on second-level directory screens.
*   **Naming:** System tab title in UI is `Система`.
*   **Density:** Use compact list rows (`dense`, reduced vertical visual density).
*   **Card Shape:** Rounded cards (~14px) with left accent stripe (entity color coding) to match object/stage cards.
*   **Dialogs:** Reuse premium dialog shell (24px corners, tinted header, concise actions).
*   **Dialog Controls:** Keep header/actions, but use refreshed form control styling (filled inputs, clearer focus border, styled switch container, consistent dropdown visual weight).
*   **Actions:** Fast inline CRUD icons (edit/delete/open) with minimal vertical space usage and hover tint.
*   **Hover:** No card scaling in directory; use light surface tint + soft shadow increase, `Clip.antiAlias`, and pointer cursor for interactive cards.
*   **Entry Behavior:** Auto-sync system sections on screen open; show blocking loading indicator with "please wait" message while synchronization is in progress.
*   **AppBar Action:** Use a back arrow as leading action. Place manual sync in right AppBar action icon on both directory tabs (neutral style, standard top-bar icon size, no blue-hover recolor).
*   **Nested Editing:** On second-level lists, tapping a row opens edit flow directly (inline edit icon remains available).
*   **Delete Icon:** Use close icon with neutral grey hover tint; destructive semantics are communicated by confirmation dialog.
*   **Affordance Cleanup:** Remove trailing chevron icon from cards that open nested lists.
*   **Nested FAB:** Second-level FAB `+` uses tooltip with the same placement pattern as stage/object analogs.

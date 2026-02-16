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
*   **Navigation:** Two tabs - `System Sections` and `Catalog`.
*   **Density:** Use compact list rows (`dense`, reduced vertical visual density).
*   **Card Shape:** Rounded cards (~14px) for list rows to match app style.
*   **Dialogs:** Reuse premium dialog shell (24px corners, tinted header, concise actions).
*   **Actions:** Fast inline CRUD icons (edit/delete/open) with minimal vertical space usage.

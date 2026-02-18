# Project: Smart Electric CRM (Constitution)

## 1. Project Goal
Create a premium, professional tool for electricians to manage projects, estimates, and engineering documentation. The app must feel "expensive" and high-quality, inspiring confidence in the user.

## 2. Core Principles
*   **Premium Aesthetics:** Use Glassmorphism, specific Color Palettes (Indigo, Teal, Orange), and custom UI components to avoid "default Flutter look".
*   **Friendly Empty States:** Any "no content yet" scenario should use a polished centered empty-state block with a subtle large icon and explanatory text, not plain one-line placeholders.
*   **Automation:** Minimizing manual entry. Engineering data (Shields) automatically generates Estimates (Materials & Works).
*   **Data Integrity:** "Safe" saving mechanisms, strict validation, and conflict resolution (e.g., smart merge logic for calculations).
*   **Controlled Admin Access:** Entry to high-impact admin areas (Directory) must require explicit warning + credential confirmation for the current account.
*   **Intentional Navigation:** Main bottom navigation stays focused on core work sections; Settings is accessed from the Home header action.
*   **Education:** The code and structure should serve as a mentorship platform, using clear English code and Russian comments/explanations.

## 3. Tech Stack
*   **Backend:** Django (Monolithic `core` app) + Django REST Framework.
*   **Database:** SQLite (Dev), PostgreSQL (Prod).
*   **Frontend:** Flutter (Windows focus, Android/Web compatible).
*   **State Management:** Riverpod.
*   **Auth:** JWT (Access/Refresh) with local secure storage.

## 4. Key Entities
*   **Project:** The central unit of work. Contains Stages, Shields, and Files.
    *   **Project Card Progress Accent:** Object list cards use stage-aware left accent stripe colors to communicate progress at a glance.
*   **Stage:** A phase of work (e.g., "Rough-in", "Finishing"). Contains the Estimate.
*   **Estimate (Smeta):** Divided into **Works** and **Materials**.
    *   **Smart Calculator:** Input 2 of 3 values (Total, Me, Partner) -> 3rd is auto-calculated.
    *   **Dense Estimate Workspace:** Works/Materials lists use compact card rows to keep many positions visible per screen while preserving existing estimate actions.
*   **Engineering Map:**
    *   **Shields (Power):** Hierarchical structure (Shield -> Groups -> Devices).
    *   **Multimedia/LED:** Low-voltage systems and LED zones.
    *   **Catalog:** The source of truth for all Items (Goods/Services) with technical keys for automation.
    *   **Directory (Reference Book):** Editable system dictionaries and catalog data to manage statuses/types/currencies and other app constants from UI.
    *   **Manual DB Editing Scope:** Directory UI must expose full practical CRUD for sections/entries/categories/items including technical automation fields (`mapping_key`, `aggregation_key`, `related_work_item`) and entry `metadata`.
    *   **Directory UX:** System dictionaries auto-synchronize on screen open with explicit loading feedback for admins.
    *   **Directory Navigation UX:** Bottom directory navigation (`System Sections` / `Catalog`) must remain visible on nested directory levels.
    *   **Directory Action UX:** Delete actions use neutral close icons with non-danger hover tint; edit on nested level is available by row tap in addition to inline actions.
    *   **Directory Entry Security:** Opening Directory from Settings is protected by danger-warning dialog and current-account password check.
    *   **Directory Data Robustness:** Text values from directory/catalog flows should stay readable in Russian even if legacy mojibake data appears (normalization + repair tooling).

## 5. Language Rules
*   **User Facing:** Russian (UI, DB Verbose Names, Messages).
*   **Code:** English (Variables, Classes, Functions).
*   **Comments/Docs:** Russian (Explaining *why* and *how*).

## 6. AI & Code Standards
*   **Style:** PEP8 (Python), Effective Dart.
*   **Logic:** Keep business logic in Backend (Services/Models) where possible.
*   **Safety:** Destructive actions must always have a `ConfirmationDialog`.

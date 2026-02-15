# Project: Smart Electric CRM (Constitution)

## 1. Project Goal
Create a premium, professional tool for electricians to manage projects, estimates, and engineering documentation. The app must feel "expensive" and high-quality, inspiring confidence in the user.

## 2. Core Principles
*   **Premium Aesthetics:** Use Glassmorphism, specific Color Palettes (Indigo, Teal, Orange), and custom UI components to avoid "default Flutter look".
*   **Automation:** Minimizing manual entry. Engineering data (Shields) automatically generates Estimates (Materials & Works).
*   **Data Integrity:** "Safe" saving mechanisms, strict validation, and conflict resolution (e.g., smart merge logic for calculations).
*   **Education:** The code and structure should serve as a mentorship platform, using clear English code and Russian comments/explanations.

## 3. Tech Stack
*   **Backend:** Django (Monolithic `core` app) + Django REST Framework.
*   **Database:** SQLite (Dev), PostgreSQL (Prod).
*   **Frontend:** Flutter (Windows focus, Android/Web compatible).
*   **State Management:** Riverpod.
*   **Auth:** JWT (Access/Refresh) with local secure storage.

## 4. Key Entities
*   **Project:** The central unit of work. Contains Stages, Shields, and Files.
*   **Stage:** A phase of work (e.g., "Rough-in", "Finishing"). Contains the Estimate.
*   **Estimate (Smeta):** Divided into **Works** and **Materials**.
    *   **Smart Calculator:** Input 2 of 3 values (Total, Me, Partner) -> 3rd is auto-calculated.
*   **Engineering Map:**
    *   **Shields (Power):** Hierarchical structure (Shield -> Groups -> Devices).
    *   **Multimedia/LED:** Low-voltage systems and LED zones.
    *   **Catalog:** The source of truth for all Items (Goods/Services) with technical keys for automation.

## 5. Language Rules
*   **User Facing:** Russian (UI, DB Verbose Names, Messages).
*   **Code:** English (Variables, Classes, Functions).
*   **Comments/Docs:** Russian (Explaining *why* and *how*).

## 6. AI & Code Standards
*   **Style:** PEP8 (Python), Effective Dart.
*   **Logic:** Keep business logic in Backend (Services/Models) where possible.
*   **Safety:** Destructive actions must always have a `ConfirmationDialog`.
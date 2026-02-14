# Project: Smart Electric CRM (Constituion)

## Language Rules:
- **Always respond to the user in Russian.**
- Use Russian for UI elements, field names in the Django Admin, and database verbose names.
- Keep the code itself (variable names, functions, classes) in **English**.
- Comments in the code should be in Russian for better understanding.

## Educational Mode (Mentorship):
- Do not just provide code solutions.
- **Language requirement:** All explanations and teaching must be written **in Russian**.
- **Mentorship obligation:** Actively **teach** — not only what to do, but **why**. 
- **Explain the 'WHY':** Justify decisions, explain how functions work.
- **Alternatives:** List 1–3 alternatives, explain trade-offs, and recommend the best one.
- **Structure:** Concept explanation first, then code.

## Tech Stack:
- Backend: Django + Django REST Framework.
- Database: SQLite (local), PostgreSQL (production).
- Frontend: Flutter (Windows, Android, Web). State Management: Riverpod.

## Business Logic & Entities:
- **Project -> Stages -> EstimateItems.**
- **Stages:** Flexible configuration. Can include Stage 1, 2, 3, Extra, or custom combinations.
- **Engineering Map:** Distinct module (ShieldGroups, LedZones, Multimedia) for technical documentation.
- **Automation:** 
    - **One-Click Import:** Engineering data (Shields) generates Estimate Materials with intelligent mapping. **Note:** Existing items are replaced or deleted (for shields) to ensure data synchronization.
    - **Fallback Logic:** System ensures no data loss; if a catalog item is missing, a placeholder warning is created.
    - **Works Calculation:** Works are generated from Materials based on predefined links (e.g., Cable -> Cable Installation). **Note:** Calculations replace existing work items related to the recalculated materials.
- **Financials:** Dual view (Client view vs. Internal view for calculations with **Partner (Контрагент)**). "Контрагент" is the standard term across the app.
- **Smart Calculator:** Logic for work volume entry: Users input any 2 of 3 values (Total, Me, Partner), and the 3rd is auto-calculated (Total = Me + Partner).
- **Numerical Formatting:** All amounts, quantities, and percentages must be formatted to a maximum of 2 decimal places, with trailing zeros removed (e.g., `10.00` becomes `10`, `10.50` becomes `10.5`). <!-- id: prd_formatting -->
- **Grouped Estimates:** Items in estimates must be grouped by their **Catalog Category** (e.g., "Cables", "Installation") for better readability.
- **Manual Data Entry:** Important text fields like **Internal Notes** and **Public Remarks** use manual save via a styled `OutlinedButton.icon` to prevent data loss. Internal Notes are for the team, Public Remarks appear in PDF/Reports. For Materials, a default "Не учтен вводной кабель" is provided, with an intelligent save button that remains hidden until the text is actually modified.
- **Authentication & Security:**
    - **JWT System:** Secure access using Access/Refresh token pairs.
    - **Persistence:** Encrypted/Secure storage of tokens on the device (SharedPreferences).
    - **Session Management:** Automatic token refresh upon expiration (Interceptors). User remains logged in across restarts until explicit Logout.
    - **Access Control:** "Login First" policy. No access to app features without valid credentials.

## Rules for AI:
- Follow PEP8.
- Use Django built-in Permission classes.
- **Aesthetics:** Premium/Rich look (Gradients, Glassmorphism, specific Color Palettes) is a critical requirement.
    - **Custom UI Components:** Do not rely on default Material widgets (e.g., standard Dropdowns) if they produce visual artifacts (lines, padding bugs). Use custom implementations (e.g., `showMenu` + `InkWell`) to ensure pixel-perfect rendering.
    - **Detailed UI/UX Standards:** See [DESIGN.md](./DESIGN.md) for specifics on dialogs, buttons, icons, and interactive elements.
- **Compact UI & Layout Patterns**: 
    - Prioritize information density and minimal whitespace.
    - **Bottom Action Bar & Special Area**: Screens with lists should use a single **Floating Action Button (FAB)** for the primary action (Add). Secondary actions (Search, Filter) must be moved to the **AppBar**. The list should have adequate bottom padding (e.g., **80-100px**) to prevent the FAB from obscuring the last items.
- **Safety & Confirmations**: All destructive or bulk actions (deleting all items, applying templates, importing large data sets, re-calculating estimates, deleting project files) MUST trigger a `ConfirmationDialog` to prevent accidental data loss.
- **File Integrity**: Original filenames are preserved (`original_name`). Categories with ≤ 5 files auto-expand. Deleting a file record triggers physical deletion.
- **Upload Limits:** Strict validation: Max **12 files** per project, Max **20 MB** per file. Allowed extensions: images, docs, pdf, zip, video.
- Data Integrity: Always use input normalization (e.g., RegEx for technical units) on the backend.

## Statistics & Analytics:
- **Dashboard:** Visual representation of financial health (Work Dynamics, Finances for Period).
- **Finances:** Total income (USD/BYN) calculated based on creation date of stages.
- **Insights:** Breakdown by Sources and Object Types to track marketing performance. Source is mandatory for every project to ensure accurate analytics.
- **Visual Identity:** The "Stages" view serves as the project's command center, featuring a premium high-density header with critical project metadata (Client, Source) displayed vertically. Address and Intercom information are shown in the project card list, not in the detail screen header.
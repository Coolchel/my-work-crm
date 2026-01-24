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
- **Automation:** Engineering data must be linkable to CatalogItems for automatic estimate generation.
- **Financials:** Dual view (Client view vs. Contractor "Internal" view with profit calculation).

## Rules for AI:
- Follow PEP8.
- Use Django built-in Permission classes.
- Design: Material 3, focus on expert-level UX (speed of input, normalization of data).
- Data Integrity: Always use input normalization (e.g., RegEx for technical units) on the backend.
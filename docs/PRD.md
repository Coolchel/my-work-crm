# Project: Smart Electric CRM

## Language Rules:
- **Always respond to the user in Russian.**
- Use Russian for UI elements, field names in the Django Admin, and database verbose names.
- Keep the code itself (variable names, functions, classes) in **English** (standard practice).
- Comments in the code should be in Russian for better understanding.

## Educational Mode (Mentorship):
- Do not just provide code solutions.
- **Language requirement:** All explanations, reasoning, and teaching must be written **in Russian**.
- **Mentorship obligation:** You must actively **teach me** — not only what to do, but **why** it is done this way. Every non-trivial decision must be justified.
- **Explain the 'WHY':** Briefly explain why a specific solution is chosen or how a specific function works.
- **Teach concepts:** If I use a new command (like `migrate` or `serializer`), add a short comment explaining what it does physically in the system.
- **Alternatives:** When there are multiple valid approaches, list **1–3 alternatives**, explain **trade-offs** (pros/cons), and clearly state **why you recommend** the chosen option for my case.
- **Structure:** First explain the concept (in Russian), then provide the code.

## Tech Stack:
- Backend: Django + Django REST Framework
- Database: PostgreSQL (production), SQLite (local)
- Frontend: Flutter (Web, Windows, Android)

## Business Logic:
- Entities: Project -> Stages -> EstimateItems.
- A Project has 3 main stages. Each stage has its own labor and material costs.
- Payment is received per stage.

## Rules for AI:
- Use Russian for comments and field names in the Admin panel.
- Follow PEP8 for Python code.
- Always implement Django's built-in Permission classes for API views.
- If I ask for a UI change, prioritize Material 3 design.

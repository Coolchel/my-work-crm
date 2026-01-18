# Project: Smart Electric CRM
## Language Rules:
- **Always respond to the user in Russian.**
- Use Russian for UI elements, field names in the Django Admin, and database verbose names.
- Keep the code itself (variable names, functions, classes) in **English** (standard practice).
- Comments in the code should be in Russian for better understanding.

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
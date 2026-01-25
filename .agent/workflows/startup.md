---
description: How to update and start the Smart Electric CRM (Backend & Frontend)
---

# Запуск и Обновление Проекта

## 1. Backend (Django)

Открыть терминал в папке `backend`:
```powershell
cd d:\my_software\work_project\backend
```

**Обновление (если были изменения в моделях):**
```powershell
python manage.py makemigrations
python manage.py migrate
```

**Запуск сервера:**
```powershell
python manage.py runserver 0.0.0.0:8000
```
*Сервер будет доступен по адресу http://127.0.0.1:8000*

## 2. Frontend (Flutter)

Открыть **новый** терминал в папке проекта Flutter:
```powershell
cd d:\my_software\work_project\frontend\smart_electric_crm
```

**Обновление зависимостей (если нужно):**
```powershell
flutter pub get
```

**Генерация кода (если менялись модели, например EstimateItem):**
```powershell
dart run build_runner build --delete-conflicting-outputs
```

**Запуск приложения (Windows):**
```powershell
flutter run -d windows
```

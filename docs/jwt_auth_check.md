# Проверка JWT авторизации (backend)

## 1) Подготовка

```bash
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

## 2) Получить JWT токены

```bash
curl -X POST http://127.0.0.1:8000/api/auth/token/ \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"YOUR_PASSWORD"}'
```

Ожидаемый ответ: JSON с полями `access` и `refresh`.

## 3) Проверить `/api/auth/me/`

```bash
curl http://127.0.0.1:8000/api/auth/me/ \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

Ожидаемый ответ: JSON с `id`, `username`, `email` текущего пользователя.

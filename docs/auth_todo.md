# TODO: Backend endpoints для авторизации

Текущий Flutter-слой авторизации реализован как каркас без реального сетевого входа.

Для интеграции с Django API нужны минимальные endpoints:
- `POST /api/auth/login` — вход, выдача access/refresh токенов.
- `POST /api/auth/refresh` — обновление access токена по refresh.
- `GET /api/auth/me` — данные текущего пользователя/валидность сессии.
- `POST /api/auth/logout` (опционально) — инвалидировать refresh токен.

> Сейчас токен хранится временно в `shared_preferences`.
> После подключения backend желательно перейти на secure storage.

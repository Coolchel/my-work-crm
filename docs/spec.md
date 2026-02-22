# Functional Specifications

## 0. Базовые контракты
- Кодировка: UTF-8 во frontend/backend и в пользовательских данных.
- Безопасность: подтверждение для разрушительных действий.
- Визуальные изменения не должны менять бизнес-поведение.

## 1. Authentication

### 1.1 Endpoints
- `POST /api/auth/token/` — логин.
- `POST /api/auth/refresh/` — обновление access.
- `GET /api/auth/me/` — профиль текущего пользователя.
- `POST /api/auth/change-password/` — смена пароля.

### 1.2 Клиентский flow
- На старте приложения проверяется валидность токенов.
- Access автоматически подставляется в запросы.
- При `401` выполняется refresh; при неуспехе — выход в экран логина.

## 2. Projects & Stages

### 2.1 Endpoints
- `GET/POST /api/projects/`
- `GET/PATCH/DELETE /api/projects/{id}/`
- `GET/POST /api/stages/`
- `GET/PATCH/DELETE /api/stages/{id}/`

### 2.2 Функциональные требования
- Создание проекта поддерживает `init_stages`.
- При создании проекта backend создает три базовых щита (`power/led/multimedia`).
- Статусы/типы и этапы задаются choices backend + доступны через Directory bootstrap.

## 3. Estimates

### 3.1 Endpoints
- `GET/POST /api/estimate-items/`
- `PATCH/DELETE /api/estimate-items/{id}/`
- `GET /api/stages/{id}/get_report/?type=work|material`

### 3.2 Функциональные требования
- Разделы: `works` и `materials`.
- Поддержка USD/BYN на уровне позиции.
- Поддержка `markup_percent`, `show_prices`, заметок и remarks на уровне этапа.

### 3.3 Формулы
- `client_amount`, `employer_amount`, `my_amount` — по правилам из `docs/LOGIC.md`.

## 4. Automation

### 4.1 Из инженерки в материалы
- `POST /api/stages/{id}/import_from_shields/`
- Создает/заменяет material-позиции по `mapping_key`.
- Добавляет/пересчитывает корпуса щитов.
- При отсутствии ключа создается предупреждающая позиция.

### 4.2 Из материалов в работы
- `POST /api/stages/{id}/calculate_works/`
- Поддержка `aggregation_key` и `related_work_item`.
- Для найденных связей создаются/заменяются work-позиции.

## 5. Templates

### 5.1 Stage templates
- Работы:
  - `GET/POST /api/work-templates/`
  - `POST /api/work-templates/create_from_stage/`
  - `POST /api/stages/{id}/apply_work_template/`
- Материалы:
  - `GET/POST /api/material-templates/`
  - `POST /api/material-templates/create_from_stage/`
  - `POST /api/stages/{id}/apply_material_template/`

### 5.2 Shield templates
- Силовые:
  - `GET/POST /api/powershield-templates/`
  - `POST /api/powershield-templates/create_from_shield/`
  - `POST /api/shields/{id}/apply_powershield_template/`
- LED:
  - `GET/POST /api/led-shield-templates/`
  - `POST /api/led-shield-templates/create_from_shield/`
  - `POST /api/shields/{id}/apply_led_shield_template/`

### 5.3 Поведение
- Применение шаблонов всегда `Clear & Apply` в границах выбранной секции.

## 6. Frontend-only workflows (важные UX-контракты)

### 6.1 `precalc` transfer
- Только для этапов `stage_1/stage_2/stage_1_2`.
- Переносится только текущая вкладка (`works` или `materials`).
- Если целевая вкладка непуста — обязательное подтверждение.

### 6.2 Stage 3 armature calculator
- Только на `stage_3` и только во вкладке материалов.
- Строки фиксированные, привязка к каталогу по `mapping_key` (с fallback по legacy имени).
- В перенос попадают строки с количеством > 0.
- Применение выполняется как `clear & replace` материалов этапа.

## 7. Engineering

### 7.1 Endpoints
- `GET/POST /api/shields/`
- `GET/POST /api/shield-groups/`
- `GET/POST /api/led-zones/`

### 7.2 Контракты
- Нормализация `poles` и `rating` в `ShieldGroup.save()`.
- Авторасчет `modules_count` по числу полюсов.
- Backend возвращает `suggested_size` для щита.

## 8. Files

### 8.1 Endpoints
- `GET/POST /api/project-files/`
- `PATCH/DELETE /api/project-files/{id}/`

### 8.2 Ограничения и поведение
- До 12 файлов на проект.
- До 20 МБ на файл.
- Категории: `PROJECT`, `WORK`, `FINISH`.
- На удалении файла backend удаляет физический файл с диска.

## 9. Finance & Statistics

### 9.1 Finance
- `GET /api/projects/unpaid_projects/` — агрегат по неоплаченным этапам (кроме `precalc`).
- `GET /api/finance/`, `PATCH /api/finance/1/` — singleton финансовых настроек.

### 9.2 Statistics
- `GET /api/statistics/?period=month|year|all`.
- Возвращает: `finances`, `sources`, `object_types`, `work_dynamics`.

## 10. Directory & Catalog

### 10.1 Endpoints
- `GET/POST /api/directory-sections/`
- `GET/PUT/PATCH/DELETE /api/directory-sections/{id}/`
- `POST /api/directory-sections/bootstrap/`
- `GET/POST /api/directory-entries/`
- `GET/PUT/PATCH/DELETE /api/directory-entries/{id}/`
- `GET/POST /api/categories/`
- `GET/POST /api/catalog-items/`

### 10.2 Контракты
- Полный CRUD для sections/entries/categories/items.
- Должны сохраняться поля автоматизации (`mapping_key`, `aggregation_key`, `related_work_item`) и `metadata` у DirectoryEntry.
- На входе в Directory выполняется bootstrap.

### 10.3 Not-ready DB contract
Если таблицы Directory не готовы:
- list endpoints могут вернуть `[]`.
- bootstrap/CRUD/retrieve должны вернуть `503` с человекочитаемой ошибкой.

## 11. Settings
- Переключение `ThemeMode` (`Light/Dark/System`) с persistence.
- Вход в Directory из Settings: warning + проверка пароля текущего аккаунта.
- Ошибка пароля отображается inline, без перехода на Directory.

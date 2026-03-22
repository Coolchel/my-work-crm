# Dialog / Modal Unification Plan

## 1. Цель
- Унифицировать все диалоговые окна Flutter frontend по визуальному стилю и поведению.
- Сначала привести к единой системе `Windows + web desktop`.
- После стабилизации desktop-подхода отдельно адаптировать `Android + web mobile`.
- Не ломать бизнес-логику, CRUD-сценарии, API и существующую архитектуру вне необходимого.

## 2. Почему идем в 2 этапа
- Desktop и mobile требуют разных modal-container паттернов.
- Если переделывать обе поверхности одновременно, возрастает риск регрессий и слишком абстрактного рефакторинга.
- Desktop проще использовать как базу для общей modal design system:
  - меньше ограничений по высоте,
  - нет проблем с экранной клавиатурой,
  - легче утвердить единый visual language.
- После этого mobile можно делать как адаптацию уже утвержденной системы, а не как параллельную реализацию.

## 3. Разделение по surface

### 3.1 Desktop surfaces
- Windows
- web desktop

Desktop contract:
- центрированные modal dialogs,
- единый shell,
- единый backdrop,
- единый header/body/footer,
- единые width/height presets,
- единый scroll contract для длинного контента.

### 3.2 Mobile surfaces
- Android
- web mobile

Mobile contract:
- единый визуальный стиль с desktop,
- но не обязательно тот же container type,
- для части сценариев использовать compact dialog,
- для части сценариев использовать bottom sheet / fullscreen modal.

## 4. Разделение по смыслу

### 4.1 Confirm
Короткие подтверждения и опасные действия.

Примеры:
- удаление,
- очистка,
- выход,
- подтверждение опасных переходов.

### 4.2 Form
Создание и редактирование сущностей.

Примеры:
- проект,
- щит,
- позиция сметы,
- quantity / edit item,
- password,
- сущности справочника и каталога.

### 4.3 Picker / List
Выбор из списка, поиск, шаблоны, stage pickers.

Примеры:
- добавление позиции из каталога,
- выбор шаблона,
- выбор этапа,
- списковые utility dialogs.

### 4.4 Message / Utility
Информационные, error, warning, fallback dialogs.

Примеры:
- error/info dialogs,
- file share fallback,
- warning dialogs в настройках.

## 5. Текущее состояние кодовой базы

### 5.1 Что уже есть
- Глобальная `dialogTheme` в `lib/src/core/theme/app_theme.dart`.
- Shared dialogs:
  - `lib/src/shared/presentation/dialogs/confirmation_dialog.dart`
  - `lib/src/shared/presentation/dialogs/text_input_dialog.dart`
- Общий dialog scrollbar:
  - `lib/src/shared/presentation/widgets/app_dialog_scrollbar.dart`

### 5.2 Что сейчас разрознено
- В проекте используются:
  - `Dialog`,
  - `AlertDialog`,
  - самописные dialog-container'ы прямо внутри screen/feature.
- Разные:
  - радиусы,
  - max width,
  - высоты,
  - header patterns,
  - footer/action layouts,
  - backdrop/barrier правила.
- Есть локальные решения внутри feature-модулей, которые не вынесены в shared.

### 5.3 Ключевая проблема mobile
- Многие dialogs сделаны как desktop-centered windows.
- На узких экранах это приводит к тесному layout, слабой работе с клавиатурой и плохой композиции.
- Часть dialogs имеет фиксированную высоту (`height: 600`) или desktop-centric width constraints.

## 6. Desktop reference

За desktop reference принимаем dialogs из справочника / каталога:
- `lib/src/features/catalog/presentation/widgets/category_list_screen_components.dart`

Почему:
- там уже есть локальный `_DialogShell`,
- есть единый header/body/footer,
- единый скролл внутри окна,
- единые поля ввода,
- визуально это самый цельный и спокойный desktop-образец.

Важно:
- использовать этот подход как основу,
- но не копировать feature-specific реализацию напрямую в другие модули,
- а вынести общий desktop modal foundation в shared.

## 7. Целевая архитектура

### 7.1 Shared foundation
Нужен общий modal layer в shared, условно:
- `AppModalShell` / `AppDesktopModalShell`
- `AppModalHeader`
- `AppModalBody`
- `AppModalFooter`
- shared field helpers для modal forms
- presets по типам:
  - `confirm`,
  - `form`,
  - `picker`,
  - `message`

### 7.2 Container strategy
- Desktop:
  - centered dialog-card
- Mobile:
  - compact dialog для коротких подтверждений,
  - bottom sheet или fullscreen modal для длинных forms/pickers

## 8. Предварительная карта диалогов

### 8.1 Confirm
- `lib/src/shared/presentation/dialogs/confirmation_dialog.dart`
- подтверждения в `projects`, `estimate`, `engineering`, `catalog`, `finance`
- часть confirm-окон в `settings_screen.dart`

### 8.2 Form
- `lib/src/features/projects/presentation/screens/add_project_screen.dart`
- `lib/src/features/projects/presentation/dialogs/engineering/add_shield_dialog.dart`
- `lib/src/features/projects/presentation/dialogs/engineering/edit_shield_dialog.dart`
- `lib/src/features/projects/presentation/dialogs/engineering/shield_group_dialog.dart`
- `lib/src/features/projects/presentation/dialogs/engineering/led_zone_dialog.dart`
- `lib/src/features/projects/presentation/dialogs/engineering/ethernet_lines_dialog.dart`
- `lib/src/features/projects/presentation/dialogs/estimate/edit_item_dialog.dart`
- `lib/src/features/projects/presentation/dialogs/estimate/quantity_input_dialog.dart`
- `lib/src/shared/presentation/dialogs/text_input_dialog.dart`
- dialogs каталога и справочника в `category_list_screen_components.dart`
- часть dialogs в `settings_screen.dart`

### 8.3 Picker / List
- `lib/src/features/projects/presentation/dialogs/estimate/add_item_dialog.dart`
- `lib/src/features/engineering/presentation/dialogs/template_selection_dialog.dart`
- `lib/src/features/projects/presentation/widgets/project_detail/add_stage_dialog.dart`
- dialogs действий сметы в `estimate_actions_dialog.dart`

### 8.4 Message / Utility
- `lib/src/shared/presentation/utils/error_feedback.dart`
- `lib/src/features/projects/presentation/dialogs/project_file_share_fallback_dialog.dart`
- warning/password dialogs в `settings_screen.dart`

## 9. План внедрения с ограничением в 8-10 промптов

Цель: удержать всю переделку в пределах 8-10 агентских задач.

### Prompt 1
Desktop foundation:
- вынести общий desktop modal shell в shared,
- взять catalog dialog style как основу,
- унифицировать shared `ConfirmationDialog` и `TextInputDialog`,
- не трогать mobile UX.

### Prompt 2
Desktop utility + settings:
- перевести desktop warning / password / logout / utility dialogs на shared desktop modal foundation.

### Prompt 3
Desktop project forms:
- `AddProjectDialog`,
- `AddStageDialog`,
- related project dialogs.

### Prompt 4
Desktop engineering forms:
- `AddShieldDialog`,
- `EditShieldDialog`,
- `ShieldGroupDialog`,
- `LedZoneDialog`,
- `EthernetLinesDialog`,
- `ShieldNotesDialog`.

### Prompt 5
Desktop estimate forms:
- `EditItemDialog`,
- `QuantityInputDialog`,
- related estimate form-like dialogs.

### Prompt 6
Desktop picker/list dialogs:
- `AddItemDialog`,
- `TemplateSelectionDialog`,
- estimate actions / preview dialogs при необходимости.

### Prompt 7
Desktop cleanup / consistency pass:
- вычистить оставшиеся desktop dialogs,
- привести barrier, sizing, action layout и scroll contracts к единому виду,
- закрыть desktop regressions.

### Prompt 8
Mobile foundation:
- адаптивный mobile modal contract,
- выбор container patterns по категориям.

### Prompt 9
Mobile form + picker migration.

### Prompt 10
Mobile cleanup / regression pass.

Если получится, desktop phase желательно закрыть в 6-7 промптов, а mobile phase в 2-3.

## 10. Практический приоритет
- Сначала строим shared desktop foundation.
- Затем переводим shared/utility dialogs.
- Только потом крупные form/picker dialogs.
- Самые рискованные и тяжелые dialogs:
  - `AddItemDialog`
  - `TemplateSelectionDialog`
  - большие estimate dialogs
  - dialogs из `settings_screen.dart`, написанные inline

## 11. Нефункциональные ограничения
- Все текстовые файлы, изменения в коде и любые создаваемые/редактируемые артефакты должны сохраняться в UTF-8.
- Не менять бизнес-логику.
- Не менять backend/API.
- Не делать лишний unrelated refactor.
- Не ломать Android/web mobile на desktop-этапе.

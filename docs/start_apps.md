# Быстрый запуск приложений

## Web

Из папки `D:\my_software\work_project\frontend\smart_electric_crm`:

```powershell
flutter run -d web-server --release --web-hostname 0.0.0.0 --web-port 3000 --dart-define=API_BASE_URL_WEB=http://192.168.0.196:8000/api
```

Открыть в браузере:

```text
http://192.168.0.196:3000/
```

## Windows

Из папки `D:\my_software\work_project\frontend\smart_electric_crm`:

```powershell
flutter run -d windows
```

## Android Meizu Pro 7

Из папки `D:\my_software\work_project\frontend\smart_electric_crm`:

```powershell
flutter run -d 79BHADRCTC6ML --dart-define=API_BASE_URL_ANDROID=http://192.168.0.196:8000/api
```

попробовать flutter install -d 79BHADRCTC6ML

## Важно

- Для физического телефона используйте только LAN IP компьютера.
- `10.0.2.2` используйте только для Android Emulator.
- После проверки на эмуляторе не переиспользуйте тот же APK на телефоне. Для телефона пересобирайте APK заново под LAN IP.

# Android Emulator Quickstart

Этот файл нужен, чтобы быстро поднимать приложение в Android Emulator без ручных правок кода.

## Какой API URL использовать

Для Android Emulator нужно использовать:

- `http://10.0.2.2:8000/api`

`10.0.2.2` внутри эмулятора указывает на `localhost` хост-машины.

## Быстрый запуск через `flutter run`

1. Убедиться, что backend запущен на ПК на порту `8000`.
2. Убедиться, что эмулятор запущен и виден в `adb devices`.
3. Запустить приложение:

```powershell
C:\src\flutter\bin\flutter.bat run -d emulator-5554 --dart-define=API_BASE_URL_ANDROID=http://10.0.2.2:8000/api
```

Если нужен `release`:

```powershell
C:\src\flutter\bin\flutter.bat run -d emulator-5554 --release --no-resident --dart-define=API_BASE_URL_ANDROID=http://10.0.2.2:8000/api
```

## Если `flutter run` пишет, что эмулятор `unsupported`

Такое может быть на некоторых `x86` AVD. В этом случае рабочий обход такой:

1. Собрать `release` APK под `android-arm`:

```powershell
cd D:\my_software\work_project\frontend\smart_electric_crm
C:\src\flutter\bin\flutter.bat build apk --release --target-platform android-arm --dart-define=API_BASE_URL_ANDROID=http://10.0.2.2:8000/api
```

2. Установить APK через `adb`:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r build\app\outputs\flutter-apk\app-release.apk
```

3. При необходимости запустить приложение:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell monkey -p com.smartelectric.smart_electric_crm -c android.intent.category.LAUNCHER 1
```

## Проверка доступности backend

На хост-машине:

```powershell
Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/auth/token/" -Method Post -Body '{"username":"x","password":"y"}' -ContentType "application/json"
```

Ожидаемо получить `401 Unauthorized`: это значит, что сервер доступен и отвечает.

Из эмулятора:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell ping -c 1 10.0.2.2
```

## Что важно помнить

1. Для эмулятора использовать `10.0.2.2`, а не LAN IP компьютера.
2. Для физического телефона использовать LAN IP компьютера, а не `10.0.2.2`.
3. Backend должен слушать `0.0.0.0:8000` или `127.0.0.1:8000`, если используется только эмулятор.
4. Для проверки системного edge-swipe back удобно использовать Android 10+ AVD с gesture navigation.

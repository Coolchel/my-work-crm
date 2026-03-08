# Running Quickstart

Единая инструкция по локальному запуску проекта:

- backend
- Android phone
- Android emulator
- Windows app

## Backend

Запуск backend:

```powershell
cd D:\my_software\work_project\backend
python manage.py runserver 0.0.0.0:8000
```

Проверка, что сервер отвечает:

```powershell
Invoke-WebRequest -Uri "http://127.0.0.1:8000/api/auth/token/" -Method Post -Body '{"username":"x","password":"y"}' -ContentType "application/json"
```

Ожидаемый результат: `401 Unauthorized`.
Это нормально и означает, что backend жив.

Тестовые учетные данные:

- `admin / admin`
- `coolchel / admin`

## Android Phone

Для физического телефона использовать LAN IP компьютера, например `192.168.0.196`.

1. Узнать IP:

```powershell
ipconfig
```

2. Собрать release APK:

```powershell
cd D:\my_software\work_project\frontend\smart_electric_crm
flutter build apk --release --dart-define=API_BASE_URL_ANDROID=http://192.168.0.196:8000/api
```

3. Установить APK на телефон:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s 79BHADRCTC6ML install -r D:\my_software\work_project\frontend\smart_electric_crm\build\app\outputs\flutter-apk\app-release.apk
```

4. Запустить приложение:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s 79BHADRCTC6ML shell monkey -p com.smartelectric.smart_electric_crm -c android.intent.category.LAUNCHER 1
```

Проверка связи телефона с backend:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s 79BHADRCTC6ML shell ping -c 1 192.168.0.196
```

Проверка, что пакет установлен:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s 79BHADRCTC6ML shell pm list packages | findstr smart_electric_crm
```

## Android Emulator

Для Android Emulator использовать только:

- `http://10.0.2.2:8000/api`

`10.0.2.2` внутри эмулятора указывает на хост-машину.

### Legacy Pixel_5

Текущий `Pixel_5`:

- AVD: `Pixel_5`
- Android: `11`
- ABI: `x86`
- adb id: обычно `emulator-5554`

Важно:

- этот AVD у Flutter считается `unsupported`
- `flutter run -d emulator-5554` для него не использовать
- основной сценарий: `build apk` + `adb install`

1. Запустить эмулятор:

```powershell
cd D:\my_software\work_project\frontend\smart_electric_crm
flutter emulators --launch Pixel_5
```

2. Проверить, что эмулятор поднялся:

```powershell
D:\Android\Sdk\platform-tools\adb.exe devices -l
```

3. Проверить доступ к backend:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell ping -c 1 10.0.2.2
```

4. Собрать release APK:

```powershell
cd D:\my_software\work_project\frontend\smart_electric_crm
flutter build apk --release --dart-define=API_BASE_URL_ANDROID=http://10.0.2.2:8000/api
```

5. Установить APK:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r D:\my_software\work_project\frontend\smart_electric_crm\build\app\outputs\flutter-apk\app-release.apk
```

6. Запустить приложение:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell monkey -p com.smartelectric.smart_electric_crm -c android.intent.category.LAUNCHER 1
```

Проверка, что пакет установлен:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell pm list packages | findstr smart_electric_crm
```

Проверка, что приложение запущено:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell pidof com.smartelectric.smart_electric_crm
```

Если приложение не стартовало сразу, через 2-3 секунды повторить `monkey`.

### Supported AVD

Для современного `x64` AVD можно использовать `flutter run`:

```powershell
cd D:\my_software\work_project\frontend\smart_electric_crm
flutter run -d emulator-5556 --no-resident --dart-define=API_BASE_URL_ANDROID=http://10.0.2.2:8000/api
```

## Windows App

### Быстрый запуск из уже собранной версии

```powershell
Start-Process D:\my_software\work_project\frontend\smart_electric_crm\build\windows\x64\runner\Release\smart_electric_crm.exe
```

### Пересборка Windows-приложения

```powershell
cd D:\my_software\work_project\frontend\smart_electric_crm
flutter build windows
```

После сборки запуск:

```powershell
Start-Process D:\my_software\work_project\frontend\smart_electric_crm\build\windows\x64\runner\Release\smart_electric_crm.exe
```

Если нужно перезапустить приложение:

```powershell
Get-Process smart_electric_crm -ErrorAction SilentlyContinue | Stop-Process -Force
Start-Process D:\my_software\work_project\frontend\smart_electric_crm\build\windows\x64\runner\Release\smart_electric_crm.exe
```

## Что помнить

1. Для телефона использовать LAN IP компьютера.
2. Для эмулятора использовать только `10.0.2.2`.
3. Backend должен слушать `0.0.0.0:8000`.
4. Для legacy `Pixel_5` не использовать `flutter run`.
5. После смены IP компьютера для телефона нужно пересобрать Android APK с новым `API_BASE_URL_ANDROID`.

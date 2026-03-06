# Android Emulator Quickstart

Этот файл нужен, чтобы быстро поднимать приложение в Android Emulator без ручных правок кода.

## Какой API URL использовать

Для Android Emulator нужно использовать:

- `http://10.0.2.2:8000/api`

`10.0.2.2` внутри эмулятора указывает на `localhost` хост-машины.

## Текущий рабочий сценарий для Pixel 5

Сейчас для тестов используется старый AVD `Pixel_5`:

- AVD: `Pixel_5`
- Android: `11`
- ABI: `x86`
- adb device id после запуска: обычно `emulator-5554`

Важно:

- этот AVD у Flutter определяется как `unsupported`
- штатный `flutter run -d emulator-5554` для него не использовать
- рабочий вариант: запустить эмулятор и установить уже собранный локальный APK через `adb`

## Пошаговый запуск Pixel 5

1. Убедиться, что backend запущен на ПК на порту `8000`.
2. Запустить эмулятор:

```powershell
cd D:\my_software\work_project\frontend\smart_electric_crm
C:\src\flutter\bin\flutter.bat emulators --launch Pixel_5
```

3. Убедиться, что эмулятор поднялся и виден в `adb`:

```powershell
D:\Android\Sdk\platform-tools\adb.exe devices -l
```

Ожидается устройство вида:

- `emulator-5554 device product:sdk_gphone_x86 model:sdk_gphone_x86`

4. Установить локальный `release` APK:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 install -r D:\my_software\work_project\frontend\smart_electric_crm\build\app\outputs\flutter-apk\app-release.apk
```

5. Запустить приложение:

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell monkey -p com.smartelectric.smart_electric_crm -c android.intent.category.LAUNCHER 1
```

6. Если сразу после установки приложение не стартовало, запустить его второй раз той же командой.

Причина:

- сразу после установки Android иногда держит пакет в состоянии `Package ... is currently frozen`
- повторный запуск через 2-3 секунды обычно решает это без переустановки

## Быстрая проверка, что приложение реально запущено

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s emulator-5554 shell pidof com.smartelectric.smart_electric_crm
```

Если команда вернула PID, приложение запущено.

## Если нужно обновить сборку для Pixel 5

Использовать тот же порядок:

1. Собрать APK отдельно.
2. Установить через `adb install -r`.
3. Запустить через `monkey`.

На текущем `Pixel_5` нельзя рассчитывать на `flutter run`, потому что это legacy `x86` AVD.

## Если нужен обычный `flutter run`

Для этого использовать supported AVD, например:

- `Medium_Phone_API_36.1`
- `Pixel_5_API_36_1_x64`

Пример:

```powershell
cd D:\my_software\work_project\frontend\smart_electric_crm
C:\src\flutter\bin\flutter.bat run -d emulator-5556 --no-resident --dart-define=API_BASE_URL_ANDROID=http://10.0.2.2:8000/api
```

Но для текущей проверки поведения в Pixel 5 рабочий сценарий выше остаётся основным.

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
3. Backend должен слушать `0.0.0.0:8000` или быть доступным локально для проброса из эмулятора.
4. Для проверки edge-swipe back удобнее использовать Android 10+ AVD с gesture navigation.
5. Если нужен именно старый `Pixel_5`, не запускать на нём `flutter run`, а ставить APK через `adb`.

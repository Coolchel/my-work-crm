# Android Network Quickstart (Physical Phone)

Этот файл нужен, чтобы быстро поднимать приложение на реальном Android-устройстве без ручных правок кода.

## Почему возникает ошибка "нет подключения к интернету"

В проекте для Android по умолчанию стоит:

- `http://10.0.2.2:8000/api`

Это адрес **эмулятора Android**, а не физического телефона.
На реальном телефоне нужно передавать LAN-адрес компьютера через `--dart-define`.

## Быстрый запуск на физический телефон (без отдельного APK)

1. Узнать IP компьютера в локальной сети (Windows):

```powershell
ipconfig
```

Нужен `IPv4` активного Wi-Fi/сетевого адаптера (например, `192.168.0.196`).

2. Запустить приложение на телефон:

```powershell
flutter run -d 79BHADRCTC6ML --release --no-resident --dart-define=API_BASE_URL_ANDROID=http://192.168.0.196:8000/api
```

Если нужен debug-режим:

```powershell
flutter run -d 79BHADRCTC6ML --dart-define=API_BASE_URL_ANDROID=http://192.168.0.196:8000/api
```

## Проверка, что сервер доступен

На ПК:

```powershell
Invoke-WebRequest -Uri "http://192.168.0.196:8000/api/auth/token/" -Method Post -Body '{"username":"x","password":"y"}' -ContentType "application/json"
```

Ожидаемо получить `401` (это нормально: сервер жив и отвечает).

С телефона (через adb):

```powershell
D:\Android\Sdk\platform-tools\adb.exe -s 79BHADRCTC6ML shell ping -c 1 192.168.0.196
```

## Что важно помнить

1. `10.0.2.2` использовать только для эмулятора Android.
2. Телефон и ПК должны быть в одной сети.
3. Backend должен слушать `0.0.0.0:8000` (не только `127.0.0.1`).
4. Брандмауэр Windows должен пропускать входящие на порт `8000`.

## Рекомендованный рабочий шаблон

Перед каждым запуском:

1. Проверить IP (`ipconfig`).
2. Подставить его в `API_BASE_URL_ANDROID`.
3. Выполнить `flutter run ... --dart-define=API_BASE_URL_ANDROID=...`.


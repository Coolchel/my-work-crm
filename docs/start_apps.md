Старт приложения в вебе:

flutter run -d web-server --release --web-hostname 0.0.0.0 --web-port 3000 --dart-define=API_BASE_URL_WEB=http://192.168.0.196:8000/api


Старт приложения в Windows:

flutter run -d windows


Старт приложения на Android Meizu Pro 7:

flutter run -d 79BHADRCTC6ML --dart-define=API_BASE_URL_ANDROID=http://192.168.0.196:8000/api


Важно:

- для физического телефона используйте только LAN IP компьютера;
- `10.0.2.2` используйте только для Android Emulator;
- после проверки на эмуляторе не переиспользуйте тот же APK на телефоне, а пересобирайте его заново под LAN IP.

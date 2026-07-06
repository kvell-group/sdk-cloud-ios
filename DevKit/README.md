# KvellDevKit

Dev-only утилиты для локальной разработки Kvell SDK. **Не распространяется** и не публикуется в CocoaPods Trunk.

## Что внутри

- `MockNetworkDispatcher` — мок-сценарии оплаты (success / 3DS / decline) без обращения к сети.
- `LoggingNetworkDispatcher` — обёртка над реальным диспетчером: сырые HTTP request/response пишутся в консоль Xcode, в `DevLogStore` (экран Logs в демо) и, опционально, в файл по пути из переменной окружения `KVELL_DEV_LOG_PATH`.
- `DevLogStore` — in-memory журнал логов; демо показывает его на экране Logs (share / clear).
- `JWTSigner` — JWT HS256 на CryptoKit (без внешних зависимостей).
- `makeRequestSigner(secret:)` — фабрика замыкания для `KvellURLSessionNetworkDispatcher.instance.requestSigner` (заголовок `X-Sign`).

## Тестовые данные

Все параметры тестового окружения — URL сервера, PublicId, ApiSecret, Private Key подписи — вводятся в форме демо-приложения и сохраняются в UserDefaults симулятора. В коде и в git секретов нет.

## Важно

- Секреты **никогда не коммитить** в git.
- `KvellDevKit` подключается **только** к demo через `:path => '../DevKit'`.
- В `Package.swift` и распространяемых podspec (`Kvell-SDK-iOS.podspec`, `KvellNetworking.podspec`) этот модуль **не упоминается**.

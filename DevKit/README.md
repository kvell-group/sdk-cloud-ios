# KvellDevKit

Dev-only утилиты для локальной разработки Kvell SDK. **Не распространяется** и не публикуется в CocoaPods Trunk.

## Что внутри

- `JWTSigner` — JWT HS256 на CryptoKit (без внешних зависимостей).
- `makeRequestSigner(secret:)` — фабрика замыкания для `KvellURLSessionNetworkDispatcher.instance.requestSigner`.
- `DevConfig` — секрет и base URL из переменных окружения.

## Как задать секрет

### Вариант 1: Xcode Scheme → Environment Variables

1. Xcode → Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables.
2. Добавить: `KVELL_DEV_SIGN_SECRET` = `<ваш секрет>`.

### Вариант 2: Экспорт перед `xcodebuild`

```bash
export KVELL_DEV_SIGN_SECRET="your_secret_here"
xcodebuild ...
```

## Важно

- Секрет **никогда не коммитить** в git.
- `KvellDevKit` подключается **только** к demo через `:path => '../DevKit'`.
- В `Package.swift` и распространяемых podspec (`Kvell-SDK-iOS.podspec`, `KvellNetworking.podspec`) этот модуль **не упоминается**.

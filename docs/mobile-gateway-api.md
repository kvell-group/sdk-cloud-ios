# Kvell Mobile Gateway API — спецификация для backend

Документ описывает HTTP-контракт мобильного gateway, который **iOS SDK (Kvell) дёргает
напрямую с устройства**. Gateway повторяет клиентскую (on-device) модель карточных
платежей и внутри транслирует вызовы в серверный провайдер (Card H2H), добавляя
серверные секреты уже на своей стороне.

## Назначение и роль

```
iOS SDK (PublicId + криптограмма)
        ↓ HTTPS, прямой вызов с устройства
   Mobile gateway  ── расшифровка криптограммы, добавление secret_key / terminal_id / browser_info
        ↓ host-to-host
   Card H2H провайдера (/card/charge, /card/post3ds, ...)
```

Gateway:
1. идентифицирует мерчанта по публичному `PublicId` (приходит внутри криптограммы);
2. расшифровывает `CardCryptogramPacket` своим приватным RSA-ключом, получая PAN/exp/cvv;
3. маппит в формат Card H2H, подставляя серверные `terminal_id` / `secret_key` /
   `browser_info` (эти секреты **никогда не покидают сервер**);
4. вызывает соответствующий метод Card H2H;
5. маппит ответ обратно в клиентский формат, описанный ниже.

## Общие положения

- **Base URL:** уточняется (тест/прод). В SDK сейчас прописан placeholder
  `https://api.pay-pulse.example/`.
- **Транспорт:** HTTPS, `Content-Type: application/json`.
- **Идентификация мерчанта:** `PublicId` — публичный, приходит с клиента (внутри
  криптограммы). `secret_key` / ЭЦП терминала — только на сервере gateway.
- **Единый конверт ответа:** `{ "Success": bool, "Message": string|null, "Model": {…} }`.
  - `Success: true` — операция завершена;
  - `Success: false` + поля 3DS в `Model` — требуется 3DS;
  - `Success: false` + `Model.ReasonCode` — отказ.

## RSA-ключевая пара gateway

Gateway владеет RSA-парой (**2048 бит, PKCS#1 v1.5**). Публичную часть отдаёт через
`GET /payments/publickey`; приватной расшифровывает криптограмму. Поддержать
версионирование ключа (`Version`) для ротации.

## Формат CardCryptogramPacket

Строка до шифрования: `CardNumber@MMYY@CVV@PublicId` (разделитель `@`).
Шифруется RSA-2048 / PKCS#1 v1.5 публичным ключом gateway, результат — base64 без
переносов строк. Gateway обязан расшифровать пакет и извлечь `CardNumber`, срок (`MMYY`),
`CVV`, `PublicId`.

## Методы

### 1. `GET /payments/publickey`
Отдаёт публичный ключ для шифрования криптограммы.
```json
{ "Pem": "-----BEGIN PUBLIC KEY-----\n...\n-----END PUBLIC KEY-----", "Version": 13 }
```

### 2. `POST /payments/cards/charge` — одностадийная оплата по криптограмме

| Поле | Тип | Обяз. | Описание |
|---|---|---|---|
| Amount | Decimal | да | Сумма, до 2 знаков |
| Currency | String | нет (RUB) | RUB/USD/EUR/… |
| CardCryptogramPacket | String | да | Криптограмма карты |
| IpAddress | String | да | IP плательщика |
| Name | String | нет | Имя на карте |
| InvoiceId | String | нет | Номер заказа мерчанта |
| Description | String | нет | Описание платежа |
| AccountId | String | нет | ID плательщика |
| Email | String | нет | Email для квитанции |
| JsonData | Object | нет | Произвольные метаданные |

Успех без 3DS:
```json
{ "Success": true, "Message": null, "Model": {
  "TransactionId": 891583633, "Amount": 10, "Currency": "RUB",
  "Status": "Completed", "StatusCode": 2,
  "CardFirstSix": "400005", "CardLastFour": "5556", "CardType": "Visa",
  "CardHolderMessage": "Платёж прошёл успешно" } }
```
Требуется 3DS:
```json
{ "Success": false, "Message": null, "Model": {
  "TransactionId": 891463508,
  "PaReq": "<base64>", "AcsUrl": "https://acs.example/acs",
  "ThreeDsCallbackId": "7be4d37f0a434c0a8a7fc0e328368d7d",
  "Amount": 100.0, "Currency": "RUB",
  "CardFirstSix": "424242", "CardLastFour": "4242" } }
```
Отказ:
```json
{ "Success": false, "Message": null, "Model": {
  "TransactionId": 891583633, "ReasonCode": 5051,
  "Status": "Declined", "StatusCode": 5,
  "CardHolderMessage": "Недостаточно средств на карте" } }
```

### 3. `POST /payments/cards/auth` — двухстадийная (блокировка), при необходимости
Поля и ответы идентичны `charge`; подтверждение/отмена — серверной стороной Card H2H.
Нужна ли двухстадийность в мобильном флоу — уточнить.

### 4. `POST /payments/cards/post3ds` — завершение 3DS

| Поле | Тип | Обяз. | Описание |
|---|---|---|---|
| TransactionId | Integer | да | Из `Model.TransactionId` ответа charge/auth |
| PaRes | String | да | Результат 3DS от ACS |
| MD | String | нет | Часто = TransactionId |
| ThreeDsCallbackId | String | нет | Из ответа charge/auth |

Ответ — тот же конверт (успех → `Status:"Completed"`; отказ → `ReasonCode`).

### 5. `POST /payments/cards/bins/info` — BIN-инфо (опционально)
Для логотипа банка / типа карты в форме. Запрос: первые 6–8 цифр карты.
Ответ — банк, страна, тип карты, логотип. Точный контракт согласовать.

## 3DS 1.0 flow (мобильный)

1. `charge`/`auth` → `PaReq`, `AcsUrl`, `TransactionId`, `ThreeDsCallbackId`.
2. SDK POST-ит на `AcsUrl` форму: `PaReq`, `MD` (= TransactionId), `TermUrl` (callback SDK).
3. Банк аутентифицирует → редирект на `TermUrl` с `PaRes`, `MD`.
4. SDK шлёт `post3ds` (`TransactionId`, `PaRes`, `MD`, `ThreeDsCallbackId`) → финал.

Внутри gateway этот клиентский 3DS-flow транслируется в redirect-схему Card H2H
(`term_url` → `/3ds/forward` → `/3ds/return` → `/card/post3ds`). 3DS 2.0 не требуется.

## Маппинг клиентский контракт ↔ Card H2H

| Клиентский (SDK → gateway) | Card H2H (gateway → провайдер) |
|---|---|
| `Amount` (decimal, руб) | `amount` (int, копейки) |
| `Currency` (буквенный) | `currency` (числовой ISO 4217) |
| `CardCryptogramPacket` (расшифровать) | `card{ pan, exp_month, exp_year, cvv, holder }` |
| `IpAddress` / `Name` | `browser_info.browser_ip` / `card.holder` |
| `InvoiceId` | `order_client_id` |
| `Description` | `description` |
| (gateway генерирует) | `term_url` |
| `PublicId` (идентификация) | `terminal_id` + `secret_key` (подставляет gateway) |
| `Model.TransactionId` ← | `tx_id` |
| `Model.AcsUrl` / `PaReq` / `MD` ← | `acs_url` / `pa_req` / `md` |
| `Model.Status` / `StatusCode` / `Success` ← | `tx_status` (APPROVED / REJECTED / …) |

## Открытые пункты

- Base URL gateway (тест/прод).
- Полная таблица `ReasonCode` отказов.
- Точный контракт BIN-инфо.
- Значение `User-Agent`, по которому gateway опознаёт мобильный клиент (сейчас SDK шлёт
  значение референса).

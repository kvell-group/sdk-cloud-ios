# Kvell SDK for iOS

Kvell SDK позволяет интегрировать приём платежей банковскими картами в мобильные приложения для платформы iOS.

### Требования

iOS 15.0 и выше.

### Подключение

#### Swift Package Manager

File → Add Package Dependencies → `https://github.com/kvell-group/sdk-cloud-ios`. Добавьте зависимость `KvellSDK` в таргет.

#### CocoaPods

```ruby
pod 'Kvell'
pod 'KvellNetworking'
```

### Структура проекта

- **demo** — пример приложения
- **sdk** — исходный код SDK
- **networking** — сетевой слой

### Использование стандартной платёжной формы

1. Создайте `PaymentData`:

```swift
let paymentData = PaymentData()
    .setAmount("100.00")
    .setCurrency(.ruble)
    .setDescription("Оплата заказа")
    .setAccountId("user_123")
    .setInvoiceId("order_456")
```

2. Создайте `PaymentConfiguration` и реализуйте `PaymentDelegate`:

```swift
let configuration = PaymentConfiguration(
    publicId: "your_public_id",
    paymentData: paymentData,
    delegate: self,
    uiDelegate: self,
    emailBehavior: .optional,
    useDualMessagePayment: false
)
```

3. Покажите платёжную форму:

```swift
// UIKit
PaymentOptionsViewController.present(with: configuration, from: self)
```

### Использование KvellApi напрямую

1. Получите публичный ключ:

```swift
KvellApi.getPublicKey { response, error in
    // response.Pem, response.Version
}
```

2. Создайте криптограмму:

```swift
let cryptogram = Card.makeCardCryptogramPacket(
    cardNumber: cardNumber,
    expDate: expDate,
    cvv: cvv,
    merchantPublicID: "your_public_id",
    publicKey: pem,
    keyVersion: version
)
```

3. При необходимости покажите 3DS-форму:

```swift
let data = ThreeDsData(transactionId: transactionId, paReq: paReq, acsUrl: acsUrl)
let processor = ThreeDsProcessor()
processor.make3DSPayment(with: data, delegate: self)
```

### Поддержка

sdk@kvell.io

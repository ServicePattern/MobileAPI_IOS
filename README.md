# BPMobileMessaging

[![CI Status](https://img.shields.io/travis/brightpattern.com/BPMobileMessaging.svg?style=flat)](https://travis-ci.org/brightpattern.com/BPMobileMessaging)
[![Version](https://img.shields.io/cocoapods/v/BPMobileMessaging.svg?style=flat)](https://cocoapods.org/pods/BPMobileMessaging)
[![License](https://img.shields.io/cocoapods/l/BPMobileMessaging.svg?style=flat)](https://cocoapods.org/pods/BPMobileMessaging)
[![Platform](https://img.shields.io/cocoapods/p/BPMobileMessaging.svg?style=flat)](https://cocoapods.org/pods/BPMobileMessaging)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Quick Start
### Adding the SDK to your project

1. BPMobileMessaging is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'BPMobileMessaging'
```
2. Add the following line into your project's AppDelegate.swift file:
```swift
import BPMobileMessaging
```
3. Generate the unique `clientID` string value. The `clientID` should be generated when application runs for the first time on the mobile device and saved in the local storage. The application should use same value until it is deleted from the device. The `clientID` should be unique for the application / device combination.
```swift
var clientID = UUID().uuidString
```

4. Create instance of the `ContactCenterCommunicator` class which would handle communications with the BPCC server:
```swift
let baseURL = URL(string: "https://<your server URL>")!
let tenantURL = URL(string: "<your tenant URL>")!
var appID: "<your messaging scenario entry ID>"

var contactCenterService: ContactCenterCommunicating = {
    ContactCenterCommunicator(baseURL: baseURL, tenantURL: tenantURL, appID: appID, clientID: clientID)
}()

```
5. Register for push notifications. The SDK supports both native APNs and Firebase push notifications frameworks. Only one framework should be used.

5.1. Define a variable to store the device token

```swift
var deviceToken: String?
```

5.2. If using APNs, implement the function to handle the APNs device token result:
```swift
var deviceToken: String?

func application(_ application: UIApplication,
            didRegisterForRemoteNotificationsWithDeviceToken
                deviceToken: Data) {
    self.deviceToken = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    service?.deviceTokenChanged(to: deviceToken)
}

```

5.3. If using Google Firebase, implement MessagingDelegate extension:

```swift
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("Empty fcm token")
            return
        }
        print("Received fcm token from Firebase: \(fcmToken)")
        self.deviceToken = fcmToken
    }
}
```

5.4. Implement UNUserNotificationCenterDelegate extension to handle push notifications:

```swift
extension AppDelegate : UNUserNotificationCenterDelegate {

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    contactCenterService.appDidReceiveMessage(userInfo)
    completionHandler()
  }
}

```

5.5. Set the delegates for APNs and Firebase frameworks:

```swift
UNUserNotificationCenter.current().delegate = self
Messaging.messaging().delegate = self
```

5.6. Request permissions to receive push notifications:

```swift
let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
UNUserNotificationCenter.current().requestAuthorization(options: authOptions) { (authorized, error) in
    guard authorized else {
        if let error = error {
            print("Failed to authorize remote notifications: \(error)")
        }
        return
    }
    DispatchQueue.main.async {
        UIApplication.shared.registerForRemoteNotifications()
    }
    print("Successfully authorized for remote notifications")
}
```

6. Implement `ContactCenterEventsDelegating` extension to receive the chat events:

```swift
extension AppDelegate: ContactCenterEventsDelegating {
    func chatSessionEvents(result: Result<[ContactCenterEvent], Error>) {
        switch result {
        case .success(let events):
            print("Received events from contact center")
            DispatchQueue.main.async {
                //  Handle events here ...
            }
        case .failure(let error):
            print("chatSessionEvents failed: \(error)")
        }
    }
}
```

7. To verify that a chat service is available, call getChatAvailability method:

```swift
contactCenterService.checkAvailability { [weak self] serviceAvailabilityResult in
    DispatchQueue.main.async {
        switch serviceAvailabilityResult {
        case .success(let serviceAvailability):
            print("Chat is \(serviceAvailability.chat)")
            self?.isChatAvailable = serviceAvailability.chat == .available
        case .failure(let error):
            print("Failed to check availability: \(error)")
        }
    }
}
```

7. To request a new chat session, call requestChat method and subscribe for push notifications for the newly created chat session:

```swift
contactCenterService.requestChat(phoneNumber: "12345", from: "54321", parameters: [:]) { [weak self] chatPropertiesResult in
    DispatchQueue.main.async {
        switch chatPropertiesResult {
        case .success(let chatProperties):
            self?.currentChatID = chatProperties.chatID
            self?.subscribeForNotifications(chatID: chatProperties.chatID) { subscribeResult in
                DispatchQueue.main.async {
                    switch subscribeResult {
                    case .success:
                        print("Subscribe for remote notifications confirmed")
                    case .failure(let error):
                        print("Failed to subscribe for notifications: \(error)")
                    }
                }
            }
        case .failure(let error):
            print("\(error)")
        }
    }
```

## Author

[BrightPattern](https://brightpattern.com)

## License

BPMobileMessaging is available under the MIT license. See the LICENSE file for more info.

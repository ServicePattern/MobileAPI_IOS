//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation
import BPMobileMessaging
import Firebase

extension PartialKeyPath where Root == ServiceManager {
    var stringValue: String {
        switch self {
        case \ServiceManager.baseURL: return "baseURL"
        case \ServiceManager.tenantURL: return "tenantURL"
        case \ServiceManager.appID: return "appID"
        case \ServiceManager.clientID: return "clientID"
        case \ServiceManager.firstName: return "firstName"
        case \ServiceManager.lastName: return "lastName"
        case \ServiceManager.phoneNumber: return "phoneNumber"
        default: fatalError("Unexpected keyPath")
        }
    }
}

@objc
final class ServiceManager: NSObject, ServiceDependencyProtocol {
    var useFirebase = true
    var deviceToken: String?
    lazy var contactCenterService: ContactCenterCommunicating = {
        ContactCenterCommunicator(baseURL: baseURL, tenantURL: tenantURL, appID: appID, clientID: clientID)
    }()

    override init() {
        super.init()

        if useFirebase {
            FirebaseApp.configure()
        }
        contactCenterService.delegate = self
        subscribeForRemoteNotifications()
    }

    func deviceTokenChanged(to deviceToken: Data) {
        // Convert data to hex string
        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Received a device token from APNs: \(deviceTokenString)")
        if useFirebase == false {
            self.deviceToken = deviceTokenString
        }
    }

    private func subscribeForRemoteNotifications() {
        UNUserNotificationCenter.current().delegate = self

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

        if useFirebase == true {
            Messaging.messaging().delegate = self
        }
    }
}

extension ServiceManager: ContactCenterEventsDelegating {
    func chatSessionEvents(result: Result<[ContactCenterEvent], Error>) {
        switch result {
        case .success(let events):
            print("Received events from contact center")
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: NotificationName.contactCenterEventsReceived.name, object: nil,
                                                userInfo: [NotificationUserInfoKey.contactCenterEvents: events])
            }
        case .failure(let error):
            print("chatSessionEvents failed: \(error)")
        }
    }
}

extension ServiceManager : UNUserNotificationCenterDelegate {

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    contactCenterService.appDidReceiveMessage(userInfo)
    completionHandler()
  }
}

extension ServiceManager: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("Empty fcm token")
            return
        }
        print("Received fcm token from Firebase: \(fcmToken)")
        self.deviceToken = fcmToken
    }
}

// MARK:- Server settings
extension ServiceManager {
    func value<T>(for keyPath: PartialKeyPath<ServiceManager>, defaultValue: T) -> T {
        let defaults = UserDefaults.standard
        guard let value = defaults.value(forKey: keyPath.stringValue) as? T else {
            defaults.set(defaultValue, forKey: keyPath.stringValue)
            return defaultValue
        }
        return value
    }
    var baseURL: URL {
        let urlString = value(for: \ServiceManager.baseURL,
                              defaultValue: "http://alvm.bugfocus.com")
        return URL(string: urlString)!
    }
    var tenantURL: URL {
        let urlString: String = value(for: \ServiceManager.tenantURL,
                                      defaultValue: "devs.alvm.bugfocus.com")
        return URL(string: urlString)!
    }
    var appID: String {
        value(for: \ServiceManager.appID,
              defaultValue: useFirebase ? "FirebaseApple": "apns")
    }
    var clientID: String {
        value(for: \ServiceManager.clientID,
              defaultValue: UUID().uuidString)
    }
    var firstName: String {
        value(for: \ServiceManager.firstName,
              defaultValue: "Mobile")
    }
    var lastName: String {
        value(for: \ServiceManager.lastName,
              defaultValue: "Customer")
    }
    var phoneNumber: String {
        value(for: \ServiceManager.phoneNumber,
              defaultValue: "15550005555")
    }
}

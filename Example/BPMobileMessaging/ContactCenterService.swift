//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation
import BPMobileMessaging
import Firebase

@objc
final class ServiceManager: NSObject, ServiceDependencyProtocol {
    var deviceToken: String?
    let baseURL: URL
    let tenantURL: URL
    let appID: String
    let useFirebase: Bool
    lazy var contactCenterService: ContactCenterCommunicating = {
        ContactCenterCommunicator(baseURL: baseURL, tenantURL: tenantURL, appID: appID, clientID: clientID)
    }()
    
    init(baseURL: URL, tenantURL: URL, appID: String, useFirebase: Bool) {
        self.baseURL = baseURL
        self.tenantURL = tenantURL
        self.appID = appID
        self.useFirebase = useFirebase

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
    func value<T>(for keyPath: PartialKeyPath<ServiceManager>) -> T? {
        let defaults = UserDefaults.standard
        guard let value = defaults.value(forKey: keyPath.stringValue) as? T else {
            return nil
        }
        return value
    }

    var clientID: String {
        value(for: \ServiceManager.clientID) ??  UUID().uuidString
    }
    var firstName: String {
        value(for: \ServiceManager.firstName) ?? ""
    }
    var lastName: String {
        value(for: \ServiceManager.lastName) ?? ""
    }
    var phoneNumber: String {
        value(for: \ServiceManager.phoneNumber) ?? ""
    }
}

//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation
import BPMobileMessaging
import Firebase

@objc
final class ServiceManager: NSObject, ServiceDependencyProtocol {
    var useFirebase = true
    let baseURL = URL(string: "http://alvm.bugfocus.com")!
    let tenantURL = URL(string: "devs.alvm.bugfocus.com")!
    var appID: String {
        useFirebase ? "FirebaseApple": "apns"
    }
    let clientID = "D3577669-EB4B-4565-B9C6-27DD857CE8E5"
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

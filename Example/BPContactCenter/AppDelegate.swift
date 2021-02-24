//
//  AppDelegate.swift
//  BPContactCenter
//
//  Created by BrightPattern on 02/12/2021.
//  Copyright (c) 2021 BrightPattern. All rights reserved.
//

import UIKit
import BPContactCenter
import Firebase

protocol DeviceTokenDelegateProtocol: class {
    func received(token: String)
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var contactCenterService: ContactCenterCommunicating?
    var deviceToken: String?
    let useFirebase = true
    weak var deviceTokenDelegate: DeviceTokenDelegateProtocol?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        let baseURL = URL(string: "http://alvm.bugfocus.com")!
        let tenantURL = URL(string: "devs.alvm.bugfocus.com")!
        let appID = useFirebase ? "FirebaseApple": "apns"
        let clientID = "D3577669-EB4B-4565-B9C6-27DD857CE8E5"

        contactCenterService = ContactCenterCommunicator(baseURL: baseURL, tenantURL: tenantURL, appID: appID, clientID: clientID)

        if useFirebase {
            FirebaseApp.configure()
        }

        subscribeForRemoteNotifications()

        return true
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

        if useFirebase {
            Messaging.messaging().delegate = self
        }
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication,
                didRegisterForRemoteNotificationsWithDeviceToken
                    deviceToken: Data) {
        // Convert data to hex string
        let deviceTokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Received a device token from APNs: \(deviceTokenString)")
        if !useFirebase {
            self.deviceToken = deviceTokenString
            deviceTokenDelegate?.received(token: deviceTokenString)
        }
    }

    func application(_ application: UIApplication,
                didFailToRegisterForRemoteNotificationsWithError
                    error: Error) {
       // Try again later.
    }
}

extension AppDelegate : UNUserNotificationCenterDelegate {

  func userNotificationCenter(_ center: UNUserNotificationCenter,
                              didReceive response: UNNotificationResponse,
                              withCompletionHandler completionHandler: @escaping () -> Void) {
    let userInfo = response.notification.request.content.userInfo
    contactCenterService?.appDidReceiveMessage(userInfo)
    completionHandler()
  }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else {
            print("Empty fcm token")
            return
        }
        print("Received fcm token from Firebase: \(fcmToken)")
        self.deviceToken = fcmToken
        deviceTokenDelegate?.received(token: fcmToken)
    }
}


//
//  AppDelegate.swift
//  BPMobileMessaging
//
//  Created by BrightPattern on 02/12/2021.
//  Copyright (c) 2021 BrightPattern. All rights reserved.
//

import UIKit
import BPMobileMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var service: ServiceManager?
    var baseURL: URL? {
        guard let urlString: String = value(for: \AppDelegate.baseURL),
              let url = URL(string: urlString) else {
            return nil
        }
        return url
    }
    var tenantURL: URL? {
        guard let urlString: String = value(for: \AppDelegate.tenantURL),
              let url = URL(string: urlString) else {
            return nil
        }
        return url
    }
    var appID: String? {
        value(for: \AppDelegate.appID)
    }
    var useFirebase: Bool? {
        value(for: \AppDelegate.useFirebase)
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        self.window = UIWindow(frame: UIScreen.main.bounds)
        registerDefaultsFromSettingsBundle()

        guard let baseURL = baseURL,
              let tenantURL = tenantURL,
              let appID = appID,
              let useFirebase = useFirebase else {

            let alert = UIAlertController(title: "Error",
                                          message:"You need to provide baseURL, tenantURL and appID to start the app. After pressing OK button you will be switched to Settings.",
                                          preferredStyle: UIAlertController.Style.alert)
            // When pressed the user is switched to the Settings
            alert.addAction(UIAlertAction(title: "OK", style: UIAlertAction.Style.default, handler: openSettings))
            // Show the alert suggesting to provide required settings
            self.window?.rootViewController = UIViewController()
            DispatchQueue.main.async {
                self.window?.rootViewController?.present(alert, animated: true, completion: nil)
            }
            self.window?.makeKeyAndVisible()

            return true
        }

        self.service = ServiceManager(baseURL: baseURL, tenantURL: tenantURL, appID: appID, useFirebase: useFirebase)

        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        guard let helpRequestViewController = storyboard.instantiateViewController(withIdentifier: "HelpRequestViewController") as? HelpRequestViewController else {
            fatalError("Failed to instantiate \(HelpRequestViewController.self)")
        }

        guard let service = service else {
            fatalError("contactCenterService is not set")
        }
        helpRequestViewController.service = service
        let navigationController = UINavigationController.init(rootViewController: helpRequestViewController)

        self.window?.rootViewController = navigationController

        self.window?.makeKeyAndVisible()

        return true
    }

    func openSettings(alert: UIAlertAction!) {
        if let url = URL.init(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
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
        
        UIApplication.shared.applicationIconBadgeNumber = 0
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    func application(_ application: UIApplication,
                didRegisterForRemoteNotificationsWithDeviceToken
                    deviceToken: Data) {
        service?.deviceTokenChanged(to: deviceToken)
    }

    func application(_ application: UIApplication,
                didFailToRegisterForRemoteNotificationsWithError
                    error: Error) {
       // Try again later.
    }
}

extension AppDelegate {
    func value<T>(for keyPath: PartialKeyPath<AppDelegate>) -> T? {
        let defaults = UserDefaults.standard
        guard let value = defaults.value(forKey: keyPath.stringValue) as? T else {
            return nil
        }
        return value
    }

    func registerDefaultsFromSettingsBundle() {
        guard let settingsBundle = Bundle.main.path(forResource: "Settings", ofType: "bundle") else {
            print("Failed to locate Settings.bundle")
            return
        }

        guard let settings = NSDictionary(contentsOfFile: settingsBundle+"/Root.plist") else {
            print("Failed to read Root.plist")
            return
        }

        let preferences = settings["PreferenceSpecifiers"] as! NSArray
        var defaultsToRegister = [String: Any]()
        for prefSpecification in preferences {
            if let spec = prefSpecification as? [String: Any] {
                guard let key = spec["Key"] as? String,
                    let defaultValue = spec["DefaultValue"] else {
                        continue
                }
                defaultsToRegister[key] = defaultValue
            }
        }
        UserDefaults.standard.register(defaults: defaultsToRegister)
        UserDefaults.standard.synchronize()
    }
}

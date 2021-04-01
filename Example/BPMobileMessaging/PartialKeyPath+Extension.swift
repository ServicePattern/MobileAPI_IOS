//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

extension PartialKeyPath where Root == ServiceManager {
    var stringValue: String {
        switch self {
        case \ServiceManager.clientID: return "clientID"
        case \ServiceManager.firstName: return "firstName"
        case \ServiceManager.lastName: return "lastName"
        case \ServiceManager.phoneNumber: return "phoneNumber"
        default: fatalError("Unexpected keyPath")
        }
    }
}

extension PartialKeyPath where Root == AppDelegate {
    var stringValue: String {
        switch self {
        case \AppDelegate.baseURL: return "baseURL"
        case \AppDelegate.tenantURL: return "tenantURL"
        case \AppDelegate.appID: return "appID"
        case \AppDelegate.useFirebase: return "useFirebase"
        default: fatalError("Unexpected keyPath")
        }
    }
}

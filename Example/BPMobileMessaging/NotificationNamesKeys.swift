//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

enum NotificationName: String {
    case contactCenterEventsReceived

    var name: Notification.Name {
        Notification.Name(rawValue: self.rawValue)
    }
}

enum NotificationUserInfoKey: String {
    case contactCenterEvents
}

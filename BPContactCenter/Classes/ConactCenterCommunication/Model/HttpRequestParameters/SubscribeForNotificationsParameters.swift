//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// - Tag: SubscribeForAPNsNotificationsParameters
struct SubscribeForAPNsNotificationsParameters: Encodable {
    let deviceToken: String
    let appBundleID: String

    enum CodingKeys: String, CodingKey {
        case deviceToken = "ios_apns_device_token"
        case appBundleID = "ios_app_bundle_id"
    }
}

/// - Tag: SubscribeForFirebaseNotificationsParameters
struct SubscribeForFirebaseNotificationsParameters: Encodable {
    let deviceToken: String

    enum CodingKeys: String, CodingKey {
        case deviceToken = "ios_firebase_device_token"
    }
}

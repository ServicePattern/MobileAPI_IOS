//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// - Tag: SubscribeForAPNsNotificationsParameters
struct SubscribeForAPNsNotificationsParameters: Encodable {
    let deviceToken: Data
    let appBundleID: String
    var deviceTokenHex: String {
        deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    }

    enum CodingKeys: String, CodingKey {
        case deviceToken = "ios_apns_device_token"
        case appBundleID = "ios_app_bundle_id"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceTokenHex, forKey: .deviceToken)
        try container.encode(appBundleID, forKey: .appBundleID)
    }
}

/// - Tag: SubscribeForFirebaseNotificationsParameters
struct SubscribeForFirebaseNotificationsParameters: Encodable {
    let deviceToken: Data
    var deviceTokenHex: String {
        deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
    }

    enum CodingKeys: String, CodingKey {
        case deviceToken = "ios_firebase_device_token"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(deviceTokenHex, forKey: .deviceToken)
    }
}

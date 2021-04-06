//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// - Tag: RequestChatParameters
struct RequestChatParameters: Encodable {
    let phoneNumber: String?
    let from: String
    let parameters: [String: String]

    enum CodingKeys: String, CodingKey {
        case phoneNumber = "phone_number"
        case from
        case parameters
    }
}

//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// Service status
/// - Tag: ContactCenterServiceAvailability
public struct ContactCenterServiceAvailability: Decodable {
    public let chat: Bool

    enum CodingKeys: String, CodingKey {
        case chat
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let chatAvailableString = try values.decode(String.self, forKey: .chat)
        chat = chatAvailableString == "available"
    }
}

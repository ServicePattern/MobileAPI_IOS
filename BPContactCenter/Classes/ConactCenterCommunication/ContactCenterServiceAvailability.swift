//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// - Tag: ContactCenterServiceChatAvailability
public enum ContactCenterServiceChatAvailability: String, Decodable {
    case available
    case unavailable
}

/// Service status
/// - Tag: ContactCenterServiceAvailability
public struct ContactCenterServiceAvailability: Decodable {
    public let chat: ContactCenterServiceChatAvailability
}

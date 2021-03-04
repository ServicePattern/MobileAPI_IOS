//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// Describes chat service availability states.
/// - Tag: ContactCenterServiceChatAvailability
public enum ContactCenterServiceChatAvailability: String, Decodable {
    case available
    case unavailable
}

/// Describes chat service status.
/// - Tag: ContactCenterServiceAvailability
public struct ContactCenterServiceAvailability: Decodable {
    public let chat: ContactCenterServiceChatAvailability
}

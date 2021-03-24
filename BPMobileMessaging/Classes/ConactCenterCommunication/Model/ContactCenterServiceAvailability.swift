//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// Describes chat service availability states.
/// - Tag: ContactCenterServiceChatAvailability
public enum ContactCenterServiceChatAvailability: String, Decodable {
    /// Chat service is available; application may request new chat sessions
    case available
    /// Chat service unavailable; application should not request new chat sessions
    case unavailable
}

/// Describes chat service status.
/// - Tag: ContactCenterServiceAvailability
public struct ContactCenterServiceAvailability {
    /// Current chat service availability state.
    public let chat: ContactCenterServiceChatAvailability
    /// Estimated time the session will stay in the queue before an agent is available (seconds)
    public let estimatedWaitTime: Int?
}

//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

/// Enumeration of allowed chat session state values.
/// - Tag: ContactCenterChatSessionState
public enum ContactCenterChatSessionState {
    case queued
    case connecting
    case connected
    case ivr
    case failed
    case completed
}

/// Describes the properties of the current chat session.
/// - Tag: ContactCenterChatSessionProperties
public struct ContactCenterChatSessionProperties {
    public let chatID: String
    public let state: ContactCenterChatSessionState
    public let estimatedWaitTime: Int
    public let isNewChat: Bool
    public let phoneNumber: String
}

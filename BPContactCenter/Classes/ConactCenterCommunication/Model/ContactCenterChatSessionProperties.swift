//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

/// - Tag: ContactCenterChatSessionState
public enum ContactCenterChatSessionState {
    case queued
    case connecting
    case connected
    case ivr
    case failed
    case completed
}

/// - Tag: ContactCenterChatSessionProperties
public struct ContactCenterChatSessionProperties {
    public let chatID: String
    public let state: ContactCenterChatSessionState
    public let ewt: String
    public let isNewChat: Bool
    public let phoneNumber: String
}

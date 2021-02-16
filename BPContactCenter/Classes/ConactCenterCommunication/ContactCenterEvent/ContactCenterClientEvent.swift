//
// Copyright © 2021 BrightPattern. All rights reserved. 

import Foundation

/// - Tag: ContactCenterChatSessionState
public enum ContactCenterChatSessionState {
    case queued
    case connecting
    case connected
    case failed
    case completed
}

/// - Tag: ContactCenterChatSessionPartyType
public enum ContactCenterChatSessionPartyType {
    case scenario
    case external
    case `internal`
}

/// Client Events that are received from the backend
/// - Tag: ContactCenterClientEvent
public enum ContactCenterClientEvent {
    /// Contains a new chat message
    case chatSessionMessage(messageID: String, message: String)
}

extension ContactCenterClientEvent: ContactCenterEventProtocol {
}

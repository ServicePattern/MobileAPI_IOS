//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

/// - Tag: ContactCenterServerEvent
public enum ContactCenterServerEvent {
    /// Contains a new chat message
    case chatSessionMessage(messageID: String, partyID: String, message: String, timestamp: Date)
    /// Updates the current state of the chat session. If the state is failed, the client application shall assume that the chat session no longer exists.
    case chatSessionStatus(state: ContactCenterChatSessionState, ewt: String)
    /// Indicates a normal termination of the chat session (e.g., when the chat session is closed by the agent). The client application shall assume that the chat session no longer exists.
    case chatSessionEnded
    /// Indicates that a new party (a new agent) has joined the chat session.
    case chatSessionPartyJoined(partyID: String, firstName: String, lastName: String, displayName: String, type: ContactCenterChatSessionPartyType, timestamp: Date)
}

extension ContactCenterServerEvent: ContactCenterEventProtocol {
}

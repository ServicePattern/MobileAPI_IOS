//
// Copyright © 2021 BrightPattern. All rights reserved. 

import Foundation

/// Defines API to convert from arbitrary data object to client or server event
/// ```
/// let eventData = Data() // Comes from the backend
/// let contactCenterEventDtoDecoded = try ContactCenterEventDto.decode(from: eventData).toModel()
/// ```
/// - Tag: ContactCenterEventModelConvertible
protocol ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent
}

/// - Tag: ContactCenterChatSessionPartyType
public enum ContactCenterChatSessionPartyType {
    case scenario
    case external
    case `internal`
}

/// - Tag: ContactCenterEvent
public enum ContactCenterEvent {
    /// Contains a new chat message
    /// Direction: S<->C
    case chatSessionMessage(messageID: String, partyID: String?, message: String, timestamp: Date?)
    /// Updates the current state of the chat session. If the state is failed, the client application shall assume that the chat session no longer exists.
    /// Direction: S->C
    case chatSessionStatus(state: ContactCenterChatSessionState, ewt: String)
    /// Indicates a normal termination of the chat session (e.g., when the chat session is closed by the agent). The client application shall assume that the chat session no longer exists.
    /// Direction: S->C
    case chatSessionEnded
    /// Indicates that a new party (a new agent) has joined the chat session.
    /// Direction: S->C
    case chatSessionPartyJoined(partyID: String, firstName: String, lastName: String, displayName: String, type: ContactCenterChatSessionPartyType, timestamp: Date)
}

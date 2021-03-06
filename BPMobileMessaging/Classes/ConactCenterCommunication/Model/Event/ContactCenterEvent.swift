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
    case chatSessionMessage(messageID: String?, partyID: String?, message: String, timestamp: Date?)
    /// Indicates that a message has been delivered
    /// Direction: S<->C
    case chatSessionMessageDelivered(messageID: String, partyID: String?, timestamp: Date?)
    /// Indicates that a message has been read
    /// Direction: S<->C
    case chatSessionMessageRead(messageID: String, partyID: String?, timestamp: Date?)
    /// Updates the current state of the chat session. If the state is failed, the client application shall assume that the chat session no longer exists.
    /// Direction: S->C
    case chatSessionStatus(state: ContactCenterChatSessionState, estimatedWaitTime: Int)
    /// Informs that a CRM case has been set or cleared for the chat session. Once case is set, application may use chatGetCaseHistory and chatCloseCase() methods.
    /// Direction: S->C
    case chatSessionCaseSet(caseID: String?, timestamp: Date)
    /// Indicates that a new party (a new agent) has joined the chat session.
    /// Direction: S->C
    case chatSessionPartyJoined(partyID: String, firstName: String?, lastName: String?, displayName: String?, type: ContactCenterChatSessionPartyType, timestamp: Date)
    /// Indicates that a party has left the chat session.
    /// Direction: S->C
    case chatSessionPartyLeft(partyID: String, timestamp: Date)
    /// Indicates that the party started typing a message
    /// Direction: S<->C
    case chatSessionTyping(partyID: String?, timestamp: Date?)
    /// Indicates that the party stopped typing a message
    /// Direction: S<->C
    case chatSessionNotTyping(partyID: String?, timestamp: Date?)
    /// Contains a new geographic location
    /// Direction: S<->C
    case chatSessionLocation(partyID: String?, url: String?, latitude: Float, longitude: Float, timestamp: Date?)
    /// Indicates that a system has requested an application to display a message. Typically used to display inactivity warning.
    /// Direction: S->C
    case chatSessionTimeoutWarning(message: String, timestamp: Date)
    /// Indicates that a system has ended the chat session due to the user's inactivity.
    /// Direction: S->C
    case chatSessionInactivityTimeout(message: String, timestamp: Date)
    /// Indicates a normal termination of the chat session (e.g., when the chat session is closed by the agent). The client application shall assume that the chat session no longer exists.
    /// Direction: S->C
    case chatSessionEnded
    /// Client sends the message to end current chat conversation but keep the session open.
    /// Direction: C->S
    case chatSessionDisconnect
    /// Client sends the message to end chat session.
    /// Direction: C->S
    case chatSessionEnd
}

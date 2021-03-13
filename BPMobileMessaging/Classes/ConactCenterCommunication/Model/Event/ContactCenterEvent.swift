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
    /// Server scenario party
    case scenario
    /// External (client) party
    case external
    /// Internal (agent) party
    case `internal`
}

/// Enumeration of the events which can be received from the server or sent to the server.
/// - Tag: ContactCenterEvent
public enum ContactCenterEvent {
    /// A new chat message is received from the server or being sent to the server.
    /// Direction: S<->C
    /// - Parameters:
    ///   - messageID: a unique ID of the message within the session
    ///   - partyID: a unique ID of the party who sent the message. Agent parties are reported by `chatSessionPartyJoined` event. Client party ID always matches the chat ID.
    ///   - message: message content
    ///   - timestamp: Timestamp of the event
    case chatSessionMessage(messageID: String?, partyID: String?, message: String, timestamp: Date?)
    /// Indicates that a message has been delivered to each party.
    /// Direction: S<->C
    /// - Parameters:
    ///   - messageID: a unique ID of the message within the session; received in` chatSessionMessage` event or sent by the `sendChatMessage` request
    ///   - partyID: a unique ID of the party the message has been delivered to
    ///   - timestamp: Timestamp of the event
    case chatSessionMessageDelivered(messageID: String?, partyID: String?, timestamp: Date?)
    /// Indicates that a message has been read
    /// Direction: S<->C
    /// - Parameters:
    ///   - messageID: a unique ID of the message within the session; received in` chatSessionMessage` event or sent by the `sendChatMessage` request
    ///   - partyID: a unique ID of the party the message who has read the message
    ///   - timestamp: Timestamp of the event
    case chatSessionMessageRead(messageID: String?, partyID: String?, timestamp: Date?)
    /// Updates the current state of the chat session. If the state is failed, the client application shall assume that the chat session no longer exists.
    /// Direction: S->C
    /// - Parameters:
    ///   - state: session state structure
    ///   - estimatedWaitTime: an estimated time the session may spend in the queue before an agent is available
    case chatSessionStatus(state: ContactCenterChatSessionState, estimatedWaitTime: Int)
    /// Informs that a CRM case has been set or cleared for the chat session. Once case is set, application may use [getCaseHistory](x-source-tag://getCaseHistory) and [closeCase](x-source-tag://closeCase) methods.
    /// Direction: S->C
    /// - Parameters:
    ///   - caseID: an ID of the case. Could be empty if scenario unassigned the case previously assigned to the session
    ///   - timestamp: Timestamp of the event
    case chatSessionCaseSet(caseID: String?, timestamp: Date)
    /// Indicates that a new party (a new agent) has joined the chat session.
    /// Direction: S->C
    /// - Parameters:
    ///   - partyID: unique ID of the party within the session. Only agent (internal) parties are reported
    ///   - firstName: Party's first name, optional
    ///   - lastName: Party's last name, optional
    ///   - displayName: Party's display name, optional
    ///   - type: Party's type
    ///   - timestamp: Timestamp of the event
    case chatSessionPartyJoined(partyID: String, firstName: String?, lastName: String?, displayName: String?, type: ContactCenterChatSessionPartyType, timestamp: Date)
    /// Indicates that a party has left the chat session.
    /// Direction: S->C
    /// - Parameters:
    ///   - partyID: unique ID of the party within the session
    ///   - timestamp: Timestamp of the event
    case chatSessionPartyLeft(partyID: String, timestamp: Date)
    /// Indicates that the party started typing a message
    /// Direction: S<->C
    /// - Parameters:
    ///   - partyID: unique ID of the party within the session
    ///   - timestamp: Timestamp of the event
    case chatSessionTyping(partyID: String?, timestamp: Date?)
    /// Indicates that the party stopped typing a message
    /// Direction: S<->C
    /// - Parameters:
    ///   - partyID: unique ID of the party within the session
    ///   - timestamp: Timestamp of the event
    case chatSessionNotTyping(partyID: String?, timestamp: Date?)
    /// Contains a new geographic location
    /// Direction: S<->C
    /// - Parameters:
    ///   - partyID: unique ID of the sender party
    ///   - url: location URL, optional
    ///   - latitude: GPS latitude
    ///   - longitude: GPS longitude
    ///   - timestamp: Timestamp of the event
    case chatSessionLocation(partyID: String?, url: String?, latitude: Float, longitude: Float, timestamp: Date?)
    /// Indicates that a system has requested an application to display a message. Typically used to display inactivity warning.
    /// Direction: S->C
    /// - Parameters:
    ///   - message: a text message to display
    ///   - timestamp: Timestamp of the event
    case chatSessionTimeoutWarning(message: String, timestamp: Date)
    /// Indicates that a system has ended the chat session due to the user's inactivity.
    /// Direction: S->C
    /// - Parameters:
    ///   - message: a text message to display
    ///   - timestamp: Timestamp of the event
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

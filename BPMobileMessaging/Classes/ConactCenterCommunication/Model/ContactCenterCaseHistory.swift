//
//  ContactCenterChatSessionCaseHistory.swift
//  BPMobileMessaging
//
//  Created by Alexander Lobastov on 2/26/21.
//

import Foundation

/// Represents a single completed chat session. Includes the session ID, session creation timestamp and array of `ContactCenterEvent` events.
/// - Tag: ContactCenterChatSession
public struct ContactCenterChatSession {
    /// ID of the chat session.
    let chatID: String
    /// Timestamp of the chat session creation.
    let createdTime: Date
    /// Array of the events [ContactCenterEvent](x-source-tag://ContactCenterEvent) within the chat session.
    let events: [ContactCenterEvent]
}

extension ContactCenterChatSession {
    func toDto() -> Encodable {
        return ChatSessionDto(chatID: chatID, createdTime: createdTime, events: events)
    }
}

/// Represents an history of the CRM case associated with the current chat session as an array of `ContactCenterChatSession` objects. Application may obtain the case history by executing a [getCaseHistory](x-source-tag://getCaseHistory) method of the ContactCenterCommunicating protocol.
/// - Tag: ContactCenterCaseHistory
public struct ContactCenterCaseHistory {
    /// An array of chat sessions [ContactCenterChatSession](x-source-tag://ContactCenterChatSession).
    public let sessions: [ContactCenterChatSession]
}

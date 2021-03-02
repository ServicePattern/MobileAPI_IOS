//
//  ContactCenterChatSessionCaseHistory.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 2/26/21.
//

import Foundation

/// - Tag: ContactCenterChatSession
public struct ContactCenterChatSession {
    let chatID: String
    let createdTime: Date
    let events: [ContactCenterEvent]
}

extension ContactCenterChatSession {
    func toDto() -> Encodable {
        return ChatSessionDto(chatID: chatID, createdTime: createdTime, events: events)
    }
}
/// - Tag: ContactCenterCaseHistory
public struct ContactCenterCaseHistory {
    public let sessions: [ContactCenterChatSession]
}

//
//  ChatSessionNotTyping.swift
//  BPMobileMessaging
//
//  Created by Alexander Lobastov on 2/25/21.
//

import Foundation

/// - Tag: ChatSessionNotTypingDto
struct ChatSessionNotTypingDto: Codable {
    let event: ContactCenterEventTypeDto
    let partyID: String?
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case event
        case partyID = "party_id"
        case timestamp
    }

    init(partyID: String?, timestamp: Date?) {
        self.event = .chatSessionNotTyping
        self.partyID = partyID
        self.timestamp = timestamp
    }
}

extension ChatSessionNotTypingDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionNotTyping(partyID: partyID, timestamp: timestamp)
    }
}

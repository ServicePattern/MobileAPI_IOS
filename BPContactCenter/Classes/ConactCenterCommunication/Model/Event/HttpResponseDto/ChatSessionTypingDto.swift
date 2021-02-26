//
//  ChatSessionTypingDto.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 2/25/21.
//

import Foundation

/// - Tag: ChatSessionTypingDto
struct ChatSessionTypingDto: Codable {
    let event: ContactCenterEventTypeDto
    let partyID: String?
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case event
        case partyID = "party_id"
        case timestamp
    }

    init(partyID: String?, timestamp: Date?) {
        self.event = .chatSessionTyping
        self.partyID = partyID
        self.timestamp = timestamp
    }
}

extension ChatSessionTypingDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionTyping(partyID: partyID, timestamp: timestamp)
    }
}

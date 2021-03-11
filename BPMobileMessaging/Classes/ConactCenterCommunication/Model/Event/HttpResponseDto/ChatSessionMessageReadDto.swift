//
//  ChatSessionMessageReadDto.swift
//  BPMobileMessaging
//
//  Created by Alexander Lobastov on 2/17/21.
//

import Foundation

/// Represents a message read confirmation event
/// - Tag: ChatSessionMessageReadDto
struct ChatSessionMessageReadDto: Codable {
    let event: ContactCenterEventTypeDto
    let messageID: String?
    let partyID: String?
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case event
        case messageID = "ref_msg_id"
        case partyID = "party_id"
        case timestamp
    }

    init(messageID: String?, partyID: String?, timestamp: Date?) {
        self.event = .chatSessionMessageRead
        self.messageID = messageID
        self.partyID = partyID
        self.timestamp = timestamp
    }
}

extension ChatSessionMessageReadDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionMessageRead(messageID: messageID, partyID: partyID, timestamp: timestamp)
    }
}

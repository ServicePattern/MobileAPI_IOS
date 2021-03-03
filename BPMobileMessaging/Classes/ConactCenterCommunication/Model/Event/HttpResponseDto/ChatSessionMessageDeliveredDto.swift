//
//  ChatSessionMessageDeliveredDto.swift
//  BPMobileMessaging
//
//  Created by Alexander Lobastov on 2/17/21.
//

import Foundation

/// Represents a message delivery confirmation event
/// - Tag: ChatSessionMessageDeliveredDto
struct ChatSessionMessageDeliveredDto: Codable {
    let event: ContactCenterEventTypeDto
    let messageID: String
    let partyID: String?
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case event
        case messageID = "msg_id"
        case partyID = "party_id"
        case timestamp
    }

    init(messageID: String, partyID: String?, timestamp: Date?) {
        self.event = .chatSessionMessageDelivered
        self.messageID = messageID
        self.partyID = partyID
        self.timestamp = timestamp
    }
}

extension ChatSessionMessageDeliveredDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionMessageDelivered(messageID: messageID, partyID: partyID, timestamp: timestamp)
    }
}

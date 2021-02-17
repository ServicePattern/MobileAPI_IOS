//
//  ChatSessionMessageDeliveredDto.swift
//  BPContactCenter
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
}

extension ChatSessionMessageDeliveredDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionMessageDelivered(messageID: messageID, partyID: partyID, timestamp: timestamp)
    }
}

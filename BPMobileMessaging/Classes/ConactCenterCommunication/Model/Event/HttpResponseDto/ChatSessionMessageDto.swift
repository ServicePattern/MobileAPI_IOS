//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

/// Represents a message event
/// - Tag: ChatSessionMessageDto
struct ChatSessionMessageDto: Codable {
    let event: ContactCenterEventTypeDto
    let messageID: String
    let partyID: String?
    let message: String
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case event
        case messageID = "msg_id"
        case partyID = "party_id"
        case message = "msg"
        case timestamp
    }

    init(messageID: String, partyID: String?, message: String, timestamp: Date?) {
        self.event = .chatSessionMessage
        self.messageID = messageID
        self.partyID = partyID
        self.message = message
        self.timestamp = timestamp
    }
}

extension ChatSessionMessageDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionMessage(messageID: messageID, partyID: partyID, message: message, timestamp: timestamp)
    }
}

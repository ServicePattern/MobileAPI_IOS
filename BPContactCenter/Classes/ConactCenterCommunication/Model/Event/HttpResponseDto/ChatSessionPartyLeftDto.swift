//
//  ChatSessionPartyLeftDto.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 2/17/21.
//

import Foundation

/// - Tag: ChatSessionPartyLeftDto
struct ChatSessionPartyLeftDto: Codable {
    let event: ContactCenterEventTypeDto
    let partyID: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case event
        case partyID = "party_id"
        case timestamp
    }

    init(partyID: String, timestamp: Date) {
        self.event = .chatSessionPartyLeft
        self.partyID = partyID
        self.timestamp = timestamp
    }
}

extension ChatSessionPartyLeftDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionPartyLeft(partyID: partyID, timestamp: timestamp)
    }
}

//
//  ChatSessionEndDto.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 2/17/21.
//

import Foundation

struct ChatSessionEndDto: Codable {
    let event: ContactCenterEventTypeDto
    let partyID: String?
    let timestamp: Date?

    enum CodingKeys: String, CodingKey {
        case event
        case partyID = "party_id"
        case timestamp
    }
}

extension ChatSessionEndDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionEnd(partyID: partyID, timestamp: timestamp)
    }
}

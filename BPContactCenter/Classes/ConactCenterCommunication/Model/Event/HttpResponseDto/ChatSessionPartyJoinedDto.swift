//
// Copyright © 2021 BrightPattern. All rights reserved. 

import Foundation

/// - Tag: ChatSessionPartyTypeDto
enum ChatSessionPartyTypeDto: String, Codable {
    case scenario
    case external
    case `internal`
}

extension ChatSessionPartyTypeDto {
    func toModel() -> ContactCenterChatSessionPartyType {
        switch self {
        case .scenario:
            return .scenario
        case .external:
            return .external
        case .internal:
            return .internal
        }
    }
}

/// - Tag: ChatSessionPartyJoinedDto
struct ChatSessionPartyJoinedDto: Codable {
    let event: ContactCenterEventTypeDto
    let partyID: String
    let firstName: String?
    let lastName: String?
    let displayName: String?
    let type: ChatSessionPartyTypeDto
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case event
        case partyID = "party_id"
        case firstName = "first_name"
        case lastName = "last_name"
        case displayName = "display_name"
        case type
        case timestamp
    }

    init(partyID: String, firstName: String?, lastName: String?, displayName: String?, type: ChatSessionPartyTypeDto, timestamp: Date) {
        self.event = .chatSessionPartyJoined
        self.partyID = partyID
        self.firstName = firstName
        self.lastName = lastName
        self.displayName = displayName
        self.type = type
        self.timestamp = timestamp
    }
}

extension ChatSessionPartyJoinedDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionPartyJoined(partyID: partyID, firstName: firstName, lastName: lastName, displayName: displayName, type: type.toModel(), timestamp: timestamp)
    }
}

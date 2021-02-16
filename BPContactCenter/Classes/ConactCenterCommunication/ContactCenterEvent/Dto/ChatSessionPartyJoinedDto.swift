//
// Copyright © 2021 BrightPattern. All rights reserved. 

import Foundation

/// - Tag: ContactCenterChatSessionPartyTypeDto
enum ContactCenterChatSessionPartyTypeDto: String, Codable {
    case scenario
    case external
    case `internal`

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
    let firstName: String
    let lastName: String
    let displayName: String
    let type: ContactCenterChatSessionPartyTypeDto
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
}

extension ChatSessionPartyJoinedDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEventProtocol {
        ContactCenterServerEvent.chatSessionPartyJoined(partyID: partyID, firstName: firstName, lastName: lastName, displayName: displayName, type: type.toModel(), timestamp: timestamp)
    }
}

//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

/// Contains all possible even types either serve or client ones
/// - Tag: ContactCenterEventTypeDto
enum ContactCenterEventTypeDto: String, Codable, CaseIterable {
    case chatSessionStatus = "chat_session_status"
    case chatSessionMessage = "chat_session_message"
    case chatSessionEnded = "chat_session_ended"
    case chatSessionPartyJoined = "chat_session_party_joined"

    /// Makes a correspondence between an even type and a particular event Dto JSON codable object
    var codableType: Codable.Type {
        switch self {
        case .chatSessionStatus:
            return ChatSessionStatusDto.self
        case .chatSessionMessage:
            return ChatSessionMessageDto.self
        case .chatSessionEnded:
            return ChatSessionEndedDto.self
        case .chatSessionPartyJoined:
            return ChatSessionPartyJoinedDto.self
        }
    }

    func decodeDto(from decoder: Decoder) throws -> ContactCenterEventModelConvertible {
        guard let dtoConvertible = try codableType.init(from: decoder) as? ContactCenterEventModelConvertible else {

            throw ContactCenterError.failedToCast("to: \(ContactCenterEventModelConvertible.self)")
        }

        return dtoConvertible
    }
}

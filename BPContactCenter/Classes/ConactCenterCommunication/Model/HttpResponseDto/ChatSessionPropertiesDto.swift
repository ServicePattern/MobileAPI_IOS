//
// Copyright © 2019 Robert Bosch GmbH. All rights reserved. 
    

import Foundation

/// - Tag: ChatSessionStateDto
enum ChatSessionStateDto: String, Codable {
    case queued
    case connecting
    case connected
    case ivr
    case failed
    case completed
}

extension ChatSessionStateDto {
    func toModel() -> ContactCenterChatSessionState {
        switch self {
        case .queued:
            return .queued
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .ivr:
            return .ivr
        case .failed:
            return .failed
        case .completed:
            return .completed
        }
    }
}

/// - Tag: ChatSessionPropertiesDto
struct ChatSessionPropertiesDto: Decodable {
    let chatID: String
    let state: ChatSessionStateDto
    let ewt: String
    let isNewChat: Bool
    let phoneNumber: String

    enum CodingKeys: String, CodingKey {
        case chatID = "chat_id"
        case state
        case ewt
        case isNewChat = "is_new_chat"
        case phoneNumber = "phone_number"
    }
}

extension ChatSessionPropertiesDto {
    func toModel() -> ContactCenterChatSessionProperties {
        ContactCenterChatSessionProperties(chatID: chatID, state: state.toModel(), ewt: ewt, isNewChat: isNewChat, phoneNumber: phoneNumber)
    }
}

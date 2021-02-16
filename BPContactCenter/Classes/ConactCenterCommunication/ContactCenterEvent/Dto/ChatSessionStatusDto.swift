//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

/// - Tag: ContactCenterChatSessionStateDto
enum ChatSessionStateDto: String, Codable {
    case queued
    case connecting
    case connected
    case failed
    case completed

    func toModel() -> ContactCenterChatSessionState {
        switch self {
        case .queued:
            return .queued
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .failed:
            return .failed
        case .completed:
            return .completed
        }
    }
}

/// - Tag: ChatSessionStatusDto
struct ChatSessionStatusDto: Codable {
    let event: ContactCenterEventTypeDto
    let state: ChatSessionStateDto
    let ewt: String
}

extension ChatSessionStatusDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEventProtocol {
        ContactCenterServerEvent.chatSessionStatus(state: state.toModel(), ewt: ewt)
    }
}

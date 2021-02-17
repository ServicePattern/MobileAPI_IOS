//
//  ChatSessionTimeoutWarning.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 2/17/21.
//

import Foundation

/// Represents a timeout warning event
/// - Tag: ChatSessionTimeoutWarningDto
struct ChatSessionTimeoutWarningDto: Codable {
    let event: ContactCenterEventTypeDto
    let message: String
    let timestamp: Date

    enum CodingKeys: String, CodingKey {
        case event
        case message = "msg"
        case timestamp
    }
}

extension ChatSessionTimeoutWarningDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionTimeoutWarning(message: message, timestamp: timestamp)
    }
}

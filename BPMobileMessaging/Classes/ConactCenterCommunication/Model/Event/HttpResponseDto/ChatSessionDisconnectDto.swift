//
//  ChatSessionDisconnect.swift
//  BPMobileMessaging
//
//  Created by Alexander Lobastov on 2/17/21.
//

import Foundation

struct ChatSessionDisconnectDto: Codable {
    let event: ContactCenterEventTypeDto

    init() {
        self.event = .chatSessionDisconnect
    }
}

extension ChatSessionDisconnectDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionDisconnect
    }
}

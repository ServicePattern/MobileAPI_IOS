//
//  ChatSessionEndDto.swift
//  BPContactCenter
//
//  Created by Alexander Lobastov on 2/17/21.
//

import Foundation

struct ChatSessionEndDto: Codable {
    let event: ContactCenterEventTypeDto

    init() {
        self.event = .chatSessionEnd
    }
}

extension ChatSessionEndDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionEnd
    }
}

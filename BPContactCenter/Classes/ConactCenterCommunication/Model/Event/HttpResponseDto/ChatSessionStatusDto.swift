//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

/// - Tag: ChatSessionStatusDto
struct ChatSessionStatusDto: Codable {
    let event: ContactCenterEventTypeDto
    let state: ChatSessionStateDto
    let ewt: String

    init(state: ChatSessionStateDto, ewt: String) {
        self.event = .chatSessionStatus
        self.state = state
        self.ewt = ewt
    }
}

extension ChatSessionStatusDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionStatus(state: state.toModel(), estimatedWaitTime: Int(ewt) ?? 0)
    }
}

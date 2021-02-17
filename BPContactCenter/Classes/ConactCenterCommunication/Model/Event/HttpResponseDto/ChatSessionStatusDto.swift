//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

/// - Tag: ChatSessionStatusDto
struct ChatSessionStatusDto: Codable {
    let event: ContactCenterEventTypeDto
    let state: ChatSessionStateDto
    let ewt: String
}

extension ChatSessionStatusDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionStatus(state: state.toModel(), ewt: ewt)
    }
}

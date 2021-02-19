//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

struct ChatSessionEndedDto: Codable {
    let event: ContactCenterEventTypeDto

    init() {
        self.event = .chatSessionEnded
    }
}

extension ChatSessionEndedDto: ContactCenterEventModelConvertible {
    func toModel() -> ContactCenterEvent {
        ContactCenterEvent.chatSessionEnded
    }
}

//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation
import BPContactCenter

protocol ChatViewModelUpdatable: class {
    func update()
}

class ChatViewModel {
    private let service: ServiceDependencyProtocol
    var sectionsCount: Int = 1
    let currentChatID: String?
    private var messages: [ChatMessage] {
        didSet {
            delegate?.update()
        }
    }
    weak var delegate: ChatViewModelUpdatable?

    init(service: ServiceDependencyProtocol, currentChatID: String) {
        self.service = service
        self.currentChatID = currentChatID
        self.messages = []
        NotificationCenter.default.addObserver(self, selector: #selector(receivedEvents), name: NotificationName.contactCenterEventsReceived.name, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func numberOfRows(section: Int) -> Int {
        return messages.count
    }

    func chatMessage(at index: Int) -> ChatMessage {
        messages[index]
    }
}

extension ChatViewModel {
    @objc
    private func receivedEvents(notification: Notification) {
        guard let events = notification.userInfo?[NotificationUserInfoKey.contactCenterEvents] as? [ContactCenterEvent] else {
            print("Failed to get contact center events: \(notification)")
            return
        }
        processSessionEvents(events: events)
    }

    private func processSessionEvents(events: [ContactCenterEvent]) {
        for e in events {
            switch e {
            case .chatSessionMessage(let messageID, let partyID, let message, let timestamp):
                print("\(timestamp): message: \(message) from party \(partyID)")
                guard let chatID = self.currentChatID else {
                    print("chatID is empty")
                    continue
                }
                messages.append(ChatMessage(type: .kBPNMessageMine, text: message, attachment: nil, senderName: nil, time: timestamp, profileImage: nil, chatID: chatID))
                chatMessageDelivered(chatID: chatID, messageID: messageID)
                chatMessageRead(chatID: chatID, messageID: messageID)
            case .chatSessionStatus(let state, let estimatedWaitTime):
                if state == .connected {
                    guard let chatID = self.currentChatID else {
                        print("chatID is empty")
                        continue
                    }
                    print("Connected to a chat: \(chatID)")
                } else {
                    guard let chatID = self.currentChatID else {
                        print("chatID is empty")
                        continue
                    }
                    print("Waiting in a queue: \(chatID) estimated wait time: \(estimatedWaitTime)")
                }
            default:()
            }
        }
    }

    private func chatMessageDelivered(chatID: String, messageID: String) {
        service.contactCenterService.chatMessageDelivered(chatID: chatID, messageID: messageID) { result in
            switch result {
            case .success(_):
                print("chatMessageDelivered confirmed")
            case .failure(let error):
                print("chatMessageDelivered error: \(error)")
            }
        }
    }

    private func chatMessageRead(chatID: String, messageID: String) {
        service.contactCenterService.chatMessageRead(chatID: chatID, messageID: messageID) { result in
            switch result {
            case .success(_):
                print("chatMessageRead confirmed")
            case .failure(let error):
                print("chatMessageRead error: \(error)")
            }
        }
    }
}

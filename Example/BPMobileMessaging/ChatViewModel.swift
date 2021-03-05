//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation
import BPMobileMessaging
import MessageKit

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
    var currentSender: SenderType {
        ChatUser(senderId: "", displayName: "")
    }
    var messagesEmpty: Bool {
        messages.count == 0
    }
    var lastMessageIndexPath: IndexPath? {
        guard messages.count > 0 else {
            return nil
        }
        return IndexPath(item: 0, section: messages.count - 1)
    }

    init(service: ServiceDependencyProtocol, currentChatID: String) {
        self.service = service
        self.currentChatID = currentChatID
        self.messages = []
        NotificationCenter.default.addObserver(self, selector: #selector(receivedEvents), name: NotificationName.contactCenterEventsReceived.name, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func chatMessagesCount() -> Int {
        messages.count
    }

    func chatMessage(at index: Int) -> ChatMessage {
        messages[index]
    }

    func userEnteredData(_ data: [Any], with completion : (() -> Void)?) {
        guard let chatID = currentChatID else {
            return
        }
        var messages = [ChatMessage]()
        data.forEach { component in
            let user = ChatUser(senderId: "", displayName: "")
            if let str = component as? String {
                messages.append(ChatMessage(text: str, user: user, messageId: UUID().uuidString, date: Date()))
            }
        }

        let dipatchGroup = DispatchGroup()
        DispatchQueue.global(qos: .default).async { [weak self] in
            for message in messages {
                guard case .text(let messageText) = message.kind else {
                    continue
                }
                dipatchGroup.enter()
                self?.service.contactCenterService.sendChatMessage(chatID: chatID,
                                                             message: messageText) { result in
                    dipatchGroup.leave()
                    switch result {
                    case .success:()
                    case .failure:()
                    }
                }
            }
            dipatchGroup.wait()

            DispatchQueue.main.async { [weak self] in
                completion?()
                self?.messages.append(contentsOf: messages)
            }
        }
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
                guard let partyID = partyID, let timestamp = timestamp else {
                    print("partyID or timestamp empty")
                    return
                }
                let chatUser = ChatUser(senderId: partyID, displayName: "")
                messages.append(ChatMessage(text: message,
                                            user: chatUser,
                                            messageId: messageID,
                                            date: timestamp))
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

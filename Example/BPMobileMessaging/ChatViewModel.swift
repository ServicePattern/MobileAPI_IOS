//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation
import BPMobileMessaging

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
    private let defaultAvatarSize = CGFloat(50)
    private let defaultAvatarCornerRadius = CGFloat(25)

    private let defaultMessageFont = UIFont.systemFont(ofSize: 17.0)
    private var lastMessageWithDateDisplayed: ChatMessage? = nil
    private let timeStampFont = UIFont.systemFont(ofSize: 11)
    private let timeStampInterval = TimeInterval(60)
    private let bubbleWidth = CGFloat(200)

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

    private func avatarImage(at indexPath: IndexPath) -> UIImage? {
        return nil
    }

    private func avatarSize(at indexPath: IndexPath) -> CGFloat {
        return defaultAvatarSize
    }

    private func messageFont(at indexPath: IndexPath) -> UIFont {
        return defaultMessageFont
    }

    func heightForRow(at indexPath: IndexPath) -> CGFloat {
        let message = messages[indexPath.row]
        let avatar = avatarImage(at: indexPath)
        let avatarSizeValue = (avatar != nil) ? avatarSize(at: indexPath): 0
        let messageFontValue = messageFont(at: indexPath)

        if 0 == indexPath.row {
            lastMessageWithDateDisplayed = nil
        }

        switch message.type {
        case .messageMine, .messageSomeone:
            let timeStampFont: UIFont?
            if let time = lastMessageWithDateDisplayed?.time {
                if let timeDiff = message.time?.timeIntervalSince(time),
                   timeDiff >= timeStampInterval {
                    timeStampFont = self.timeStampFont
                } else {
                    timeStampFont = nil
                }
                lastMessageWithDateDisplayed = message
            } else {
                lastMessageWithDateDisplayed = message
                timeStampFont = self.timeStampFont
            }
            return ChatBubbleCell.requiredHeight(forCellDisplayingMessage: message, avatarHeight: avatarSizeValue, videoFilePlaceholderImage: nil, otherFilePlaceholderImage: nil, messageFont: messageFontValue, timeStamp: timeStampFont, senderNameFont: nil, timeStamp: .timeStampSideAligned, limitedByWidth: bubbleWidth)
        case .messageTypingMine,
             .messageTypingSomeone,
             .messageStatus:
            return 0
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
                messages.append(ChatMessage(type: .messageMine, text: message, attachment: nil, senderName: nil, time: timestamp, profileImage: nil, chatID: chatID))
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

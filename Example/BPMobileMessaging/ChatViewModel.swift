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
    private var systemParty = ChatUser(senderId: "", displayName: "")
    private var myParty = ChatUser(senderId: "", displayName: "Me")
    private var parties: [String: ChatUser] = [:]
    private var messages: [ChatMessage] {
        didSet {
            delegate?.update()
        }
    }
    weak var delegate: ChatViewModelUpdatable?
    var currentSender: SenderType {
        myParty
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
        //  My party ID is the same as the chat ID
        self.myParty = ChatUser(senderId: currentChatID, displayName: "Me")
        self.parties[myParty.senderId] = myParty
        self.messages = []
        
        NotificationCenter.default.addObserver(self, selector: #selector(receivedEvents), name: NotificationName.contactCenterEventsReceived.name, object: nil)

        self.subscribeForNotifications() { subscribeResult in
            DispatchQueue.main.async {
                switch subscribeResult {
                case .success:
                    print("Subscribe for remote notifications confirmed")
                case .failure(let error):
                    print("Failed to subscribe for notifications: \(error)")
                }
            }
        }
   }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getParty(partyID: String) -> ChatUser {
       parties[partyID] ?? ChatUser(senderId: "", displayName: "")
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
            if let str = component as? String {
                messages.append(ChatMessage(text: str, user: myParty, messageId: UUID().uuidString, date: Date()))
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

    private func subscribeForNotifications(completion: @escaping (Result<Void, Error>) -> Void) {
        
        guard let chatID = self.currentChatID else {
            print("Chat ID is not set")
            completion(.failure(ExampleAppError.chatIdNotSet))
            return
        }
        
        guard let deviceToken = service.deviceToken else {
            print("Device token is not set")
            completion(.failure(ExampleAppError.deviceTokenNotSet))
            return
        }

        if service.useFirebase {
            service.contactCenterService.subscribeForRemoteNotificationsFirebase(chatID: chatID,
                                                                         deviceToken: deviceToken,
                                                                         with: completion)
        } else {
            service.contactCenterService.subscribeForRemoteNotificationsAPNs(chatID: chatID,
                                                                     deviceToken: deviceToken,
                                                                     with: completion)
        }
    }

    private func processSessionEvents(events: [ContactCenterEvent]) {
        for e in events {
            guard let chatID = self.currentChatID else {
                print("chatID is empty")
                continue
            }

            switch e {
            case .chatSessionPartyJoined(let partyID, let firstName, let lastName, let displayName, let type, let timestamp):
                print("\(timestamp): party: \(partyID) joined: \(firstName), \(lastName), \(displayName)")
                let chatUser = ChatUser(senderId: partyID, displayName: displayName ?? ((firstName ?? "") + " " + (lastName ?? "")))
                self.parties[partyID] = chatUser
                messages.append(ChatMessage(text: "Joined the session",
                                            user: chatUser,
                                            messageId: "",
                                            date: timestamp))
            case .chatSessionPartyLeft(let partyID, let timestamp):
                print("\(timestamp): party: \(partyID) left")
                messages.append(ChatMessage(text: "Left the session",
                                            user: self.getParty(partyID: partyID),
                                            messageId: "",
                                            date: timestamp))
            case .chatSessionMessage(let messageID, let partyID, let message, let timestamp):
                print("\(timestamp): message: \(message) from party \(partyID)")
                guard let partyID = partyID, let timestamp = timestamp, let messageID = messageID else {
                    print("partyID or timestamp empty")
                    return
                }
                messages.append(ChatMessage(text: message,
                                            user: self.getParty(partyID: partyID),
                                            messageId: messageID,
                                            date: timestamp))
                chatMessageDelivered(chatID: chatID, messageID: messageID)
                chatMessageRead(chatID: chatID, messageID: messageID)
            case .chatSessionStatus(let state, let estimatedWaitTime):
                if state == .connected {
                    print("Connected to a chat: \(chatID)")
                } else {
                    print("Waiting in a queue: \(chatID) estimated wait time: \(estimatedWaitTime)")
                }
            case .chatSessionCaseSet(let caseID, let timestamp):
                self.getCaseHistory(chatID: chatID)
            case .chatSessionTimeoutWarning(let message, let timestamp):
                messages.append(ChatMessage(text: message,
                                            user: self.systemParty,
                                            messageId: "",
                                            date: timestamp))
            case .chatSessionInactivityTimeout(let message, let timestamp):
                messages.append(ChatMessage(text: message,
                                            user: self.systemParty,
                                            messageId: "",
                                            date: timestamp))
            case .chatSessionEnded:
                messages.append(ChatMessage(text: "The session has ended",
                                            user: self.systemParty,
                                            messageId: "",
                                            date: Date()))
//                self.closeCase(chatID: chatID)
            default:()
            }
        }
    }

    private func getChatHistory(chatID: String) {
        service.contactCenterService.getChatHistory(chatID: chatID) { [weak self] eventsResult in
            DispatchQueue.main.async {
                switch eventsResult {
                case .success(let events):
                    print("Received chat history")
                        self?.processSessionEvents(events: events)
                case .failure(let error):
                    print("Failed to getChatHistory: \(error)")
                }
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
    
    private func getCaseHistory(chatID: String) {
        service.contactCenterService.getCaseHistory(chatID: chatID) { [weak self] eventsResult in
            switch eventsResult {
            case .success(let sessions):
                print("Received case history: \(sessions)")
            case .failure(let error):
                print("Failed to getCaseHistory: \(error)")
            }
        }
    }

    private func closeCase(chatID: String) {
        service.contactCenterService.closeCase(chatID: chatID) { result in
            switch result {
            case .success(_):
                print("closeCase confirmed")
            case .failure(let error):
                print("closeCase error: \(error)")
            }
        }
    }

    private func sendChatMessage(chatID: String, message: String) {
        service.contactCenterService.sendChatMessage(chatID: chatID, message: "Hello") { chatMessageResult in
            switch chatMessageResult {
            case .success(let messageID):
                print("MessageID: \(messageID)")

            case .failure(let error):

                print("Failed to send chat message: \(error)")
            }
        }
    }

    private func disconnectChat(chatID: String) {
        service.contactCenterService.disconnectChat(chatID: chatID) { result in
            switch result {
            case .success(_):
                print("disconnectChat confirmed")
            case .failure(let error):
                print("disconnectChat error: \(error)")
            }
        }
    }

    private func endChat(chatID: String) {
        service.contactCenterService.endChat(chatID: chatID) { result in
            switch result {
            case .success(_):
                print("endChat confirmed")
            case .failure(let error):
                print("endChat error: \(error)")
            }
        }
    }
}

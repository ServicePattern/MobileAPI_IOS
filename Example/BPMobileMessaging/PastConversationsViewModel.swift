//
// Copyright © 2021 BrightPattern. All rights reserved. 

import Foundation
import MessageKit
import BPMobileMessaging

protocol PastConversationsViewModelUpdatable: class {
    func update()
}

class PastConversationsViewModel {
    weak var delegate: PastConversationsViewModelUpdatable?
    private var systemParty = ChatUser(senderId: "", displayName: "")
    private var myParty = ChatUser(senderId: "", displayName: "Me")
    private var parties: [String: ChatUser] = [:]
    var currentSender: SenderType {
        myParty
    }
    private var messagesValue = [ChatMessage]()
    private var messages: [ChatMessage] {
        get {
            messagesValue
        }
        set {
            messagesValue = newValue
            delegate?.update()
        }
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

    init(sessions: [ContactCenterChatSession]) {
        var messages = [ChatMessage]()
        sessions.forEach { session in
            if session.events.count > 0 {
                messages.append(ChatMessage(text: "Session started",
                                            user: self.systemParty,
                                            messageId: "",
                                            date: session.createdTime))
            }
            session.events.forEach { event in
                switch event {
                case .chatSessionPartyJoined(let partyID, let firstName, let lastName, let displayName, _, let timestamp):
                    let chatUser = ChatUser(senderId: partyID, displayName: displayName ?? ((firstName ?? "") + " " + (lastName ?? "")))
                    self.parties[partyID] = chatUser
                    messages.append(ChatMessage(text: "Joined the session",
                                                user: chatUser,
                                                messageId: "",
                                                date: timestamp))
                case .chatSessionPartyLeft(let partyID, let timestamp):
                    let user = getParty(partyID: partyID)
                    messages.append(ChatMessage(text: "Left the session",
                                                user: user,
                                                messageId: "",
                                                date: timestamp))
                case .chatSessionMessage(let messageID, let partyID, let message, let timestamp):
                    guard let partyID = partyID,
                          let messageID = messageID else {
                        print("partyID, timestamp or messageID empty")
                        return
                    }
                    let user = getParty(partyID: partyID)
                    messages.append(ChatMessage(text: message,
                                                user: user,
                                                messageId: messageID,
                                                date: timestamp ?? Date()))
                case .chatSessionStatus:()
                case .chatSessionCaseSet: ()
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
                case let .chatSessionMessageRead(messageID, _, _):
                    var message = messages.first(where: { $0.messageId == messageID })
                    message?.read = true
                default:()
                }
            }
        }
        self.messages = messages
    }

    func chatMessagesCount() -> Int {
        messages.count
    }

    func chatMessage(at index: Int) -> ChatMessage {
        messages[index]
    }

    func getParty(partyID: String) -> ChatUser {
       parties[partyID] ?? systemParty
    }
}

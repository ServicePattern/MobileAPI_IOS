//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation
import BPMobileMessaging

protocol HelpRequestUpdatable: class {
    func update()
    func showChat()
}

class HelpRequestViewModel {
    let service: ServiceDependencyProtocol
    var currentChatID: String?
    let bottomSpace = CGFloat(105)
    var isChatAvailable: Bool = false {
        didSet {
            delegate?.update()
        }
    }
    var isRequestInProgress: Bool = false {
        didSet {
            delegate?.update()
        }
    }
    weak var delegate: HelpRequestUpdatable?

    init(service: ServiceDependencyProtocol) {
        self.service = service

        NotificationCenter.default.addObserver(self, selector: #selector(receivedEvents), name: NotificationName.contactCenterEventsReceived.name, object: nil)
        checkChatAvailability()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func helpMePressed() {
        requestChat()
    }

    func pastConversationsPressed() {
        guard let chatID = currentChatID else {
            print("chatID is empty")
            return
        }
        getChatHistory(chatID: chatID)
    }

    @objc
    private func receivedEvents(notification: Notification) {
        guard let events = notification.userInfo?[NotificationUserInfoKey.contactCenterEvents] as? [ContactCenterEvent] else {
            print("Failed to get contact center events: \(notification)")
            return
        }
        processSessionEvents(events: events)
    }
}

extension HelpRequestViewModel {
    private func checkChatAvailability() {
        isRequestInProgress = true
        service.contactCenterService.checkAvailability { [weak self] serviceAvailabilityResult in
            DispatchQueue.main.async {
                self?.isRequestInProgress = false
                switch serviceAvailabilityResult {
                case .success(let serviceAvailability):
                    print("Chat is \(serviceAvailability.chat)")
                    self?.isChatAvailable = serviceAvailability.chat == .available
                case .failure(let error):
                    print("Failed to check availability: \(error)")
                }
            }
        }
    }
    private func requestChat() {
        isRequestInProgress = true
        service.contactCenterService.requestChat(phoneNumber: "12345", from: "54321", parameters: [:]) { [weak self] chatPropertiesResult in
            DispatchQueue.main.async {
                self?.isRequestInProgress = false
                switch chatPropertiesResult {
                case .success(let chatProperties):
                    print("Chat properties: \(chatProperties)")
                    self?.currentChatID = chatProperties.chatID
                    self?.subscribeForNotifications(chatID: chatProperties.chatID) { subscribeResult in
                        DispatchQueue.main.async {
                            switch subscribeResult {
                            case .success:
                                print("Subscribe for remote notifications confirmed")
                            case .failure(let error):
                                print("Failed to subscribe for notifications: \(error)")
                            }
                        }
                    }
                case .failure(let error):
                    print("\(error)")
                }
            }
        }
    }

    private func getChatHistory(chatID: String) {
        isRequestInProgress = true
        service.contactCenterService.getChatHistory(chatID: chatID) { [weak self] eventsResult in
            DispatchQueue.main.async {
                self?.isRequestInProgress = false
                switch eventsResult {
                case .success(let events):
                    print("Received chat history")
                        self?.currentChatID = chatID
                        self?.processSessionEvents(events: events)
                case .failure(let error):
                    print("Failed to getChatHistory: \(error)")
                }
            }
        }
    }

    private func getCaseHistory(chatID: String) {
        service.contactCenterService.getCaseHistory(chatID: chatID) { [weak self] eventsResult in
            switch eventsResult {
            case .success(let sessions):
                print("Received case history: \(sessions)")
                DispatchQueue.main.async {
//                    self?.currentChatID = chatID
//                    self?.processSessionEvents(chatID: chatID, events: events)
                }
            case .failure(let error):
                print("Failed to getCaseHistory: \(error)")
            }
        }
    }

    private func endChatSession(chatID: String) {
        self.disconnectChat(chatID: chatID)
        self.endChat(chatID: chatID)
    }

    private func subscribeForNotifications(chatID: String, completion: @escaping (Result<Void, Error>) -> Void) {
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

    private func processSessionEvents(events: [ContactCenterEvent]) {
        for e in events {
            switch e {
            case .chatSessionMessage(let messageID, let partyID, let message, let timestamp):
                print("\(timestamp): message: \(message) from party \(partyID)")
                guard let chatID = self.currentChatID else {
                    print("chatID is empty")
                    continue
                }
                self.chatMessageDelivered(chatID: chatID, messageID: messageID)
                self.chatMessageRead(chatID: chatID, messageID: messageID)
            case .chatSessionStatus(let state, let estimatedWaitTime):
                if state == .connected {
                    self.delegate?.showChat()
                    guard let chatID = self.currentChatID else {
                        print("chatID is empty")
                        continue
                    }
                    print("Connected to a chat: \(chatID)")
                } else if state == .queued {
                    guard let chatID = self.currentChatID else {
                        print("chatID is empty")
                        continue
                    }
                    print("Waiting in a queue: \(chatID) estimated wait time: \(estimatedWaitTime)")
                }
            case .chatSessionCaseSet(let caseID, let timestamp):
                guard let chatID = self.currentChatID else {
                    return
                }
                self.getCaseHistory(chatID: chatID)
            case .chatSessionPartyLeft(let partyID, let timestamp):
                guard let chatID = self.currentChatID else {
                    return
                }
                self.closeCase(chatID: chatID)
            default:()
            }
        }
    }
}

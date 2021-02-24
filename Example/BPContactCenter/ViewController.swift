//
//  ViewController.swift
//  BPContactCenter
//
//  Created by BrightPattern on 02/12/2021.
//  Copyright (c) 2021 BrightPattern. All rights reserved.
//

import UIKit
import BPContactCenter

enum ExampleAppError: Error {
    case deviceTokenNotSet
}

extension UIViewController {
    var appDelegate: AppDelegate {
        UIApplication.shared.delegate as! AppDelegate
    }
}

extension DefaultStringInterpolation {
    /// Allows to print optional values without a prefix.
    /// ```
    /// let x: Int? = 1
    /// print("\(x)") // > 1
    /// ```
    mutating func appendInterpolation<T>(_ optional: T?) {
        appendInterpolation(String(describing: optional))
    }
}

class ViewController: UIViewController {

    var contactCenterService: ContactCenterCommunicating {
        appDelegate.contactCenterService!
    }
    var deviceToken: String? {
        appDelegate.deviceToken
    }

    var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? ""
    }

    var useFirebase: Bool {
        appDelegate.useFirebase
    }

    var currentChatID: String?

    override func viewDidLoad() {
        super.viewDidLoad()

        appDelegate.deviceTokenDelegate = self
        appDelegate.contactCenterService?.delegate = self
    }
}

extension ViewController: DeviceTokenDelegateProtocol {
    func received(token _: String) {
        checkChatAvailability()
    }
}

extension ViewController {
    private func checkChatAvailability() {
        contactCenterService.checkAvailability { [weak self] serviceAvailabilityResult in
            DispatchQueue.main.async {
                switch serviceAvailabilityResult {
                case .success(let serviceAvailability):
                    print("Chat is \(serviceAvailability.chat)")
                    if serviceAvailability.chat == .available {
                        self?.requestChat()
                    }
                case .failure(let error):
                    print("Failed to check availability: \(error)")
                }
            }
        }
    }
    private func requestChat() {
        contactCenterService.requestChat(phoneNumber: "12345", from: "54321", parameters: [:]) { [weak self] chatPropertiesResult in
            switch chatPropertiesResult {
            case .success(let chatProperties):
                print("Chat properties: \(chatProperties)")
                DispatchQueue.main.async {
                    self?.getChatHistory(chatID: chatProperties.chatID)
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
                }
            case .failure(let error):
                print("\(error)")
            }
        }
    }

    private func getChatHistory(chatID: String) {
        contactCenterService.getChatHistory(chatID: chatID) { [weak self] eventsResult in
            switch eventsResult {
            case .success(let events):
                print("Received chat history")
                DispatchQueue.main.async {
                    self?.currentChatID = chatID
                    self?.processSessionEvents(chatID: chatID, events: events)
                }
            case .failure(let error):
                print("Failed to getChatHistory: \(error)")
            }
        }
    }

    private func endChatSession(chatID: String) {
        self.disconnectChat(chatID: chatID)
        self.endChat(chatID: chatID)
    }

    private func subscribeForNotifications(chatID: String, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let deviceToken = deviceToken else {
            print("Device token is not set")
            completion(.failure(ExampleAppError.deviceTokenNotSet))
            return
        }

        if useFirebase {
            contactCenterService.subscribeForRemoteNotificationsFirebase(chatID: chatID,
                                                                         deviceToken: deviceToken,
                                                                         with: completion)
        } else {
            contactCenterService.subscribeForRemoteNotificationsAPNs(chatID: chatID,
                                                                     deviceToken: deviceToken,
                                                                     with: completion)
        }
    }

    private func sendChatMessage(chatID: String, message: String) {
        contactCenterService.sendChatMessage(chatID: chatID, message: "Hello") { chatMessageResult in
            switch chatMessageResult {
            case .success(let messageID):
                print("MessageID: \(messageID)")

            case .failure(let error):

                print("Failed to send chat message: \(error)")
            }
        }
    }

    private func chatMessageDelivered(chatID: String, messageID: String) {
        contactCenterService.chatMessageDelivered(chatID: chatID, messageID: messageID) { result in
            switch result {
            case .success(_):
                print("chatMessageDelivered confirmed")
            case .failure(let error):
                print("chatMessageDelivered error: \(error)")
            }
        }
    }

    private func chatMessageRead(chatID: String, messageID: String) {
        contactCenterService.chatMessageRead(chatID: chatID, messageID: messageID) { result in
            switch result {
            case .success(_):
                print("chatMessageRead confirmed")
            case .failure(let error):
                print("chatMessageRead error: \(error)")
            }
        }
    }

    private func disconnectChat(chatID: String) {
        contactCenterService.disconnectChat(chatID: chatID) { result in
            switch result {
            case .success(_):
                print("disconnectChat confirmed")
            case .failure(let error):
                print("disconnectChat error: \(error)")
            }
        }
    }

    private func endChat(chatID: String) {
        contactCenterService.endChat(chatID: chatID) { result in
            switch result {
            case .success(_):
                print("endChat confirmed")
            case .failure(let error):
                print("endChat error: \(error)")
            }
        }
    }

    private func processSessionEvents(chatID: String, events: [ContactCenterEvent]) {
        for e in events {
            switch e {
            case .chatSessionMessage(let messageID, let partyID, let message, let timestamp):
                print("\(timestamp): message: \(message) from party \(partyID)")
                self.chatMessageDelivered(chatID: chatID, messageID: messageID)
                self.chatMessageRead(chatID: chatID, messageID: messageID)
            case .chatSessionStatus(let state, let estimatedWaitTime):
                if state == .connected {
                    print("Connected to a chat: \(chatID)")
                } else {
                    print("Waiting in a queue: \(chatID) estimated wait time: \(estimatedWaitTime)")
                }
            default:()
            }
        }
    }
}

extension ViewController: ContactCenterEventsDelegating {
    func chatSessionEvents(result: Result<[ContactCenterEvent], Error>) {
        switch result {
        case .success(let events):
            print("Received events from delegate")
            guard let chatID = self.currentChatID else {
                print("ChatID is not set")
                return
            }
            DispatchQueue.main.async {
                self.processSessionEvents(chatID: chatID, events: events)
            }
        case .failure(let error):
            print("chatSessionEvents failed: \(error)")
        }
    }
}

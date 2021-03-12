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

        checkChatAvailability()
    }

    deinit {
    }

    func helpMePressed(problemDescription: String) {
        requestChat(problemDescription: problemDescription)
    }

    func pastConversationsPressed() {
        guard let chatID = currentChatID else {
            print("chatID is empty")
            return
        }
//        getChatHistory(chatID: chatID)
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
    private func requestChat(problemDescription: String) {
        isRequestInProgress = true
        service.contactCenterService.requestChat(phoneNumber: "12345",
                                                 from: "54321",
                                                 parameters:
                                                    ["email": "mobilecustomer@example.com",
                                                     "problem_description": problemDescription]) { [weak self] chatPropertiesResult in
            DispatchQueue.main.async {
                self?.isRequestInProgress = false
                switch chatPropertiesResult {
                case .success(let chatProperties):
                    print("Chat properties: \(chatProperties)")
                    self?.currentChatID = chatProperties.chatID
                    self?.delegate?.showChat()
                case .failure(let error):
                    print("\(error)")
                }
            }
        }
    }
}

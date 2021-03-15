//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

/// Implement this protocol in order to receive events from the server.
/// - Tag: ContactCenterEventsDelegating
public protocol ContactCenterEventsDelegating: class {
    /// Called when new events received from the server
    /// - Parameter result: Array of `ContactCenterEvent` events
    func chatSessionEvents(result: Result<[ContactCenterEvent], Error>)
}

/// Provides chat and voice interactions.
/// This API can be used for development of rich contact applications, such as customer-facing mobile and
/// web applications for advanced chat, voice, and video communications with Bright Pattern Contact Center-based contact centers.
/// Sends `poll` request to the backend repeatedly for get new chat events. The chat events are received through `delegate`
public protocol ContactCenterCommunicating {
    // MARK: - Event delivery delegate
    /// Chat events delegate.
    /// If successful returns an array of chat events [ContactCenterEvent](x-source-tag://ContactCenterEvent)
    /// for the current session that came from the server or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: DelegateContactCenter
    var delegate: ContactCenterEventsDelegating? { get set }
    // MARK: - Requesting chat availability
    /// Checks the current status of configured services.
    /// - Parameters:
    ///   - completion: Current status [ContactCenterServiceAvailability](x-source-tag://ContactCenterServiceAvailability) of configured services if successful or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: checkAvailability
    func checkAvailability(with completion: @escaping ((Result<ContactCenterServiceAvailability, Error>) -> Void))
    // MARK: - Requesting a new chat session
    /// Request Chat initiates a chat session. It provides values of all or some of the expected parameters, and
    /// it may also contain the phone number of the mobile device. Note that if the mobile scenario entry is
    /// not configured for automatic callback, the agent can still use this number to call the mobile user
    /// manually, either upon the agent's own initiative or when asked to do this via a chat message from the mobile user.
    /// - Parameters:
    ///   - phoneNumber: phone number for callback, if necessary
    ///   - from: Propagated into scenario variable $(item.from). May be used to specify either the device owner’s name or phone number.
    ///   - parameters: Additional parameters.
    ///   - completion: Returns chat session properties that includes `chatID` in [ContactCenterChatSessionProperties](x-source-tag://ContactCenterChatSessionProperties) or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: requestChat
    func requestChat(phoneNumber: String, from: String, parameters: [String: String], with completion: @escaping ((Result<ContactCenterChatSessionProperties, Error>) -> Void))
    // MARK: - Chat session related methods
    /// Returns all client events and all server events for the current session. Multiple event objects can be returned; each event's timestamp attribute can be used to restore the correct message order.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - completion: Chat client and server events [ContactCenterEvent](x-source-tag://ContactCenterEvent) or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: getChatHistory
    func getChatHistory(chatID: String, with completion: @escaping ((Result<[ContactCenterEvent], Error>) -> Void))
    /// Returns all client events and all server events for all sessions related to the CRM case defined by the scenario
    /// which handles a current chat session. For each session, multiple event objects can be returned;
    /// each event's timestamp attribute can be used to restore the correct message order.
    /// Can be called after receiving `chatSessionCaseSet`; will return `chatSessionCaseNotSpecified` if
    /// server scenario did not specify the case.
    /// Note that the case could be specified later during the scenario execution; not necessarily immediately after session start.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - completion: Chat sessions with client and server events [ContactCenterChatSession](x-source-tag://ContactCenterEvent) or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: getCaseHistory
    func getCaseHistory(chatID: String, with completion: @escaping ((Result<[ContactCenterChatSession], Error>) -> Void))
    /// Send a chat message. Before message is sent the function generates a `messageID` which is
    /// returned in a completion. This `messageID` should be later used to match
    /// the `chatSessionMessageDelivered` and `chatSessionMessageRead` server events
    /// which notify the application that the message has been delivered to or read by an agent.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - message: Text of the message
    ///   - completion: Returns  `messageID` in the format chatId:messageNumber where messageNumber is
    /// ordinal number of the given message in the chat exchange or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: sendChatMessage
    func sendChatMessage(chatID: String, message: String, with completion: @escaping (Result<String, Error>) -> Void)
    /// Confirms that a chat message has been delivered to the application. This does not necessarily mean that a user had read the message.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - messageID: The message ID from the `chatSessionMessage` event
    ///   - completion: Returns ` .success` or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: chatMessageDelivered
    func chatMessageDelivered(chatID: String, messageID: String, with completion: @escaping (Result<Void, Error>) -> Void)
    /// Confirms that a chat message has been read by the user.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - messageID: The message ID from the `chatSessionMessage` event
    ///   - completion: Returns `.success` or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: chatMessageRead
    func chatMessageRead(chatID: String, messageID: String, with completion: @escaping (Result<Void, Error>) -> Void)
    /// Informs that a user started to type in a new chat message.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - completion: Returns `.success` or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: chatTyping
    func chatTyping(chatID: String, with completion: @escaping (Result<Void, Error>) -> Void)
    /// Informs that a user stopped to type in a new chat message.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - completion: Returns `.success` or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: chatNotTyping
    func chatNotTyping(chatID: String, with completion: @escaping (Result<Void, Error>) -> Void)
    /// Closes the CRM case defined by the scenario which handles a current chat session.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - completion: Returns `.success` or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: closeCase
    func closeCase(chatID: String, with completion: @escaping ((Result<Void, Error>) -> Void))
    /// Request to disconnect from a chat conversation but keep the session active. Server may continue communicating with the client.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - completion: Returns `.success` or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: disconnectChat
    func disconnectChat(chatID: String, with completion: @escaping (Result<Void, Error>) -> Void)
    /// Request to disconnect from a chat conversation and complete the session. Server will not continue communicating with the client once request is sent.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - completion: Returns `.success` or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: endChat
    func endChat(chatID: String, with completion: @escaping (Result<Void, Error>) -> Void)
    // MARK: - Remote push notifications
    /// Subscribes the specified chat session for push notifications from APNs server.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - deviceToken: Unique to both the device and the app. Which is received in `didRegisterForRemoteNotificationsWithDeviceToken`
    ///   - completion: Returns `.success` or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: subscribeForRemoteNotificationsAPNs
    func subscribeForRemoteNotificationsAPNs(chatID: String, deviceToken: String, with completion: @escaping (Result<Void, Error>) -> Void)
    /// Subscribes the specified chat session for push notifications from APNs server when using Firebase service.
    /// Firebase gives one more layer of flexibility to have event more granular control of notifications that are sent to the users devices.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - deviceToken: Unique to both the device and the app. Which is received in `didReceiveRegistrationToken`
   ///   - completion: Returns `.success` or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    /// - Tag: subscribeForRemoteNotificationsFirebase
    func subscribeForRemoteNotificationsFirebase(chatID: String, deviceToken: String, with completion: @escaping (Result<Void, Error>) -> Void)
    /// Notify contact center library about new remote notification.
    /// - Parameters:
    ///   - userInfo: Contains a payload with a new event from a backend which is received in `didReceiveRemoteNotification` or `userNotificationCenter`
    /// - Tag: appDidReceiveMessage
    func appDidReceiveMessage(_ userInfo: [AnyHashable : Any])
}

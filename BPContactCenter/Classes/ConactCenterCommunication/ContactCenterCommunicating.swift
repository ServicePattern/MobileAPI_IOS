//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

/// Provides chat and voice interactions.
/// This API can be used for development of rich contact applications, such as customer-facing mobile and web applications for advanced chat, voice, and video communications with Bright Pattern Contact Center-based contact centers.
/// Sends "poll" request to the backend repeatedly for get new chat events. The chat events are received through ```delegate```
public protocol ContactCenterCommunicating {
    // MARK: - Initialization
    /// Base URL to make requests
    var baseURL: URL { get }
    /// Identifies your contact center.
    /// It corresponds to the domain name of your contact center that you see in the upper right corner of the Contact Center Administrator application after login.
    var tenantURL: URL { get }
    /// Unique identifier of the Messaging/Chat scenario entry that will be used to associate your application with a specific scenario
    var appID: String { get }
    /// Unique identifier of the client application. It is used to identify communication sessions of a particular instance of the mobile application (i.e., of a specific mobile device).
    /// It must be generated by the mobile application in the UUID format. If clientId is set to WebChat, HTTP cookies will be used for client identification.
    var clientID: String { get }
    // MARK: - Client events delegate
    /// Chat event delegate
    /// If successful returns an array of chat events [ContactCenterEvent](x-source-tag://ContactCenterEvent) for the current session that came from the server or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    var delegate: ((Result<[ContactCenterEvent], Error>) -> Void)? { get set }
    // MARK:- Chat
    /// Checks the current status of configured services
    /// - Parameters:
    ///   - completion: Current status [ContactCenterServiceAvailability](x-source-tag://ContactCenterServiceAvailability) of configured services if successful or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    func checkAvailability(with completion: @escaping ((Result<ContactCenterServiceAvailability, Error>) -> Void))
    /// Returns all client events and all server events for the current session. Multiple event objects can be returned; each event's timestamp attribute can be used to restore the correct message order.
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - completion: Chat client and server events [ContactCenterEvent](x-source-tag://ContactCenterEvent) or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    func getChatHistory(chatID: String, with completion: @escaping ((Result<[ContactCenterEvent], Error>) -> Void))
    /// Request Chat initiates a chat session. It provides values of all or some of the expected parameters, and it may also contain the phone number of the mobile device. Note that if the mobile scenario entry is not configured for automatic callback, the agent can still use this number to call the mobile user manually, either upon the agent's own initiative or when asked to do this via a chat message from the mobile user.
    /// - Parameters:
    ///   - phoneNumber: phone number for callback, if necessary
    ///   - from: Propagated into scenario variable $(item.from). May be used to specify either the device owner’s name or phone number.
    ///   - parameters: Additional parameters.
    ///   - completion: Returns chat session properties that includes ``chatID`` in [ContactCenterChatSessionProperties](x-source-tag://ContactCenterChatSessionProperties) or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    func requestChat(phoneNumber: String, from: String, parameters: [String: String], with completion: @escaping ((Result<ContactCenterChatSessionProperties, Error>) -> Void))
    /// Send a chat message. Before message is sent the function generates a ```messageID``` which is returned in a completion
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - message: Text of the message
    ///   - completion: Returns  ```messageID``` in the format chatId:messageNumber where messageNumber is ordinal number of the given message in the chat exchange or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    func sendChatMessage(chatID: String, message: String, completion: @escaping ((Result<String, Error>) -> Void))
    /// Confirms that a chat message has been delivered to the application
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - messageID: The message ID
    ///   - completion: Returns  true or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    func chatMessageDelivered(chatID: String, messageID: String, completion: @escaping ((Result<Void, Error>) -> Void))
    /// Confirms that a chat message has been read by the user
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - messageID: The message ID
    ///   - completion: Returns  true or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    func chatMessageRead(chatID: String, messageID: String, completion: @escaping ((Result<Void, Error>) -> Void))
    /// Request to disconnect chat conversation but keep the session active. Server may continue communicating with the client
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - completion: Returns  true or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    func disconnectChat(chatID: String, completion: @escaping ((Result<Void, Error>) -> Void))
    /// Request to disconnect chat conversation and complete the session. Server will not continue communicating with the client once request is sent
    /// - Parameters:
    ///   - chatID: The current chat ID
    ///   - completion: Returns  true or [ContactCenterError](x-source-tag://ContactCenterError) otherwise
    func endChat(chatID: String, completion: @escaping ((Result<Void, Error>) -> Void))
}

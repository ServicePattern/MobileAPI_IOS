//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

protocol HttpRequestBuilding: class {
    func httpGetRequest(with endpoint: URLProvider.Endpoint) throws -> URLRequest
}

public final class ContactCenterCommunicator: ContactCenterCommunicating {
    public let baseURL: URL
    public let tenantURL: URL
    public let appID: String
    public let clientID: String
    public weak var delegate: ContactCenterEventsDelegating? {
        get {
            pollRequestService.delegate
        }
        set {
            pollRequestService.delegate = newValue
        }
    }

    internal let networkService: NetworkServiceable
    private var defaultHttpHeaderFields: HttpHeaderFields
    private var defaultHttpRequestParameters: Encodable
    private var messageNumberValue: Int = 0
    private var messageNumber: Int {
        get {
            readerWriterQueue.sync {
                messageNumberValue
            }
        }
        set {
            readerWriterQueue.async(flags: .barrier) { [weak self] in
                self?.messageNumberValue = newValue
            }
        }
    }
    private let readerWriterQueue = DispatchQueue(label: "com.BPContactCenter.ContactCenterCommunicator.reader-writer", attributes: .concurrent)
    private var pollRequestService: PollRequestServiceable
    private var bundleIdentifier: String {
        guard let bundleIdentifier = Bundle.main.bundleIdentifier else {
            fatalError("Failed to get a bundle identitifer")
        }
        return bundleIdentifier
    }

    /// This method is not exposed to the consumer and it might be used to inject dependencies for unit testing
    init(baseURL: URL, tenantURL: URL, appID: String, clientID: String, networkService: NetworkServiceable, pollRequestService: PollRequestServiceable) {

        do {
            self.baseURL = try URLProvider.baseURL(basedOn: baseURL)
        } catch {
            fatalError("Failed to construct Base URL based on: \(baseURL)")
        }
        self.tenantURL = tenantURL
        self.appID = appID
        self.clientID = clientID
        self.networkService = networkService
        self.defaultHttpHeaderFields = HttpHeaderFields.defaultFields(appID: appID, clientID: clientID)
        self.defaultHttpRequestParameters = HttpRequestDefaultParameters(tenantUrl: tenantURL.absoluteString)
        self.pollRequestService = pollRequestService
    }

    // MARK:- Convenience
    public convenience init(baseURL: URL, tenantURL: URL, appID: String, clientID: String, pollInterval: Double = 1.0) {
        let networkService = NetworkService(encoder: JSONCoder.encoder(),
                                            decoder: JSONCoder.decoder())
        let pollRequestService = PollRequestService(networkService: networkService, pollInterval: pollInterval)
        self.init(baseURL: baseURL,
                  tenantURL: tenantURL,
                  appID: appID,
                  clientID: clientID,
                  networkService: networkService,
                  pollRequestService: pollRequestService)

        pollRequestService.httpRequestBuilder = self
    }

    // MARK: - Public methods
    public func checkAvailability(with completion: @escaping ((Result<ContactCenterServiceAvailability, Error>) -> Void)) {
        do {
            networkService.dataTask(using: try httpGetRequest(with: .checkAvailability), with: completion)
        } catch {
            log.error("Failed to checkAvailability: \(error)")
            completion(.failure(error))
        }
    }

    public func getChatHistory(chatID: String, with completion: @escaping ((Result<[ContactCenterEvent], Error>) -> Void)) {
        do {
            let urlRequest = try httpGetRequest(with: .getChatHistory(chatID: chatID))
            networkService.dataTask(using: urlRequest) { (result: Result<ContactCenterEventsContainerDto, Error>) -> Void in
                switch result {
                case .success(let eventsContainer):
                    completion(.success(eventsContainer.events))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            log.error("Failed to getChatHistory: \(error) chatID: \(chatID)")
            completion(.failure(error))
        }
    }

    public func requestChat(phoneNumber: String, from: String, parameters: [String: String], with completion: @escaping ((Result<ContactCenterChatSessionProperties, Error>) -> Void)) {
        do {
            let requestChatBodyParameters = RequestChatParameters(phoneNumber: phoneNumber, from: from, parameters: parameters)
            let urlRequest = try httpPostRequest(with: .requestChat, body: requestChatBodyParameters)
            networkService.dataTask(using: urlRequest) { [weak self] (result: Result<ChatSessionPropertiesDto, Error>) -> Void in
                switch result {
                case .success(let chatSessionProperties):
                    // Save a chat ID which will initiate polling for chat events
                    self?.pollRequestService.currentChatID = chatSessionProperties.chatID
                    // Since it is a new chat session reset a message number counter
                    self?.messageNumber = 0
                    completion(.success(chatSessionProperties.toModel()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            log.error("Failed to requestChat: \(error)")
            completion(.failure(error))
        }
    }

    private func messageIdentifier() -> String {
        "\(UUID()):\(messageNumber)"
    }

    public func sendChatMessage(chatID: String, message: String, with completion: @escaping (Result<String, Error>) -> Void) {
        let messageID = messageIdentifier()
        do {
            let urlRequest = try httpSendEventsPostRequest(chatID: chatID,
                                                           events: [.chatSessionMessage(messageID: messageID,
                                                                                        partyID: nil,
                                                                                        message: message,
                                                                                        timestamp: nil)])
            networkService.dataTask(using: urlRequest) { [weak self] (response: NetworkDataResponse) in
                switch response {
                case .success(_):
                    // Change the internal state on the main thread which used at other places
                    self?.messageNumber += 1
                    completion(.success(messageID))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            log.error("Failed to sendChatMessage: \(error)")
            completion(.failure(error))
        }
    }

    public func chatMessageDelivered(chatID: String, messageID: String, with completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let urlRequest = try httpSendEventsPostRequest(chatID: chatID,
                                                           events: [.chatSessionMessageDelivered(messageID: messageID,
                                                                                                 partyID: nil,
                                                                                                 timestamp: nil)])
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to chatMessageDelivered: \(error)")
            completion(.failure(error))
        }
    }

    public func chatMessageRead(chatID: String, messageID: String, with completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let urlRequest = try httpSendEventsPostRequest(chatID: chatID,
                                                           events: [.chatSessionMessageRead(messageID: messageID,
                                                                                            partyID: nil,
                                                                                            timestamp: nil)])
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to chatMessageRead: \(error)")
            completion(.failure(error))
        }
    }

    public func disconnectChat(chatID: String, with completion: @escaping ((Result<Void, Error>) -> Void)) {
        do {
            let urlRequest = try httpSendEventsPostRequest(chatID: chatID,
                                                           events: [.chatSessionDisconnect])
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to disconnectChat: \(error)")
            completion(.failure(error))
        }
    }

    public func endChat(chatID: String, with completion: @escaping ((Result<Void, Error>) -> Void)) {
        do {
            let urlRequest = try httpSendEventsPostRequest(chatID: chatID,
                                                           events: [.chatSessionEnd])
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to endChat: \(error)")
            completion(.failure(error))
        }
    }

    // MARK: - Remote notifications
    public func subscribeForRemoteNotificationsAPNs(chatID: String, deviceToken: Data, with completion: @escaping (Result<Void, Error>) -> Void) {
        let bodyParameters = SubscribeForAPNsNotificationsParameters(deviceToken: deviceToken, appBundleID: bundleIdentifier)
        do {
            let urlRequest = try httpPostRequest(with: .subscribeForNotifications(chatID: chatID), body: bodyParameters)
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to subscribePushAPNs: \(error)")
            completion(.failure(error))
        }
    }

    public func subscribeForRemoteNotificationsFirebase(chatID: String, deviceToken: Data, with completion: @escaping (Result<Void, Error>) -> Void) {
        let bodyParameters = SubscribeForFirebaseNotificationsParameters(deviceToken: deviceToken)
        do {
            let urlRequest = try httpPostRequest(with: .subscribeForNotifications(chatID: chatID), body: bodyParameters)
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to subscribePushAPNs: \(error)")
            completion(.failure(error))
        }
    }

    public func appDidReceiveMessage(_ userInfo: [AnyHashable : Any]) {
        // Parse APNs message payload
    }
}

// MARK: - HTTP request helper factory functions
extension ContactCenterCommunicator: HttpRequestBuilding {
    internal func httpGetRequest(with endpoint: URLProvider.Endpoint) throws -> URLRequest {
        guard let urlRequest = try networkService.createRequest(method: .get,
                                                                baseURL: baseURL,
                                                                endpoint: endpoint,
                                                                headerFields: defaultHttpHeaderFields,
                                                                parameters: defaultHttpRequestParameters) else {
            log.error("Failed to create URL request")

            throw ContactCenterError.failedToCreateURLRequest
        }

        return urlRequest
    }

    private func httpPostRequest(with endpoint: URLProvider.Endpoint, body: Encodable) throws -> URLRequest {
        guard let urlRequest = try networkService.createRequest(method: .post,
                                                                baseURL: baseURL,
                                                                endpoint: endpoint,
                                                                headerFields: defaultHttpHeaderFields,
                                                                parameters: defaultHttpRequestParameters,
                                                                body: body) else {
            log.error("Failed to create URL request")

            throw ContactCenterError.failedToCreateURLRequest
        }
        return urlRequest
    }

    private func httpSendEventsPostRequest(chatID: String, events: [ContactCenterEvent]) throws -> URLRequest {
        let eventsContainer = ContactCenterEventsContainerDto(events: events)
        do {
            return try httpPostRequest(with: .sendEvents(chatID: chatID), body: eventsContainer)
        } catch {
            log.error("Failed to sendChatMessage: \(error)")
            throw error
        }
    }
}

// MARK: - Decoding
extension ContactCenterCommunicator {
    enum JSONCoder {
        /// Custom decoding for special types that comes from the backend like: UNIX epoch time
        static func decoder() -> JSONDecoder {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .custom { decoder in
                let container = try decoder.singleValueContainer()
                let dateString = try container.decode(String.self)
                guard let sec = TimeInterval(dateString) else {

                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected String containing Int")
                }

                return Date(timeIntervalSince1970: sec)
            }

            return decoder
        }

        static func encoder() -> JSONEncoder {
            JSONEncoder()
        }
    }
}

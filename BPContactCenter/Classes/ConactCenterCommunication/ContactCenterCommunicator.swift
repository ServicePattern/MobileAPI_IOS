//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

public class ContactCenterCommunicator: ContactCenterCommunicating {
    public let baseURL: URL
    public let tenantURL: URL
    public let appID: String
    public let clientID: String
    public var delegate: ((Result<[ContactCenterEvent], Error>) -> Void)?

    internal let networkService: NetworkService
    private var defaultHttpHeaderFields: HttpHeaderFields
    private var defaultHttpRequestParameters: Encodable
    internal var pollTimer: Timer?
    internal let pollInterval: Double
    internal static let timerTolerance = 0.2
    private var messageNumber = 0
    internal var currentChatID: String? {
        didSet {
            startPollingIfNeeded()
        }
    }

    internal var isForeground: Bool = false {
        didSet {
            startPollingIfNeeded()
        }
    }
    internal var pollRequestDataTask: URLSessionDataTask?

    /// This method is not exposed to the consumer and it might be used to inject dependencies for unit testing
    init(baseURL: URL, tenantURL: URL, appID: String, clientID: String, networkService: NetworkService, pollInterval: Double = 1.0) {

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
        self.pollInterval = pollInterval

        subscribeToNotifications()
    }

    // MARK:- Convenience
    public convenience init(baseURL: URL, tenantURL: URL, appID: String, clientID: String, pollInterval: Double = 1.0) {
        let networkService = NetworkService(encoder: JSONCoder.encoder(),
                                            decoder: JSONCoder.decoder())
        self.init(baseURL: baseURL,
                  tenantURL: tenantURL,
                  appID: appID,
                  clientID: clientID,
                  networkService: networkService,
                  pollInterval: pollInterval)
    }

    // MARK:- Deinitialization part
    deinit {
        NotificationCenter.default.removeObserver(self)
        // Use synchronous method to make sure the self point is still alive
        DispatchQueue.main.sync { [unowned self] in
            self.invalidatePollTimer()
        }
    }

    // MARK: - HTTP request helper factory functions
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

    private func httpSendEventsPostRequest(chatID: String, events: [ContactCenterEvent]) throws -> URLRequest {
        let eventsContainer = ContactCenterEventsContainerDto(events: events)
        do {
            guard let urlRequest = try networkService.createRequest(method: .post,
                                                                    baseURL: baseURL,
                                                                    endpoint: .sendEvents(chatID: chatID),
                                                                    headerFields: defaultHttpHeaderFields,
                                                                    parameters: defaultHttpRequestParameters) else {
                log.error("Failed to create URL request")

                throw ContactCenterError.failedToCreateURLRequest
            }
            return try networkService.encode(from: eventsContainer, request: urlRequest)
        } catch {
            log.error("Failed to sendChatMessage: \(error)")
            throw error
        }
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
            guard let urlRequest = try networkService.createRequest(method: .post,
                                                                    baseURL: baseURL,
                                                                    endpoint: .requestChat,
                                                                    headerFields: defaultHttpHeaderFields,
                                                                    parameters: defaultHttpRequestParameters,
                                                                    body: requestChatBodyParameters) else {
                log.error("Failed to create URL request")

                throw ContactCenterError.failedToCreateURLRequest
            }
            networkService.dataTask(using: urlRequest) { [weak self] (result: Result<ChatSessionPropertiesDto, Error>) -> Void in
                switch result {
                case .success(let chatSessionProperties):
                    // Change the internal state on the main thread which used at other places
                    DispatchQueue.main.async {
                        // Save a chat ID which will initiate polling for chat events
                        self?.currentChatID = chatSessionProperties.chatID
                        // Since it is a new chat session reset a message number counter
                        self?.messageNumber = 0
                    }
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
                    DispatchQueue.main.async {
                        self?.messageNumber += 1
                    }
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
}

// MARK:- Background/foreground notifications subscribtion
extension ContactCenterCommunicator {
    private func subscribeToNotifications() {
        // Restore a poll action when the app is going to go the foreground
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willEnterForeground),
                                               name: .UIApplicationWillEnterForeground,
                                               object: nil)
        // Pause a poll action after the app goes to the background
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didEnterBackground),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
    }

    @objc private func willEnterForeground() {
        DispatchQueue.main.async { [weak self] in
            self?.isForeground = true
        }
    }

    @objc private func didEnterBackground() {
        DispatchQueue.main.async { [weak self] in
            self?.isForeground = false
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

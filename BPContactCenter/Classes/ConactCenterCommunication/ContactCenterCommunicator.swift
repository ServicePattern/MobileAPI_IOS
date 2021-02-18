//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

public class ContactCenterCommunicator: ContactCenterCommunicating {
    public let baseURL: URL
    public let tenantURL: URL
    public let appID: String
    public let clientID: String
    public var delegate: ((Result<[ContactCenterEvent], Error>) -> Void)?

    private let networkService: NetworkService
    private var defaultHttpHeaderFields: HttpHeaderFields
    private var defaultHttpRequestParameters: Encodable
    private var pollTimer: Timer?
    private let pollInterval: Double
    private static let timerTolerance = 0.2
    private var messageNumber = 0

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

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func httpGetRequest(with endpoint: URLProvider.Endpoint) throws -> URLRequest {
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
            networkService.dataTask(using: urlRequest) { (result: Result<ChatSessionPropertiesDto, Error>) -> Void in
                switch result {
                case .success(let chatSessionProperties):
                    //  Start polling for chat events
                    self.startTimer(chatId: chatSessionProperties.chatID)
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
}

// MARK: - Poll action
extension ContactCenterCommunicator {
    @objc private func pollAction(chatId: String) {
        do {
            guard let urlRequest = try networkService.createRequest(method: .get,
                                                                    baseURL: baseURL,
                                                                    endpoint: .getNewChatEvents(chatID: chatId),
                                                                    headerFields: defaultHttpHeaderFields,
                                                                    parameters: defaultHttpRequestParameters) else {
                log.error("Failed to create URL request")

                throw ContactCenterError.failedToCreateURLRequest
            }
            networkService.dataTask(using: urlRequest) { (result: Result<ContactCenterEventsContainerDto, Error>) -> Void in
                switch result {
                case .success(let eventsContainer):
                    //  Report received server events to the application
                    self.delegate?(.success(eventsContainer.events))
                    
                    //  Stop polling timer if session has ended; otherwise need to start new getNewChatEvents request
                    for e in eventsContainer.events {
                        switch e {
                        case .chatSessionEnded:
                            self.stopTimer()
                        default:
                            break
                        }
                    }
                default:
                    break
                }
            }
        } catch {
        }
    }

    private func subscribeToNotifications() {
        // Restore a poll action when the app is going to go the foreground
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(startTimer),
                                               name: .UIApplicationWillEnterForeground,
                                               object: nil)
        // Pause a poll action after the app goes to the background
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(stopTimer),
                                               name: .UIApplicationDidEnterBackground,
                                               object: nil)
    }

    private func setupTimer(chatId: String, pollInterval: Double) {
        guard pollTimer == nil else {
            log.debug("Timer already set")
            return
        }
        let timer =  Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.pollAction(chatId: chatId)
        }
        // Allow a timer to run when a UI thread block execution
        RunLoop.current.add(timer, forMode: .commonModes)
        // Gives OS a chance to safe a battery life
        timer.tolerance = Self.timerTolerance

        pollTimer = timer
    }

    private func invalidateTimer() {
        self.pollTimer?.invalidate()
        self.pollTimer = nil
    }

    @objc private func startTimer(chatId: String) {
        // Make sure that a timer is scheduled and invalidated on the same thread
        DispatchQueue.main.async { [unowned self] in
            setupTimer(chatId: chatId, pollInterval: self.pollInterval)
        }
    }

    @objc private func stopTimer() {
        // Make sure that a timer is scheduled and invalidated on the same thread
        DispatchQueue.main.async { [unowned self] in
            self.invalidateTimer()
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

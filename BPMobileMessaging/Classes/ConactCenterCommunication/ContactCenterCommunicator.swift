//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

protocol HttpRequestBuilding: AnyObject {
    func httpGetRequest(with endpoint: URLProvider.Endpoint) throws -> URLRequest
}

/// Impementation of the `ContactCenterCommunicating` protocol.
public final class ContactCenterCommunicator: ContactCenterCommunicating {
    internal let baseURL: URL
    internal let baseFileURL: URL
    internal let tenantURL: URL
    internal let appID: String
    internal let clientID: String
    
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
    private let readerWriterQueue = DispatchQueue(label: "com.BPMobileMessaging.ContactCenterCommunicator.reader-writer", attributes: .concurrent)
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
        do {
            self.baseFileURL = try URLProvider.baseFileURL(basedOn: baseURL)
        } catch {
            fatalError("Failed to construct Base File URL based on: \(baseURL)")
        }
        self.tenantURL = tenantURL
        self.appID = appID
        self.clientID = clientID
        self.networkService = networkService
        self.defaultHttpHeaderFields = HttpHeaderFields.defaultFields(appID: appID, clientID: clientID)
        self.defaultHttpRequestParameters = HttpRequestDefaultParameters(tenantUrl: tenantURL.absoluteString)
        self.pollRequestService = pollRequestService
    }

    // MARK: - Event delivery delegate
    public weak var delegate: ContactCenterEventsDelegating? {
        get {
            pollRequestService.delegate
        }
        set {
            pollRequestService.delegate = newValue
        }
    }

    // MARK: - Convenience
    /// Creates an instance of the API class.
    /// - Parameters:
    ///   - baseURL: HTTP(S) URL to your server. Usually it matches the `tenantUrl` but could be different in development or staging environments. The http(s):// protocol part is required.
    ///   - tenantURL: Identifies your contact center. It corresponds to the domain name of your contact center
    /// that you see in the upper right corner of the Contact Center Administrator application after login.
    ///   - appID: Unique identifier of the Messaging/Chat scenario entry that will be used to associate your application with a specific scenario.
    ///   - clientID: Unique identifier of the client application. It is used to identify communication sessions of
    /// a particular instance of the mobile application (i.e., of a specific mobile device). It must be generated by
    /// the mobile application preferably in the UUID format, saved in the local storage and used for all subsequent application sessions on that device.
    /// - Tag: init
    public convenience init(baseURL: URL, tenantURL: URL, appID: String, clientID: String) {
        let networkService = NetworkService(encoder: JSONCoder.encoder(),
                                            decoder: JSONCoder.decoder())
        let pollRequestService = PollRequestService(networkService: networkService)
        self.init(baseURL: baseURL,
                  tenantURL: tenantURL,
                  appID: appID,
                  clientID: clientID,
                  networkService: networkService,
                  pollRequestService: pollRequestService)

        pollRequestService.httpRequestBuilder = self
    }
    
    // MARK: - Requesting server version
    public func getVersion(with completion: @escaping ((Result<ContactCenterVersion, Error>) -> Void)) {
        do {
            networkService.dataTask(using: try httpGetRequest(with: .getVersion)) { (result: Result<ContactCenterVersionDto, Error>) -> Void in
                switch result {
                case .success(let version):
                    completion(.success(version.toModel()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            log.error("Failed to getVersion: \(error)")
            completion(.failure(error))
        }
    }
    
    // MARK: - Full URL to the chat file
    public func getFileUrl(fileID: String) throws -> URL {
        var urlComponents = URLComponents(url: self.baseFileURL, resolvingAgainstBaseURL: true)
        let basePath = urlComponents?.path ?? ""
        urlComponents?.path = basePath.appendingPathComponents(fileID)

        guard let completeURL = urlComponents?.url else {
            throw ContactCenterError.failedToBuildBaseURL
        }
        return completeURL
    }

    // MARK: - Requesting chat availability
    public func checkAvailability(with completion: @escaping ((Result<ContactCenterServiceAvailability, Error>) -> Void)) {
        do {
            networkService.dataTask(using: try httpGetRequest(with: .checkAvailability)) { (result: Result<ContactCenterServiceAvailabilityDto, Error>) -> Void in
                switch result {
                case .success(let chatAvailability):
                    completion(.success(chatAvailability.toModel()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            log.error("Failed to checkAvailability: \(error)")
            completion(.failure(error))
        }
    }

    private func uploadData(fileName: String, contentType: HttpHeaderContentType, body: Data, with completion: @escaping (Result<ContactCenterUploadedFileInfo, Error>) -> Void) {
        do {
            let boundary = UUID().uuidString
            
            let headers = defaultHttpHeaderFields.merging(HttpHeaderFields(fields: [.contentType : .multipart(boundary: boundary)]), true)
            let httpBodyEncoded = body.httpBodyEncoded(boundary: boundary,
                                                       fileName: fileName,
                                                       contentType: contentType)
            guard let urlRequest = try networkService.createRequest(method: .post,
                                                                    baseURL: baseURL,
                                                                    endpoint: .uploadFile,
                                                                    headerFields: headers,
                                                                    parameters: defaultHttpRequestParameters,
                                                                    data: httpBodyEncoded) else {
                throw ContactCenterError.failedToCreateURLRequest
            }

            networkService.dataTask(using: urlRequest) { (result: Result<UploadFileResultDto, Error>) -> Void in
                switch result {
                case .success(let fileInfo):
                    completion(.success(fileInfo.toModel()))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            log.error("Failed to uploadFile: \(error)")
            completion(.failure(error))
        }
    }
    
    // MARK: - Uploading an image
    public func uploadFile(fileName: String, image: UIImage, with completion: @escaping (Result<ContactCenterUploadedFileInfo, Error>) -> Void) {
        guard let encodedImage = image.jpegData(compressionQuality: 1.0) else {
            completion(.failure(ContactCenterError.failedToEncodeImage))
            return
        }
        uploadData(fileName: fileName,
                   contentType: .image,
                   body: encodedImage,
                   with:completion)
    }

    // MARK: - Requesting a new chat session
    public func requestChat(phoneNumber: String?, from: String, parameters: [String: String], with completion: @escaping ((Result<ContactCenterChatSessionProperties, Error>) -> Void)) {
        do {
            let requestChatBodyParameters = RequestChatParameters(phoneNumber: phoneNumber, from: from, parameters: parameters)
            let urlRequest = try httpPostRequest(with: .requestChat, body: requestChatBodyParameters)
            networkService.dataTask(using: urlRequest) { [weak self] (result: Result<ChatSessionPropertiesDto, Error>) -> Void in
                switch result {
                case .success(let chatSessionProperties):
                    // Save a chat ID which will initiate polling for chat events
                    self?.pollRequestService.addChatID(chatSessionProperties.chatID)
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

    // MARK: - Chat session related methods
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

    public func getCaseHistory(chatID: String, with completion: @escaping ((Result<[ContactCenterChatSession], Error>) -> Void)) {
        do {
            let urlRequest = try httpGetRequest(with: .getCaseHistory(chatID: chatID))
            networkService.dataTask(using: urlRequest) { (result: Result<ChatSessionCaseHistoryDto, Error>) -> Void in
                switch result {
                case .success(let sessionsContainer):
                    completion(.success(sessionsContainer.sessions))
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        } catch {
            log.error("Failed to getChatHistory: \(error) chatID: \(chatID)")
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
    
    public func sendChatFile(chatID: String, fileID: String, fileName: String, fileType: String, with completion: @escaping (Result<String, Error>) -> Void) {
        let messageID = messageIdentifier()
        do {
            let urlRequest = try httpSendEventsPostRequest(chatID: chatID,
                                                           events: [.chatSessionFile(messageID: messageID, partyID: nil, fileID: fileID, fileName: fileName, fileType: fileType, timestamp: nil)])
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

    public func chatTyping(chatID: String, with completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let urlRequest = try httpSendEventsPostRequest(chatID: chatID,
                                                           events: [.chatSessionTyping(partyID: nil,
                                                                                            timestamp: nil)])
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to chatTyping: \(error)")
            completion(.failure(error))
        }
    }

    public func chatNotTyping(chatID: String, with completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            let urlRequest = try httpSendEventsPostRequest(chatID: chatID,
                                                           events: [.chatSessionNotTyping(partyID: nil,
                                                                                            timestamp: nil)])
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to chatNotTyping: \(error)")
            completion(.failure(error))
        }
    }

    public func closeCase(chatID: String, with completion: @escaping ((Result<Void, Error>) -> Void)) {
        do {
            let urlRequest = try httpPostRequest(with: .closeCase(chatID: chatID), body: nil)
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to getChatHistory: \(error) chatID: \(chatID)")
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
    public func subscribeForRemoteNotificationsAPNs(chatID: String, deviceToken: String, with completion: @escaping (Result<Void, Error>) -> Void) {
        let bodyParameters = SubscribeForAPNsNotificationsParameters(deviceToken: deviceToken, appBundleID: bundleIdentifier)
        do {
            let urlRequest = try httpPostRequest(with: .subscribeForNotifications(chatID: chatID), body: bodyParameters)
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to subscribePushAPNs: \(error)")
            completion(.failure(error))
        }
    }

    public func subscribeForRemoteNotificationsFirebase(chatID: String, deviceToken: String, with completion: @escaping (Result<Void, Error>) -> Void) {
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
        guard let chatID = userInfo["chatID"] as? String else {
            log.error("Failed to get chatID from remote message")
            return
        }
        pollRequestService.addChatID(chatID)
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

    private func httpPostRequest(with endpoint: URLProvider.Endpoint, body: Encodable?) throws -> URLRequest {
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

//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

public class ContactCenterCommunicator: ContactCenterCommunicating {
    public let baseURL: URL
    public let tenantURL: URL
    public let appID: String
    public let clientID: String
    public var delegate: ((Result<[ContactCenterClientEvent], Error>) -> Void)?

    private let networkService: NetworkService
    private var defaultHttpHeaderFields: HttpHeaderFields
    private var defaultHttpRequestParameters: Encodable
    private var pollTimer: Timer?
    private let pollInterval: Double
    private static let timerTolerance = 0.2

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
        startTimer()
    }

    // MARK:- Convenience
    public convenience init(baseURL: URL, tenantURL: URL, appID: String, clientID: String, pollInterval: Double = 1.0) {
        let networkService = NetworkService(decoder: JSONCoder.decoder())
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

    // MARK: - Public methods
    public func checkAvailability(with completion: @escaping ((Result<ContactCenterServiceAvailability, Error>) -> Void)) {
        do {

            guard let urlRequest = try networkService.createRequest(method: .get,
                                                                    baseURL: baseURL,
                                                                    endpoint: .checkAvailability,
                                                                    headerFields: defaultHttpHeaderFields,
                                                                    parameters: defaultHttpRequestParameters) else {
                log.error("Failed to create URL request")
                completion(.failure(ContactCenterError.failedToCreateURLRequest))

                return
            }
            networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to checkAvailability: \(error)")
            completion(.failure(error))
        }
    }

    public func getChatHistory(with completion: @escaping ((Result<ContactCenterEventContainer, Error>) -> Void)) {
        do {

            guard let urlRequest = try networkService.createRequest(method: .get,
                                                                    baseURL: baseURL,
                                                                    endpoint: .checkAvailability,
                                                                    headerFields: defaultHttpHeaderFields,
                                                                    parameters: defaultHttpRequestParameters) else {
                log.error("Failed to create URL request")
                completion(.failure(ContactCenterError.failedToCreateURLRequest))

                return
            }
            //networkService.dataTask(using: urlRequest, with: completion)
        } catch {
            log.error("Failed to checkAvailability: \(error)")
            completion(.failure(error))
        }
    }
}


// MARK: - Poll action
extension ContactCenterCommunicator {
    @objc private func pollAction() {
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

    private func setupTimer(pollInterval: Double) {
        guard pollTimer == nil else {
            log.debug("Timer already set")
            return
        }
        let timer =  Timer(timeInterval: pollInterval, repeats: true) { [weak self] _ in
            self?.pollAction()
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

    @objc private func startTimer() {
        // Make sure that a timer is scheduled and invalidated on the same thread
        DispatchQueue.main.async { [unowned self] in
            setupTimer(pollInterval: self.pollInterval)
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
                guard let ms = TimeInterval(dateString) else {

                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Expected String containing Int")
                }

                return Date(timeIntervalSince1970: ms / 1000)
            }

            return decoder
        }
    }
}

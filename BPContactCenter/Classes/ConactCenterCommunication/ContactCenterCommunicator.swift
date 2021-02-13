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


    /// This method is not exposed to the consumer and it might be used to inject dependencies for unit testing
    init(baseURL: URL, tenantURL: URL, appID: String, clientID: String, networkService: NetworkService) {
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
    }

    // MARK:- Convenience
    public convenience init(baseURL: URL, tenantURL: URL, appID: String, clientID: String) {
        let networkService = NetworkService()
        self.init(baseURL: baseURL,
                  tenantURL: tenantURL,
                  appID: appID,
                  clientID: clientID,
                  networkService: networkService)
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
}

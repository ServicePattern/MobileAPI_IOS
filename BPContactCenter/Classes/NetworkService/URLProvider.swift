//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

class URLProvider {
    static let apiVersion = "v1"
    static let basePath = "clientweb/api"

    struct HTTPRequestDefaultParameters: Codable {
        let tenantURL: String
    }

    static func baseURL(basedOn baseURL: URL) throws -> URL {
        let baseAndVersionPath = (basePath as NSString).appendingPathComponent(apiVersion)
        var urlComponents = URLComponents(string: baseURL.absoluteString)
        urlComponents?.scheme = "https"
        urlComponents?.port = 443

        guard let completeBaseURL = URL(string: baseAndVersionPath, relativeTo:  urlComponents?.url) else {

            throw ContactCenterError.failedToBuildBaseURL
        }

        return completeBaseURL
    }

    enum Endpoint {
        case checkAvailability
        case getChatHistory(chatID: String)
        case getNewChatEvents(chatID: String)
        case requestChat
        case sendEvents(chatID: String)

        var endpointPathString: String {
            switch self {
            case .checkAvailability:
                return "availability"
            case .getChatHistory(let chatID):
                return "chats/\(chatID)/history"
            case .getNewChatEvents(let chatID):
                return "chats/\(chatID)/events"
            case .requestChat:
                return "chats"
            case .sendEvents(let chatID):
                return "chats/\(chatID)/events"
            }
        }
    }
}

extension String {
    func appendingPathComponents(_ pathComponent: String) -> String {
        guard pathComponent.count > 0 else {
            return self
        }
        let path = (self as NSString).appendingPathComponent(pathComponent)
        return path.first == "/" ? path : "/\(path)"
    }
}

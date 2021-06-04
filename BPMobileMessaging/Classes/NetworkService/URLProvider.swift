//
// Copyright © 2021 BrightPattern. All rights reserved.
    

import Foundation

class URLProvider {
    static let apiVersion = "v2"
    static let basePath = "clientweb/api"
    static let filePath = "clientweb/file"

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

    static func baseFileURL(basedOn baseURL: URL) throws -> URL {
        var urlComponents = URLComponents(string: baseURL.absoluteString)
        urlComponents?.scheme = "https"
        urlComponents?.port = 443

        guard let completeBaseURL = URL(string: filePath, relativeTo:  urlComponents?.url) else {

            throw ContactCenterError.failedToBuildBaseURL
        }

        return completeBaseURL
    }

    enum Endpoint {
        case getVersion
        case checkAvailability
        case getChatHistory(chatID: String)
        case getCaseHistory(chatID: String)
        case getNewChatEvents(chatID: String)
        case requestChat
        case sendEvents(chatID: String)
        case subscribeForNotifications(chatID: String)
        case closeCase(chatID: String)
        case getFile(chatID: String, fileID: String)
        case uploadFile

        var endpointPathString: String {
            switch self {
            case .getVersion:
                return "version"
            case .checkAvailability:
                return "availability"
            case .getChatHistory(let chatID):
                return "chats/\(chatID)/history"
            case .getCaseHistory(let chatID):
                return "chats/\(chatID)/casehistory"
            case .getNewChatEvents(let chatID):
                return "chats/\(chatID)/events"
            case .requestChat:
                return "chats"
            case .sendEvents(let chatID):
                return "chats/\(chatID)/events"
            case .subscribeForNotifications(let chatID):
                return "chats/\(chatID)/notifications"
            case .closeCase(let chatID):
                return "chats/\(chatID)/closecase"
            case .getFile(let chatID, let fileID):
                return "chats/\(chatID)/files/\(fileID)"
            case .uploadFile:
                return "files"
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

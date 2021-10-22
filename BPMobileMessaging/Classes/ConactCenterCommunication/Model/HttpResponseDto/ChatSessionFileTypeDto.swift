//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

enum ChatSessionFileTypeDto: String, Codable {
    case image
    case attachment
}

extension ChatSessionFileTypeDto {
    func toModel() -> ChatSessionFileType {
        switch self {
        case .image:
            return .image
        case .attachment:
            return .attachment
        }
    }
}

extension ChatSessionFileType {
    func toDto() -> ChatSessionFileTypeDto {
        switch self {
        case .image:
            return .image
        case .attachment:
            return .attachment
        }
    }
}

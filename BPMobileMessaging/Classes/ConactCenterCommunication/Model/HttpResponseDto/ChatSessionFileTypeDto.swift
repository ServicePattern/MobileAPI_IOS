//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

/// Represents chat file type
/// - Tag: ChatSessionFileTypeDto
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

/// Represents chat file type
/// - Tag: ChatSessionFileType
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

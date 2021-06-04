//
//  UploadFileResultDto.swift
//  BPMobileMessaging
//
//  Created by Alexander Lobastov on 6/2/21.
//

import Foundation

/// - Tag: UploadFileResultDto
struct UploadFileResultDto: Decodable {
    let fileID: String
    let fileName: String
    
    enum CodingKeys: String, CodingKey {
        case fileID = "file_id"
        case fileName = "file_name"
    }
}

extension UploadFileResultDto {
    func toModel() -> ContactCenterUploadedFileInfo {
        ContactCenterUploadedFileInfo(fileID: fileID, fileName: fileName)
    }
}

//
//  ImageMediaItem.swift
//  BPMobileMessaging_Example
//
//  Created by Alexander Lobastov on 5/29/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import MessageKit

struct ImageMediaItem: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
    
    init(url: URL) {
        self.url = url
        self.size = CGSize(width: 240, height: 240)
        self.placeholderImage = UIImage()
    }
}

//
//  RTCSimluatorVideoEncoderFactory.swift
//  BPMobileMessaging_Example
//
//  Created by Artem Mkrtchyan on 4/24/23.
//  Copyright © 2023 BrightPattern. All rights reserved.
//

import Foundation
import WebRTC

class RTCSimluatorVideoEncoderFactory: RTCDefaultVideoEncoderFactory {
    
    override init() {
        super.init()
    }
    
    override class func supportedCodecs() -> [RTCVideoCodecInfo] {
        var codecs = super.supportedCodecs()
        codecs = codecs.filter{$0.name != "H264"}
        return codecs
    }
}

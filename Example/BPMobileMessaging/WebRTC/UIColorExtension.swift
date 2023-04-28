//
//  UIColorExtension.swift
//  BPMobileMessaging_Example
//
//  Created by Artem Mkrtchyan on 4/24/23.
//  Copyright © 2023 BrightPattern. All rights reserved.
//

import Foundation
import UIKit

extension UIColor {

    func rectImage(width: CGFloat, height: CGFloat) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        UIGraphicsBeginImageContext(rect.size)
        let contextRef = UIGraphicsGetCurrentContext()
        contextRef?.setFillColor(self.cgColor)
        contextRef?.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }

}

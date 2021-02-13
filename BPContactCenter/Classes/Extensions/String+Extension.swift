//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

extension String.StringInterpolation {
    /// Allows to print optional values without a prefix.
    /// ```
    /// let x: Int? = 1
    /// print("\(x)") // > 1
    /// ```
    mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T?) {
        appendInterpolation(value, defaultValue: "nil")
    }

    mutating func appendInterpolation<T: CustomStringConvertible>(_ value: T?, defaultValue: @autoclosure () -> String) {
        appendInterpolation(value ?? defaultValue() as CustomStringConvertible)
    }
}

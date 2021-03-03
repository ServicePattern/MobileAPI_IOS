//
// Copyright © 2021 BrightPattern. All rights reserved.

import Foundation

extension DefaultStringInterpolation {
    /// Allows to print optional values without a prefix.
    /// ```
    /// let x: Int? = 1
    /// print("\(x)") // > 1
    /// ```
    mutating func appendInterpolation<T>(_ optional: T?) {
        appendInterpolation(String(describing: optional))
    }
}

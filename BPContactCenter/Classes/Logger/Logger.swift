//
// Copyright © 2021 BrightPattern. All rights reserved. 
    

import Foundation

let log = Logger()

typealias LogString = String

enum LogCategory {
    case debug
    case error
    case uncategorized

    func canLog(for category: LogCategory) -> Bool {
        // In non debug build print errors only
#if !DEBUG
        return category == .error
#else
        return true
#endif
    }

}

class Logger {
    public func debug(_ category: LogCategory, _ message: @autoclosure () -> LogString, file: String = #file, function: String = #function, line: Int = #line) {
        guard category.canLog(for: .debug) else { return }

        log(message(), category: category, file: file, function: function, line: line)
    }

    public func debug(_ message: @autoclosure () -> LogString, file: String = #file, function: String = #function, line: Int = #line) {
        debug(.uncategorized, message(), file: file, function: function, line: line)
    }

    public func error(_ category: LogCategory, _ message: @autoclosure () -> LogString, file: String = #file, function: String = #function, line: Int = #line) {
        guard category.canLog(for: .error) else { return }

        log(message(), category: category, file: file, function: function, line: line)
    }

    public func error(_ message: @autoclosure () -> LogString, file: String = #file, function: String = #function, line: Int = #line) {
        error(.uncategorized, message(), file: file, function: function, line: line)
    }

    private func log(_ message: LogString, category: LogCategory, file: String = #file, function: String = #function, line: Int = #line) {
        print("[\((file as NSString).lastPathComponent) \(function):\(line)] \(message)")
    }
}

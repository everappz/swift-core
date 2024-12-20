import Foundation
import XCGLogger

public class LibraryLogger {
    public static let shared = LibraryLogger()
    private var loggers: [String: XCGLogger] = [:]

    private init() {}

    /// Creates or retrieves a logger for a specific subsystem and category.
    public func getLogger(subsystem: String, category: String) -> XCGLogger {
        let loggerKey = "\(subsystem).\(category)"
        
        if let existingLogger = loggers[loggerKey] {
            return existingLogger
        }

        let logger = XCGLogger(identifier: loggerKey, includeDefaultDestinations: false)

        // System log destination (console output)
        let systemDestination = AppleSystemLogDestination(identifier: "\(loggerKey).systemDestination")
        systemDestination.outputLevel = .debug
        systemDestination.showLogIdentifier = false
        systemDestination.showFunctionName = false
        systemDestination.showThreadName = false
        systemDestination.showLevel = true
        systemDestination.showFileName = true
        systemDestination.showLineNumber = true
        systemDestination.showDate = true
        logger.add(destination: systemDestination)

        // File log destination
        if let logsDirectory = LibraryLogger.getLogsDirectory() {
            let logFile = logsDirectory.appendingPathComponent("\(loggerKey).log")
            let fileDestination = FileDestination(writeToFile: logFile.path, identifier: "\(loggerKey).fileDestination", shouldAppend: true)
            fileDestination.outputLevel = .debug
            fileDestination.showLogIdentifier = false
            fileDestination.showFunctionName = false
            fileDestination.showThreadName = false
            fileDestination.showLevel = true
            fileDestination.showFileName = true
            fileDestination.showDate = true
            fileDestination.logQueue = DispatchQueue.global(qos: .background)
            logger.add(destination: fileDestination)
        }

        loggers[loggerKey] = logger
        return logger
    }



    /// Retrieves the directory for logs, creating it if necessary.
    private static func getLogsDirectory() -> URL? {
        let fileManager = FileManager.default
        if let groupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "JR4S3SY396.group.internxt.desktop") {
            let logsDirectory = groupURL.appendingPathComponent("Logs")
            try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true, attributes: nil)
            return logsDirectory
        }
        let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        let logsDirectory = documentsDirectory.appendingPathComponent("Logs")
        try? fileManager.createDirectory(at: logsDirectory, withIntermediateDirectories: true, attributes: nil)
        return logsDirectory
    }
}


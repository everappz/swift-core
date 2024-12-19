import XCGLogger
import Foundation

public class LibraryLogger {
    public static let shared = LibraryLogger()
    private let logger: XCGLogger

    private init() {
        logger = XCGLogger(identifier: "InternxtSwiftCoreLogger")
        
        logger.setup(level: .debug)
        
      
        let logsDirectory = LibraryLogger.getLogsDirectory()
        let logFile = logsDirectory.appendingPathComponent("InternxtSwiftCore.log")
        
        let fileDestination = FileDestination(writeToFile: logFile.path, identifier: "fileDestination")
        fileDestination.outputLevel = .debug
        fileDestination.showDate = true
        fileDestination.showLogIdentifier = true
        fileDestination.showFunctionName = true
        fileDestination.showThreadName = true
        
        logger.add(destination: fileDestination)
    }

    public func logInfo(_ message: String) {
        logger.info(message)
    }

    public func logDebug(_ message: String) {
        logger.debug(message)
    }

    public func logError(_ message: String) {
        logger.error(message)
    }

    private static func getLogsDirectory() -> URL {
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


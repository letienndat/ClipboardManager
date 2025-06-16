//
//  Log.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 16/6/25.
//

import Foundation

class Log {
    // Folder path ~/ClipboardManager/
    private static var clipboardDirURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(AppConst.clipboardDirName)
    }

    // File path clipboard_manager.log
    private static var logFileURL: URL {
        clipboardDirURL.appendingPathComponent(AppConst.logFileName)
    }

    static func log(_ message: String) {
        let timestamp = Date().formatToString()
        let logLine = "[\(timestamp)] \(message)\n"
        print(logLine)

        do {
            let fileHandle = try FileHandle(forWritingTo: logFileURL)
            if #available(macOS 10.15, *) {
                try fileHandle.seekToEnd()
            } else {
                fileHandle.seekToEndOfFile()
            }
            if let data = logLine.data(using: .utf8) {
                fileHandle.write(data)
            }
            try fileHandle.close()
        } catch {
            do {
                try logLine.write(
                    to: logFileURL, atomically: true, encoding: .utf8)
            } catch {
                log("Failed to write log to \(logFileURL.path): \(error)")
            }
        }
    }
}

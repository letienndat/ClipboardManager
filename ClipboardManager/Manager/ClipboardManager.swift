//
//  ClipboardManager.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/13/25.
//

import AppKit
import UniformTypeIdentifiers

class ClipboardManager: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var isCopying = false
    private let pasteboard = NSPasteboard.general
    private var lastContent: String?
    private var justSetClipboard = false
    private let clipboardDirName = "ClipboardManager"
    private let jsonFileName = "clipboard.json"
    private let logFileName = "clipboard_manager.log"

    // Format in log
    private let logDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // Format timestamp in UI and log
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss dd:MM:yyyy"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    // Folder path ~/ClipboardManager/
    private var clipboardDirURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(clipboardDirName)
    }

    // File path file clipboard.json
    private var fileURL: URL {
        clipboardDirURL.appendingPathComponent(jsonFileName)
    }

    // File path clipboard_manager.log
    private var logFileURL: URL {
        clipboardDirURL.appendingPathComponent(logFileName)
    }

    init() {
        setupClipboardDirectory()
        loadItems()
        startMonitoring()
    }

    // Create folder ~/ClipboardManager/ if not exist
    private func setupClipboardDirectory() {
        let fileManager = FileManager.default
        do {
            if !fileManager.fileExists(atPath: clipboardDirURL.path) {
                try fileManager.createDirectory(
                    at: clipboardDirURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                log("Created directory: \(clipboardDirURL.path)")
            }
        } catch {
            log("Error creating directory \(clipboardDirURL.path): \(error)")
        }
    }

    private func log(_ message: String) {
        let timestamp = logDateFormatter.string(from: Date())
        let logLine = "[\(timestamp)] \(message)\n"

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

    func startMonitoring() {
        lastChangeCount = pasteboard.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self, !self.isCopying else { return }
            if pasteboard.changeCount != self.lastChangeCount {
                if self.justSetClipboard {
                    self.justSetClipboard = false
                    self.lastChangeCount = pasteboard.changeCount
                    return
                }
                if let string = pasteboard.string(forType: .string) {
                    DispatchQueue.main.async {
                        self.copyItem(ClipboardItem(content: string))
                    }
                } else {
                    let classes = [NSImage.self]
                    let options = [
                        NSPasteboard.ReadingOptionKey
                            .urlReadingContentsConformToTypes: [
                                UTType.image.identifier
                            ]
                    ]

                    // swiftlint:disable opening_brace
                    if let images = pasteboard.readObjects(
                        forClasses: classes, options: options) as? [NSImage],
                        let image = images.first
                    {
                        DispatchQueue.main.async {
                            self.copyItem(ClipboardItem(content: image))
                        }
                    }
                    // swiftlint:enable opening_brace
                }
                self.lastChangeCount = pasteboard.changeCount
            }
        }
    }

    func copyItem(_ item: ClipboardItem) {
        isCopying = true
        defer { isCopying = false }

        switch item.content {
        case .text(let text):
            // swiftlint:disable opening_brace
            if let firstItem = clipboardItems.first,
                case .text(let firstText) = firstItem.content, firstText == text
            {
                var updatedItem = firstItem
                updatedItem.updateTimestamp(Date())
                clipboardItems[0] = updatedItem
                log(
                    "Updated timestamp for existing text: \"\(text)\" to \(dateFormatter.string(from: updatedItem.timestamp))"
                )
            } else {
                pasteboard.clearContents()
                pasteboard.setString(text, forType: .string)
                self.justSetClipboard = true

                if let index = clipboardItems.firstIndex(where: { existingItem in
                    if case .text(let existingText) = existingItem.content {
                        return existingText == text
                    }
                    return false
                }) {
                    var updatedItem = clipboardItems[index]
                    updatedItem.updateTimestamp(Date())
                    clipboardItems.remove(at: index)
                    clipboardItems.insert(updatedItem, at: 0)
                    log(
                        "Updated existing text: \"\(text)\" with new timestamp: \(dateFormatter.string(from: updatedItem.timestamp))"
                    )
                } else {
                    clipboardItems.insert(item, at: 0)
                    log(
                        "Copied new text: \"\(text)\" with timestamp: \(dateFormatter.string(from: item.timestamp))"
                    )
                }
            }
        // swiftlint:enable opening_brace

        case .image(let data):
            if let image = NSImage(data: data) {
                // swiftlint:disable opening_brace
                if let firstItem = clipboardItems.first,
                    case .image(let firstData) = firstItem.content,
                    firstData == data
                {
                    var updatedItem = firstItem
                    updatedItem.updateTimestamp(Date())
                    clipboardItems[0] = updatedItem
                    log(
                        "Updated timestamp for existing image to \(dateFormatter.string(from: updatedItem.timestamp))"
                    )
                } else {
                    pasteboard.clearContents()
                    pasteboard.writeObjects([image])
                    self.justSetClipboard = true

                    if let index = clipboardItems.firstIndex(where: { existingItem in
                        if case .image(let existingData) = existingItem.content
                        {
                            return existingData == data
                        }
                        return false
                    }) {
                        var updatedItem = clipboardItems[index]
                        updatedItem.updateTimestamp(Date())
                        clipboardItems.remove(at: index)
                        clipboardItems.insert(updatedItem, at: 0)
                        log(
                            "Updated existing image with new timestamp: \(dateFormatter.string(from: updatedItem.timestamp))"
                        )
                    } else {
                        clipboardItems.insert(item, at: 0)
                        log(
                            "Copied new image with timestamp: \(dateFormatter.string(from: item.timestamp))"
                        )
                    }
                }
                // swiftlint:enable opening_brace
            }
        }

        saveItems()

        if clipboardItems.count > AppConst.numberOfItems {
            clipboardItems.removeLast(
                clipboardItems.count - AppConst.numberOfItems)
        }
    }

    func loadItems() {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path) {
                let data = try Data(contentsOf: fileURL)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    formatter.timeZone = TimeZone.current
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    throw DecodingError.dataCorruptedError(
                        in: container, debugDescription: "Invalid date format")
                }
                self.clipboardItems = try decoder.decode(
                    [ClipboardItem].self, from: data)
                log("Loaded \(clipboardItems.count) items from JSON")
            }
        } catch {
            log("Error loading JSON: \(error)")
            self.clipboardItems = []
        }
    }

    func saveItems() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .custom { date, encoder in
                var container = encoder.singleValueContainer()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                formatter.timeZone = TimeZone.current
                try container.encode(formatter.string(from: date))
            }
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(clipboardItems)
            try data.write(to: fileURL, options: .atomic)
            log("Saved \(clipboardItems.count) items to JSON")
        } catch {
            log("Error saving JSON: \(error)")
        }
    }
}

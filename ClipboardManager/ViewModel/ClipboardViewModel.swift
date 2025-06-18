//
//  ClipboardViewModel.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/18/25.
//

import AppKit
import UniformTypeIdentifiers

enum FileOperationResult {
    case success(String)
    case failure(String)
}

class ClipboardViewModel: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var isCopying = false
    private let pasteboard = NSPasteboard.general
    private var lastContent: String?
    private var justSetClipboard = false
    private let appManager = AppManager.shared

    init() {
        setupClipboardDirectory()
        loadItems()
        startMonitoring()
    }

    // Create folder ~/ClipboardManager/ if not exist
    private func setupClipboardDirectory() {
        let fileManager = FileManager.default
        do {
            if !fileManager.fileExists(atPath: appManager.clipboardDirURL.path) {
                try fileManager.createDirectory(
                    at: appManager.clipboardDirURL,
                    withIntermediateDirectories: true,
                    attributes: nil
                )
                Log.log("Created directory: \(appManager.clipboardDirURL.path)")
            }
        } catch {
            Log.log(
                "Error creating directory \(appManager.clipboardDirURL.path): \(error)")
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
                Log.log(
                    "Updated timestamp for existing text: \"\(text)\" to \(updatedItem.timestamp.formatToString())"
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
                    Log.log(
                        "Updated existing text: \"\(text)\" with new timestamp: \(updatedItem.timestamp.formatToString())"
                    )
                } else {
                    clipboardItems.insert(item, at: 0)
                    Log.log(
                        "Copied new text: \"\(text)\" with timestamp: \(item.timestamp.formatToString())"
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
                    Log.log(
                        "Updated timestamp for existing image to \(updatedItem.timestamp.formatToString())"
                    )
                } else {
                    pasteboard.clearContents()
                    pasteboard.writeObjects([image])
                    self.justSetClipboard = true

                    if let index = clipboardItems.firstIndex(where: { existingItem in
                        if case .image(let existingData) = existingItem.content {
                            return existingData == data
                        }
                        return false
                    }) {
                        var updatedItem = clipboardItems[index]
                        updatedItem.updateTimestamp(Date())
                        clipboardItems.remove(at: index)
                        clipboardItems.insert(updatedItem, at: 0)
                        Log.log(
                            "Updated existing image with new timestamp: \(updatedItem.timestamp.formatToString())"
                        )
                    } else {
                        clipboardItems.insert(item, at: 0)
                        Log.log(
                            "Copied new image with timestamp: \(item.timestamp.formatToString())"
                        )
                    }
                }
                // swiftlint:enable opening_brace
            }
        }

        saveItems()
    }

    func deleteItem(id: UUID) {
        if let index = clipboardItems.firstIndex(where: { $0.id == id }) {
            clipboardItems.remove(at: index)
            saveItems()
            let message = "Deleted item with ID \(id) from clipboard"
            Log.log(message)
            postResult(.success(message))
        } else {
            let errorMessage =
                "Failed to delete item: No item found with ID \(id)"
            Log.log(errorMessage)
            postResult(.failure(errorMessage))
        }
    }

    func loadItems() {
        do {
            if FileManager.default.fileExists(atPath: appManager.fileJSONURL.path) {
                let data = try Data(contentsOf: appManager.fileJSONURL)
                let decoder = JSONDecoder()

                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)

                    let date = Date.loadFormatedWithString(
                        dateString: dateString)
                    if let date {
                        return date
                    }

                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Invalid date format"
                    )
                }

                var clipboardItemsLoaded = try decoder.decode(
                    [ClipboardItem].self, from: data
                )
                    .sorted(by: { $0.timestamp > $1.timestamp })
                if clipboardItemsLoaded.count > AppConst.numberOfItems {
                    clipboardItemsLoaded.removeLast(
                        clipboardItemsLoaded.count - AppConst.numberOfItems)
                }
                self.clipboardItems = clipboardItemsLoaded
                let message =
                "Loaded \(clipboardItems.count) items from \(appManager.fileJSONURL.relativePath)"
                Log.log(message)
                postResult(.success(message))
            } else {
                self.clipboardItems = []
                let message =
                "No JSON file found at \(appManager.fileJSONURL.relativePath)"
                Log.log(message)
                postResult(.success(message))
            }
        } catch {
            let errorMessage =
            "Error loading JSON from \(appManager.fileJSONURL.relativePath): \(error.localizedDescription)"
            Log.log(errorMessage)
            self.clipboardItems = []
            postResult(.failure(errorMessage))
        }
    }

    func saveItems() {
        do {
            let encoder = JSONEncoder()

            encoder.dateEncodingStrategy = .custom { date, encoder in
                var container = encoder.singleValueContainer()
                let formatter = DateFormatter()
                formatter.configFormatLoadStringDate()
                try container.encode(formatter.string(from: date))
            }

            encoder.outputFormatting = .prettyPrinted

            if clipboardItems.count > AppConst.numberOfItems {
                clipboardItems.removeLast(
                    clipboardItems.count - AppConst.numberOfItems)
            }

            let data = try encoder.encode(clipboardItems)
            try data.write(to: appManager.fileJSONURL, options: .atomic)

            Log.log("Saved \(clipboardItems.count) items to JSON")
        } catch {
            Log.log("Error saving JSON: \(error)")
        }
    }

    func exportJSON() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "clipboard_export.json"
        panel.canCreateDirectories = true
        panel.title = "Export Clipboard Items"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .custom { date, encoder in
                    var container = encoder.singleValueContainer()
                    let formatter = DateFormatter()
                    formatter.configFormatLoadStringDate()
                    try container.encode(formatter.string(from: date))
                }
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(clipboardItems)
                try data.write(to: url, options: .atomic)
                let message =
                    "Exported \(clipboardItems.count) items to \(url.relativePath)"
                Log.log(message)
                postResult(.success(message))
            } catch {
                let errorMessage =
                    "Error exporting JSON to \(url.relativePath): \(error.localizedDescription)"
                Log.log(errorMessage)
                postResult(.failure(errorMessage))
            }
        } else {
            postResult(.failure("No file selected for export"))
        }
    }

    func importJSON(shouldMerge: Bool = false) {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.title = "Import Clipboard Items"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    let date = Date.loadFormatedWithString(
                        dateString: dateString)
                    if let date {
                        return date
                    }
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Invalid date format"
                    )
                }
                let importedItems = try decoder.decode(
                    [ClipboardItem].self, from: data)

                if shouldMerge {
                    var combinedItems = clipboardItems
                    for importedItem in importedItems {
                        let isDuplicate = combinedItems.contains { existingItem in
                            if existingItem.timestamp == importedItem.timestamp {
                                switch (
                                    existingItem.content, importedItem.content
                                ) {
                                case let (
                                    .text(existingText), .text(importedText)
                                ):
                                    return existingText == importedText
                                case let (
                                    .image(existingData), .image(importedData)
                                ):
                                    return existingData == importedData
                                default:
                                    return false
                                }
                            }
                            return false
                        }
                        if !isDuplicate {
                            combinedItems.append(importedItem)
                        }
                    }

                    clipboardItems = Array(
                        combinedItems
                            .sorted(by: { $0.timestamp > $1.timestamp })
                            .prefix(AppConst.numberOfItems)
                    )

                    saveItems()
                    let newItemCount =
                        importedItems.count
                        - (combinedItems.count - clipboardItems.count)
                    let message =
                        "Merged \(newItemCount) new items from \(url.relativePath)"
                    Log.log(message)
                    postResult(.success(message))
                } else {
                    clipboardItems = Array(
                        importedItems
                            .sorted(by: { $0.timestamp > $1.timestamp })
                            .prefix(AppConst.numberOfItems)
                    )

                    saveItems()
                    let message =
                        "Imported \(clipboardItems.count) items from \(url.relativePath)"
                    Log.log(message)
                    postResult(.success(message))
                }
            } catch {
                let errorMessage =
                    "Error importing JSON from \(url.relativePath): \(error.localizedDescription)"
                Log.log(errorMessage)
                postResult(.failure(errorMessage))
            }
        } else {
            postResult(.failure("No file selected for import"))
        }
    }
}

private func postResult(_ result: FileOperationResult) {
    NotificationCenter.default.post(name: .clipboardOperationResult, object: result)
}

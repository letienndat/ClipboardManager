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
    private let fileName = "clipboard.json"
    private var fileURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent(fileName)
    }
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss dd:MM:yyyy"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    init() {
        loadItems()
        startMonitoring()
    }

    func startMonitoring() {
        lastChangeCount = pasteboard.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, !self.isCopying else { return }
            if pasteboard.changeCount != self.lastChangeCount {
                if let string = pasteboard.string(forType: .string) {
                    if string != self.lastContent {
                        self.lastContent = string
                        DispatchQueue.main.async {
                            self.copyItem(ClipboardItem(content: string))
                        }
                    }
                } else {
                    let classes = [NSImage.self]
                    let options = [NSPasteboard.ReadingOptionKey.urlReadingContentsConformToTypes: [UTType.image.identifier]]
                    if let images = pasteboard.readObjects(forClasses: classes, options: options) as? [NSImage],
                       let image = images.first,
                       let imageData = image.tiffRepresentation,
                       imageData.base64EncodedString() != self.lastContent {
                        self.lastContent = imageData.base64EncodedString()
                        DispatchQueue.main.async {
                            self.copyItem(ClipboardItem(content: image))
                        }
                    }
                }
                self.lastChangeCount = pasteboard.changeCount
            }
        }
    }

    func copyItem(_ item: ClipboardItem) {
        isCopying = true
        defer { isCopying = false }

        pasteboard.clearContents()

        switch item.content {
        case .text(let text):
            if let firstItem = clipboardItems.first,
               case .text(let firstText) = firstItem.content,
               firstText == text {
                pasteboard.setString(text, forType: .string)
                print("Copied existing text: \(text) with timestamp: \(dateFormatter.string(from: firstItem.timestamp))")
            } else {
                pasteboard.setString(text, forType: .string)
                print("Copied new text: \(text) with timestamp: \(dateFormatter.string(from: item.timestamp))")
                clipboardItems.removeAll { existingItem in
                    if case .text(let existingText) = existingItem.content {
                        return existingText == text
                    }
                    return false
                }
                clipboardItems.insert(item, at: 0)
                saveItems()
            }
        case .image(let data):
            if let image = NSImage(data: data) {
                pasteboard.writeObjects([image])
                print("Copied image with timestamp: \(dateFormatter.string(from: item.timestamp))")
                clipboardItems.removeAll { existingItem in
                    if case .image(let existingData) = existingItem.content {
                        return existingData == data
                    }
                    return false
                }
                clipboardItems.insert(item, at: 0)
                saveItems()
            }
        }

        if clipboardItems.count > AppConst.numberOfItems {
            clipboardItems.removeLast(clipboardItems.count - AppConst.numberOfItems)
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
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format")
                }
                self.clipboardItems = try decoder.decode([ClipboardItem].self, from: data)
                print("Loaded \(clipboardItems.count) items from JSON")
            }
        } catch {
            print("Error loading JSON: \(error)")
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
            print("Saved \(clipboardItems.count) items to JSON")
        } catch {
            print("Error saving JSON: \(error)")
        }
    }
}

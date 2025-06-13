//
//  ClipboardManager.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/13/25.
//

import AppKit
import Combine
import UniformTypeIdentifiers

class ClipboardManager: ObservableObject {
    @Published var clipboardItems: [ClipboardItem] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var isCopying = false

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        let pasteboard = NSPasteboard.general
        lastChangeCount = pasteboard.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {
            [weak self] _ in
            guard let self = self else { return }
            if pasteboard.changeCount != self.lastChangeCount && !self.isCopying
            {
                if let string = pasteboard.string(forType: .string) {
                    DispatchQueue.main.async {
                        if self.clipboardItems.isEmpty
                            || self.clipboardItems[0].content as? String
                                != string
                        {
                            self.clipboardItems.insert(
                                ClipboardItem(content: string), at: 0)
                            if self.clipboardItems.count > 50 {
                                self.clipboardItems.removeLast()
                            }
                            print("New clipboard item (text): \(string)")
                        }
                    }
                } else {

                    let classes = [NSImage.self]
                    let options = [
                        NSPasteboard.ReadingOptionKey
                            .urlReadingContentsConformToTypes: [
                                UTType.image.identifier
                            ]
                    ]
                    if let images = pasteboard.readObjects(
                        forClasses: classes, options: options) as? [NSImage],
                        let image = images.first
                    {
                        DispatchQueue.main.async {
                            if self.clipboardItems.isEmpty
                                || self.clipboardItems[0].content as? NSImage
                                    != image
                            {
                                self.clipboardItems.insert(
                                    ClipboardItem(content: image), at: 0)
                                if self.clipboardItems.count > 50 {
                                    self.clipboardItems.removeLast()
                                }
                                print("New clipboard item (image)")
                            }
                        }
                    }
                }
                self.lastChangeCount = pasteboard.changeCount
            }
        }
    }

    func copyItem(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        self.isCopying = true
        pasteboard.clearContents()
        if let text = item.content as? String {
            pasteboard.setString(text, forType: .string)
            print("Copied to clipboard (text): \(text)")
        } else if let image = item.content as? NSImage {
            pasteboard.writeObjects([image])
            print("Copied to clipboard (image)")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isCopying = false
        }
    }
}

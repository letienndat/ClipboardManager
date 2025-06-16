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

    init() {
        startMonitoring()
    }

    func startMonitoring() {
        lastChangeCount = pasteboard.changeCount

        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) {  [weak self] _ in
            guard let self = self else { return }
            if pasteboard.changeCount != self.lastChangeCount && !self.isCopying {
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
                    if let images = pasteboard.readObjects(
                        forClasses: classes, options: options) as? [NSImage],
                        let image = images.first {
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
        self.isCopying = true
        pasteboard.clearContents()

        if let text = item.content as? String {
            pasteboard.setString(text, forType: .string)
            print("Copied to clipboard (text): \(text)")

            clipboardItems.removeAll(where: {
                if let existingText = $0.content as? String {
                    return existingText == text
                }
                return false
            })
        } else if let image = item.content as? NSImage {
            pasteboard.writeObjects([image])
            print("Copied to clipboard (image)")

            clipboardItems.removeAll(where: {
                if let existingImage = $0.content as? NSImage {
                    return existingImage.tiffRepresentation
                        == image.tiffRepresentation
                }
                return false
            })
        }

        clipboardItems.insert(item, at: 0)

        if clipboardItems.count > AppConst.numberOfItems {
            clipboardItems.removeLast(
                clipboardItems.count - AppConst.numberOfItems)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isCopying = false
        }
    }
}

//
//  ClipboardManager.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/13/25.
//

import AppKit
import Combine

class ClipboardManager: ObservableObject {
    @Published var clipboardItems: [String] = []
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private var isCopying = false
    
    init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        let pasteboard = NSPasteboard.general
        lastChangeCount = pasteboard.changeCount
        
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if pasteboard.changeCount != self.lastChangeCount && !self.isCopying {
                if let newItem = pasteboard.string(forType: .string) {
                    DispatchQueue.main.async {
                        if self.clipboardItems.isEmpty || self.clipboardItems[0] != newItem {
                            self.clipboardItems.insert(newItem, at: 0)
                            if self.clipboardItems.count > 50 {
                                self.clipboardItems.removeLast()
                            }
                            print("New clipboard item: \(newItem)")
                        }
                    }
                }
                self.lastChangeCount = pasteboard.changeCount
            }
        }
    }

    func copyItem(_ item: String) {
        let pasteboard = NSPasteboard.general
        self.isCopying = true
        pasteboard.clearContents()
        pasteboard.setString(item, forType: .string)
        if let copiedString = pasteboard.string(forType: .string), copiedString == item {
            print("Copied to clipboard: \(item)")
        } else {
            print("Failed to copy to clipboard")
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.isCopying = false
        }
    }
}

//
//  ClipboardItem.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 13/6/25.
//

import Foundation

struct ClipboardItem: Identifiable {
    let id = UUID()
    let content: Any
    let timestamp = Date()

    init(content: Any) {
        self.content = content
    }
}

//
//  AppManager.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/18/25.
//

import Foundation
import AppKit

class AppManager {
    public static let shared = AppManager()

    // Folder path ~/ClipboardManager/
    var clipboardDirURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(AppConst.clipboardDirName)
    }

    // File path file clipboard.json
    var fileJSONURL: URL {
        clipboardDirURL.appendingPathComponent(AppConst.jsonFileName)
    }

    private init() {}

    func openClipboardDirectory() {
        NSWorkspace.shared.open(clipboardDirURL)
    }
}

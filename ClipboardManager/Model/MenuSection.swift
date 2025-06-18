//
//  MenuSection.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/18/25.
//

import Foundation

enum MenuAction: CaseIterable {
    case importJSONOverride
    case importJSONMerge
    case exportJSON
    case openClipboardDirectory
    case forceQuit

    var title: String {
        switch self {
        case .importJSONOverride: return "Import JSON: Override"
        case .importJSONMerge: return "Import JSON: Merge"
        case .exportJSON: return "Export JSON"
        case .openClipboardDirectory: return "Open Clipboard Directory"
        case .forceQuit: return "Force Quit"
        }
    }

    var selector: Selector? {
        switch self {
        case .importJSONOverride: return #selector(AppDelegate.importJSONOverride)
        case .importJSONMerge: return #selector(AppDelegate.importJSONMerge)
        case .exportJSON: return #selector(AppDelegate.exportJSON)
        case .openClipboardDirectory: return #selector(AppDelegate.openClipboardDirectory)
        case .forceQuit:  return #selector(AppDelegate.forceQuit)
        }
    }
}

struct MenuSection {
    let items: [MenuAction]
}

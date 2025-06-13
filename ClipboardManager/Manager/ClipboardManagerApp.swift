//
//  ClipboardManagerApp.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 13/6/25.
//

import SwiftUI

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var popoverManager = PopoverManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(popoverManager)
        }
    }
}

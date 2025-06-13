//
//  AppDelegate.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/13/25.
//

import SwiftUI
import AppKit
import Carbon
import ServiceManagement

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.windows.forEach { $0.close() }
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard")
            button.action = #selector(togglePopover)
        }
        
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(rootView: ContentView())
        popover?.behavior = .transient
        
        registerGlobalHotkey()
        
        let helperBundleIdentifier = "com.datlt.ClipboardManagerHelper"
        SMLoginItemSetEnabled(helperBundleIdentifier as CFString, true)
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button, let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }
    
    func registerGlobalHotkey() {
        let hotKeyID = EventHotKeyID(signature: UInt32("swif".fourCharCodeValue), id: 1)
        let modifierFlags: UInt32 = UInt32(cmdKey | shiftKey)
        let keyCode: UInt32 = UInt32(kVK_ANSI_V)
        
        var hotKeyRef: EventHotKeyRef?
        let eventTarget = GetApplicationEventTarget()
        
        let status = RegisterEventHotKey(
            keyCode,
            modifierFlags,
            hotKeyID,
            eventTarget,
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            print("Failed to register hotkey with error: \(status)")
            return
        }
        
        var eventSpec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        var eventHandler: EventHandlerRef?
        
        let handler: @convention(c) (EventHandlerCallRef?, EventRef?, UnsafeMutableRawPointer?) -> OSStatus = { (nextHandler, event, userData) -> OSStatus in
            if let userData = userData {
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
                appDelegate.togglePopover()
            }
            return noErr
        }
        
        let uppHandler = handler
        let userData = Unmanaged.passUnretained(self).toOpaque()
        
        InstallEventHandler(
            GetApplicationEventTarget(),
            uppHandler,
            1,
            &eventSpec,
            userData,
            &eventHandler
        )
    }
}

extension String {
    var fourCharCodeValue: UInt32 {
        var result: UInt32 = 0
        let chars = self.utf8.prefix(4).map { UInt8($0) }
        for (index, char) in chars.enumerated() {
            result = result | (UInt32(char) << (8 * (3 - index)))
        }
        return result
    }
}

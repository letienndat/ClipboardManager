//
//  AppDelegate.swift
//  ClipboardManager
//
//  Created by Le Tien Dat on 6/13/25.
//

import AppKit
import Carbon
import ServiceManagement
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    @ObservedObject var popoverManager = PopoverManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.windows.forEach { $0.close() }

        statusItem = NSStatusBar.system.statusItem(
            withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "Clipboard")
            button.action = #selector(togglePopover)
        }

        popover = NSPopover()
        popover?.contentViewController = NSHostingController(
            rootView: ContentView().environmentObject(popoverManager))
        popover?.behavior = .transient

        popoverManager.popover = popover

        registerGlobalHotkey()
    }

    @objc
    func togglePopover() {
        if let button = statusItem?.button, let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
                popoverManager.isShown = false
            } else {
                popover.show(
                    relativeTo: button.bounds, of: button, preferredEdge: .minY)
                popoverManager.isShown = true
            }
        }
    }

    func registerGlobalHotkey() {
        let hotKeyID = EventHotKeyID(
            signature: UInt32("swif".fourCharCodeValue), id: 1)
        let modifierFlags = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_V)

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

        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed))
        var eventHandler: EventHandlerRef?

        let handler:
            @convention(c) (
                EventHandlerCallRef?, EventRef?, UnsafeMutableRawPointer?
            ) -> OSStatus = { (_, _, userData) -> OSStatus in
                if let userData = userData {
                    let appDelegate = Unmanaged<AppDelegate>.fromOpaque(
                        userData
                    )
                        .takeUnretainedValue()
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

class PopoverManager: ObservableObject {
    @Published var isShown = false
    weak var popover: NSPopover?

    func closePopover() {
        if isShown, let popover = popover {
            popover.performClose(nil)
            isShown = false
        }
    }
}

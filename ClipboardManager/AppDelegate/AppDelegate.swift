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
    private var contextMenu: NSMenu?
    var clipboardViewModel = ClipboardViewModel()
    private let appManager = AppManager.shared
    private let menuSections: [MenuSection] = [
        MenuSection(items: [.importJSONOverride, .importJSONMerge, .exportJSON]),
        MenuSection(items: [.openClipboardDirectory]),
        MenuSection(items: [.forceQuit])
    ]
    @ObservedObject var popoverManager = PopoverManager()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.windows.forEach { $0.close() }

        configButtonMenuBar()
        configRightClickMenuBar()
        configPopover()
        registerGlobalHotkey()
    }

    private func configButtonMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(
                systemSymbolName: "doc.on.clipboard",
                accessibilityDescription: "Clipboard")
            button.action = #selector(handleButtonClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    private func configRightClickMenuBar() {
        contextMenu = NSMenu()

        for (index, section) in menuSections.enumerated() {
            for action in section.items {
                let item = NSMenuItem(title: action.title, action: action.selector, keyEquivalent: "")
                item.target = self
                contextMenu?.addItem(item)
            }
            if index < menuSections.count - 1 {
                contextMenu?.addItem(.separator())
            }
        }
    }

    private func configPopover() {
        popover = NSPopover()
        popover?.contentViewController = NSHostingController(
            rootView: ClipboardView(viewModel: clipboardViewModel).environmentObject(popoverManager))
        popover?.behavior = .transient

        popoverManager.popover = popover
    }

    func registerGlobalHotkey() {
        let hotKeyID = EventHotKeyID(
            signature: UInt32("swif".fourCharCodeValue), id: 1)
        let modifierFlags = UInt32(cmdKey | shiftKey) // Cmd + Shift
        let keyCode = UInt32(kVK_ANSI_V) // Key 'V'

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
            Log.log("Failed to register hotkey with error: \(status)")
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

    @objc
    private func handleButtonClick(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            statusItem?.menu = contextMenu
            statusItem?.button?.performClick(nil)
            DispatchQueue.main.async {
                self.statusItem?.menu = nil
            }
        } else if event?.type == .leftMouseUp {
            togglePopover()
        }
    }

    @objc
    private func togglePopover() {
        if let button = statusItem?.button, let popover = popover {
            if popover.isShown {
                popover.performClose(nil)
                popoverManager.isShown = false
            } else {
                NSApp.activate(ignoringOtherApps: true)

                popover.show(
                    relativeTo: button.bounds,
                    of: button,
                    preferredEdge: .minY
                )
                popoverManager.isShown = true
            }
        }
    }

    @objc
    func importJSONOverride() {
        clipboardViewModel.importJSON()
    }

    @objc
    func importJSONMerge() {
        clipboardViewModel.importJSON(shouldMerge: true)
    }

    @objc
    func exportJSON() {
        clipboardViewModel.exportJSON()
    }

    @objc
    func openClipboardDirectory() {
        appManager.openClipboardDirectory()
    }

    @objc
    func forceQuit() {
        NSApp.terminate(nil)
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

//
//  HelperAppDelegate.swift
//  ClipboardManagerHelper
//
//  Created by Le Tien Dat on 6/13/25.
//

import Cocoa

@main
class HelperAppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        
        let mainAppBundleIdentifier = "com.datlt.ClipboardManager"
        if let mainApp = NSRunningApplication.runningApplications(withBundleIdentifier: mainAppBundleIdentifier).first {
            mainApp.activate(options: .activateIgnoringOtherApps)
        } else {
            NSWorkspace.shared.launchApplication(withBundleIdentifier: mainAppBundleIdentifier, options: [], additionalEventParamDescriptor: nil, launchIdentifier: nil)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            NSApp.terminate(nil)
        }
    }
}

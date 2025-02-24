//
//  AIPhotoKeyApp.swift
//  AIPhotoKey
//
//  Created by Elie Cohen on 2025-02-24.
//

import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Application did finish launching")
    }
    
    func applicationWillFinishLaunching(_ notification: Notification) {
        print("Application will finish launching")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        print("Checking if should terminate")
        return true
    }
}

@main
struct AIPhotoKeyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    print("Building main scene")
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 800, height: 600)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }
    }
    
    init() {
        print("AIPhotoKeyApp initializing...")
        NSWindow.allowsAutomaticWindowTabbing = false
    }
}

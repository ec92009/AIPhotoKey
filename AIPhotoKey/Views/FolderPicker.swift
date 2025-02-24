import SwiftUI
import AppKit

public struct FolderPicker {
    public static func showPicker(completion: @escaping (URL?) -> Void) {
        let openPanel = NSOpenPanel()
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = false
        openPanel.treatsFilePackagesAsDirectories = true // This allows browsing into packages
        openPanel.directoryURL = URL(string: NSString(string: "~/Photos").expandingTildeInPath)
        
        openPanel.begin { response in
            if response == .OK {
                completion(openPanel.url)
            } else {
                completion(nil)
            }
        }
    }
}

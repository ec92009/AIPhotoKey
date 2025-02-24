import SwiftUI
import Foundation

public class SessionPreferences: ObservableObject {
    public static let shared = SessionPreferences()

    // Using @AppStorage to store user preferences in UserDefaults
    @AppStorage("photosSourceFolder") private var _photosSourceFolder: String = "~/Pictures" {
        didSet {
            print("photosSourceFolder updated to: \(_photosSourceFolder)")
        }
    }
    
    public var photosSourceFolder: String {
        get {
            (_photosSourceFolder as NSString).expandingTildeInPath
        }
        set {
            _photosSourceFolder = newValue
        }
    }
    
    // Store model choice as raw value string since AppStorage doesn't directly support enums
    @AppStorage("selectedAIModel") public var aiModelChoice: AIModel = .mobilenetV1 {
        didSet {
            print("aiModelChoice updated to: \(aiModelChoice)")
        }
    }
    
    @AppStorage("confidenceSetting") public var confidenceSetting: Double = 0.5 {
        didSet {
            print("confidenceSetting updated to: \(confidenceSetting)")
        }
    }

    private init() {
        print("SessionPreferences initialized")
        print("Photos source folder: \(photosSourceFolder)")
        print("Selected AI model: \(aiModelChoice)")
        print("Confidence setting: \(confidenceSetting)")
    }
}

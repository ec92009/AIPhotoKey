import SwiftUI

public class SessionPreferences: ObservableObject {
    public static let shared = SessionPreferences()

    // Using @AppStorage to store user preferences in UserDefaults
    @AppStorage("photosSourceFolder", store: UserDefaults.standard) public var photosSourceFolder: String = "" {
        didSet {
            print("photosSourceFolder updated to: \(photosSourceFolder)")
        }
    }
    
    // Store model choice as raw value string since AppStorage doesn't directly support enums
    @AppStorage("modelChoice", store: UserDefaults.standard) private var modelChoiceRaw: String = AIModel.mobilenetV2.rawValue {
        didSet {
            print("modelChoice updated to: \(modelChoiceRaw)")
        }
    }
    
    // Public computed property to handle conversion between String and AIModel
    public var modelChoice: AIModel {
        get {
            AIModel(rawValue: modelChoiceRaw) ?? .mobilenetV2
        }
        set {
            modelChoiceRaw = newValue.rawValue
        }
    }
    
    @AppStorage("confidenceSetting", store: UserDefaults.standard) public var confidenceSetting: Double = 0.9 {
        didSet {
            print("confidenceSetting updated to: \(confidenceSetting)")
        }
    }

    private init() {}
}

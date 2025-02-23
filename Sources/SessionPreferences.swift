import SwiftUI

public class SessionPreferences: ObservableObject {
    public static let shared = SessionPreferences()

    // Using @AppStorage to store user preferences in UserDefaults
    @AppStorage("photosSourceFolder", store: UserDefaults.standard) public var photosSourceFolder: String = "" {
        didSet {
            print("photosSourceFolder updated to: \(photosSourceFolder)")
        }
    }
    
    @AppStorage("modelChoice", store: UserDefaults.standard) public var modelChoice: String = "" {
        didSet {
            print("modelChoice updated to: \(modelChoice)")
        }
    }
    
    @AppStorage("confidenceSetting", store: UserDefaults.standard) public var confidenceSetting: Double = 0.9 {
        didSet {
            print("confidenceSetting updated to: \(confidenceSetting)")
        }
    }

    private init() {}
}

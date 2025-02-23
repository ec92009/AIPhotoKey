import SwiftUI

class SessionPreferences: ObservableObject {
    // Using @AppStorage to store user preferences in UserDefaults
    @AppStorage("photosSourceFolder") var photosSourceFolder: String = ""
    @AppStorage("modelChoice") var modelChoice: String = ""
    @AppStorage("confidenceSetting") var confidenceSetting: Double = 0.9
}

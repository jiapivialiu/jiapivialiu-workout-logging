import SwiftUI

@main
struct WorkoutLogApp: App {
    @StateObject private var tracker = TrackerStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(tracker)
                .tint(Color(red: 0.18, green: 0.44, blue: 0.34))
        }
    }
}

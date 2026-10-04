import SwiftUI

@main
struct TankTimeApp: App {
    @StateObject private var store = AppStore()
    @StateObject private var consent = ConsentManager()
    @StateObject private var ads = AdsCoordinator()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environmentObject(consent)
                .environmentObject(ads)
                .task {
                    if !LaunchConfig.screenshotMode {
                        await ads.prepare(consent: consent)
                    }
                }
        }
    }
}

import SwiftUI

private enum AppTab: Hashable {
    case calculate, plan, tanks, history, settings

    init(screen: String) {
        switch screen.lowercased() {
        case "plan": self = .plan
        case "tanks": self = .tanks
        case "history": self = .history
        case "settings": self = .settings
        default: self = .calculate
        }
    }
}

struct RootView: View {
    @State private var selection: AppTab

    init() {
        _selection = State(initialValue: AppTab(screen: LaunchConfig.screen))
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selection) {
                NavigationStack { CalculatorView() }
                    .tabItem { Label("Calculate", systemImage: "gauge.with.dots.needle.67percent") }
                    .tag(AppTab.calculate)

                NavigationStack { PlannerView() }
                    .tabItem { Label("Plan", systemImage: "map.fill") }
                    .tag(AppTab.plan)

                NavigationStack { TanksView() }
                    .tabItem { Label("Tanks", systemImage: "cylinder.fill") }
                    .tag(AppTab.tanks)

                NavigationStack { HistoryView() }
                    .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                    .tag(AppTab.history)

                NavigationStack { SettingsView() }
                    .tabItem { Label("Settings", systemImage: "gearshape") }
                    .tag(AppTab.settings)
            }
            if !LaunchConfig.screenshotMode {
                BannerAdView()
            }
        }
        .tint(Color(red: 0.78, green: 0.49, blue: 0.18))
    }
}

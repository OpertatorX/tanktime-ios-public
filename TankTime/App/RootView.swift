import SwiftUI
import UIKit

private enum AppTab: Hashable, CaseIterable {
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

    var title: LocalizedStringKey {
        switch self {
        case .calculate: "Calculate"
        case .plan: "Plan"
        case .tanks: "Tanks"
        case .history: "History"
        case .settings: "Settings"
        }
    }

    var symbol: String {
        switch self {
        case .calculate: "flame.fill"
        case .plan: "map.fill"
        case .tanks: "cylinder.fill"
        case .history: "clock.arrow.circlepath"
        case .settings: "slider.horizontal.3"
        }
    }
}

enum AppTheme {
    static let background = Color(red: 0.035, green: 0.039, blue: 0.047)
    static let backgroundLifted = Color(red: 0.055, green: 0.059, blue: 0.071)
    static let surface = Color.white.opacity(0.065)
    static let surfaceStrong = Color.white.opacity(0.105)
    static let border = Color.white.opacity(0.10)
    static let borderStrong = Color.white.opacity(0.17)
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.60)
    static let accent = Color(red: 0.96, green: 0.57, blue: 0.20)
    static let accentDeep = Color(red: 0.77, green: 0.34, blue: 0.10)
    static let success = Color(red: 0.35, green: 0.82, blue: 0.55)

    static let accentGradient = LinearGradient(
        colors: [accent, Color(red: 0.94, green: 0.40, blue: 0.13)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backdrop = LinearGradient(
        colors: [backgroundLifted, background],
        startPoint: .top,
        endPoint: .bottom
    )
}

struct RootView: View {
    @State private var selection: AppTab

    init() {
        _selection = State(initialValue: AppTab(screen: LaunchConfig.screen))
    }

    var body: some View {
        ZStack {
            AppTheme.backdrop.ignoresSafeArea()

            TabView(selection: $selection) {
                NavigationStack { CalculatorView() }
                    .tag(AppTab.calculate)

                NavigationStack { PlannerView() }
                    .tag(AppTab.plan)

                NavigationStack { TanksView() }
                    .tag(AppTab.tanks)

                NavigationStack { HistoryView() }
                    .tag(AppTab.history)

                NavigationStack { SettingsView() }
                    .tag(AppTab.settings)
            }
            .toolbar(.hidden, for: .tabBar)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VStack(spacing: 0) {
                if !LaunchConfig.screenshotMode {
                    BannerAdView()
                        .background(AppTheme.background)
                }
                PremiumTabBar(selection: $selection)
            }
        }
        .tint(AppTheme.accent)
        .preferredColorScheme(.dark)
    }
}

private struct PremiumTabBar: View {
    @Binding var selection: AppTab

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.snappy(duration: 0.28)) {
                        selection = tab
                    }
                } label: {
                    VStack(spacing: 5) {
                        ZStack {
                            if selection == tab {
                                Capsule(style: .continuous)
                                    .fill(AppTheme.accent.opacity(0.16))
                                    .frame(width: 45, height: 28)
                            }
                            Image(systemName: tab.symbol)
                                .font(.system(size: 15, weight: .semibold))
                                .symbolRenderingMode(.hierarchical)
                        }
                        Text(tab.title)
                            .font(.system(size: 10, weight: selection == tab ? .semibold : .medium, design: .rounded))
                            .lineLimit(1)
                    }
                    .foregroundStyle(selection == tab ? AppTheme.accent : AppTheme.textSecondary)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(selection == tab ? .isSelected : [])
            }
        }
        .padding(.horizontal, 12)
        .padding(.top, 9)
        .padding(.bottom, 7)
        .background(.ultraThinMaterial)
        .overlay(alignment: .top) {
            Rectangle()
                .fill(AppTheme.border)
                .frame(height: 0.5)
        }
    }
}

struct PremiumPageHeader: View {
    let eyebrow: LocalizedStringKey
    let title: LocalizedStringKey
    var subtitle: LocalizedStringKey?
    var symbol: String?

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(alignment: .leading, spacing: 7) {
                Text(eyebrow)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .tracking(1.2)
                    .textCase(.uppercase)
                    .foregroundStyle(AppTheme.accent)
                Text(title)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                if let subtitle {
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundStyle(AppTheme.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 8)
            if let symbol {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.13))
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.accent.opacity(0.22), lineWidth: 1)
                    Image(systemName: symbol)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
                .frame(width: 54, height: 54)
            }
        }
    }
}

struct PremiumCard<Content: View>: View {
    var padding: CGFloat = 18
    let content: Content

    init(padding: CGFloat = 18, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        content
            .padding(padding)
            .background {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(AppTheme.surface)
                    .overlay {
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    }
            }
    }
}

struct PremiumSectionTitle: View {
    let title: LocalizedStringKey
    var caption: LocalizedStringKey?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            if let caption {
                Text(caption)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

struct PremiumTextField: View {
    let title: LocalizedStringKey
    @Binding var text: String
    var placeholder: String = "0"
    var suffix: String? = nil
    var keyboard: UIKeyboardType = .decimalPad

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
            HStack(spacing: 10) {
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                if let suffix {
                    Text(suffix)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.accent)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .background(AppTheme.accent.opacity(0.11), in: Capsule())
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 54)
            .background(AppTheme.background.opacity(0.62), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(AppTheme.border, lineWidth: 1)
            }
        }
    }
}

struct PrimaryActionButton: View {
    let title: LocalizedStringKey
    let symbol: String
    var disabled = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: symbol)
                    .font(.system(size: 15, weight: .bold))
                    .frame(width: 34, height: 34)
                    .background(Color.white.opacity(0.14), in: Circle())
            }
            .foregroundStyle(.white)
            .padding(.leading, 18)
            .padding(.trailing, 10)
            .frame(height: 58)
            .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: AppTheme.accent.opacity(disabled ? 0 : 0.18), radius: 18, y: 8)
            .opacity(disabled ? 0.42 : 1)
        }
        .buttonStyle(.plain)
        .disabled(disabled)
    }
}

struct MetricTile: View {
    let title: LocalizedStringKey
    let value: String
    var symbol: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(AppTheme.accent)
            }
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(AppTheme.background.opacity(0.52), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct PremiumDivider: View {
    var body: some View {
        Rectangle()
            .fill(AppTheme.border)
            .frame(height: 1)
    }
}

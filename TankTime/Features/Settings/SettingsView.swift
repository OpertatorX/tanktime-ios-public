import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var consent: ConsentManager

    private func localizedURL(en: String, fr: String) -> URL {
        let language = Locale.current.language.languageCode?.identifier
        return URL(string: language == "fr" ? fr : en)!
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PremiumPageHeader(
                    eyebrow: "Preferences",
                    title: "Make TankTime yours",
                    subtitle: "Units, privacy controls and the essentials in one place.",
                    symbol: "slider.horizontal.3"
                )
                .padding(.bottom, 4)

                unitsCard

                if consent.privacyOptionsRequired {
                    privacyCard
                }

                aboutCard
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.backdrop.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var unitsCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                PremiumSectionTitle(title: "Units", caption: "Measurement system")

                HStack(spacing: 8) {
                    unitButton(title: "Imperial", symbol: "ruler", value: .imperial)
                    unitButton(title: "Metric", symbol: "scalemass", value: .metric)
                }

                Text("TankTime stores normalized values internally and converts weight and power inputs for the selected system.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }

    private func unitButton(title: LocalizedStringKey, symbol: String, value: UnitSystem) -> some View {
        Button {
            withAnimation(.snappy(duration: 0.25)) {
                store.unitSystem = value
            }
        } label: {
            HStack(spacing: 9) {
                Image(systemName: symbol)
                    .font(.system(size: 14, weight: .bold))
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Spacer()
                Image(systemName: store.unitSystem == value ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundStyle(store.unitSystem == value ? AppTheme.textPrimary : AppTheme.textSecondary)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                store.unitSystem == value ? AppTheme.accent.opacity(0.12) : AppTheme.background.opacity(0.5),
                in: RoundedRectangle(cornerRadius: 15, style: .continuous)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(store.unitSystem == value ? AppTheme.accent.opacity(0.28) : AppTheme.border, lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }

    private var privacyCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 15) {
                PremiumSectionTitle(title: "Privacy", caption: "Advertising")
                Button {
                    Task { await consent.presentPrivacyOptions() }
                } label: {
                    settingsRow(
                        title: "Manage ad privacy choices",
                        symbol: "hand.raised.fill",
                        trailingSymbol: "chevron.right"
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var aboutCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                PremiumSectionTitle(title: "About", caption: "TankTime")

                infoRow(title: "App", value: "TankTime", symbol: "app.fill")
                PremiumDivider()
                infoRow(
                    title: "Version",
                    value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
                    symbol: "number"
                )
                PremiumDivider()

                Link(destination: localizedURL(
                    en: "https://operatorx-tanktime.vercel.app/privacy.html",
                    fr: "https://operatorx-tanktime.vercel.app/privacy-fr.html"
                )) {
                    settingsRow(title: "Privacy Policy", symbol: "lock.shield.fill", trailingSymbol: "arrow.up.right")
                }

                PremiumDivider()

                Link(destination: localizedURL(
                    en: "https://operatorx-tanktime.vercel.app/terms.html",
                    fr: "https://operatorx-tanktime.vercel.app/terms-fr.html"
                )) {
                    settingsRow(title: "Terms of Use", symbol: "doc.text.fill", trailingSymbol: "arrow.up.right")
                }

                PremiumDivider()

                Link(destination: localizedURL(
                    en: "https://operatorx-tanktime.vercel.app/support.html",
                    fr: "https://operatorx-tanktime.vercel.app/support-fr.html"
                )) {
                    settingsRow(title: "Support", symbol: "questionmark.bubble.fill", trailingSymbol: "arrow.up.right")
                }

                Text("TankTime provides planning estimates only. Follow cylinder, appliance, fire-safety and local handling guidance.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .padding(.top, 4)
            }
        }
    }

    private func infoRow(title: LocalizedStringKey, value: String, symbol: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30, height: 30)
                .background(AppTheme.accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private func settingsRow(
        title: LocalizedStringKey,
        symbol: String,
        trailingSymbol: String
    ) -> some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 30, height: 30)
                .background(AppTheme.accent.opacity(0.11), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(AppTheme.textPrimary)
            Spacer()
            Image(systemName: trailingSymbol)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(AppTheme.textSecondary)
        }
        .contentShape(Rectangle())
    }
}

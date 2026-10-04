import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var consent: ConsentManager

    private func localizedURL(en: String, fr: String) -> URL {
        let language = Locale.current.language.languageCode?.identifier
        return URL(string: language == "fr" ? fr : en)!
    }

    var body: some View {
        Form {
            Section("Units") {
                Picker("Measurement system", selection: $store.unitSystem) {
                    Text("Imperial").tag(UnitSystem.imperial)
                    Text("Metric").tag(UnitSystem.metric)
                }
                .pickerStyle(.segmented)
                Text("TankTime stores normalized values internally and converts weight and power inputs for the selected system.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if consent.privacyOptionsRequired {
                Section("Privacy") {
                    Button("Manage ad privacy choices") {
                        Task { await consent.presentPrivacyOptions() }
                    }
                }
            }

            Section("About") {
                LabeledContent("App", value: "TankTime")
                LabeledContent("Version", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                Link("Privacy Policy", destination: localizedURL(
                    en: "https://operatorx-tanktime.vercel.app/privacy.html",
                    fr: "https://operatorx-tanktime.vercel.app/privacy-fr.html"
                ))
                Link("Terms of Use", destination: localizedURL(
                    en: "https://operatorx-tanktime.vercel.app/terms.html",
                    fr: "https://operatorx-tanktime.vercel.app/terms-fr.html"
                ))
                Link("Support", destination: localizedURL(
                    en: "https://operatorx-tanktime.vercel.app/support.html",
                    fr: "https://operatorx-tanktime.vercel.app/support-fr.html"
                ))
                Text("TankTime provides planning estimates only. Follow cylinder, appliance, fire-safety and local handling guidance.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Settings")
    }
}

import SwiftUI
import AppTrackingTransparency
import GoogleMobileAds
import UserMessagingPlatform

@MainActor
final class ConsentManager: ObservableObject {
    @Published private(set) var canRequestAds = false
    @Published private(set) var privacyOptionsRequired = false
    @Published private(set) var lastError: String?

    func gatherConsent() async {
        let parameters = RequestParameters()
        await withCheckedContinuation { continuation in
            ConsentInformation.shared.requestConsentInfoUpdate(with: parameters) { error in
                Task { @MainActor in
                    if let error { self.lastError = error.localizedDescription }
                    continuation.resume()
                }
            }
        }
        do {
            try await ConsentForm.loadAndPresentIfRequired(from: nil)
        } catch {
            lastError = error.localizedDescription
        }
        canRequestAds = ConsentInformation.shared.canRequestAds
        privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    func requestTrackingAuthorizationIfNeeded() async {
        guard #available(iOS 14, *),
              ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        await withCheckedContinuation { continuation in
            ATTrackingManager.requestTrackingAuthorization { _ in
                continuation.resume()
            }
        }
    }

    func presentPrivacyOptions() async {
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: nil)
            canRequestAds = ConsentInformation.shared.canRequestAds
            privacyOptionsRequired = ConsentInformation.shared.privacyOptionsRequirementStatus == .required
        } catch {
            lastError = error.localizedDescription
        }
    }
}


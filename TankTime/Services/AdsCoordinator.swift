import GoogleMobileAds
import UIKit

@MainActor
final class AdsCoordinator: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published private(set) var ready = false
    @Published private(set) var bannerUnitID = ""

    private var interstitial: InterstitialAd?
    private var savedCalculationCount = 0
    private var started = false

    func prepare(consent: ConsentManager) async {
        await consent.gatherConsent()
        guard consent.canRequestAds else { return }
        await consent.requestTrackingAuthorizationIfNeeded()
        startSDKIfNeeded()
        bannerUnitID = Bundle.main.object(forInfoDictionaryKey: "TankTimeBannerAdUnitID") as? String ?? ""
        await loadInterstitial()
        ready = !bannerUnitID.isEmpty
    }

    private func startSDKIfNeeded() {
        guard !started else { return }
        started = true
        MobileAds.shared.requestConfiguration.maxAdContentRating = GADMaxAdContentRating.general
        MobileAds.shared.requestConfiguration.publisherPrivacyPersonalizationState = .disabled
        MobileAds.shared.requestConfiguration.setPublisherFirstPartyIDEnabled(false)
        MobileAds.shared.start()
    }

    private func loadInterstitial() async {
        guard let unitID = Bundle.main.object(forInfoDictionaryKey: "TankTimeInterstitialAdUnitID") as? String,
              !unitID.isEmpty else { return }
        do {
            interstitial = try await InterstitialAd.load(with: unitID, request: Request())
            interstitial?.fullScreenContentDelegate = self
        } catch {
            interstitial = nil
        }
    }

    func calculationSaved() {
        savedCalculationCount += 1
        guard savedCalculationCount % 4 == 0, let interstitial else { return }
        interstitial.present(from: nil)
    }

    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        interstitial = nil
        Task { await loadInterstitial() }
    }

    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        interstitial = nil
        Task { await loadInterstitial() }
    }
}

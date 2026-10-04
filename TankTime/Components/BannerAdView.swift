import GoogleMobileAds
import SwiftUI

struct BannerAdView: View {
    @EnvironmentObject private var ads: AdsCoordinator

    var body: some View {
        if ads.ready, !ads.bannerUnitID.isEmpty {
            GeometryReader { proxy in
                let width = max(proxy.size.width, 320)
                let size = largeAnchoredAdaptiveBanner(width: width)
                BannerContainer(adSize: size, unitID: ads.bannerUnitID)
                    .frame(width: size.size.width, height: size.size.height)
                    .frame(maxWidth: .infinity)
            }
            .frame(height: 100)
        }
    }
}

private struct BannerContainer: UIViewRepresentable {
    let adSize: AdSize
    let unitID: String

    func makeUIView(context: Context) -> BannerView {
        let view = BannerView(adSize: adSize)
        view.adUnitID = unitID
        view.load(Request())
        return view
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        if uiView.adUnitID != unitID {
            uiView.adUnitID = unitID
            uiView.load(Request())
        }
    }
}

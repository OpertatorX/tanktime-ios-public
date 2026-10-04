import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore

    private var isMetric: Bool { store.unitSystem == .metric }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PremiumPageHeader(
                    eyebrow: "Saved results",
                    title: "Your runtime history",
                    subtitle: "A clean record of the estimates you chose to keep.",
                    symbol: "clock.arrow.circlepath"
                )
                .padding(.bottom, 4)

                if store.history.isEmpty {
                    emptyState
                } else {
                    VStack(spacing: 12) {
                        ForEach(store.history) { item in
                            historyCard(item)
                        }
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.backdrop.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
    }

    private var emptyState: some View {
        PremiumCard(padding: 24) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.12))
                    Image(systemName: "bookmark")
                        .font(.system(size: 25, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
                .frame(width: 64, height: 64)

                Text("No saved calculations")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("Save a runtime estimate and it will appear here.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
        }
    }

    private func historyCard(_ item: FuelCalculation) -> some View {
        PremiumCard(padding: 16) {
            VStack(spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(AppTheme.accent.opacity(0.12))
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundStyle(AppTheme.accent)
                    }
                    .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.tankName)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                        Text(LocalizedStringKey(item.applianceName))
                            .font(.system(size: 13, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 6) {
                        Text(item.date, style: .date)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        Menu {
                            Button(role: .destructive) {
                                delete(item)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundStyle(AppTheme.textSecondary)
                                .frame(width: 32, height: 26)
                        }
                    }
                }

                PremiumDivider()

                HStack(spacing: 10) {
                    MetricTile(title: "Fuel left", value: fuelText(item), symbol: "drop.fill")
                    MetricTile(
                        title: "Estimated runtime",
                        value: "\(item.runtimeHours.formatted(.number.precision(.fractionLength(1)))) h",
                        symbol: "clock.fill"
                    )
                }
            }
        }
    }

    private func delete(_ item: FuelCalculation) {
        guard let index = store.history.firstIndex(where: { $0.id == item.id }) else { return }
        withAnimation(.snappy(duration: 0.25)) {
            store.deleteHistory(IndexSet(integer: index))
        }
    }

    private func fuelText(_ item: FuelCalculation) -> String {
        if isMetric {
            let kg = item.fuelRemainingLb / PropaneMath.poundsPerKilogram
            return "\(kg.formatted(.number.precision(.fractionLength(1)))) kg"
        }
        return "\(item.fuelRemainingLb.formatted(.number.precision(.fractionLength(1)))) lb"
    }
}

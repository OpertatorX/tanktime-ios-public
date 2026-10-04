import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var store: AppStore

    private var isMetric: Bool { store.unitSystem == .metric }

    var body: some View {
        Group {
            if store.history.isEmpty {
                ContentUnavailableView(
                    "No saved calculations",
                    systemImage: "clock.arrow.circlepath",
                    description: Text("Save a runtime estimate and it will appear here.")
                )
            } else {
                List {
                    ForEach(store.history) { item in
                        VStack(alignment: .leading, spacing: 7) {
                            HStack {
                                Text(item.tankName).font(.headline)
                                Spacer()
                                Text(item.date, style: .date).font(.caption).foregroundStyle(.secondary)
                            }
                            Text(LocalizedStringKey(item.applianceName)).font(.subheadline).foregroundStyle(.secondary)
                            HStack(spacing: 18) {
                                Label(fuelText(item), systemImage: "drop.fill")
                                Label("\(item.runtimeHours.formatted(.number.precision(.fractionLength(1)))) h", systemImage: "clock")
                            }
                            .font(.caption.weight(.semibold))
                        }
                        .padding(.vertical, 5)
                    }
                    .onDelete(perform: store.deleteHistory)
                }
            }
        }
        .navigationTitle("History")
    }

    private func fuelText(_ item: FuelCalculation) -> String {
        if isMetric {
            let kg = item.fuelRemainingLb / PropaneMath.poundsPerKilogram
            return "\(kg.formatted(.number.precision(.fractionLength(1)))) kg"
        }
        return "\(item.fuelRemainingLb.formatted(.number.precision(.fractionLength(1)))) lb"
    }
}

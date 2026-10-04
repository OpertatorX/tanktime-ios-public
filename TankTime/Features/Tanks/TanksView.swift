import SwiftUI

struct TanksView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAdd = false

    private var isMetric: Bool { store.unitSystem == .metric }

    var body: some View {
        List {
            ForEach(store.tanks) { tank in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "cylinder.fill")
                        Text(tank.name).font(.headline)
                    }
                    HStack(spacing: 16) {
                        Label(capacityText(tank), systemImage: "scalemass")
                        Label(tareText(tank), systemImage: "tag")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.vertical, 6)
            }
            .onDelete(perform: store.deleteTank)
        }
        .navigationTitle("Tanks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingAdd = true } label: { Image(systemName: "plus") }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddTankView(unitSystem: store.unitSystem) { tank in
                store.tanks.append(tank)
                showingAdd = false
            }
        }
    }

    private func capacityText(_ tank: TankProfile) -> String {
        if isMetric {
            let kg = tank.capacityLb / PropaneMath.poundsPerKilogram
            return "\(kg.formatted(.number.precision(.fractionLength(1)))) kg \(String(localized: "capacity"))"
        }
        return "\(tank.capacityLb.formatted(.number.precision(.fractionLength(0)))) lb \(String(localized: "capacity"))"
    }

    private func tareText(_ tank: TankProfile) -> String {
        if isMetric {
            let kg = tank.tareWeightLb / PropaneMath.poundsPerKilogram
            return "TW \(kg.formatted(.number.precision(.fractionLength(1)))) kg"
        }
        return "TW \(tank.tareWeightLb.formatted(.number.precision(.fractionLength(1)))) lb"
    }
}

private struct AddTankView: View {
    @Environment(\.dismiss) private var dismiss
    let unitSystem: UnitSystem
    @State private var name = ""
    @State private var capacity = ""
    @State private var tare = ""
    let onSave: (TankProfile) -> Void

    private var isMetric: Bool { unitSystem == .metric }
    private var unit: String { isMetric ? "kg" : "lb" }
    private var capacityLabel: String { "\(String(localized: "Capacity")) (\(unit))" }
    private var tareLabel: String { "\(String(localized: "Tare weight")) (\(unit))" }

    var body: some View {
        NavigationStack {
            Form {
                Section("Cylinder") {
                    HStack(spacing: 16) {
                        Text("Name")
                        Spacer(minLength: 12)
                        TextField("—", text: $name)
                            .multilineTextAlignment(.trailing)
                            .frame(minWidth: 100, maxWidth: 190)
                            .accessibilityLabel(String(localized: "Name"))
                    }
                    numericRow(capacityLabel, text: $capacity)
                    numericRow(tareLabel, text: $tare)
                }
            }
            .navigationTitle("New tank")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let enteredCapacity = Double(capacity.replacingOccurrences(of: ",", with: ".")),
                              let enteredTare = Double(tare.replacingOccurrences(of: ",", with: ".")),
                              enteredCapacity > 0, enteredTare >= 0 else { return }
                        let multiplier = isMetric ? PropaneMath.poundsPerKilogram : 1
                        let finalName = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? String(localized: "Standard cylinder") : name
                        onSave(TankProfile(
                            name: finalName,
                            capacityLb: enteredCapacity * multiplier,
                            tareWeightLb: enteredTare * multiplier
                        ))
                    }
                }
            }
        }
    }

    private func numericRow(_ title: String, text: Binding<String>) -> some View {
        HStack(spacing: 16) {
            Text(title)
            Spacer(minLength: 12)
            TextField("0", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 72, maxWidth: 150)
                .accessibilityLabel(title)
        }
    }
}

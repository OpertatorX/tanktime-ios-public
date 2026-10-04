import SwiftUI

struct CalculatorView: View {
    @EnvironmentObject private var store: AppStore
    @EnvironmentObject private var ads: AdsCoordinator

    @State private var selectedTankID: UUID?
    @State private var selectedApplianceID: UUID?
    @State private var scaleWeight = ""
    @State private var customPower = ""
    @State private var hoursPerDay = "2"
    @State private var result: ResultSnapshot?

    private var tank: TankProfile? {
        store.tanks.first(where: { $0.id == selectedTankID }) ?? store.tanks.first
    }

    private var appliance: AppliancePreset? {
        store.appliances.first(where: { $0.id == selectedApplianceID }) ?? store.appliances.first
    }

    private var isMetric: Bool { store.unitSystem == .metric }
    private var weightUnit: String { isMetric ? "kg" : "lb" }
    private var weightLabel: String { "\(String(localized: "Current scale weight")) (\(weightUnit))" }
    private var powerLabel: String { isMetric ? "\(String(localized: "Power override")) (kW)" : String(localized: "BTU per hour (optional override)") }

    var body: some View {
        Form {
            Section("Tank") {
                Picker("Cylinder", selection: $selectedTankID) {
                    ForEach(store.tanks) { tank in
                        Text(tank.name).tag(Optional(tank.id))
                    }
                }
                numericRow(weightLabel, text: $scaleWeight, placeholder: "0")
            }

            Section("Appliance") {
                Picker("Preset", selection: $selectedApplianceID) {
                    ForEach(store.appliances) { appliance in
                        Label(appliance.localizedName, systemImage: appliance.symbol)
                            .tag(Optional(appliance.id))
                    }
                }
                numericRow(powerLabel, text: $customPower, placeholder: "—")
                numericRow(String(localized: "Hours used per day"), text: $hoursPerDay, placeholder: "0")
            }

            Section {
                Button(action: calculate) {
                    Label("Calculate runtime", systemImage: "equal.circle.fill")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }

            if let result {
                ResultCard(result: result, onSave: saveResult)
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
        }
        .navigationTitle("TankTime")
        .onAppear(perform: prepareInitialState)
    }

    private func numericRow(_ title: String, text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 16) {
            Text(title)
                .foregroundStyle(.primary)
            Spacer(minLength: 12)
            TextField(placeholder, text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(minWidth: 72, maxWidth: 150)
                .accessibilityLabel(title)
        }
    }

    private func prepareInitialState() {
        if selectedTankID == nil {
            selectedTankID = store.tanks.first?.id
        }
        if selectedApplianceID == nil {
            selectedApplianceID = store.appliances.first?.id
        }
        guard LaunchConfig.screenshotMode else { return }
        selectedTankID = store.tanks.first?.id
        let furnace = store.appliances.first(where: { $0.name == "RV furnace" })
        selectedApplianceID = furnace?.id ?? store.appliances.first?.id
        scaleWeight = isMetric ? "19.1" : "42"
        hoursPerDay = "3"
        DispatchQueue.main.async { calculate() }
    }

    private func calculate() {
        guard let tank, let appliance,
              let enteredWeight = Double(scaleWeight.replacingOccurrences(of: ",", with: ".")) else { return }
        let weightLb = isMetric ? enteredWeight * PropaneMath.poundsPerKilogram : enteredWeight
        let enteredPower = Double(customPower.replacingOccurrences(of: ",", with: "."))
        let drawBTU = enteredPower.map { isMetric ? $0 * 3_412.142 : $0 } ?? appliance.btuPerHour
        let fuel = PropaneMath.remainingFuelLb(
            scaleWeightLb: weightLb,
            tareWeightLb: tank.tareWeightLb,
            capacityLb: tank.capacityLb
        )
        let runtime = PropaneMath.runtimeHours(fuelLb: fuel, btuPerHour: drawBTU)
        let fraction = PropaneMath.fillFraction(fuelLb: fuel, capacityLb: tank.capacityLb)
        let daily = max(Double(hoursPerDay.replacingOccurrences(of: ",", with: ".")) ?? 1, 0.1)
        result = ResultSnapshot(
            tank: tank,
            appliance: appliance,
            fuelLb: fuel,
            fillFraction: fraction,
            runtimeHours: runtime,
            daysAtUsage: runtime / daily,
            drawBTU: drawBTU,
            unitSystem: store.unitSystem
        )
    }

    private func saveResult() {
        guard let result else { return }
        store.addHistory(.init(
            tankName: result.tank.name,
            applianceName: result.appliance.name,
            fuelRemainingLb: result.fuelLb,
            drawBTUPerHour: result.drawBTU,
            runtimeHours: result.runtimeHours
        ))
        ads.calculationSaved()
    }
}

private struct ResultSnapshot {
    let tank: TankProfile
    let appliance: AppliancePreset
    let fuelLb: Double
    let fillFraction: Double
    let runtimeHours: Double
    let daysAtUsage: Double
    let drawBTU: Double
    let unitSystem: UnitSystem

    var fuelDisplay: String {
        if unitSystem == .metric {
            let kg = fuelLb / PropaneMath.poundsPerKilogram
            return "\(kg.formatted(.number.precision(.fractionLength(1)))) kg"
        }
        return "\(fuelLb.formatted(.number.precision(.fractionLength(1)))) lb"
    }
}

private struct ResultCard: View {
    let result: ResultSnapshot
    let onSave: () -> Void

    var shareText: String {
        "TankTime — \(result.tank.name): \(result.fuelDisplay) remaining, about \(result.runtimeHours.formatted(.number.precision(.fractionLength(1)))) hours with \(result.appliance.localizedName)."
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated runtime").font(.subheadline).foregroundStyle(.secondary)
                    Text("\(result.runtimeHours.formatted(.number.precision(.fractionLength(1)))) h")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                }
                Spacer()
                Gauge(value: result.fillFraction) { EmptyView() }
                    .gaugeStyle(.accessoryCircularCapacity)
                    .tint(Color(red: 0.78, green: 0.49, blue: 0.18))
            }
            HStack {
                metric("Fuel left", result.fuelDisplay)
                Spacer()
                metric("Tank", "\((result.fillFraction * 100).formatted(.number.precision(.fractionLength(0))))%")
                Spacer()
                metric("At usage", "\(result.daysAtUsage.formatted(.number.precision(.fractionLength(1)))) days")
            }
            HStack {
                Button("Save result", action: onSave)
                    .buttonStyle(.borderedProminent)
                ShareLink(item: shareText) {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
            }
            Text("Planning estimate only. Confirm appliance ratings and cylinder markings before use.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func metric(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(title)).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.headline)
        }
    }
}

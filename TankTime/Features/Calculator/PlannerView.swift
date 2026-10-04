import SwiftUI

struct PlannerView: View {
    @EnvironmentObject private var store: AppStore

    @State private var selectedTankID: UUID?
    @State private var currentWeight = ""
    @State private var tripDays = "3"
    @State private var reservePercent = "20"
    @State private var pricePerUnit = ""
    @State private var enabledAppliances: Set<UUID> = []
    @State private var hoursByAppliance: [UUID: String] = [:]
    @State private var result: PlanSnapshot?

    private var tank: TankProfile? {
        store.tanks.first(where: { $0.id == selectedTankID }) ?? store.tanks.first
    }

    private var isMetric: Bool { store.unitSystem == .metric }
    private var weightUnit: String { isMetric ? "kg" : "lb" }
    private var currentWeightLabel: String { "\(String(localized: "Current scale weight")) (\(weightUnit))" }
    private var fuelPriceLabel: String { isMetric ? String(localized: "Fuel price per kg (optional)") : String(localized: "Fuel price per lb (optional)") }

    var body: some View {
        Form {
            tankSection
            tripSection
            if LaunchConfig.screenshotMode, let result {
                PlanResultCard(result: result)
            }
            loadsSection
            actionSection
            if !LaunchConfig.screenshotMode, let result {
                PlanResultCard(result: result)
            }
        }
        .navigationTitle("Plan")
        .onAppear {
            if selectedTankID == nil { selectedTankID = store.tanks.first?.id }
            if enabledAppliances.isEmpty, let first = store.appliances.first {
                enabledAppliances.insert(first.id)
                hoursByAppliance[first.id] = "1"
            }
            if LaunchConfig.screenshotMode {
                selectedTankID = store.tanks.first?.id
                currentWeight = isMetric ? "19.1" : "42"
                tripDays = "4"
                reservePercent = "20"
                pricePerUnit = isMetric ? "1.85" : "0.84"
                enabledAppliances.removeAll()
                for appliance in store.appliances where appliance.name == "RV furnace" || appliance.name == "Camp stove" {
                    enabledAppliances.insert(appliance.id)
                    hoursByAppliance[appliance.id] = appliance.name == "RV furnace" ? "2.5" : "0.6"
                }
                DispatchQueue.main.async { calculate() }
            }
        }
    }

    private var tankSection: some View {
        Section("Starting tank") {
            Picker("Cylinder", selection: $selectedTankID) {
                ForEach(store.tanks) { tank in
                    Text(tank.name).tag(Optional(tank.id))
                }
            }
            numericRow(currentWeightLabel, text: $currentWeight, placeholder: "0")
        }
    }

    private var tripSection: some View {
        Section("Trip") {
            numericRow(String(localized: "Trip length (days)"), text: $tripDays, placeholder: "0")
            numericRow(String(localized: "Reserve (%)"), text: $reservePercent, placeholder: "0")
            numericRow(fuelPriceLabel, text: $pricePerUnit, placeholder: "—")
        }
    }

    private var loadsSection: some View {
        Section("Daily loads") {
            ForEach(store.appliances) { appliance in
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: enabledBinding(for: appliance.id)) {
                        Label(appliance.localizedName, systemImage: appliance.symbol)
                    }
                    if enabledAppliances.contains(appliance.id) {
                        numericRow(String(localized: "Hours per day"), text: hoursBinding(for: appliance.id), placeholder: "0")
                    }
                }
            }
        }
    }

    private var actionSection: some View {
        Section {
            Button(action: calculate) {
                Label("Build fuel plan", systemImage: "map.fill")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(enabledAppliances.isEmpty)
        }
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

    private func enabledBinding(for id: UUID) -> Binding<Bool> {
        Binding(
            get: { enabledAppliances.contains(id) },
            set: { enabled in
                if enabled {
                    enabledAppliances.insert(id)
                    if hoursByAppliance[id] == nil { hoursByAppliance[id] = "1" }
                } else {
                    enabledAppliances.remove(id)
                }
            }
        )
    }

    private func hoursBinding(for id: UUID) -> Binding<String> {
        Binding(
            get: { hoursByAppliance[id] ?? "1" },
            set: { hoursByAppliance[id] = $0 }
        )
    }

    private func calculate() {
        guard let tank,
              let enteredWeight = number(currentWeight),
              let days = number(tripDays), days > 0 else { return }

        let currentWeightLb = isMetric
            ? enteredWeight * PropaneMath.poundsPerKilogram
            : enteredWeight
        let currentFuelLb = PropaneMath.remainingFuelLb(
            scaleWeightLb: currentWeightLb,
            tareWeightLb: tank.tareWeightLb,
            capacityLb: tank.capacityLb
        )

        let loads = store.appliances.compactMap { appliance -> (btuPerHour: Double, hoursPerDay: Double)? in
            guard enabledAppliances.contains(appliance.id) else { return nil }
            let hours = max(number(hoursByAppliance[appliance.id] ?? "") ?? 0, 0)
            guard hours > 0 else { return nil }
            return (btuPerHour: appliance.btuPerHour, hoursPerDay: hours)
        }

        let dailyBurn = PropaneMath.dailyFuelBurnLb(loads: loads)
        guard dailyBurn > 0 else { return }
        let reserve = min(max((number(reservePercent) ?? 20) / 100, 0), 0.95)
        let required = PropaneMath.requiredFuelLb(
            dailyBurnLb: dailyBurn,
            tripDays: days,
            reserveFraction: reserve
        )
        let extras = PropaneMath.cylindersNeeded(
            requiredFuelLb: required,
            usableCurrentFuelLb: currentFuelLb,
            fullCylinderCapacityLb: tank.capacityLb
        )
        let enteredPrice = max(number(pricePerUnit) ?? 0, 0)
        let pricePerLb = isMetric ? enteredPrice / PropaneMath.poundsPerKilogram : enteredPrice
        let fuelToAcquire = PropaneMath.fuelToAcquireLb(requiredFuelLb: required, currentFuelLb: currentFuelLb)
        let projectedCost = PropaneMath.projectedCost(requiredFuelLb: fuelToAcquire, pricePerLb: pricePerLb)

        result = PlanSnapshot(
            tank: tank,
            currentFuelLb: currentFuelLb,
            dailyBurnLb: dailyBurn,
            requiredFuelLb: required,
            tripDays: days,
            reserveFraction: reserve,
            extraCylinders: extras,
            projectedCost: projectedCost,
            unitSystem: store.unitSystem
        )
    }

    private func number(_ text: String) -> Double? {
        Double(text.replacingOccurrences(of: ",", with: "."))
    }
}

private struct PlanSnapshot {
    let tank: TankProfile
    let currentFuelLb: Double
    let dailyBurnLb: Double
    let requiredFuelLb: Double
    let tripDays: Double
    let reserveFraction: Double
    let extraCylinders: Int
    let projectedCost: Double
    let unitSystem: UnitSystem

    var currentCoverageDays: Double {
        guard dailyBurnLb > 0 else { return 0 }
        return currentFuelLb / dailyBurnLb
    }

    func weightDisplay(_ pounds: Double) -> String {
        if unitSystem == .metric {
            let kg = pounds / PropaneMath.poundsPerKilogram
            return "\(kg.formatted(.number.precision(.fractionLength(1)))) kg"
        }
        return "\(pounds.formatted(.number.precision(.fractionLength(1)))) lb"
    }
}

private struct PlanResultCard: View {
    let result: PlanSnapshot

    private var shareText: String {
        "\(String(localized: "TankTime plan")): \(result.tripDays.formatted(.number.precision(.fractionLength(1)))) \(String(localized: "days")), \(result.weightDisplay(result.requiredFuelLb)) \(String(localized: "required")), \(result.extraCylinders) \(String(localized: "extra cylinders"))."
    }

    var body: some View {
        Section("Fuel plan") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Extra cylinders").font(.subheadline).foregroundStyle(.secondary)
                        Text("\(result.extraCylinders)")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                    }
                    Spacer()
                    Image(systemName: result.extraCylinders == 0 ? "checkmark.seal.fill" : "cylinder.fill")
                        .font(.largeTitle)
                        .foregroundStyle(Color(red: 0.78, green: 0.49, blue: 0.18))
                }
                metric("Current fuel", result.weightDisplay(result.currentFuelLb))
                metric("Daily burn", result.weightDisplay(result.dailyBurnLb))
                metric("Fuel required", result.weightDisplay(result.requiredFuelLb))
                metric("Current tank covers", "\(result.currentCoverageDays.formatted(.number.precision(.fractionLength(1)))) \(String(localized: "days"))")
                metric("Reserve", "\((result.reserveFraction * 100).formatted(.number.precision(.fractionLength(0))))%")
                if result.projectedCost > 0 {
                    metric("Projected fuel cost", result.projectedCost.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                }
                ShareLink(item: shareText) {
                    Label("Share plan", systemImage: "square.and.arrow.up")
                }
                .buttonStyle(.bordered)
                Text("Planning estimate only. Real consumption changes with duty cycle, weather, regulator performance and appliance load.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 8)
        }
    }

    private func metric(_ title: String, _ value: String) -> some View {
        HStack {
            Text(LocalizedStringKey(title)).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold)
        }
    }
}

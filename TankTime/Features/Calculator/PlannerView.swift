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
    private var priceUnit: String { isMetric ? "/kg" : "/lb" }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PremiumPageHeader(
                    eyebrow: "Trip planning",
                    title: "Leave with enough fuel",
                    subtitle: "Build a practical reserve around the way you actually use your appliances.",
                    symbol: "map.fill"
                )
                .padding(.bottom, 4)

                startingTankCard
                tripCard
                loadsCard

                PrimaryActionButton(
                    title: "Build fuel plan",
                    symbol: "arrow.right",
                    disabled: enabledAppliances.isEmpty
                ) {
                    withAnimation(.snappy(duration: 0.35)) {
                        calculate()
                    }
                }

                if let result {
                    PlanResultCard(result: result)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 18)
            .padding(.bottom, 24)
        }
        .scrollIndicators(.hidden)
        .background(AppTheme.backdrop.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .onAppear(perform: prepareInitialState)
    }

    private var startingTankCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                PremiumSectionTitle(title: "Starting tank", caption: "Today")

                Menu {
                    ForEach(store.tanks) { option in
                        Button {
                            selectedTankID = option.id
                        } label: {
                            if option.id == tank?.id {
                                Label(option.name, systemImage: "checkmark")
                            } else {
                                Text(option.name)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 13) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(AppTheme.accent.opacity(0.12))
                            Image(systemName: "cylinder.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.accent)
                        }
                        .frame(width: 42, height: 42)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Cylinder")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(tank?.name ?? String(localized: "Standard cylinder"))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        Spacer()
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    .padding(12)
                    .background(AppTheme.background.opacity(0.58), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                PremiumTextField(
                    title: "Current scale weight",
                    text: $currentWeight,
                    placeholder: "0",
                    suffix: weightUnit
                )
            }
        }
    }

    private var tripCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                PremiumSectionTitle(title: "Trip", caption: "Plan buffer")

                HStack(alignment: .top, spacing: 12) {
                    PremiumTextField(title: "Trip length (days)", text: $tripDays, placeholder: "0", suffix: "d")
                    PremiumTextField(title: "Reserve (%)", text: $reservePercent, placeholder: "0", suffix: "%")
                }

                PremiumTextField(
                    title: isMetric ? "Fuel price per kg (optional)" : "Fuel price per lb (optional)",
                    text: $pricePerUnit,
                    placeholder: "—",
                    suffix: priceUnit
                )
            }
        }
    }

    private var loadsCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 14) {
                PremiumSectionTitle(title: "Daily loads", caption: "Tap to include")

                ForEach(Array(store.appliances.enumerated()), id: \.element.id) { index, appliance in
                    VStack(spacing: 11) {
                        Button {
                            withAnimation(.snappy(duration: 0.25)) {
                                let enabled = !enabledAppliances.contains(appliance.id)
                                enabledBinding(for: appliance.id).wrappedValue = enabled
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(enabledAppliances.contains(appliance.id) ? AppTheme.accent.opacity(0.14) : AppTheme.background.opacity(0.55))
                                    Image(systemName: appliance.symbol)
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundStyle(enabledAppliances.contains(appliance.id) ? AppTheme.accent : AppTheme.textSecondary)
                                }
                                .frame(width: 40, height: 40)

                                Text(appliance.localizedName)
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppTheme.textPrimary)
                                Spacer()

                                Image(systemName: enabledAppliances.contains(appliance.id) ? "checkmark.circle.fill" : "circle")
                                    .font(.system(size: 19, weight: .semibold))
                                    .foregroundStyle(enabledAppliances.contains(appliance.id) ? AppTheme.accent : AppTheme.textSecondary.opacity(0.55))
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if enabledAppliances.contains(appliance.id) {
                            PremiumTextField(
                                title: "Hours per day",
                                text: hoursBinding(for: appliance.id),
                                placeholder: "0",
                                suffix: "h"
                            )
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }

                    if index < store.appliances.count - 1 {
                        PremiumDivider()
                    }
                }
            }
        }
    }

    private func prepareInitialState() {
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
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Extra cylinders")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(0.7)
                            .textCase(.uppercase)
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\(result.extraCylinders)")
                            .font(.system(size: 46, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    Spacer()
                    ZStack {
                        Circle()
                            .fill((result.extraCylinders == 0 ? AppTheme.success : AppTheme.accent).opacity(0.13))
                        Image(systemName: result.extraCylinders == 0 ? "checkmark.seal.fill" : "cylinder.fill")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(result.extraCylinders == 0 ? AppTheme.success : AppTheme.accent)
                    }
                    .frame(width: 64, height: 64)
                }

                PremiumDivider()

                HStack(spacing: 10) {
                    MetricTile(title: "Current fuel", value: result.weightDisplay(result.currentFuelLb), symbol: "drop.fill")
                    MetricTile(title: "Daily burn", value: result.weightDisplay(result.dailyBurnLb), symbol: "flame.fill")
                }
                HStack(spacing: 10) {
                    MetricTile(title: "Fuel required", value: result.weightDisplay(result.requiredFuelLb), symbol: "shippingbox.fill")
                    MetricTile(
                        title: "Current tank covers",
                        value: "\(result.currentCoverageDays.formatted(.number.precision(.fractionLength(1)))) d",
                        symbol: "calendar"
                    )
                }

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reserve")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(AppTheme.textSecondary)
                        Text("\((result.reserveFraction * 100).formatted(.number.precision(.fractionLength(0))))%")
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundStyle(AppTheme.textPrimary)
                    }
                    Spacer()
                    if result.projectedCost > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Projected fuel cost")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(result.projectedCost.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD")))
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                    }
                }

                ShareLink(item: shareText) {
                    Label("Share plan", systemImage: "square.and.arrow.up")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .foregroundStyle(AppTheme.textPrimary)
                        .background(AppTheme.surfaceStrong, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                }

                Text("Planning estimate only. Real consumption changes with duty cycle, weather, regulator performance and appliance load.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

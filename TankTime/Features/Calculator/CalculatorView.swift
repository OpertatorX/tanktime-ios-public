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
    private var powerUnit: String { isMetric ? "kW" : "BTU/h" }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                PremiumPageHeader(
                    eyebrow: "TankTime",
                    title: "Know what your tank can do",
                    subtitle: "Fast runtime estimates without the spreadsheet feel.",
                    symbol: "flame.fill"
                )
                .padding(.bottom, 4)

                tankCard
                applianceCard

                PrimaryActionButton(
                    title: "Calculate runtime",
                    symbol: "arrow.right"
                ) {
                    withAnimation(.snappy(duration: 0.35)) {
                        calculate()
                    }
                }

                if let result {
                    ResultCard(result: result, onSave: saveResult)
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

    private var tankCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                PremiumSectionTitle(title: "Tank", caption: "Starting point")

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
                    text: $scaleWeight,
                    placeholder: "0",
                    suffix: weightUnit
                )
            }
        }
    }

    private var applianceCard: some View {
        PremiumCard {
            VStack(alignment: .leading, spacing: 16) {
                PremiumSectionTitle(title: "Appliance", caption: "Daily use")

                Menu {
                    ForEach(store.appliances) { option in
                        Button {
                            selectedApplianceID = option.id
                        } label: {
                            Label(option.localizedName, systemImage: option.symbol)
                        }
                    }
                } label: {
                    HStack(spacing: 13) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 13, style: .continuous)
                                .fill(Color.white.opacity(0.07))
                            Image(systemName: appliance?.symbol ?? "flame")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                        }
                        .frame(width: 42, height: 42)

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Preset")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                            Text(appliance?.localizedName ?? "—")
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

                HStack(alignment: .top, spacing: 12) {
                    PremiumTextField(
                        title: "Power override",
                        text: $customPower,
                        placeholder: "—",
                        suffix: powerUnit
                    )
                    PremiumTextField(
                        title: "Hours used per day",
                        text: $hoursPerDay,
                        placeholder: "0",
                        suffix: "h"
                    )
                }
            }
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

    private var shareText: String {
        "TankTime — \(result.tank.name): \(result.fuelDisplay) remaining, about \(result.runtimeHours.formatted(.number.precision(.fractionLength(1)))) hours with \(result.appliance.localizedName)."
    }

    var body: some View {
        PremiumCard(padding: 20) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 16) {
                    VStack(alignment: .leading, spacing: 5) {
                        Text("Estimated runtime")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .tracking(0.7)
                            .textCase(.uppercase)
                            .foregroundStyle(AppTheme.textSecondary)
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(result.runtimeHours.formatted(.number.precision(.fractionLength(1))))
                                .font(.system(size: 46, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("h")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.accent)
                        }
                    }
                    Spacer()
                    FuelRing(progress: result.fillFraction)
                }

                PremiumDivider()

                HStack(spacing: 10) {
                    MetricTile(title: "Fuel left", value: result.fuelDisplay, symbol: "drop.fill")
                    MetricTile(
                        title: "Tank",
                        value: "\((result.fillFraction * 100).formatted(.number.precision(.fractionLength(0))))%",
                        symbol: "cylinder.fill"
                    )
                    MetricTile(
                        title: "At usage",
                        value: "\(result.daysAtUsage.formatted(.number.precision(.fractionLength(1)))) d",
                        symbol: "calendar"
                    )
                }

                HStack(spacing: 10) {
                    Button(action: onSave) {
                        Label("Save result", systemImage: "bookmark.fill")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .frame(maxWidth: .infinity)
                            .frame(height: 48)
                            .background(AppTheme.accentGradient, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)

                    ShareLink(item: shareText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 48, height: 48)
                            .foregroundStyle(AppTheme.textPrimary)
                            .background(AppTheme.surfaceStrong, in: RoundedRectangle(cornerRadius: 15, style: .continuous))
                    }
                }

                Text("Planning estimate only. Confirm appliance ratings and cylinder markings before use.")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

private struct FuelRing: View {
    let progress: Double

    private var normalized: Double {
        min(max(progress, 0), 1)
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 8)
            Circle()
                .trim(from: 0, to: normalized)
                .stroke(AppTheme.accentGradient, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text("\((normalized * 100).formatted(.number.precision(.fractionLength(0))))")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.textPrimary)
                Text("%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .frame(width: 78, height: 78)
        .accessibilityLabel("Tank fill")
        .accessibilityValue("\((normalized * 100).formatted(.number.precision(.fractionLength(0)))) percent")
    }
}

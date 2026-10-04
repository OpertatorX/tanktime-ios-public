import SwiftUI

struct TanksView: View {
    @EnvironmentObject private var store: AppStore
    @State private var showingAdd = false

    private var isMetric: Bool { store.unitSystem == .metric }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                HStack(alignment: .bottom) {
                    PremiumPageHeader(
                        eyebrow: "Tank library",
                        title: "Your cylinders",
                        subtitle: "Keep the real tare and capacity values you use most.",
                        symbol: "cylinder.fill"
                    )
                    Spacer(minLength: 8)
                }

                Button {
                    showingAdd = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "plus")
                            .font(.system(size: 15, weight: .bold))
                            .frame(width: 36, height: 36)
                            .background(AppTheme.accent.opacity(0.14), in: Circle())
                        Text("New tank")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(AppTheme.textPrimary)
                    .padding(.horizontal, 14)
                    .frame(height: 60)
                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 19, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 19, style: .continuous)
                            .stroke(AppTheme.border, lineWidth: 1)
                    }
                }
                .buttonStyle(.plain)

                VStack(spacing: 12) {
                    ForEach(store.tanks) { tank in
                        tankCard(tank)
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
        .sheet(isPresented: $showingAdd) {
            AddTankView(unitSystem: store.unitSystem) { tank in
                store.tanks.append(tank)
                showingAdd = false
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(30)
        }
    }

    private func tankCard(_ tank: TankProfile) -> some View {
        PremiumCard(padding: 16) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .fill(AppTheme.accent.opacity(0.12))
                    Image(systemName: "cylinder.fill")
                        .font(.system(size: 21, weight: .bold))
                        .foregroundStyle(AppTheme.accent)
                }
                .frame(width: 54, height: 54)

                VStack(alignment: .leading, spacing: 7) {
                    Text(tank.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)

                    HStack(spacing: 8) {
                        infoChip(capacityText(tank), symbol: "scalemass.fill")
                        infoChip(tareText(tank), symbol: "tag.fill")
                    }
                }

                Spacer(minLength: 6)

                Menu {
                    Button(role: .destructive) {
                        delete(tank)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(AppTheme.textSecondary)
                        .frame(width: 38, height: 38)
                        .background(AppTheme.background.opacity(0.52), in: Circle())
                }
            }
        }
    }

    private func infoChip(_ text: String, symbol: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
            Text(text)
                .lineLimit(1)
        }
        .font(.system(size: 10, weight: .semibold, design: .rounded))
        .foregroundStyle(AppTheme.textSecondary)
    }

    private func delete(_ tank: TankProfile) {
        guard let index = store.tanks.firstIndex(where: { $0.id == tank.id }) else { return }
        withAnimation(.snappy(duration: 0.25)) {
            store.deleteTank(at: IndexSet(integer: index))
        }
    }

    private func capacityText(_ tank: TankProfile) -> String {
        if isMetric {
            let kg = tank.capacityLb / PropaneMath.poundsPerKilogram
            return "\(kg.formatted(.number.precision(.fractionLength(1)))) kg"
        }
        return "\(tank.capacityLb.formatted(.number.precision(.fractionLength(0)))) lb"
    }

    private func tareText(_ tank: TankProfile) -> String {
        if isMetric {
            let kg = tank.tareWeightLb / PropaneMath.poundsPerKilogram
            return "TW \(kg.formatted(.number.precision(.fractionLength(1))))"
        }
        return "TW \(tank.tareWeightLb.formatted(.number.precision(.fractionLength(1))))"
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

    var body: some View {
        ZStack {
            AppTheme.backdrop.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("New tank")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundStyle(AppTheme.textPrimary)
                            Text("Add the values printed on your cylinder.")
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(AppTheme.textPrimary)
                                .frame(width: 38, height: 38)
                                .background(AppTheme.surfaceStrong, in: Circle())
                        }
                        .buttonStyle(.plain)
                    }

                    PremiumCard {
                        VStack(spacing: 15) {
                            PremiumTextField(
                                title: "Name",
                                text: $name,
                                placeholder: "Standard cylinder",
                                keyboard: .default
                            )
                            PremiumTextField(title: "Capacity", text: $capacity, placeholder: "0", suffix: unit)
                            PremiumTextField(title: "Tare weight", text: $tare, placeholder: "0", suffix: unit)
                        }
                    }

                    PrimaryActionButton(title: "Save", symbol: "checkmark") {
                        save()
                    }
                }
                .padding(18)
            }
            .scrollIndicators(.hidden)
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
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

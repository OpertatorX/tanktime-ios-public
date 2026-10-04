import SwiftUI

@MainActor
final class AppStore: ObservableObject {
    @Published var tanks: [TankProfile] { didSet { save() } }
    @Published var appliances: [AppliancePreset] { didSet { save() } }
    @Published var history: [FuelCalculation] { didSet { save() } }
    @Published var unitSystem: UnitSystem { didSet { save() } }

    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {
        if LaunchConfig.screenshotMode {
            let rvTank = String(localized: "RV cylinder")
            let grillTank = String(localized: "Grill cylinder")
            let backupTank = String(localized: "Backup cylinder")
            tanks = [
                TankProfile(name: rvTank, capacityLb: 30, tareWeightLb: 24),
                TankProfile(name: grillTank, capacityLb: 20, tareWeightLb: 17),
                TankProfile(name: backupTank, capacityLb: 20, tareWeightLb: 17)
            ]
            appliances = AppliancePreset.defaults
            history = [
                FuelCalculation(tankName: rvTank, applianceName: "RV furnace", fuelRemainingLb: 18.4, drawBTUPerHour: 30_000, runtimeHours: 13.2),
                FuelCalculation(tankName: grillTank, applianceName: "Gas grill", fuelRemainingLb: 11.0, drawBTUPerHour: 35_000, runtimeHours: 6.8),
                FuelCalculation(tankName: rvTank, applianceName: "Camp stove", fuelRemainingLb: 20.2, drawBTUPerHour: 20_000, runtimeHours: 21.8)
            ]
            unitSystem = LaunchConfig.units ?? .imperial
            return
        }

        tanks = Self.load([TankProfile].self, key: "tanks") ?? [
            TankProfile(name: String(localized: "Standard cylinder"), capacityLb: 20, tareWeightLb: 17)
        ]
        appliances = Self.load([AppliancePreset].self, key: "appliances") ?? AppliancePreset.defaults
        history = Self.load([FuelCalculation].self, key: "history") ?? []
        unitSystem = UnitSystem(rawValue: defaults.string(forKey: "unitSystem") ?? "imperial") ?? .imperial
    }

    func addHistory(_ item: FuelCalculation) {
        history.insert(item, at: 0)
        if history.count > 200 { history = Array(history.prefix(200)) }
    }

    func deleteTank(at offsets: IndexSet) { tanks.remove(atOffsets: offsets) }
    func deleteHistory(at offsets: IndexSet) { history.remove(atOffsets: offsets) }

    private func save() {
        if LaunchConfig.screenshotMode { return }
        if let data = try? encoder.encode(tanks) { defaults.set(data, forKey: "tanks") }
        if let data = try? encoder.encode(appliances) { defaults.set(data, forKey: "appliances") }
        if let data = try? encoder.encode(history) { defaults.set(data, forKey: "history") }
        defaults.set(unitSystem.rawValue, forKey: "unitSystem")
    }

    private static func load<T: Decodable>(_ type: T.Type, key: String) -> T? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(type, from: data)
    }
}

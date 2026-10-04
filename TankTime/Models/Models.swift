import Foundation

enum UnitSystem: String, Codable, CaseIterable, Identifiable {
    case imperial, metric
    var id: String { rawValue }
}

struct TankProfile: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var capacityLb: Double
    var tareWeightLb: Double
    var refillThreshold: Double = 0.20

    static let sampleSizes: [(String, Double)] = [
        ("20 lb", 20), ("30 lb", 30), ("40 lb", 40), ("100 lb", 100)
    ]
}

struct AppliancePreset: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var btuPerHour: Double
    var localizedName: String { NSLocalizedString(name, comment: "Appliance preset") }
    var symbol: String

    static let defaults: [AppliancePreset] = [
        .init(name: "Gas grill", btuPerHour: 35_000, symbol: "flame.fill"),
        .init(name: "Patio heater", btuPerHour: 48_000, symbol: "sun.max.fill"),
        .init(name: "RV furnace", btuPerHour: 30_000, symbol: "caravan.fill"),
        .init(name: "Camp stove", btuPerHour: 20_000, symbol: "tent.fill"),
        .init(name: "Portable heater", btuPerHour: 18_000, symbol: "heater.vertical.fill"),
        .init(name: "Generator", btuPerHour: 40_000, symbol: "bolt.fill")
    ]
}

struct FuelCalculation: Identifiable, Codable, Hashable {
    var id = UUID()
    var date = Date()
    var tankName: String
    var applianceName: String
    var fuelRemainingLb: Double
    var drawBTUPerHour: Double
    var runtimeHours: Double
}

enum PropaneMath {
    static let btuPerPound = 21_548.0
    static let poundsPerKilogram = 2.204_622_621_8

    static func remainingFuelLb(scaleWeightLb: Double, tareWeightLb: Double, capacityLb: Double) -> Double {
        min(max(scaleWeightLb - tareWeightLb, 0), max(capacityLb, 0))
    }

    static func fillFraction(fuelLb: Double, capacityLb: Double) -> Double {
        guard capacityLb > 0 else { return 0 }
        return min(max(fuelLb / capacityLb, 0), 1)
    }

    static func runtimeHours(fuelLb: Double, btuPerHour: Double) -> Double {
        guard fuelLb > 0, btuPerHour > 0 else { return 0 }
        return fuelLb * btuPerPound / btuPerHour
    }

    static func fuelBurnLb(hours: Double, btuPerHour: Double) -> Double {
        guard hours > 0, btuPerHour > 0 else { return 0 }
        return hours * btuPerHour / btuPerPound
    }

    static func dailyFuelBurnLb(loads: [(btuPerHour: Double, hoursPerDay: Double)]) -> Double {
        loads.reduce(0) { partial, load in
            partial + fuelBurnLb(hours: load.hoursPerDay, btuPerHour: load.btuPerHour)
        }
    }

    static func requiredFuelLb(dailyBurnLb: Double, tripDays: Double, reserveFraction: Double) -> Double {
        guard dailyBurnLb > 0, tripDays > 0 else { return 0 }
        let reserve = min(max(reserveFraction, 0), 0.95)
        return dailyBurnLb * tripDays / (1 - reserve)
    }

    static func cylindersNeeded(requiredFuelLb: Double, usableCurrentFuelLb: Double, fullCylinderCapacityLb: Double) -> Int {
        guard requiredFuelLb > 0 else { return 0 }
        let remaining = max(requiredFuelLb - max(usableCurrentFuelLb, 0), 0)
        guard remaining > 0, fullCylinderCapacityLb > 0 else { return 0 }
        return Int(ceil(remaining / fullCylinderCapacityLb))
    }

    static func fuelToAcquireLb(requiredFuelLb: Double, currentFuelLb: Double) -> Double {
        max(requiredFuelLb - max(currentFuelLb, 0), 0)
    }
    static func projectedCost(requiredFuelLb: Double, pricePerLb: Double) -> Double {
        max(requiredFuelLb, 0) * max(pricePerLb, 0)
    }
}

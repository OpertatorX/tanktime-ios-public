import XCTest
@testable import TankTime

final class PropaneMathTests: XCTestCase {
    func testRemainingFuelSubtractsTare() {
        XCTAssertEqual(
            PropaneMath.remainingFuelLb(scaleWeightLb: 29, tareWeightLb: 17, capacityLb: 20),
            12,
            accuracy: 0.0001
        )
    }

    func testRemainingFuelClampsToCapacity() {
        XCTAssertEqual(
            PropaneMath.remainingFuelLb(scaleWeightLb: 50, tareWeightLb: 17, capacityLb: 20),
            20,
            accuracy: 0.0001
        )
    }

    func testRuntimeUsesEnergyContent() {
        let hours = PropaneMath.runtimeHours(fuelLb: 20, btuPerHour: 40_000)
        XCTAssertEqual(hours, 10.774, accuracy: 0.01)
    }

    func testFuelBurnRoundTrip() {
        let burned = PropaneMath.fuelBurnLb(hours: 3.5, btuPerHour: 35_000)
        let runtime = PropaneMath.runtimeHours(fuelLb: burned, btuPerHour: 35_000)
        XCTAssertEqual(runtime, 3.5, accuracy: 0.0001)
    }

    func testDailyFuelBurnCombinesMultipleLoads() {
        let burn = PropaneMath.dailyFuelBurnLb(loads: [
            (btuPerHour: 30_000, hoursPerDay: 2),
            (btuPerHour: 20_000, hoursPerDay: 1)
        ])
        XCTAssertEqual(burn, 80_000 / PropaneMath.btuPerPound, accuracy: 0.0001)
    }

    func testRequiredFuelIncludesReserve() {
        let required = PropaneMath.requiredFuelLb(
            dailyBurnLb: 2,
            tripDays: 4,
            reserveFraction: 0.20
        )
        XCTAssertEqual(required, 10, accuracy: 0.0001)
    }

    func testFuelToAcquireSubtractsFuelAlreadyOnHand() {
        XCTAssertEqual(
            PropaneMath.fuelToAcquireLb(requiredFuelLb: 30, currentFuelLb: 12),
            18,
            accuracy: 0.0001
        )
        XCTAssertEqual(
            PropaneMath.fuelToAcquireLb(requiredFuelLb: 10, currentFuelLb: 15),
            0,
            accuracy: 0.0001
        )
    }
    func testCylinderCountUsesCurrentFuelFirst() {
        let extras = PropaneMath.cylindersNeeded(
            requiredFuelLb: 35,
            usableCurrentFuelLb: 10,
            fullCylinderCapacityLb: 20
        )
        XCTAssertEqual(extras, 2)
    }
}

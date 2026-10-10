import ECore
import EMFBase
import Foundation
import Model

/// Reports a failed check and stops with a failure status.
func expect(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        print("FAILED: \(message)")
        exit(1)
    }
}

/// Exercises the generated model whose names are Swift keywords or clash with the runtime: quoted names,
/// renamed members, a class that other classes extend, one-to-one references and values of every kind.
@main
struct Check {
    static func main() {
        let factory = SwiftnamesPackage.shared.factory
        let vehicle: VehicleImpl = factory.createVehicle()
        vehicle.guard = "g"
        vehicle.class = "c"
        vehicle.operator = 3
        vehicle.repeat = true
        vehicle.where = "w"
        vehicle.in = "i"
        vehicle.protocol = "p"
        vehicle.id_ = "identifier"
        vehicle.hash_ = 9
        vehicle.default = "d"
        expect(vehicle.guard == "g" && vehicle.id_ == "identifier" && vehicle.hash_ == 9, "renamed members")
        expect(vehicle.id != EUUID(), "the identifier is the runtime's")

        let guardFeature = SwiftnamesPackage.shared.eVehicle.allStructuralFeatures.first { $0.name == "guard" }!
        expect((vehicle.eGet(guardFeature) as? String) == "g", "reflective read of a quoted name")
        vehicle.eSet(guardFeature, "h")
        expect(vehicle.guard == "h", "reflective write of a quoted name")

        let truck = factory.createTruck()
        let driver = factory.createDriver()
        driver.vehicle = truck
        expect(truck.driver === driver, "a one-to-one reference sets its opposite")
        driver.vehicle = vehicle
        expect(truck.driver == nil && vehicle.driver === driver, "a one-to-one reference moves its opposite")

        let first = factory.createTruck()
        let second = factory.createTruck()
        first.trailer = second
        expect(second.towedBy === first, "a reference to the same class sets its opposite")
        first.trailer = nil
        expect(second.towedBy == nil, "clearing a reference to the same class clears its opposite")

        let anyVehicle: any Vehicle = truck
        expect(anyVehicle.hue == .green, "the default literal of the model")
        expect(truck.load == 2.5 && truck.plate == "N/A", "the defaults of the model")
        let named: any `Type` = truck
        expect(named.name == "say \"hi\"\n\\there", "string defaults are escaped")

        let wheel = factory.createVehicle()
        let part = PartsFactory.shared.createWheel()
        wheel.wheels.append(part)
        part.vehicle = wheel
        expect(part.vehicle === wheel, "a reference to a class of another package")

        let values = factory.createValues()
        expect(values.initial == "x" && values.huge == 99_999_999_999 && values.count == 7, "defaults of values")
        expect(values.ratio == 0.5 && values.tiny == 0 && values.flag == nil, "zero values and no values")
        values.payload = "anything"
        expect(values.payload != nil, "any Ecore value is kept")
        let date = factory.createDate()
        date.when = Date(timeIntervalSince1970: 0)
        expect(date.when == Date(timeIntervalSince1970: 0), "dates are kept")

        expect(Hue(literalText: "blue") == .blue && Hue.red.literalText == "red", "enumerations")
        expect(Hue.allCases.contains(.red) && Hue.allCases.contains(.blue), "enumerations are iterable")
        let hueData = try! JSONEncoder().encode(Hue.blue)
        expect(try! JSONDecoder().decode(Hue.self, from: hueData) == .blue, "enumerations survive a JSON round trip")
        expect(Mood.allCases.isEmpty, "an enumeration without literals has no cases")
        expect(factory.create(SwiftnamesPackage.shared.eVehicle) is VehicleImpl, "the factory creates the class")
        expect(factory.create(SwiftnamesPackage.shared.eType) == nil, "no object for an abstract class")
        _ = PartsFactory.shared.createSelf()
        _ = PartsFactory.shared.createProtocol()
        _ = PartsFactory.shared.createString()

        print("checks passed")
    }
}

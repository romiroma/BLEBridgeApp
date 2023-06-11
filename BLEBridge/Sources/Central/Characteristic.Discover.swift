
import ComposableArchitecture
import CoreBluetooth

extension Characteristic {

    public typealias Discover = PropertyDiscover<[Characteristic.Discovered]>
}

extension Characteristic {

    public struct Discovered: Equatable, Hashable {

        public static func == (lhs: Characteristic.Discovered, rhs: Characteristic.Discovered) -> Bool {
            lhs.id == rhs.id
        }

        public func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }


        let id: State.ID
        let name: String
        let property: CBCharacteristicProperties

        public init(
            id: State.ID,
            name: String,
            property: CBCharacteristicProperties
        ) {
            self.id = id
            self.name = name
            self.property = property
        }
    }
}

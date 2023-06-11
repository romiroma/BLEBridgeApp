
import ComposableArchitecture
import CoreBluetooth
import Foundation


extension Service {

    public typealias Discover = PropertyDiscover<[Service.Discovered]>
}

extension Service {

    public struct Discovered: Equatable, Hashable {

        let id: CBUUID
        let name: String

        public init(id: CBUUID, name: String) {
            self.id = id
            self.name = name
        }
    }
}

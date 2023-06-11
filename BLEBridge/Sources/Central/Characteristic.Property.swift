

import ComposableArchitecture
import CoreBluetooth

public extension Characteristic {

    struct Property: ReducerProtocol {

        public struct State: Equatable, Hashable {

            public var usage: Usage? = .none
            private let permittedUsage: Set<Usage?> = [.none, .notify, .writeWithoutResponse]
            public var supportedUsage: [Usage?]

            public var canBeUsedFor: [Usage?] = []

            init(_ property: CBCharacteristicProperties) {

                supportedUsage = Usage.allCases.filter { property.contains($0.property) }
                supportedUsage.insert(.none, at: 0)
                canBeUsedFor = .init(permittedUsage.intersection(supportedUsage))
            }
        }

        public enum Action: Equatable {

            case use(Usage?)
        }

        public var body: some ReducerProtocolOf<Property> {

            Reduce { state, action in

                switch action {

                case .use(let usage) where state.canBeUsedFor.contains(usage):
                    state.usage = usage
                default:
                    break
                }

                return .none
            }
        }
    }
}

extension Optional: Identifiable where Wrapped == Characteristic.Property.Usage {

    public var id: UInt {

        switch self {
        case .none:
            return 0
        case .some(let usage):
            return usage.id
        }
    }
}

public extension Characteristic.Property {

    enum Usage: UInt, Identifiable, CaseIterable, Equatable, Hashable {

        public var id: UInt {
            property.rawValue
        }

        public var property: CBCharacteristicProperties {

            let property: CBCharacteristicProperties

            switch self {
            case .broadcast:
                property = .broadcast
            case .read:
                property = .read
            case .writeWithoutResponse:
                property = .writeWithoutResponse
            case .write:
                property = .write
            case .notify:
                property = .notify
            case .indicate:
                property = .indicate
            case .authenticatedSignedWrites:
                property = .authenticatedSignedWrites
            case .extendedProperties:
                property = .extendedProperties
            }

            return property
        }

        case broadcast
        case read
        case writeWithoutResponse
        case write
        case notify
        case indicate
        case authenticatedSignedWrites
        case extendedProperties
    }
}

extension CBCharacteristicProperties {

    public func can(_ usage: Characteristic.Property.Usage?) -> Bool {

        guard let usage else { return true }
        return contains(usage.property)
    }
}

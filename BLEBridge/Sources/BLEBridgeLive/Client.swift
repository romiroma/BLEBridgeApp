
import Combine
import ComposableArchitecture
import CoreBluetooth
import Foundation
import Central

extension DependencyValues.ClientKey: DependencyKey {

    public static var liveValue: Client {
        DependencyValues.client
    }
}

class ClientImpl: NSObject, Client {

    let clientOutput: PassthroughSubject<Data, Never> = .init()
    let input: PassthroughSubject<Data, Never> = .init()
    private(set) lazy var output: AnyPublisher<Data, Never> = clientOutput
        .eraseToAnyPublisher()

    private var peripheralID: UUID?
    private var serviceID: CBUUID?
    private var rxID: CBUUID?
    private var txID: CBUUID?

    private var peripheralCancellable: AnyCancellable?
    private let bluetoothQueue: DispatchQueue
    private let peripheralStorage: Storage<CBPeripheral>
    private let servicesStorage: Storage<CBService>

    init(
        bluetoothQueue: DispatchQueue,
        peripheralStorage: Storage<CBPeripheral>,
        servicesStorage: Storage<CBService>
    ) {
        self.bluetoothQueue = bluetoothQueue
        self.peripheralStorage = peripheralStorage
        self.servicesStorage = servicesStorage
    }

    func start(
        peripheralID: UUID,
        serviceID: CBUUID,
        rxID: CBUUID,
        txID: CBUUID
    ) -> AnyPublisher<Void, Never> {

        self.peripheralID = peripheralID
        self.serviceID = serviceID
        self.rxID = rxID
        self.txID = txID

        guard let peripheral = peripheralStorage[peripheralID],
              let service = servicesStorage[serviceID] else {
            return Just(()).eraseToAnyPublisher()
        }

        var tx: CBCharacteristic?
        var rx: CBCharacteristic?

        for characteristic in service.characteristics ?? [] {

            if characteristic.id == txID {
                tx = characteristic
            } else if characteristic.id == rxID {
                rx = characteristic
            }
        }

        guard let rx, let tx else { return Just(()).eraseToAnyPublisher() }

        bluetoothQueue.async {
            peripheral.setNotifyValue(true, for: rx)
        }

        return input.receive(on: bluetoothQueue).map { [weak peripheral] data in
            guard let peripheral else {
                return
            }
            peripheral.writeValue(data, for: tx, type: .withoutResponse)
        }.eraseToAnyPublisher()
    }

    func stop() {

        guard let peripheralID,
              let serviceID,
              let rxID else {
            return
        }

        guard let peripheral = peripheralStorage[peripheralID],
              let service = servicesStorage[serviceID] else {
            return
        }

        var rx: CBCharacteristic?

        for characteristic in service.characteristics ?? [] where characteristic.id == rxID {
            rx = characteristic
            break
        }

        guard let rx else { return }

        bluetoothQueue.async {
            peripheral.setNotifyValue(false, for: rx)
        }
    }
}

extension ClientImpl: CBPeripheralDelegate {

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?) {

            guard peripheral.id == self.peripheralID,
                  characteristic.id == self.txID else {
                return
            }
        }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?) {

            guard peripheral.id == self.peripheralID,
                  characteristic.id == self.rxID,
                  let data = characteristic.value else {
                return
            }

            Task(priority: .high) {
                self.clientOutput.send(data)
            }
        }
}
